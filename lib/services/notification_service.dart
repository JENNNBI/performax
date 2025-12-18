import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _pushNotificationsKey = 'push_notifications';

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('⚠️ Notification permission request error: $e');
      return false;
    }
  }

  Future<void> enableNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, enabled);
    } catch (e) {
      debugPrint('⚠️ Persist notifications_enabled failed: $e');
    }
  }

  Future<void> setEmailNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emailNotificationsKey, enabled);
    } catch (e) {
      debugPrint('⚠️ Persist email_notifications failed: $e');
    }
  }

  Future<void> setPushNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pushNotificationsKey, enabled);
    } catch (e) {
      debugPrint('⚠️ Persist push_notifications failed: $e');
    }
  }
}
