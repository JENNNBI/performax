import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:performax/screens/password_reset_confirmation_screen.dart';
import 'package:performax/screens/login_screen.dart';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  static DeepLinkHandler get instance => _instance;

  /// Handle incoming Firebase Auth action links
  Future<void> handleFirebaseActionLink(String link, BuildContext context) async {
    try {
      final uri = Uri.parse(link);
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];

      switch (mode) {
        case 'resetPassword':
          if (oobCode != null) {
            await _handlePasswordReset(oobCode, context);
          } else {
            _showError(context, 'Invalid password reset link');
          }
          break;
        case 'verifyEmail':
          if (oobCode != null) {
            await _handleEmailVerification(oobCode, context);
          } else {
            _showError(context, 'Invalid email verification link');
          }
          break;
        case 'recoverEmail':
          if (oobCode != null) {
            await _handleEmailRecovery(oobCode, context);
          } else {
            _showError(context, 'Invalid email recovery link');
          }
          break;
        default:
          _showError(context, 'Unknown action type');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error processing link: $e');
      }
    }
  }

  /// Handle password reset action
  Future<void> _handlePasswordReset(String oobCode, BuildContext context) async {
    try {
      if (!context.mounted) return;
      // Navigate to password reset confirmation screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        PasswordResetConfirmationScreen.id,
        (route) => false,
        arguments: oobCode,
      );
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to handle password reset: $e');
      }
    }
  }

  /// Handle email verification action
  Future<void> _handleEmailVerification(String oobCode, BuildContext context) async {
    try {
      await FirebaseAuth.instance.applyActionCode(oobCode);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email başarıyla doğrulandı!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!context.mounted) return;
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.id,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String message;
      switch (e.code) {
        case 'expired-action-code':
          message = 'Doğrulama bağlantısı süresi dolmuş';
          break;
        case 'invalid-action-code':
          message = 'Geçersiz doğrulama bağlantısı';
          break;
        case 'user-disabled':
          message = 'Kullanıcı hesabı devre dışı bırakılmış';
          break;
        case 'user-not-found':
          message = 'Kullanıcı bulunamadı';
          break;
        default:
          message = 'Email doğrulanamadı: ${e.message}';
      }
      _showError(context, message);
    }
  }

  /// Handle email recovery action
  Future<void> _handleEmailRecovery(String oobCode, BuildContext context) async {
    try {
      await FirebaseAuth.instance.applyActionCode(oobCode);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email başarıyla geri yüklendi!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!context.mounted) return;
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.id,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String message;
      switch (e.code) {
        case 'expired-action-code':
          message = 'Geri yükleme bağlantısı süresi dolmuş';
          break;
        case 'invalid-action-code':
          message = 'Geçersiz geri yükleme bağlantısı';
          break;
        case 'user-disabled':
          message = 'Kullanıcı hesabı devre dışı bırakılmış';
          break;
        case 'user-not-found':
          message = 'Kullanıcı bulunamadı';
          break;
        default:
          message = 'Email geri yüklenemedi: ${e.message}';
      }
      _showError(context, message);
    }
  }

  /// Show error message to user
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );

    // Navigate to login screen
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.id,
      (route) => false,
    );
  }

  /// Parse Firebase Action URL to extract parameters
  static Map<String, String> parseActionUrl(String url) {
    final uri = Uri.parse(url);
    return {
      'mode': uri.queryParameters['mode'] ?? '',
      'oobCode': uri.queryParameters['oobCode'] ?? '',
      'continueUrl': uri.queryParameters['continueUrl'] ?? '',
      'lang': uri.queryParameters['lang'] ?? '',
    };
  }

  /// Validate if URL is a Firebase Auth action URL
  static bool isFirebaseActionUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters.containsKey('mode') && 
             uri.queryParameters.containsKey('oobCode');
    } catch (e) {
      return false;
    }
  }
} 