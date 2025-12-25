import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete the current user's account and all associated data
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'No user signed in');

    // Step A: Delete Firestore user document
    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (e) {
      // Log error but continue with auth deletion if possible
      // In a real app, you might want to stop here or handle it differently
      print('Error deleting user document: $e');
    }

    // Clear local data before deleting the account
    await UserService.clearAllUserData();

    // Step B: Delete Auth User
    // This might throw 'requires-recent-login'
    await user.delete();
  }
}
