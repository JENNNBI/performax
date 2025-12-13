import 'dart:convert';
import '../models/qr_content.dart';
import 'qr_code_service.dart';

/// Service for generating QR code data with embedded actions
class QRGeneratorService {
  static final QRGeneratorService _instance = QRGeneratorService._internal();
  factory QRGeneratorService() => _instance;
  QRGeneratorService._internal();

  static QRGeneratorService get instance => _instance;

  /// Generate QR data for video content
  String generateVideoQR({
    required String videoId,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeService.instance.generateVideoQRData(videoId, title);
  }

  /// Generate QR data for subject content
  String generateSubjectQR({
    required String subjectName,
    required String sectionType,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeService.instance.generateSubjectQRData(subjectName, sectionType, title);
  }

  /// Generate QR data for exam content
  String generateExamQR({
    required String subjectName,
    required String grade,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeService.instance.generateExamQRData(subjectName, grade, title);
  }

  /// Generate QR data for practice content
  String generatePracticeQR({
    required String subjectName,
    required String grade,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeService.instance.generatePracticeQRData(subjectName, grade, title);
  }

  /// Generate QR data for URL content
  String generateURLQR({
    required String url,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    final content = QRContent.url(
      id: url,
      title: title,
      url: url,
      description: description,
      metadata: metadata,
    );
    return QRCodeService.instance.generateQRData(content);
  }

  /// Generate QR data for text content
  String generateTextQR({
    required String text,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    final content = QRContent.text(
      id: text,
      title: title,
      text: text,
      description: description,
      metadata: metadata,
    );
    return QRCodeService.instance.generateQRData(content);
  }

  /// Generate simple format QR data (for backward compatibility)
  String generateSimpleVideoQR(String videoId) {
    return videoId; // Direct video ID for simple format
  }

  String generateSimpleSubjectQR(String subjectName, String sectionType) {
    return 'subject:$subjectName:$sectionType';
  }

  String generateSimpleExamQR(String subjectName, String grade) {
    return 'exam:$subjectName:$grade';
  }

  String generateSimplePracticeQR(String subjectName, String grade) {
    return 'practice:$subjectName:$grade';
  }

  /// Generate QR data with custom format
  String generateCustomQR({
    required String type,
    required String id,
    required String title,
    Map<String, dynamic>? data,
  }) {
    final content = {
      'type': type,
      'id': id,
      'title': title,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return json.encode(content);
  }

  /// Get QR code preview information
  Map<String, dynamic> getQRPreview(String qrData) {
    try {
      // Try to parse as JSON first
      if (qrData.trim().startsWith('{') && qrData.trim().endsWith('}')) {
        final Map<String, dynamic> jsonData = json.decode(qrData);
        return {
          'type': 'JSON',
          'title': jsonData['title'] ?? 'QR Code',
          'description': jsonData['description'] ?? 'Custom QR content',
          'data': jsonData,
        };
      }

      // Check for simple formats
      if (qrData.contains('subject:')) {
        final parts = qrData.split(':');
        return {
          'type': 'Subject',
          'title': 'Subject Content',
          'description': '${parts[1]} - ${parts[2]}',
          'data': {'subject': parts[1], 'section': parts[2]},
        };
      }

      if (qrData.contains('exam:')) {
        final parts = qrData.split(':');
        return {
          'type': 'Exam',
          'title': 'Exam Content',
          'description': '${parts[1]} - Grade ${parts[2]}',
          'data': {'subject': parts[1], 'grade': parts[2]},
        };
      }

      if (qrData.contains('practice:')) {
        final parts = qrData.split(':');
        return {
          'type': 'Practice',
          'title': 'Practice Content',
          'description': '${parts[1]} - Grade ${parts[2]}',
          'data': {'subject': parts[1], 'grade': parts[2]},
        };
      }

      if (qrData.contains('video:')) {
        final parts = qrData.split(':');
        return {
          'type': 'Video',
          'title': parts.length > 2 ? parts[2] : 'Video Content',
          'description': 'Video ID: ${parts[1]}',
          'data': {'videoId': parts[1]},
        };
      }

      if (Uri.tryParse(qrData)?.hasAbsolutePath == true) {
        return {
          'type': 'URL',
          'title': 'External Link',
          'description': qrData,
          'data': {'url': qrData},
        };
      }

      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(qrData)) {
        return {
          'type': 'YouTube Video',
          'title': 'YouTube Video',
          'description': 'Video ID: $qrData',
          'data': {'videoId': qrData},
        };
      }

      return {
        'type': 'Text',
        'title': 'Text Content',
        'description': qrData,
        'data': {'text': qrData},
      };
    } catch (e) {
      return {
        'type': 'Unknown',
        'title': 'Unknown Content',
        'description': 'Could not parse QR data',
        'data': {'raw': qrData},
      };
    }
  }

  /// Validate QR data format
  bool isValidQRData(String qrData) {
    try {
      // Check if it's valid JSON
      if (qrData.trim().startsWith('{') && qrData.trim().endsWith('}')) {
        json.decode(qrData);
        return true;
      }

      // Check simple formats
      final patterns = [
        RegExp(r'^subject:[^:]+:[^:]+$'),
        RegExp(r'^exam:[^:]+:\d+$'),
        RegExp(r'^practice:[^:]+:\d+$'),
        RegExp(r'^video:[^:]+:.+$'),
      ];

      for (final pattern in patterns) {
        if (pattern.hasMatch(qrData)) {
          return true;
        }
      }

      // Check URL
      if (Uri.tryParse(qrData)?.hasAbsolutePath == true) {
        return true;
      }

      // Check YouTube video ID
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(qrData)) {
        return true;
      }

      // Any non-empty text is valid
      return qrData.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
