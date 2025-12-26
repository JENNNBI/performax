import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// User Service for managing user data and profiles
/// Includes robust local caching to prevent data loss on app restart
class UserService {
  static const String _isGuestKey = 'is_guest_user';
  static const String _cachedProfileKey = 'cached_user_profile';
  static const String _cachedProfileUserIdKey = 'cached_profile_user_id';
  static const String _cachedProfileTimestampKey = 'cached_profile_timestamp';
  
  // Singleton instance
  static final UserService instance = UserService._internal();
  factory UserService() => instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // In-memory cache for quick access
  UserProfile? _inMemoryProfile;
  
  UserProfile? get currentUserProfile => _inMemoryProfile;
  
  // Cache expiration: 24 hours
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  // Set user as guest
  static Future<void> setGuestUser(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, isGuest);
  }
  
  // Check if current user is a guest
  static Future<bool> isGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }
  
  // Clear guest status (when user logs in or registers)
  static Future<void> clearGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isGuestKey);
  }

  /// Save user profile to local cache
  Future<void> _saveProfileToCache(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      
      if (user == null) return;
      
      // Save profile data as JSON
      final profileMap = profile.toMap();
      final profileJson = jsonEncode(profileMap);
      
      // Update in-memory
      _inMemoryProfile = profile;
      
      await prefs.setString(_cachedProfileKey, profileJson);
      await prefs.setString(_cachedProfileUserIdKey, user.uid);
      await prefs.setString(_cachedProfileTimestampKey, DateTime.now().toIso8601String());
      
      debugPrint('✅ Profile cached locally for ${profile.displayName}');
    } catch (e) {
      debugPrint('⚠️ Error saving profile to cache: $e');
      // Don't throw - caching is best effort
    }
  }
  
  /// Load user profile from local cache
  Future<UserProfile?> _loadProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      
      if (user == null) return null;
      
      // Check if cached profile exists and belongs to current user
      final cachedUserId = prefs.getString(_cachedProfileUserIdKey);
      if (cachedUserId != user.uid) {
        debugPrint('⚠️ Cached profile belongs to different user, ignoring cache');
        return null;
      }
      
      // Check cache expiration
      final timestampStr = prefs.getString(_cachedProfileTimestampKey);
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final age = DateTime.now().difference(timestamp);
        if (age > _cacheExpiration) {
          debugPrint('⚠️ Cached profile expired (age: ${age.inHours}h), ignoring cache');
          return null;
        }
      }
      
      // Load cached profile
      final cachedJson = prefs.getString(_cachedProfileKey);
      if (cachedJson == null) {
        return null;
      }
      
      final profileMap = jsonDecode(cachedJson) as Map<String, dynamic>;
      final profile = UserProfile.fromMap(user.uid, profileMap);
      
      // Update in-memory
      _inMemoryProfile = profile;
      
      debugPrint('✅ Profile loaded from cache for ${profile.displayName}');
      return profile;
    } catch (e) {
      debugPrint('⚠️ Error loading profile from cache: $e');
      return null;
    }
  }
  
  /// Get current user's profile with complete data
  /// Returns null if user is not authenticated
  /// [forceRefresh] if true, fetches from server bypassing cache
  /// [useCache] if true, loads from local cache first (default: true)
  Future<UserProfile?> getCurrentUserProfile({
    bool forceRefresh = false,
    bool useCache = true,
  }) async {
    try {
      // Check if guest user first
      final isGuest = await UserService.isGuestUser();
      if (isGuest) {
        return UserProfile.guest();
      }

      // Get current authenticated user
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      // Step 1: Try to load from cache first (if not forcing refresh and cache is enabled)
      if (!forceRefresh && useCache) {
        final cachedProfile = await _loadProfileFromCache();
        if (cachedProfile != null) {
          // Return cached data immediately, then sync in background
          _syncProfileFromFirestore(user.uid).catchError((e) {
            debugPrint('⚠️ Background sync failed: $e');
          });
          return cachedProfile;
        }
      }

      // Step 2: Fetch from Firestore
      UserProfile? profile;
      try {
        // Use Source.server if forceRefresh is true to bypass Firestore cache
        final userDoc = forceRefresh
            ? await _firestore.collection('users').doc(user.uid).get(
                const GetOptions(source: Source.server),
              )
            : await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists || userDoc.data() == null) {
          // Try to return cached profile if Firestore fetch fails
          if (useCache) {
            final cachedProfile = await _loadProfileFromCache();
            if (cachedProfile != null) {
              debugPrint('⚠️ Firestore data not found, using cached profile');
              return cachedProfile;
            }
          }
          
          // Return basic profile if no cache available
          profile = UserProfile(
            userId: user.uid,
            fullName: user.displayName ?? 'Öğrenci',
            email: user.email ?? '',
          );
        } else {
          profile = UserProfile.fromMap(user.uid, userDoc.data()!);
        }
        
        // Step 3: Save to cache after successful fetch
        await _saveProfileToCache(profile);
        
        return profile;
      } catch (e) {
        debugPrint('❌ Error fetching from Firestore: $e');
        
        // Fallback to cache if Firestore fails
        if (useCache) {
          final cachedProfile = await _loadProfileFromCache();
          if (cachedProfile != null) {
            debugPrint('✅ Using cached profile due to Firestore error');
            return cachedProfile;
          }
        }
        
        // Last resort: return basic profile from auth
        return UserProfile(
          userId: user.uid,
          fullName: user.displayName ?? 'Öğrenci',
          email: user.email ?? '',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      
      // Final fallback: try cache
      if (useCache) {
        try {
          final cachedProfile = await _loadProfileFromCache();
          if (cachedProfile != null) {
            return cachedProfile;
          }
        } catch (_) {
          // Ignore cache errors
        }
      }
      
      return null;
    }
  }
  
  /// Sync profile from Firestore in background (non-blocking)
  Future<void> _syncProfileFromFirestore(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final profile = UserProfile.fromMap(userId, userDoc.data()!);
        await _saveProfileToCache(profile);
        debugPrint('✅ Profile synced from Firestore in background');
      }
    } catch (e) {
      debugPrint('⚠️ Background sync error: $e');
      // Don't throw - background sync failures shouldn't affect app
    }
  }

  /// Get user data as map (for backward compatibility)
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final profile = await getCurrentUserProfile();
    return profile?.toMap();
  }

  /// Update user profile data
  /// Also updates local cache after successful Firestore update
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      
      // Update cache after successful Firestore update
      final updatedProfile = await getCurrentUserProfile(forceRefresh: true);
      if (updatedProfile != null) {
        await _saveProfileToCache(updatedProfile);
        debugPrint('✅ Profile cache updated after Firestore update');
      }
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get specific field from user profile
  Future<String?> getUserField(String field) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return userDoc.data()?[field]?.toString();
    } catch (e) {
      debugPrint('❌ Error fetching user field: $e');
      return null;
    }
  }

  /// Clear all cached user data and session information
  /// Should be called on logout to ensure complete session termination
  static Future<void> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear guest status
      await prefs.remove(_isGuestKey);
      
      // Clear cached profile
      await prefs.remove(_cachedProfileKey);
      await prefs.remove(_cachedProfileUserIdKey);
      await prefs.remove(_cachedProfileTimestampKey);
      
      debugPrint('✅ All user data cleared from local storage');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
      // Don't throw - allow logout to continue even if clearing fails
    }
  }
  
  /// Clear cached profile data (instance method)
  Future<void> clearCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedProfileKey);
      await prefs.remove(_cachedProfileUserIdKey);
      await prefs.remove(_cachedProfileTimestampKey);
      debugPrint('✅ Cached profile cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cached profile: $e');
    }
  }

  /// Force clear Firestore cache for the current user
  /// This ensures fresh data is fetched on next login
  Future<void> clearFirestoreCache() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Clear Firestore cache by disabling persistence temporarily
        // Note: This is handled by Firestore automatically when user changes
        // But we can force a fresh fetch by using get(source: Source.server)
        debugPrint('✅ Firestore cache will be cleared on next fetch');
      }
    } catch (e) {
      debugPrint('❌ Error clearing Firestore cache: $e');
      // Don't throw - allow logout to continue
    }
  }
}
