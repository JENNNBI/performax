import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite_question.dart';
import '../models/favorite_book.dart';
import '../models/favorite_playlist.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');
  
  CollectionReference get _favoriteBooksCollection =>
      _firestore.collection('favorite_books');

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add question to favorites
  /// Uses authenticated user's UID to securely identify and store the favorite question
  Future<bool> addFavoriteQuestion({
    required int questionNumber,
    required String imagePath,
    required String testName,
    String? userAnswer,
    String? correctAnswer,
    String? notes,
  }) async {
    try {
      // Ensure user is authenticated - Firebase Security Rules require this
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot add favorite');
        return false;
      }

      // Use authenticated user's UID for document identification
      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_${testName}_Q$questionNumber';

      // Create favorite question with authenticated user's UID
      final favoriteQuestion = FavoriteQuestion(
        id: docId,
        userId: authenticatedUserId, // Ensures userId matches authenticated user
        questionNumber: questionNumber,
        imagePath: imagePath,
        testName: testName,
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
        createdAt: DateTime.now(),
        notes: notes,
      );

      // Write to Firestore - Security Rules validate userId matches request.auth.uid
      await _favoritesCollection.doc(docId).set(
        favoriteQuestion.toMap(),
        SetOptions(merge: false), // Overwrite if exists (idempotent operation)
      );

      debugPrint('✅ Question $questionNumber from $testName added to favorites for user $authenticatedUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding favorite: $e');
      // Check if error is due to security rules
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - ensure Firebase Security Rules allow authenticated writes');
      }
      return false;
    }
  }

  /// Remove question from favorites
  /// Uses authenticated user's UID to securely identify and delete the favorite question
  Future<bool> removeFavoriteQuestion({
    required String testName,
    required int questionNumber,
  }) async {
    try {
      // Ensure user is authenticated - Firebase Security Rules require this
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot remove favorite');
        return false;
      }

      // Use authenticated user's UID for document identification
      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_${testName}_Q$questionNumber';
      
      // Delete from Firestore - Security Rules validate ownership
      await _favoritesCollection.doc(docId).delete();

      debugPrint('✅ Question $questionNumber from $testName removed from favorites for user $authenticatedUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - ensure Firebase Security Rules allow authenticated deletes');
      }
      return false;
    }
  }

  /// Check if question is favorited
  /// Uses authenticated user's UID to securely check favorite status
  Future<bool> isQuestionFavorited({
    required String testName,
    required int questionNumber,
  }) async {
    try {
      // Ensure user is authenticated - Firebase Security Rules require this
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot check favorite status');
        return false;
      }

      // Use authenticated user's UID for document identification
      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_${testName}_Q$questionNumber';
      
      // Read from Firestore - Security Rules validate ownership
      final doc = await _favoritesCollection.doc(docId).get();

      if (doc.exists) {
        // Additional validation: ensure userId in document matches authenticated user
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['userId'] == authenticatedUserId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - ensure Firebase Security Rules allow authenticated reads');
      }
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required int questionNumber,
    required String imagePath,
    required String testName,
    String? userAnswer,
    String? correctAnswer,
  }) async {
    final isFavorited = await isQuestionFavorited(
      testName: testName,
      questionNumber: questionNumber,
    );

    if (isFavorited) {
      return await removeFavoriteQuestion(
        testName: testName,
        questionNumber: questionNumber,
      );
    } else {
      return await addFavoriteQuestion(
        questionNumber: questionNumber,
        imagePath: imagePath,
        testName: testName,
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
      );
    }
  }

  /// Get all favorite questions for current user
  /// Returns a stream that automatically updates when favorites change
  Stream<List<FavoriteQuestion>> getFavoriteQuestions() {
    // Check authentication status
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('⚠️ No authenticated user - returning empty stream');
      return Stream.value([]);
    }

    final authenticatedUserId = currentUser.uid;
    debugPrint('📖 Fetching favorites for user: $authenticatedUserId');

    try {
      // Note: Removing orderBy to avoid Firestore index requirement
      // We'll sort in memory instead
      return _favoritesCollection
          .where('userId', isEqualTo: authenticatedUserId)
          .snapshots()
          .map((snapshot) {
        debugPrint('📦 Received ${snapshot.docs.length} favorite documents');
        
        final favorites = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            
            // Ensure id field is set (use document ID if not present)
            if (!data.containsKey('id') || data['id'] == null) {
              data['id'] = doc.id;
            }
            
            // Normalize image path - fix common issues
            if (data.containsKey('imagePath') && data['imagePath'] is String) {
              String imagePath = data['imagePath'] as String;
              final originalPath = imagePath;
              
              // Fix missing slash between test directory and soru filename
              // e.g., "assets/.../test1soru3.png" -> "assets/.../test1/soru3.png"
              // Pattern: test followed by digits, then soru followed by digits, then .png
              if (imagePath.contains('test') && imagePath.contains('soru')) {
                // Check if path is missing the slash (e.g., test1soru3.png instead of test1/soru3.png)
                final needsFix = RegExp(r'test\d+soru\d+').hasMatch(imagePath);
                
                if (needsFix && !imagePath.contains('/soru')) {
                  // Fix: test1soru3.png -> test1/soru3.png
                  imagePath = imagePath.replaceAllMapped(
                    RegExp(r'(test\d+)(soru\d+\.png)', caseSensitive: false),
                    (match) => '${match.group(1)}/${match.group(2)}',
                  );
                  
                  // If still not fixed (maybe no .png in the pattern match)
                  if (imagePath == originalPath) {
                    imagePath = imagePath.replaceAllMapped(
                      RegExp(r'(test\d+)(soru\d+)', caseSensitive: false),
                      (match) => '${match.group(1)}/${match.group(2)}',
                    );
                  }
                  
                  if (imagePath != originalPath) {
                    debugPrint('🔧 Fixed image path: $originalPath -> $imagePath');
                    data['imagePath'] = imagePath;
                    
                    // Update the document in Firestore with the corrected path (async, non-blocking)
                    _fixImagePathInFirestore(doc.id, imagePath).catchError((e) {
                      debugPrint('⚠️ Failed to update image path in Firestore: $e');
                    });
                  }
                }
              }
              
              // Log the final path for debugging
              debugPrint('📸 Final image path: $imagePath');
              
              // Ensure path starts with 'assets/'
              if (!imagePath.startsWith('assets/')) {
                debugPrint('⚠️ Image path does not start with assets/: $imagePath');
              }
            }
            
            // Handle createdAt field - convert Firestore Timestamp to ISO8601 string
            if (data['createdAt'] != null) {
              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                // Firestore Timestamp - convert to ISO8601 string
                data['createdAt'] = createdAt.toDate().toIso8601String();
              } else if (createdAt is DateTime) {
                // Already DateTime - convert to ISO8601 string
                data['createdAt'] = createdAt.toIso8601String();
              } else if (createdAt is! String) {
                // Unknown type - try to convert or use current time
                debugPrint('⚠️ Unknown createdAt type: ${createdAt.runtimeType}');
                data['createdAt'] = DateTime.now().toIso8601String();
              }
              // If it's already a String, keep it as is
            } else {
              // createdAt missing - use document creation time or current time
              debugPrint('⚠️ createdAt field missing in document ${doc.id}');
              data['createdAt'] = DateTime.now().toIso8601String();
            }
            
            final favorite = FavoriteQuestion.fromMap(data);
            debugPrint('✅ Loaded favorite: ${favorite.testName} Q${favorite.questionNumber} (image: ${favorite.imagePath})');
            return favorite;
          } catch (e) {
            debugPrint('❌ Error parsing favorite document ${doc.id}: $e');
            debugPrint('   Document data: ${doc.data()}');
            // Return null for invalid documents, filter them out
            return null;
          }
        }).whereType<FavoriteQuestion>() // Filter out nulls
         .toList();
        
        // Sort by createdAt in descending order (newest first)
        favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ Successfully loaded ${favorites.length} favorites');
        return favorites;
      }).handleError((error) {
        debugPrint('❌ Error in favorites stream: $error');
        return <FavoriteQuestion>[];
      });
    } catch (e) {
      debugPrint('❌ Error setting up favorites stream: $e');
      return Stream.value(<FavoriteQuestion>[]);
    }
  }

  /// Get favorite questions count
  Future<int> getFavoritesCount() async {
    try {
      if (_currentUserId == null) return 0;

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: _currentUserId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting favorites count: $e');
      return 0;
    }
  }

  /// Get favorites by test name
  Future<List<FavoriteQuestion>> getFavoritesByTest(String testName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final authenticatedUserId = currentUser.uid;

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: authenticatedUserId)
          .where('testName', isEqualTo: testName)
          .orderBy('questionNumber')
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Normalize image path - same logic as getFavoriteQuestions
          if (data.containsKey('imagePath') && data['imagePath'] is String) {
            String imagePath = data['imagePath'] as String;
            final originalPath = imagePath;
            
            if (imagePath.contains('test') && imagePath.contains('soru') && !imagePath.contains('/soru')) {
              imagePath = imagePath.replaceAllMapped(
                RegExp(r'(test\d+)(soru\d+\.png)', caseSensitive: false),
                (match) => '${match.group(1)}/${match.group(2)}',
              );
              
              if (imagePath == originalPath) {
                imagePath = imagePath.replaceAllMapped(
                  RegExp(r'(test\d+)(soru\d+)', caseSensitive: false),
                  (match) => '${match.group(1)}/${match.group(2)}',
                );
              }
              
              if (imagePath != originalPath) {
                data['imagePath'] = imagePath;
                _fixImagePathInFirestore(doc.id, imagePath).catchError((e) {
                  debugPrint('⚠️ Failed to update image path: $e');
                });
              }
            }
          }
          
          return FavoriteQuestion.fromMap(data);
        } catch (e) {
          debugPrint('❌ Error parsing favorite document ${doc.id}: $e');
          return null;
        }
      }).whereType<FavoriteQuestion>().toList();
    } catch (e) {
      debugPrint('❌ Error getting favorites by test: $e');
      return [];
    }
  }

  /// Fix image path in a Firestore document
  /// Updates the document with the corrected path format
  Future<void> _fixImagePathInFirestore(String docId, String correctedPath) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No authenticated user - cannot update Firestore');
        return;
      }

      await _favoritesCollection.doc(docId).update({
        'imagePath': correctedPath,
      });
      
      debugPrint('✅ Updated image path in Firestore for document: $docId');
    } catch (e) {
      debugPrint('❌ Error updating image path in Firestore: $e');
      // Don't throw - this is a background fix operation
    }
  }

  /// Fix all favorite questions with incorrect image paths
  /// Scans all favorites and corrects paths like "test1soru3.png" to "test1/soru3.png"
  Future<int> fixAllImagePaths() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No authenticated user - cannot fix paths');
        return 0;
      }

      final authenticatedUserId = currentUser.uid;
      debugPrint('🔍 Scanning favorites for incorrect image paths...');

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: authenticatedUserId)
          .get();

      int fixedCount = 0;
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final imagePath = data['imagePath'] as String?;

        if (imagePath != null && imagePath.contains('test') && imagePath.contains('soru')) {
          // Check if path needs fixing (has test1soru3 pattern instead of test1/soru3)
          final needsFix = RegExp(r'test\d+soru\d+').hasMatch(imagePath);
          
          if (needsFix && !imagePath.contains('/soru')) {
            // Fix the path: test1soru3.png -> test1/soru3.png
            String correctedPath = imagePath.replaceAllMapped(
              RegExp(r'(test\d+)(soru\d+\.png)', caseSensitive: false),
              (match) => '${match.group(1)}/${match.group(2)}',
            );

            // If no change, try without .png in the pattern
            if (correctedPath == imagePath) {
              correctedPath = imagePath.replaceAllMapped(
                RegExp(r'(test\d+)(soru\d+)', caseSensitive: false),
                (match) => '${match.group(1)}/${match.group(2)}',
              );
            }

            if (correctedPath != imagePath) {
              debugPrint('🔧 Batch fixing path: $imagePath -> $correctedPath');
              batch.update(doc.reference, {'imagePath': correctedPath});
              fixedCount++;
            }
          }
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        debugPrint('✅ Fixed $fixedCount favorite question image paths in Firestore');
      } else {
        debugPrint('✅ No incorrect paths found');
      }

      return fixedCount;
    } catch (e) {
      debugPrint('❌ Error fixing image paths: $e');
      return 0;
    }
  }

  /// Clear all favorites for current user
  Future<bool> clearAllFavorites() async {
    try {
      if (_currentUserId == null) return false;

      final snapshot = await _favoritesCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All favorites cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing favorites: $e');
      return false;
    }
  }

  // ==================== BOOK FAVORITES METHODS ====================

  /// Add book to favorites
  /// Uses authenticated user's UID to securely identify and store the favorite book
  Future<bool> addFavoriteBook({
    required String testSeriesTitle,
    required String subject,
    required String grade,
    required String testSeriesKey,
    required String coverImagePath,
  }) async {
    try {
      // Ensure user is authenticated - Firebase Security Rules require this
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot add favorite book');
        return false;
      }

      // Use authenticated user's UID for document identification
      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_$testSeriesKey';

      // Create favorite book with authenticated user's UID
      final favoriteBook = FavoriteBook(
        id: docId,
        userId: authenticatedUserId, // Ensures userId matches authenticated user
        testSeriesTitle: testSeriesTitle,
        subject: subject,
        grade: grade,
        testSeriesKey: testSeriesKey,
        coverImagePath: coverImagePath,
        createdAt: DateTime.now(),
      );

      // Write to Firestore - Security Rules validate userId matches request.auth.uid
      await _favoriteBooksCollection.doc(docId).set(
        favoriteBook.toMap(),
        SetOptions(merge: false), // Overwrite if exists (idempotent operation)
      );

      debugPrint('✅ Book "$testSeriesTitle" added to favorites for user $authenticatedUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding favorite book: $e');
      // Check if error is due to security rules
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - ensure Firebase Security Rules allow authenticated writes');
      }
      return false;
    }
  }

  /// Remove book from favorites
  /// Uses authenticated user's UID to securely identify and delete the favorite book
  Future<bool> removeFavoriteBook({
    required String testSeriesKey,
  }) async {
    try {
      // Ensure user is authenticated - Firebase Security Rules require this
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot remove favorite book');
        return false;
      }

      // Use authenticated user's UID for document identification
      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_$testSeriesKey';
      
      // Delete from Firestore - Security Rules validate ownership
      await _favoriteBooksCollection.doc(docId).delete();

      debugPrint('✅ Book with key "$testSeriesKey" removed from favorites for user $authenticatedUserId');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing favorite book: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - ensure Firebase Security Rules allow authenticated deletes');
      }
      return false;
    }
  }

  /// Check if book is favorited
  /// Uses authenticated user's UID to securely check favorite status
  Future<bool> isBookFavorited({
    required String testSeriesKey,
  }) async {
    try {
      // Ensure user is authenticated - Firebase Security Rules require this
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot check favorite status');
        return false;
      }

      // Use authenticated user's UID for document identification
      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_$testSeriesKey';
      
      // Read from Firestore - Security Rules validate ownership
      final doc = await _favoriteBooksCollection.doc(docId).get();

      if (doc.exists) {
        // Additional validation: ensure userId in document matches authenticated user
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['userId'] == authenticatedUserId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking favorite book status: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('⚠️ Permission denied - ensure Firebase Security Rules allow authenticated reads');
      }
      return false;
    }
  }

  /// Toggle favorite book status
  Future<bool> toggleFavoriteBook({
    required String testSeriesTitle,
    required String subject,
    required String grade,
    required String testSeriesKey,
    required String coverImagePath,
  }) async {
    final isFavorited = await isBookFavorited(
      testSeriesKey: testSeriesKey,
    );

    if (isFavorited) {
      return await removeFavoriteBook(
        testSeriesKey: testSeriesKey,
      );
    } else {
      return await addFavoriteBook(
        testSeriesTitle: testSeriesTitle,
        subject: subject,
        grade: grade,
        testSeriesKey: testSeriesKey,
        coverImagePath: coverImagePath,
      );
    }
  }

  /// Get all favorite books for current user
  /// Returns a stream that automatically updates when favorites change
  Stream<List<FavoriteBook>> getFavoriteBooks() {
    // Check authentication status
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('⚠️ No authenticated user - returning empty stream');
      return Stream.value([]);
    }

    final authenticatedUserId = currentUser.uid;
    debugPrint('📖 Fetching favorite books for user: $authenticatedUserId');

    try {
      return _favoriteBooksCollection
          .where('userId', isEqualTo: authenticatedUserId)
          .snapshots()
          .map((snapshot) {
        debugPrint('📦 Received ${snapshot.docs.length} favorite book documents');
        
        final favorites = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            
            // Ensure id field is set (use document ID if not present)
            if (!data.containsKey('id') || data['id'] == null) {
              data['id'] = doc.id;
            }
            
            // Handle createdAt field - convert Firestore Timestamp to ISO8601 string
            if (data['createdAt'] != null) {
              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                // Firestore Timestamp - convert to ISO8601 string
                data['createdAt'] = createdAt.toDate().toIso8601String();
              } else if (createdAt is DateTime) {
                // Already DateTime - convert to ISO8601 string
                data['createdAt'] = createdAt.toIso8601String();
              } else if (createdAt is! String) {
                // Unknown type - try to convert or use current time
                debugPrint('⚠️ Unknown createdAt type: ${createdAt.runtimeType}');
                data['createdAt'] = DateTime.now().toIso8601String();
              }
              // If it's already a String, keep it as is
            } else {
              // createdAt missing - use document creation time or current time
              debugPrint('⚠️ createdAt field missing in document ${doc.id}');
              data['createdAt'] = DateTime.now().toIso8601String();
            }
            
            final favorite = FavoriteBook.fromMap(data);
            debugPrint('✅ Loaded favorite book: ${favorite.testSeriesTitle} (cover: ${favorite.coverImagePath})');
            return favorite;
          } catch (e) {
            debugPrint('❌ Error parsing favorite book document ${doc.id}: $e');
            debugPrint('   Document data: ${doc.data()}');
            // Return null for invalid documents, filter them out
            return null;
          }
        }).whereType<FavoriteBook>() // Filter out nulls
         .toList();
        
        // Sort by createdAt in descending order (newest first)
        favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ Successfully loaded ${favorites.length} favorite books');
        return favorites;
      }).handleError((error) {
        debugPrint('❌ Error in favorite books stream: $error');
        return <FavoriteBook>[];
      });
    } catch (e) {
      debugPrint('❌ Error setting up favorite books stream: $e');
      return Stream.value(<FavoriteBook>[]);
    }
  }

  /// Get favorite books count
  Future<int> getFavoriteBooksCount() async {
    try {
      if (_currentUserId == null) return 0;

      final snapshot = await _favoriteBooksCollection
          .where('userId', isEqualTo: _currentUserId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting favorite books count: $e');
      return 0;
    }
  }

  // ==================== PLAYLIST FAVORITES METHODS ====================

  CollectionReference get _favoritePlaylistsCollection =>
      _firestore.collection('favorite_playlists');

  /// Get all favorite playlists for current user
  /// Returns a stream that automatically updates when favorites change
  Stream<List<FavoritePlaylist>> getFavoritePlaylists() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('⚠️ No authenticated user - returning empty stream');
      return Stream.value([]);
    }

    final authenticatedUserId = currentUser.uid;
    debugPrint('📖 Fetching favorite playlists for user: $authenticatedUserId');

    try {
      return _favoritePlaylistsCollection
          .where('userId', isEqualTo: authenticatedUserId)
          .snapshots()
          .map((snapshot) {
        debugPrint('📦 Received ${snapshot.docs.length} favorite playlist documents');
        
        final playlists = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            
            if (!data.containsKey('id') || data['id'] == null) {
              data['id'] = doc.id;
            }
            
            if (data['createdAt'] != null) {
              final createdAt = data['createdAt'];
              if (createdAt is Timestamp) {
                data['createdAt'] = createdAt.toDate().toIso8601String();
              } else if (createdAt is DateTime) {
                data['createdAt'] = createdAt.toIso8601String();
              } else if (createdAt is! String) {
                debugPrint('⚠️ Unknown createdAt type: ${createdAt.runtimeType}');
                data['createdAt'] = DateTime.now().toIso8601String();
              }
            } else {
              debugPrint('⚠️ createdAt field missing in document ${doc.id}');
              data['createdAt'] = DateTime.now().toIso8601String();
            }
            
            return FavoritePlaylist.fromMap(data);
          } catch (e) {
            debugPrint('❌ Error parsing favorite playlist document ${doc.id}: $e');
            return null;
          }
        }).whereType<FavoritePlaylist>()
         .toList();
        
        playlists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ Successfully loaded ${playlists.length} favorite playlists');
        return playlists;
      }).handleError((error) {
        debugPrint('❌ Error in favorite playlists stream: $error');
        return <FavoritePlaylist>[];
      });
    } catch (e) {
      debugPrint('❌ Error setting up favorite playlists stream: $e');
      return Stream.value(<FavoritePlaylist>[]);
    }
  }

  /// Check if playlist is favorited
  Future<bool> isPlaylistFavorited({
    required String playlistId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot check favorite status');
        return false;
      }

      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_$playlistId';
      
      final doc = await _favoritePlaylistsCollection.doc(docId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['userId'] == authenticatedUserId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking favorite playlist status: $e');
      return false;
    }
  }

  /// Toggle favorite playlist status
  Future<bool> toggleFavoritePlaylist({
    required String playlistId,
    required String playlistName,
    required String subjectKey,
    required String sectionType,
    String? thumbnailUrl,
    List<String> instructorImagePaths = const [],
    required int videoCount,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user - cannot toggle favorite playlist');
        return false;
      }

      final authenticatedUserId = currentUser.uid;
      final docId = '${authenticatedUserId}_$playlistId';
      
      final isFavorited = await isPlaylistFavorited(playlistId: playlistId);

      if (isFavorited) {
        await _favoritePlaylistsCollection.doc(docId).delete();
        debugPrint('✅ Playlist "$playlistName" removed from favorites');
        return true;
      } else {
        final favoritePlaylist = FavoritePlaylist(
          id: docId,
          userId: authenticatedUserId,
          playlistId: playlistId,
          playlistName: playlistName,
          subjectKey: subjectKey,
          sectionType: sectionType,
          thumbnailUrl: thumbnailUrl,
          instructorImagePaths: instructorImagePaths,
          videoCount: videoCount,
          createdAt: DateTime.now(),
        );

        await _favoritePlaylistsCollection.doc(docId).set(
          favoritePlaylist.toMap(),
          SetOptions(merge: false),
        );
        debugPrint('✅ Playlist "$playlistName" added to favorites');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite playlist: $e');
      return false;
    }
  }
}

