import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/video_watch_session.dart';

/// Video Session Service
/// 
/// Manages video watch sessions with data persistence
/// Tracks watch time, branch, and grade level information
class VideoSessionService {
  static const String _sessionsKey = 'video_watch_sessions';
  static const String _currentSessionKey = 'current_video_session';
  
  // Singleton
  static final VideoSessionService _instance = VideoSessionService._internal();
  factory VideoSessionService() => _instance;
  VideoSessionService._internal();
  
  /// Save current session to persistent storage
  Future<void> saveCurrentSession(VideoWatchSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = jsonEncode(session.toMap());
      await prefs.setString(_currentSessionKey, sessionJson);
      
      debugPrint('💾 Session saved: ${session.getMetricFormat()}');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
    }
  }
  
  /// Get current session from storage
  Future<VideoWatchSession?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_currentSessionKey);
      
      if (sessionJson != null) {
        final map = jsonDecode(sessionJson) as Map<String, dynamic>;
        return VideoWatchSession.fromMap(map);
      }
    } catch (e) {
      debugPrint('❌ Error loading session: $e');
    }
    return null;
  }
  
  /// Clear current session
  Future<void> clearCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentSessionKey);
      debugPrint('🗑️ Current session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }
  
  /// Save completed session to history
  Future<void> saveToHistory(VideoWatchSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history
      final historyJson = prefs.getString(_sessionsKey);
      List<Map<String, dynamic>> history = [];
      
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List;
        history = decoded.cast<Map<String, dynamic>>();
      }
      
      // Add new session
      history.add(session.toMap());
      
      // Keep only last 100 sessions
      if (history.length > 100) {
        history = history.sublist(history.length - 100);
      }
      
      // Save back
      await prefs.setString(_sessionsKey, jsonEncode(history));
      
      debugPrint('📚 Session saved to history (${history.length} total)');
    } catch (e) {
      debugPrint('❌ Error saving to history: $e');
    }
  }
  
  /// Get all sessions from history
  Future<List<VideoWatchSession>> getSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_sessionsKey);
      
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List;
        return decoded
            .cast<Map<String, dynamic>>()
            .map((map) => VideoWatchSession.fromMap(map))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading history: $e');
    }
    return [];
  }
  
  /// Get sessions for specific branch and grade
  Future<List<VideoWatchSession>> getSessionsByBranchAndGrade({
    required String branch,
    required String gradeLevel,
  }) async {
    final history = await getSessionHistory();
    return history.where((session) => 
      session.branch == branch && session.gradeLevel == gradeLevel
    ).toList();
  }
}

