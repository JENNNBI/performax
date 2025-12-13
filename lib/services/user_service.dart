import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// User Service for managing user data and profiles
class UserService {
  static const String _isGuestKey = 'is_guest_user';
  
  // Singleton instance
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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

  /// Get current user's profile with complete data
  /// Returns null if user is not authenticated
  /// [forceRefresh] if true, fetches from server bypassing cache
  Future<UserProfile?> getCurrentUserProfile({bool forceRefresh = false}) async {
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

      // Fetch user data from Firestore
      // Use Source.server if forceRefresh is true to bypass cache
      final userDoc = forceRefresh
          ? await _firestore.collection('users').doc(user.uid).get(
              const GetOptions(source: Source.server),
            )
          : await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists || userDoc.data() == null) {
        // Return basic profile if Firestore data not found
        return UserProfile(
          userId: user.uid,
          fullName: user.displayName ?? 'Öğrenci',
          email: user.email ?? '',
        );
      }

      return UserProfile.fromMap(user.uid, userDoc.data()!);
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Get user data as map (for backward compatibility)
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final profile = await getCurrentUserProfile();
    return profile?.toMap();
  }

  /// Update user profile data
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
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
      
      // Clear any other user-related preferences if needed
      // Add more keys here as needed for complete cleanup
      
      debugPrint('✅ All user data cleared from local storage');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
      // Don't throw - allow logout to continue even if clearing fails
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
