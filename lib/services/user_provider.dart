import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 USER PROVIDER - User-Specific Data Persistence
/// 
/// **CRITICAL ARCHITECTURE:**
/// - All SharedPreferences keys are prefixed with userId to prevent data bleeding
/// - Data persists across sessions (survives logout/login)
/// - RAM state is cleared on logout, but disk data remains
/// 
/// **Data Flow:**
/// 1. Login → loadUserData(userId) → Restore from disk
/// 2. Updates → saveUserData(userId) → Write to disk
/// 3. Logout → clearSession() → Clear RAM only (preserve disk)
class UserProvider extends ChangeNotifier {
  // Current User Session
  String? _currentUserId; // 🔑 CRITICAL: Tracks which user's data is loaded
  
  // User Avatar State
  String? _currentAvatarPath;
  String? _currentAvatarId;
  
  // Gamification State
  int _score = 100;
  int _rockets = 100;
  int _rank = 1982;
  
  // Personal Info (Optional - for offline access)
  String? _fullName;
  String? _email;
  String? _class;
  String? _gender;
  
  // Loading state tracking
  bool _isLoaded = false;

  // Getters
  String? get currentUserId => _currentUserId;
  String? get currentAvatarPath => _currentAvatarPath;
  String? get currentAvatarId => _currentAvatarId;
  bool get isLoaded => _isLoaded;
  
  // Gamification Getters
  int get score => _score;
  int get rockets => _rockets;
  int get rank => _rank;
  
  // Personal Info Getters
  String? get fullName => _fullName;
  String? get email => _email;
  String? get userClass => _class;
  String? get gender => _gender;

  /// 📥 LOAD USER DATA - Restore user's session from disk
  /// 
  /// **CRITICAL:** This MUST be called after successful login/authentication
  /// **Parameter:** userId - Firebase UID or email (consistent identifier)
  /// **Timing:** Immediately after FirebaseAuth.signIn() succeeds
  /// 
  /// **What it does:**
  /// 1. Sets _currentUserId to track session
  /// 2. Loads ALL user data from SharedPreferences using userId prefix
  /// 3. Updates RAM state
  /// 4. Notifies listeners to rebuild UI
  Future<void> loadUserData(String userId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📥 UserProvider: LOADING USER DATA');
      debugPrint('   User ID: $userId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = userId;
      
      // 🎨 Avatar Data (user-specific keys)
      _currentAvatarPath = prefs.getString('${userId}_avatar_path');
      _currentAvatarId = prefs.getString('${userId}_avatar_id');
      
      // 🚀 Gamification Data (user-specific keys)
      _score = prefs.getInt('${userId}_score') ?? 100;
      _rockets = prefs.getInt('${userId}_rockets') ?? 100;
      _rank = prefs.getInt('${userId}_rank') ?? 1982;
      
      // 👤 Personal Info (user-specific keys)
      _fullName = prefs.getString('${userId}_fullName');
      _email = prefs.getString('${userId}_email');
      _class = prefs.getString('${userId}_class');
      _gender = prefs.getString('${userId}_gender');
      
      _isLoaded = true;
      
      // 📊 Debug Report
      debugPrint('✅ USER DATA LOADED SUCCESSFULLY!');
      debugPrint('   Avatar Path: ${_currentAvatarPath ?? "Not set"}');
      debugPrint('   Avatar ID: ${_currentAvatarId ?? "Not set"}');
      debugPrint('   Score: $_score');
      debugPrint('   Rockets: $_rockets');
      debugPrint('   Rank: $_rank');
      debugPrint('   Name: ${_fullName ?? "Not set"}');
      debugPrint('   Class: ${_class ?? "Not set"}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider: CRITICAL ERROR loading user data: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }
  
  /// 🔄 LEGACY SUPPORT: Load without userId (for backwards compatibility)
  /// **DEPRECATED:** Use loadUserData(userId) instead
  @Deprecated('Use loadUserData(userId) instead for user-specific data')
  Future<void> loadAvatar() async {
    debugPrint('⚠️ UserProvider: loadAvatar() called without userId - using legacy keys');
    debugPrint('⚠️ This may cause data mixing! Please use loadUserData(userId) instead');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load from legacy keys (no userId prefix)
      _currentAvatarPath = prefs.getString('selected_avatar_path');
      _currentAvatarId = prefs.getString('selected_avatar_id');
      _score = prefs.getInt('user_score') ?? 100;
      _rockets = prefs.getInt('user_rockets') ?? 100;
      _rank = prefs.getInt('user_rank') ?? 1982;
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider: Error in legacy loadAvatar: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 💾 SAVE USER DATA - Commit all user data to disk
  /// 
  /// **CRITICAL:** This saves ALL user data using userId-prefixed keys
  /// **Parameter:** userId - Firebase UID or email (must match loadUserData)
  /// **Call this:** After ANY user data change (avatar, score, rockets, etc.)
  /// 
  /// **What it saves:**
  /// - Avatar selection
  /// - Gamification stats (score, rockets, rank)
  /// - Personal info (name, class, etc.)
  Future<void> saveUserData(String userId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💾 UserProvider: SAVING USER DATA');
      debugPrint('   User ID: $userId');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = userId;
      
      // 🎨 Avatar Data
      if (_currentAvatarPath != null) {
        await prefs.setString('${userId}_avatar_path', _currentAvatarPath!);
      }
      if (_currentAvatarId != null) {
        await prefs.setString('${userId}_avatar_id', _currentAvatarId!);
      }
      
      // 🚀 Gamification Data
      await prefs.setInt('${userId}_score', _score);
      await prefs.setInt('${userId}_rockets', _rockets);
      await prefs.setInt('${userId}_rank', _rank);
      
      // 👤 Personal Info
      if (_fullName != null) await prefs.setString('${userId}_fullName', _fullName!);
      if (_email != null) await prefs.setString('${userId}_email', _email!);
      if (_class != null) await prefs.setString('${userId}_class', _class!);
      if (_gender != null) await prefs.setString('${userId}_gender', _gender!);
      
      debugPrint('✅ USER DATA SAVED SUCCESSFULLY!');
      debugPrint('   Avatar: ${_currentAvatarPath ?? "None"}');
      debugPrint('   Score: $_score | Rockets: $_rockets | Rank: $_rank');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider: CRITICAL ERROR saving user data: $e');
    }
  }
  
  /// 🎁 Claims a reward (e.g., Daily Login)
  /// Adds rockets, syncs score, and recalculates rank.
  Future<void> claimLoginReward() async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot claim reward: No user logged in');
      return;
    }
    
    const int rewardAmount = 20;
    
    _rockets += rewardAmount;
    _score += rewardAmount;
    _rank = _calculateRank(_score);
    
    // 💾 Persist to disk with user-specific keys
    await saveUserData(_currentUserId!);
    
    debugPrint('🎁 Reward Claimed! Rockets: $_rockets | Rank: $_rank');
    notifyListeners();
  }
  
  /// Simple logic to simulate rank improvement.
  /// Higher score = Lower (better) rank number.
  /// Baseline: Score 100 = Rank 1982.
  int _calculateRank(int currentScore) {
    const int baseScore = 100;
    const int baseRank = 1982;
    
    if (currentScore <= baseScore) return baseRank;
    
    // For every 20 points, improve rank by ~15 spots
    // Formula: (Score Diff / 20) * 15
    // But let's make it granular: ~0.75 rank spots per point
    final int scoreDiff = currentScore - baseScore;
    final int rankImprovement = (scoreDiff * 0.75).round();
    
    int newRank = baseRank - rankImprovement;
    return newRank < 1 ? 1 : newRank; // Cap at Rank #1
  }

  /// 🎨 Save Avatar Selection
  /// Updates avatar in RAM and optionally persists to disk with user-specific keys
  /// 
  /// **During Registration:** Can be called without userId - only updates RAM
  /// **After Login:** Should be called with userId to persist to disk
  Future<void> saveAvatar(String path, String id, {String? userId}) async {
    try {
      // Use provided userId or current session userId
      final targetUserId = userId ?? _currentUserId;
      
      // Update RAM state immediately (always safe)
      _currentAvatarPath = path;
      _currentAvatarId = id;
      _isLoaded = true;
      
      if (targetUserId == null) {
        // No userId available (likely during registration BEFORE user is created)
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('⚠️ UserProvider: Avatar saved to RAM only (no userId yet)');
        debugPrint('   Avatar ID: $id');
        debugPrint('   Path: $path');
        debugPrint('   This is normal during registration.');
        debugPrint('   Will be saved to disk when registration completes.');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        notifyListeners();
        return; // Don't try to persist without userId
      }
      
      // We have a userId - persist to disk
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🎨 UserProvider: SAVING AVATAR');
      debugPrint('   User ID: $targetUserId');
      debugPrint('   Avatar ID: $id');
      debugPrint('   Path: $path');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      _currentUserId = targetUserId;
      
      // 💾 Persist to disk using user-specific keys
      await saveUserData(targetUserId);
      
      debugPrint('✅ Avatar saved successfully with user-specific keys!');
      debugPrint('   Key: ${targetUserId}_avatar_path');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('❌ UserProvider: ERROR saving avatar: $e');
      // Don't rethrow - avatar is at least in RAM
      notifyListeners();
    }
  }
  
  /// 📝 Update Personal Info
  /// Updates personal data in RAM and persists to disk
  Future<void> updatePersonalInfo({
    String? fullName,
    String? email,
    String? userClass,
    String? gender,
  }) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot update personal info: No user logged in');
      return;
    }
    
    try {
      debugPrint('📝 UserProvider: Updating personal info for ${_currentUserId}');
      
      if (fullName != null) _fullName = fullName;
      if (email != null) _email = email;
      if (userClass != null) _class = userClass;
      if (gender != null) _gender = gender;
      
      // 💾 Persist to disk
      await saveUserData(_currentUserId!);
      
      debugPrint('✅ Personal info updated successfully!');
    } catch (e) {
      debugPrint('❌ Error updating personal info: $e');
    }
  }
  
  /// 🚀 Update Score/Rockets/Rank
  /// Updates gamification stats and persists to disk
  Future<void> updateStats({int? score, int? rockets, int? rank}) async {
    if (_currentUserId == null) {
      debugPrint('⚠️ Cannot update stats: No user logged in');
      return;
    }
    
    try {
      if (score != null) _score = score;
      if (rockets != null) _rockets = rockets;
      if (rank != null) _rank = rank;
      
      // Auto-calculate rank if score changed
      if (score != null) {
        _rank = _calculateRank(_score);
      }
      
      // 💾 Persist to disk
      await saveUserData(_currentUserId!);
      
      debugPrint('📊 Stats updated: Score=$_score, Rockets=$_rockets, Rank=$_rank');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating stats: $e');
    }
  }

  /// 🧹 CLEAR SESSION - Reset RAM state on logout
  /// 
  /// **CRITICAL BEHAVIOR:**
  /// - Clears RAM (in-memory) state ONLY
  /// - Does NOT delete SharedPreferences data
  /// - Preserves user data on disk for next login
  /// 
  /// **Why?** So when User "Ali" logs back in, his avatar & rockets are still there!
  /// 
  /// **Call this:** When user logs out
  Future<void> clearSession() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🧹 UserProvider: CLEARING SESSION (RAM ONLY)');
      debugPrint('   Previous User: ${_currentUserId ?? "None"}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // 🎯 CRITICAL: Clear RAM state ONLY (not disk)
      // This prevents data bleeding into next user's session
      // But preserves data for when same user logs back in
      
      _currentUserId = null; // 🔑 Clear session identifier
      _currentAvatarPath = null;
      _currentAvatarId = null;
      _score = 100;
      _rockets = 100;
      _rank = 1982;
      _fullName = null;
      _email = null;
      _class = null;
      _gender = null;
      _isLoaded = false;
      
      debugPrint('✅ SESSION CLEARED (RAM reset to defaults)');
      debugPrint('📁 Disk data preserved for future logins');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider: Error clearing session: $e');
    }
  }
  
  /// 🗑️ DELETE USER DATA - Permanently remove user data from disk
  /// 
  /// **DANGEROUS:** This permanently deletes the user's saved data
  /// **Use case:** Account deletion, data reset
  /// **NOT for logout:** Use clearSession() instead
  Future<void> deleteUserData(String userId) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🗑️ UserProvider: DELETING USER DATA FROM DISK');
      debugPrint('   User ID: $userId');
      debugPrint('   ⚠️ WARNING: This is permanent!');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all user-specific keys
      await prefs.remove('${userId}_avatar_path');
      await prefs.remove('${userId}_avatar_id');
      await prefs.remove('${userId}_score');
      await prefs.remove('${userId}_rockets');
      await prefs.remove('${userId}_rank');
      await prefs.remove('${userId}_fullName');
      await prefs.remove('${userId}_email');
      await prefs.remove('${userId}_class');
      await prefs.remove('${userId}_gender');
      
      // If this is the current user, also clear RAM
      if (_currentUserId == userId) {
        await clearSession();
      }
      
      debugPrint('✅ User data permanently deleted from disk');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
    }
  }
}
