import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';

/// Google Sheets Export Service
/// 
/// Handles secure HTTP requests to Apps Script Web App URL
/// for exporting user data to Google Sheets.
/// 
/// The service supports two modes:
/// 1. Direct data transfer: Sends user data in POST request
/// 2. Signal mode: Sends userId only, script retrieves from Firebase
class GoogleSheetsExportService {
  static GoogleSheetsExportService? _instance;
  factory GoogleSheetsExportService() => _instance ??= GoogleSheetsExportService._internal();
  GoogleSheetsExportService._internal();

  /// Get the Apps Script Web App URL from environment variables
  String? get _webAppUrl {
    return dotenv.env['GOOGLE_APPS_SCRIPT_WEB_APP_URL'];
  }

  /// Get the Apps Script access token (optional, for additional security)
  String? get _accessToken {
    return dotenv.env['GOOGLE_APPS_SCRIPT_ACCESS_TOKEN'];
  }

  /// Export user data to Google Sheets
  /// 
  /// [userProfile] - The user profile data to export
  /// [exportMode] - 'direct' to send data in request, 'signal' to only send userId
  /// [additionalData] - Optional additional data to include in export
  /// 
  /// Returns a result object with success status and message
  Future<ExportResult> exportDataToSheet({
    required UserProfile userProfile,
    ExportMode exportMode = ExportMode.direct,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate Web App URL is configured
      final webAppUrl = _webAppUrl;
      if (webAppUrl == null || webAppUrl.isEmpty) {
        debugPrint('❌ Google Sheets Export: Web App URL not configured');
        return ExportResult(
          success: false,
          message: 'Google Sheets export is not configured. Please contact support.',
          errorCode: 'MISSING_CONFIG',
        );
      }

      // Validate URL format
      final uri = Uri.tryParse(webAppUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        debugPrint('❌ Google Sheets Export: Invalid Web App URL format');
        return ExportResult(
          success: false,
          message: 'Invalid configuration. Please contact support.',
          errorCode: 'INVALID_URL',
        );
      }

      // Prepare request payload
      final payload = _buildPayload(
        userProfile: userProfile,
        exportMode: exportMode,
        additionalData: additionalData,
      );

      debugPrint('📤 Google Sheets Export: Sending request to ${uri.host}');
      debugPrint('📤 Export mode: $exportMode');
      debugPrint('📤 User ID: ${userProfile.userId}');

      // Make secure HTTP POST request
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      // Parse response
      return _parseResponse(response);

    } on http.ClientException catch (e) {
      debugPrint('❌ Google Sheets Export: Network error - $e');
      return ExportResult(
        success: false,
        message: 'Network error. Please check your internet connection.',
        errorCode: 'NETWORK_ERROR',
        errorDetails: e.toString(),
      );
    } on FormatException catch (e) {
      debugPrint('❌ Google Sheets Export: JSON parsing error - $e');
      return ExportResult(
        success: false,
        message: 'Invalid response from server. Please try again.',
        errorCode: 'PARSE_ERROR',
        errorDetails: e.toString(),
      );
    } catch (e) {
      debugPrint('❌ Google Sheets Export: Unexpected error - $e');
      return ExportResult(
        success: false,
        message: 'An unexpected error occurred. Please try again later.',
        errorCode: 'UNKNOWN_ERROR',
        errorDetails: e.toString(),
      );
    }
  }

  /// Build request payload based on export mode
  Map<String, dynamic> _buildPayload({
    required UserProfile userProfile,
    required ExportMode exportMode,
    Map<String, dynamic>? additionalData,
  }) {
    final payload = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'exportMode': exportMode.name,
    };

    if (exportMode == ExportMode.direct) {
      // Direct mode: Send all user data in the request
      payload['userData'] = userProfile.toMap();
      
      // Include additional data if provided
      if (additionalData != null && additionalData.isNotEmpty) {
        payload['additionalData'] = additionalData;
      }
    } else {
      // Signal mode: Only send userId, script will fetch from Firebase
      payload['userId'] = userProfile.userId;
      
      // Optionally include Firebase project ID if needed
      payload['firebaseProjectId'] = 'performax-e4b1c';
    }

    return payload;
  }

  /// Build HTTP request headers
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add access token if configured (for additional security)
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Parse HTTP response from Apps Script
  ExportResult _parseResponse(http.Response response) {
    debugPrint('📥 Google Sheets Export: Response status: ${response.statusCode}');
    debugPrint('📥 Response body: ${response.body}');

    // Check HTTP status code
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success status codes
      try {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        
        final success = jsonResponse['success'] as bool? ?? true;
        final message = jsonResponse['message'] as String? ?? 
                       jsonResponse['status'] as String? ?? 
                       'Data exported successfully';
        
        return ExportResult(
          success: success,
          message: message,
          data: jsonResponse,
        );
      } catch (e) {
        // Response is not JSON but status is OK
        return ExportResult(
          success: true,
          message: 'Data exported successfully',
          data: {'rawResponse': response.body},
        );
      }
    } else if (response.statusCode == 401) {
      // Unauthorized - missing or invalid credentials
      return ExportResult(
        success: false,
        message: 'Authorization failed. Please contact support.',
        errorCode: 'UNAUTHORIZED',
      );
    } else if (response.statusCode == 403) {
      // Forbidden - permission issue
      return ExportResult(
        success: false,
        message: 'Permission denied. Please contact support.',
        errorCode: 'FORBIDDEN',
      );
    } else if (response.statusCode == 404) {
      // Not found - incorrect URL or deployment issue
      return ExportResult(
        success: false,
        message: 'Service not found. This may indicate a deployment issue.',
        errorCode: 'NOT_FOUND',
      );
    } else if (response.statusCode == 500) {
      // Server error - Apps Script execution error
      try {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = jsonResponse['error'] as String? ?? 
                           jsonResponse['message'] as String? ?? 
                           'Server error occurred';
        
        return ExportResult(
          success: false,
          message: 'Server error: $errorMessage',
          errorCode: 'SERVER_ERROR',
          errorDetails: response.body,
        );
      } catch (e) {
        return ExportResult(
          success: false,
          message: 'Server error occurred. Please try again later.',
          errorCode: 'SERVER_ERROR',
          errorDetails: response.body,
        );
      }
    } else {
      // Other error codes
      return ExportResult(
        success: false,
        message: 'Request failed with status ${response.statusCode}',
        errorCode: 'HTTP_ERROR',
        errorDetails: response.body,
      );
    }
  }

  /// Test connection to Apps Script Web App
  /// Useful for debugging deployment and authorization issues
  Future<ExportResult> testConnection() async {
    try {
      final webAppUrl = _webAppUrl;
      if (webAppUrl == null || webAppUrl.isEmpty) {
        return ExportResult(
          success: false,
          message: 'Web App URL not configured',
          errorCode: 'MISSING_CONFIG',
        );
      }

      final uri = Uri.parse(webAppUrl);
      
      // Send a test request
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({
          'action': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return _parseResponse(response);
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Connection test failed: $e',
        errorCode: 'TEST_FAILED',
        errorDetails: e.toString(),
      );
    }
  }
}

/// Export modes for Google Sheets export
enum ExportMode {
  /// Direct mode: Send user data directly in HTTP request
  direct,
  
  /// Signal mode: Only send userId, Apps Script retrieves from Firebase
  signal,
}

/// Result of Google Sheets export operation
class ExportResult {
  final bool success;
  final String message;
  final String? errorCode;
  final String? errorDetails;
  final Map<String, dynamic>? data;

  ExportResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.errorDetails,
    this.data,
  });

  @override
  String toString() {
    return 'ExportResult(success: $success, message: $message, errorCode: $errorCode)';
  }
}
