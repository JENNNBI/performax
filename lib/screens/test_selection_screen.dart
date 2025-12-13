import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../blocs/bloc_exports.dart';
import '../services/favorites_service.dart';
import 'interactive_test_screen.dart';

/// Test Selection Screen
/// Shows available tests with completion status and success rates
class TestSelectionScreen extends StatefulWidget {
  final String testSeriesTitle;
  final String subject;
  final String grade;
  final String testSeriesKey;
  final String coverImagePath;
  final int totalTests;
  final Color gradientStart;
  final Color gradientEnd;
  
  const TestSelectionScreen({
    super.key,
    required this.testSeriesTitle,
    required this.subject,
    required this.grade,
    required this.testSeriesKey,
    required this.coverImagePath,
    required this.totalTests,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  State<TestSelectionScreen> createState() => _TestSelectionScreenState();
}

class _TestSelectionScreenState extends State<TestSelectionScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  Map<int, Map<String, dynamic>> _testResults = {}; // testNumber -> {score, totalQuestions, date}
  bool _isLoading = true;
  bool _isBookFavorited = false;
  bool _isLoadingFavorite = true;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    
    _headerSlideAnimation = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _headerController.forward();
    _loadTestResults();
    _checkFavoriteStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload test results when app comes back to foreground
      _loadTestResults();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  /// Get user-specific storage key for test results
  String _getUserSpecificStorageKey(String userId) {
    return 'test_results_${userId}_${widget.testSeriesKey}';
  }

  /// Migrate old non-user-specific data (for security - clear old shared keys)
  Future<void> _migrateOldData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldKey = 'test_results_${widget.testSeriesKey}';
      
      // Only migrate if old key exists and new user-specific key doesn't exist
      if (prefs.containsKey(oldKey)) {
        final oldResultsJson = prefs.getString(oldKey);
        if (oldResultsJson != null && oldResultsJson.isNotEmpty) {
          final newKey = _getUserSpecificStorageKey(userId);
          if (!prefs.containsKey(newKey)) {
            // Migrate old data to user-specific key (only if user was authenticated when data was saved)
            debugPrint('🔄 Migrating old test results data to user-specific key');
            await prefs.setString(newKey, oldResultsJson);
          }
          // Always remove old non-user-specific key for security
          await prefs.remove(oldKey);
          debugPrint('🧹 Removed old non-user-specific storage key: $oldKey');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error during data migration: $e');
    }
  }

  /// Load test results from Firestore (user-specific)
  Future<Map<int, Map<String, dynamic>>> _loadFromFirestore(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final testResultsQuery = firestore
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .where('testSeriesKey', isEqualTo: widget.testSeriesKey)
          .where('subject', isEqualTo: widget.subject)
          .where('grade', isEqualTo: widget.grade);

      final snapshot = await testResultsQuery.get();
      
      final Map<int, Map<String, dynamic>> results = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final testNumber = data['testNumber'] as int?;
        if (testNumber != null) {
          results[testNumber] = {
            'score': data['highestScore'] as int? ?? 0,
            'totalQuestions': data['totalQuestions'] as int? ?? 0,
            'date': (data['lastAttemptDate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
            'attempts': data['totalAttempts'] as int? ?? 1,
          };
        }
      }
      
      if (results.isNotEmpty) {
        debugPrint('✅ Loaded ${results.length} test results from Firestore');
      }
      return results;
    } catch (e) {
      debugPrint('⚠️ Error loading from Firestore: $e');
      return {};
    }
  }

  Future<void> _loadTestResults() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user - cannot load user-specific test results');
        _testResults = {};
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final userId = user.uid;
      debugPrint('🔍 Loading test results for user: $userId, testSeries: ${widget.testSeriesKey}');
      
      // Step 1: Migrate any old non-user-specific data
      await _migrateOldData(userId);
      
      // Step 2: Try loading from Firestore first (source of truth, user-specific)
      _testResults = await _loadFromFirestore(userId);
      
      // Step 3: If Firestore has data, sync to local storage for offline access
      if (_testResults.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userSpecificKey = _getUserSpecificStorageKey(userId);
        final resultsJson = json.encode(_testResults.map((key, value) => MapEntry(key.toString(), value)));
        await prefs.setString(userSpecificKey, resultsJson);
        debugPrint('✅ Synced Firestore results to local storage');
      } else {
        // Step 4: Fallback to user-specific local storage if Firestore is empty
        final prefs = await SharedPreferences.getInstance();
        final userSpecificKey = _getUserSpecificStorageKey(userId);
        final resultsJson = prefs.getString(userSpecificKey);
        
        debugPrint('📦 Loading from local storage (user-specific): $userSpecificKey');
        
        if (resultsJson != null && resultsJson.isNotEmpty) {
          final Map<String, dynamic> decoded = json.decode(resultsJson);
          _testResults = decoded.map((key, value) => MapEntry(
            int.parse(key),
            Map<String, dynamic>.from(value),
          ));
          debugPrint('✅ Loaded ${_testResults.length} test results from local storage');
        } else {
          debugPrint('⚠️ No test results found in storage');
          _testResults = {};
        }
      }
      
      debugPrint('✅ Final loaded results: $_testResults');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading test results: $e');
      _testResults = {};
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      if (_listController.status != AnimationStatus.completed) {
        _listController.forward();
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorited = await _favoritesService.isBookFavorited(
        testSeriesKey: widget.testSeriesKey,
      );
      if (mounted) {
        setState(() {
          _isBookFavorited = isFavorited;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      // Show loading state
      if (mounted) {
        setState(() {
          _isLoadingFavorite = true;
        });
      }

      final success = await _favoritesService.toggleFavoriteBook(
        testSeriesTitle: widget.testSeriesTitle,
        subject: widget.subject,
        grade: widget.grade,
        testSeriesKey: widget.testSeriesKey,
        coverImagePath: widget.coverImagePath,
      );

      if (success) {
        // Update state after successful toggle
        final isFavorited = await _favoritesService.isBookFavorited(
          testSeriesKey: widget.testSeriesKey,
        );
        
        if (mounted) {
          setState(() {
            _isBookFavorited = isFavorited;
            _isLoadingFavorite = false;
          });

          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    _isBookFavorited ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isBookFavorited
                        ? 'Favorilere eklendi'
                        : 'Favorilerden çıkarıldı',
                  ),
                ],
              ),
              backgroundColor: _isBookFavorited ? Colors.red[600] : Colors.grey[600],
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingFavorite = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveTestResult(int testNumber, int correctCount, int totalQuestions) async {
    try {
      debugPrint('💾 Saving test result: Test $testNumber, Score: $correctCount/$totalQuestions');
      
      final currentScore = correctCount;
      final existingResult = _testResults[testNumber];
      final previousHighScore = existingResult != null ? (existingResult['score'] as int) : 0;
      
      // Keep highest score
      final highestScore = currentScore > previousHighScore ? currentScore : previousHighScore;
      
      _testResults[testNumber] = {
        'score': highestScore,
        'totalQuestions': totalQuestions,
        'date': DateTime.now().toIso8601String(),
        'attempts': (existingResult?['attempts'] as int? ?? 0) + 1,
      };
      
      debugPrint('📊 Updated test results: $_testResults');
      
      // Get current user ID for user-specific storage
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No authenticated user - cannot save user-specific test results');
        return;
      }
      
      // Save to SharedPreferences with user-specific key
      final prefs = await SharedPreferences.getInstance();
      final resultsKey = _getUserSpecificStorageKey(user.uid);
      final resultsJson = json.encode(_testResults.map((key, value) => MapEntry(key.toString(), value)));
      await prefs.setString(resultsKey, resultsJson);
      
      debugPrint('✅ Saved to SharedPreferences with user-specific key: $resultsKey');
      debugPrint('📦 JSON: $resultsJson');
      
      // Save to Firebase (backend persistence)
      await _saveToFirestore(testNumber, highestScore, totalQuestions, currentScore);
      
      // Refresh UI with setState
      if (mounted) {
        setState(() {
          debugPrint('🔄 UI refreshed with new test results');
        });
      }
      
      // Show score update if improved
      if (currentScore > previousHighScore && mounted) {
        final successRate = (highestScore / totalQuestions * 100).toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Yeni rekor! Skorunuz: $successRate%'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving test result: $e');
    }
  }
  
  Future<void> _saveToFirestore(int testNumber, int highestScore, int totalQuestions, int currentScore) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in, skipping Firestore save');
        return;
      }
      
      final firestore = FirebaseFirestore.instance;
      final testResultRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('test_results')
          .doc('${widget.subject}_${widget.grade}_${widget.testSeriesKey}_test$testNumber');
      
      // Get existing document to check if this is a new high score
      final existingDoc = await testResultRef.get();
      final previousHighScore = existingDoc.exists ? (existingDoc.data()?['highestScore'] as int? ?? 0) : 0;
      
      await testResultRef.set({
        'subject': widget.subject,
        'grade': widget.grade,
        'testSeriesKey': widget.testSeriesKey,
        'testNumber': testNumber,
        'highestScore': highestScore,
        'totalQuestions': totalQuestions,
        'lastScore': currentScore,
        'lastAttemptDate': FieldValue.serverTimestamp(),
        'isNewHighScore': currentScore > previousHighScore,
        'totalAttempts': FieldValue.increment(1),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Test result saved to Firestore: Test $testNumber - Score: $highestScore/$totalQuestions');
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
      // Don't throw - allow local save to succeed even if Firebase fails
    }
  }

  void _navigateToTest(int testNumber) {
    if (testNumber == 1) {
      debugPrint('🚀 Navigating to Test $testNumber');
      
      // Only Test 1 is active
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => InteractiveTestScreen(
            testTitle: '${widget.testSeriesTitle} - Test $testNumber',
            assetPathPrefix: 'assets/sorular/${widget.subject}/${widget.grade}/${widget.testSeriesKey}/test$testNumber',
            answerKeyPath: 'assets/sorular/${widget.subject}/${widget.grade}/${widget.testSeriesKey}/test$testNumber/answers.json',
            totalQuestions: 5,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ).then((result) async {
        debugPrint('⬅️ Returned from test with result: $result');
        debugPrint('⬅️ Result type: ${result.runtimeType}');
        
        // Check if test was completed and save result
        if (result != null && result is Map<String, dynamic>) {
          final correctCount = result['correctCount'] as int?;
          final totalQuestions = result['totalQuestions'] as int?;
          debugPrint('📝 Extracted from result: correctCount=$correctCount, totalQuestions=$totalQuestions');
          
          if (correctCount != null && totalQuestions != null) {
            debugPrint('💾 About to save test result...');
            await _saveTestResult(testNumber, correctCount, totalQuestions);
            debugPrint('✅ Test result saved successfully!');
          } else {
            debugPrint('❌ Missing correctCount or totalQuestions in result');
          }
        } else {
          debugPrint('❌ Result is null or not a Map');
        }
        
        // Always reload results when returning
        debugPrint('🔄 Reloading test results after navigation');
        await _loadTestResults();
        debugPrint('✅ Test results reloaded, current results: $_testResults');
      });
    } else {
      _showComingSoonDialog(testNumber);
    }
  }

  void _showComingSoonDialog(int testNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.gradientStart, widget.gradientEnd]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Yakında Gelecek', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test $testNumber henüz hazır değil.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.gradientStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.gradientStart.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.construction_rounded, color: widget.gradientStart, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Şu anda sadece Test 1 aktif.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: widget.gradientStart,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.gradientStart, widget.gradientEnd]),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.testSeriesTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              // Favorite Icon Button (Top-Right Corner)
              IconButton(
                icon: _isLoadingFavorite
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isBookFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.white,
                      ),
                onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                tooltip: _isBookFavorited ? 'Favorilerden çıkar' : 'Favorilere ekle',
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: widget.gradientStart),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Book Cover Card
                      FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: SlideTransition(
                          position: _headerSlideAnimation,
                          child: Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                widget.coverImagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          widget.testSeriesTitle,
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Section Title
                      Row(
                        children: [
                          Icon(Icons.assignment_rounded, color: widget.gradientStart, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            languageBloc.currentLanguage == 'tr' ? 'Testler' : 'Tests',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Test Cards
                      ...List.generate(widget.totalTests, (index) {
                        final testNumber = index + 1;
                        final isActive = testNumber == 1;
                        final hasResult = _testResults.containsKey(testNumber);
                        final result = _testResults[testNumber];
                        
                        return _buildTestCard(
                          testNumber: testNumber,
                          isActive: isActive,
                          hasResult: hasResult,
                          result: result,
                          index: index,
                        );
                      }),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTestCard({
    required int testNumber,
    required bool isActive,
    required bool hasResult,
    Map<String, dynamic>? result,
    required int index,
  }) {
    final successRate = hasResult && result != null
        ? ((result['score'] as int) / (result['totalQuestions'] as int) * 100).toInt()
        : null;
    
    final isPerfectScore = successRate == 100;
    final attempts = hasResult && result != null ? (result['attempts'] as int? ?? 1) : 0;
    
    // Format test title based on score - ENHANCED VISUAL REQUIREMENTS
    String testTitle;
    String statusLabel;
    IconData? statusIcon;
    Color? statusColor;
    
    if (hasResult && successRate != null) {
      final score = result!['score'] as int;
      final total = result['totalQuestions'] as int;
      final incorrect = total - score;
      
      if (isPerfectScore) {
        // Perfect score: Display "Önceki Skorun: 5 Doğru, 0 Yanlış"
        testTitle = 'Test $testNumber';
        statusLabel = 'Önceki Skorun: $score Doğru, $incorrect Yanlış';
        statusIcon = Icons.workspace_premium_rounded;
        statusColor = Colors.amber[700];
      } else {
        // Partial score: Display "Önceki Skorun: 4 Doğru, 1 Yanlış"
        testTitle = 'Test $testNumber';
        statusLabel = 'Önceki Skorun: $score Doğru, $incorrect Yanlış';
        statusIcon = Icons.check_circle_rounded;
        statusColor = Colors.green[700];
      }
    } else {
      // Not attempted
      testTitle = 'Test $testNumber';
      if (isActive) {
        statusLabel = '5 Soru • Başlat'; // Active test not yet attempted
        statusIcon = Icons.play_circle_rounded;
        statusColor = widget.gradientStart;
      } else {
        statusLabel = 'Yakında Gelecek'; // Locked test
        statusIcon = Icons.lock_clock_rounded;
        statusColor = Colors.orange[700];
      }
    }
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isPerfectScore
                    ? Border.all(color: Colors.amber[600]!, width: 2)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToTest(testNumber),
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Test Number Circle
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(colors: [widget.gradientStart, widget.gradientEnd])
                                    : null,
                                color: isActive ? null : Colors.grey[300],
                                shape: BoxShape.circle,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: widget.gradientStart.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '$testNumber',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                  if (isPerfectScore)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber[400],
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Test Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? isPerfectScore
                                              ? Colors.amber[700]
                                              : Colors.black87
                                          : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Enhanced Status Badge with Icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: (statusColor ?? Colors.grey[700])!.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (statusColor ?? Colors.grey[700])!.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (statusIcon != null) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Icon(
                                              statusIcon,
                                              size: 16,
                                              color: statusColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                              letterSpacing: 0.2,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasResult && attempts > 1) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.repeat_rounded,
                                          size: 12,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$attempts deneme',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Status Icon
                            Icon(
                              isActive
                                  ? hasResult
                                      ? isPerfectScore
                                          ? Icons.star_rounded
                                          : Icons.replay_rounded
                                      : Icons.play_arrow_rounded
                                  : Icons.lock_rounded,
                              color: isActive
                                  ? hasResult
                                      ? isPerfectScore
                                          ? Colors.amber[600]
                                          : Colors.green[700]
                                      : widget.gradientStart
                                  : Colors.grey[400],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                      
                      // Question Count Badge (Top-Right Corner)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.gradientStart.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.gradientStart.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.quiz_rounded,
                                size: 14,
                                color: widget.gradientStart,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '5 Soru',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: widget.gradientStart,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

