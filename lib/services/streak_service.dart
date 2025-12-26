import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quest_service.dart';

/// Service to handle user login streak tracking
/// Tracks consecutive days of app usage with automatic reset logic
/// 
/// CRITICAL STREAK RESET RULES:
/// - Streak increments by 1 for consecutive day logins (1 day gap)
/// - Streak resets to 1 (first day) if consecutive usage period is broken (2+ days gap)
/// - Same day logins maintain the current streak value
/// - All streak data is strictly partitioned per user ID to prevent data contamination
class StreakService {
  // Legacy global keys (deprecated - kept for migration)
  static const String _legacyKeyLastLoginDate = 'last_login_date';
  static const String _legacyKeyCurrentStreak = 'current_streak';
  
  // User-specific key prefixes
  static const String _keyPrefixLastLoginDate = 'streak_last_login_';
  static const String _keyPrefixCurrentStreak = 'streak_current_';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get user-specific storage key for last login date
  String _getLastLoginKey(String userId) => '$_keyPrefixLastLoginDate$userId';
  
  /// Get user-specific storage key for current streak
  String _getCurrentStreakKey(String userId) => '$_keyPrefixCurrentStreak$userId';
  
  /// Migrate legacy global keys to user-specific keys
  /// This ensures existing users don't lose their streak data
  Future<void> _migrateLegacyData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if legacy keys exist
      if (prefs.containsKey(_legacyKeyLastLoginDate) || 
          prefs.containsKey(_legacyKeyCurrentStreak)) {
        
        final userSpecificLastLoginKey = _getLastLoginKey(userId);
        final userSpecificStreakKey = _getCurrentStreakKey(userId);
        
        // Only migrate if user-specific keys don't already exist
        if (!prefs.containsKey(userSpecificLastLoginKey) && 
            !prefs.containsKey(userSpecificStreakKey)) {
          
          debugPrint('🔄 Migrating legacy streak data to user-specific keys for user: $userId');
          
          // Migrate last login date
          if (prefs.containsKey(_legacyKeyLastLoginDate)) {
            final legacyLastLogin = prefs.getString(_legacyKeyLastLoginDate);
            if (legacyLastLogin != null) {
              await prefs.setString(userSpecificLastLoginKey, legacyLastLogin);
              debugPrint('✅ Migrated last login date');
            }
          }
          
          // Migrate current streak
          if (prefs.containsKey(_legacyKeyCurrentStreak)) {
            final legacyStreak = prefs.getInt(_legacyKeyCurrentStreak);
            if (legacyStreak != null) {
              await prefs.setInt(userSpecificStreakKey, legacyStreak);
              debugPrint('✅ Migrated current streak: $legacyStreak');
            }
          }
        }
        
        // Remove legacy keys after migration to prevent future contamination
        await prefs.remove(_legacyKeyLastLoginDate);
        await prefs.remove(_legacyKeyCurrentStreak);
        debugPrint('🧹 Removed legacy global streak keys');
      }
    } catch (e) {
      debugPrint('⚠️ Error during streak data migration: $e');
      // Don't throw - allow app to continue even if migration fails
    }
  }
  
  /// Check and update streak on app launch
  /// Returns the current streak count after update
  /// CRITICAL: This method ensures strict user isolation - each user's streak is stored separately
  Future<StreakData> checkAndUpdateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      
      // CRITICAL: Require authenticated user for streak tracking
      // Guest users cannot have persistent streaks to prevent data contamination
      if (user == null) {
        debugPrint('⚠️ No authenticated user - streak tracking skipped');
        return StreakData(
          currentStreak: 0,
          lastLoginDate: DateTime.now(),
          isNewStreak: false,
          isStreakIncremented: false,
          isStreakReset: false,
        );
      }
      
      final userId = user.uid;
      
      // Migrate legacy data if exists
      await _migrateLegacyData(userId);
      
      // Get current date (normalized to midnight for consistent comparison)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Load last login date and current streak from USER-SPECIFIC local storage
      final userSpecificLastLoginKey = _getLastLoginKey(userId);
      final userSpecificStreakKey = _getCurrentStreakKey(userId);
      
      final lastLoginString = prefs.getString(userSpecificLastLoginKey);
      int currentStreak = prefs.getInt(userSpecificStreakKey) ?? 0;
      
      DateTime? lastLoginDate;
      if (lastLoginString != null) {
        lastLoginDate = DateTime.parse(lastLoginString);
      }
      
      // Determine new streak value
      int newStreak;
      bool isNewStreak = false;
      bool isStreakIncremented = false;
      bool isStreakReset = false;
      
      if (lastLoginDate == null) {
        // First time user - initialize streak to 1
        newStreak = 1;
        isNewStreak = true;
        debugPrint('🔥 New user ($userId) - Initializing streak to 1');
      } else {
        final daysSinceLastLogin = today.difference(lastLoginDate).inDays;
        
        // CRITICAL: Handle edge case where lastLoginDate is in the future (timezone/clock issues)
        if (daysSinceLastLogin < 0) {
          // Last login appears to be in the future - treat as same day
          newStreak = currentStreak > 0 ? currentStreak : 1;
          debugPrint('⚠️ Last login date in future ($userId) - Treating as same day, streak: $newStreak');
        } else if (daysSinceLastLogin == 0) {
          // Same day login - maintain current streak (no change)
          newStreak = currentStreak > 0 ? currentStreak : 1;
          debugPrint('✅ Same day login ($userId) - Streak unchanged: $newStreak');
      } else if (daysSinceLastLogin == 1) {
        // Consecutive day - increment streak
        newStreak = currentStreak + 1;
        isStreakIncremented = true;
        debugPrint('🚀 Consecutive day login ($userId) - Streak incremented to $newStreak');
        // Quest event: daily login contributes to quests
        QuestService.instance.onDailyLogin();
      } else {
        // CRITICAL: Broken consecutive usage period - reset to first day (1)
        // Any gap of 2+ days breaks the streak and resets to day 1
        newStreak = 1;
        isStreakReset = true;
          debugPrint('💔 Streak broken: $daysSinceLastLogin day(s) since last login ($userId) - Reset to day 1');
        }
      }
      
      // Save to USER-SPECIFIC local storage
      await prefs.setString(userSpecificLastLoginKey, today.toIso8601String());
      await prefs.setInt(userSpecificStreakKey, newStreak);
      
      // Sync to Firebase (already user-specific via userId)
      await _syncToFirebase(userId, newStreak, today);
      
      return StreakData(
        currentStreak: newStreak,
        lastLoginDate: today,
        isNewStreak: isNewStreak,
        isStreakIncremented: isStreakIncremented,
        isStreakReset: isStreakReset,
      );
    } catch (e) {
      debugPrint('❌ Error checking/updating streak: $e');
      // Return default streak data on error
      return StreakData(
        currentStreak: 1,
        lastLoginDate: DateTime.now(),
        isNewStreak: true,
        isStreakIncremented: false,
        isStreakReset: false,
      );
    }
  }
  
  /// Sync streak data to Firebase
  /// CRITICAL: Firebase storage is already user-specific via userId document path
  Future<void> _syncToFirebase(String userId, int streak, DateTime lastLogin) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      
      await docRef.set({
        'streak': {
          'current': streak,
          'lastLoginDate': Timestamp.fromDate(lastLogin),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      debugPrint('☁️ Synced streak to Firebase for user $userId: Streak $streak');
    } catch (e) {
      debugPrint('⚠️ Failed to sync streak to Firebase for user $userId: $e');
      // Don't throw - allow local streak to work even if Firebase fails
    }
  }
  
  /// Get current streak data (without updating)
  Future<StreakData> getStreakData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StreakData(
          currentStreak: 0,
          lastLoginDate: DateTime.now(),
          isNewStreak: false,
          isStreakIncremented: false,
          isStreakReset: false,
        );
      }
      
      final userId = user.uid;
      final prefs = await SharedPreferences.getInstance();
      
      final userSpecificLastLoginKey = _getLastLoginKey(userId);
      final userSpecificStreakKey = _getCurrentStreakKey(userId);
      
      final lastLoginString = prefs.getString(userSpecificLastLoginKey);
      int currentStreak = prefs.getInt(userSpecificStreakKey) ?? 0;
      
      DateTime lastLoginDate = DateTime.now();
      if (lastLoginString != null) {
        lastLoginDate = DateTime.parse(lastLoginString);
      }
      
      return StreakData(
        currentStreak: currentStreak,
        lastLoginDate: lastLoginDate,
        isNewStreak: false,
        isStreakIncremented: false,
        isStreakReset: false,
      );
    } catch (e) {
      debugPrint('❌ Error getting streak data: $e');
      return StreakData(
        currentStreak: 0,
        lastLoginDate: DateTime.now(),
        isNewStreak: false,
        isStreakIncremented: false,
        isStreakReset: false,
      );
    }
  }

  /// Get current streak (from user-specific local storage)
  /// Returns 0 if user is not authenticated
  Future<int> getCurrentStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user - cannot get streak');
        return 0;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userSpecificStreakKey = _getCurrentStreakKey(user.uid);
      return prefs.getInt(userSpecificStreakKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting current streak: $e');
      return 0;
    }
  }
  
  /// Load streak from Firebase (for cross-device sync)
  /// CRITICAL: Only loads data for the currently authenticated user
  /// Also validates and resets streak if consecutive usage period was broken
  Future<void> loadStreakFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user - cannot load streak from Firebase');
        return;
      }
      
      final userId = user.uid;
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final streakData = data?['streak'] as Map<String, dynamic>?;
        
        if (streakData != null) {
          final firebaseStreak = streakData['current'] as int?;
          final firebaseLastLogin = (streakData['lastLoginDate'] as Timestamp?)?.toDate();
          
          if (firebaseStreak != null && firebaseLastLogin != null) {
            // CRITICAL: Validate streak - check if consecutive usage period was broken
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final lastLoginNormalized = DateTime(
              firebaseLastLogin.year,
              firebaseLastLogin.month,
              firebaseLastLogin.day,
            );
            final daysSinceLastLogin = today.difference(lastLoginNormalized).inDays;
            
            int validatedStreak = firebaseStreak;
            
            // If streak was broken (2+ days gap), reset to 1
            if (daysSinceLastLogin > 1) {
              validatedStreak = 1;
              debugPrint('⚠️ Streak broken when loading from Firebase: $daysSinceLastLogin day(s) gap - Reset to 1');
              // Sync the corrected streak back to Firebase
              await _syncToFirebase(userId, validatedStreak, today);
            }
            
            // Update USER-SPECIFIC local storage with validated Firebase data
            final prefs = await SharedPreferences.getInstance();
            final userSpecificLastLoginKey = _getLastLoginKey(userId);
            final userSpecificStreakKey = _getCurrentStreakKey(userId);
            
            await prefs.setInt(userSpecificStreakKey, validatedStreak);
            await prefs.setString(userSpecificLastLoginKey, today.toIso8601String());
            
            debugPrint('📥 Loaded streak from Firebase for user $userId: Streak $validatedStreak');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading streak from Firebase: $e');
    }
  }
  
  /// Reset streak manually (for testing or admin purposes)
  /// CRITICAL: Only resets streak for the currently authenticated user
  Future<void> resetStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user - cannot reset streak');
        return;
      }
      
      final userId = user.uid;
      final prefs = await SharedPreferences.getInstance();
      
      // Remove USER-SPECIFIC keys
      final userSpecificLastLoginKey = _getLastLoginKey(userId);
      final userSpecificStreakKey = _getCurrentStreakKey(userId);
      
      await prefs.remove(userSpecificLastLoginKey);
      await prefs.remove(userSpecificStreakKey);
      
      // Also remove from Firebase
      await _firestore.collection('users').doc(userId).update({
        'streak': FieldValue.delete(),
      });
      
      debugPrint('🔄 Streak reset successfully for user $userId');
    } catch (e) {
      debugPrint('❌ Error resetting streak: $e');
    }
  }
  
  /// Clean up streak data for a specific user (e.g., on logout)
  /// This ensures no data leakage when switching users
  Future<void> cleanupUserStreakData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userSpecificLastLoginKey = _getLastLoginKey(userId);
      final userSpecificStreakKey = _getCurrentStreakKey(userId);
      
      await prefs.remove(userSpecificLastLoginKey);
      await prefs.remove(userSpecificStreakKey);
      
      debugPrint('🧹 Cleaned up streak data for user $userId');
    } catch (e) {
      debugPrint('⚠️ Error cleaning up streak data for user $userId: $e');
    }
  }
}

/// Data class to hold streak information
class StreakData {
  final int currentStreak;
  final DateTime lastLoginDate;
  final bool isNewStreak;
  final bool isStreakIncremented;
  final bool isStreakReset;
  
  StreakData({
    required this.currentStreak,
    required this.lastLoginDate,
    required this.isNewStreak,
    required this.isStreakIncremented,
    required this.isStreakReset,
  });
  
  /// Get appropriate message based on streak status
  String getMessage() {
    if (isNewStreak) {
      return 'Performax\'a hoş geldiniz! Streakınız başladı!';
    } else if (isStreakIncremented) {
      return 'Harika! Streakınız devam ediyor!';
    } else if (isStreakReset) {
      return 'Streak sıfırlandı. Yeniden başlayalım!';
    } else {
      return 'Bugün zaten giriş yaptınız!';
    }
  }
  
  /// Get appropriate icon based on streak status
  IconData getIcon() {
    if (isStreakIncremented && currentStreak >= 7) {
      return Icons.emoji_events_rounded; // Trophy for week+
    } else if (isStreakIncremented) {
      return Icons.local_fire_department_rounded; // Fire for active streak
    } else if (isStreakReset) {
      return Icons.refresh_rounded; // Refresh for reset
    } else if (isNewStreak) {
      return Icons.celebration_rounded; // Celebration for new
    } else {
      return Icons.check_circle_rounded; // Check for same day
    }
  }
  
  /// Get appropriate color based on streak status
  Color getColor() {
    if (isStreakIncremented && currentStreak >= 7) {
      return const Color(0xFFFFD700); // Gold for week+
    } else if (isStreakIncremented) {
      return const Color(0xFFFF6B35); // Orange-red for active streak
    } else if (isStreakReset) {
      return const Color(0xFF667eea); // Blue for reset
    } else if (isNewStreak) {
      return const Color(0xFF4CAF50); // Green for new
    } else {
      return const Color(0xFF2196F3); // Blue for same day
    }
  }
}
