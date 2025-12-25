import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../blocs/bloc_exports.dart';
import '../services/favorites_service.dart';
import 'interactive_test_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

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

  String _getUserSpecificStorageKey(String userId) {
    return 'test_results_${userId}_${widget.testSeriesKey}';
  }

  Future<void> _migrateOldData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldKey = 'test_results_${widget.testSeriesKey}';
      
      if (prefs.containsKey(oldKey)) {
        final oldResultsJson = prefs.getString(oldKey);
        if (oldResultsJson != null && oldResultsJson.isNotEmpty) {
          final newKey = _getUserSpecificStorageKey(userId);
          if (!prefs.containsKey(newKey)) {
            await prefs.setString(newKey, oldResultsJson);
          }
          await prefs.remove(oldKey);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error during data migration: $e');
    }
  }

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
        _testResults = {};
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userId = user.uid;
      await _migrateOldData(userId);
      _testResults = await _loadFromFirestore(userId);
      
      if (_testResults.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userSpecificKey = _getUserSpecificStorageKey(userId);
        final resultsJson = json.encode(_testResults.map((key, value) => MapEntry(key.toString(), value)));
        await prefs.setString(userSpecificKey, resultsJson);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userSpecificKey = _getUserSpecificStorageKey(userId);
        final resultsJson = prefs.getString(userSpecificKey);
        
        if (resultsJson != null && resultsJson.isNotEmpty) {
          final Map<String, dynamic> decoded = json.decode(resultsJson);
          _testResults = decoded.map((key, value) => MapEntry(
            int.parse(key),
            Map<String, dynamic>.from(value),
          ));
        } else {
          _testResults = {};
        }
      }
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading test results: $e');
      _testResults = {};
      if (mounted) setState(() => _isLoading = false);
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
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (mounted) setState(() => _isLoadingFavorite = true);

      final success = await _favoritesService.toggleFavoriteBook(
        testSeriesTitle: widget.testSeriesTitle,
        subject: widget.subject,
        grade: widget.grade,
        testSeriesKey: widget.testSeriesKey,
        coverImagePath: widget.coverImagePath,
      );

      if (success) {
        final isFavorited = await _favoritesService.isBookFavorited(
          testSeriesKey: widget.testSeriesKey,
        );
        
        if (mounted) {
          setState(() {
            _isBookFavorited = isFavorited;
            _isLoadingFavorite = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBookFavorited ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı'),
              backgroundColor: _isBookFavorited ? Colors.green : Colors.grey,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) setState(() => _isLoadingFavorite = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _saveTestResult(int testNumber, int correctCount, int totalQuestions) async {
    try {
      final currentScore = correctCount;
      final existingResult = _testResults[testNumber];
      final previousHighScore = existingResult != null ? (existingResult['score'] as int) : 0;
      final highestScore = currentScore > previousHighScore ? currentScore : previousHighScore;
      
      _testResults[testNumber] = {
        'score': highestScore,
        'totalQuestions': totalQuestions,
        'date': DateTime.now().toIso8601String(),
        'attempts': (existingResult?['attempts'] as int? ?? 0) + 1,
      };
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final resultsKey = _getUserSpecificStorageKey(user.uid);
      final resultsJson = json.encode(_testResults.map((key, value) => MapEntry(key.toString(), value)));
      await prefs.setString(resultsKey, resultsJson);
      
      await _saveToFirestore(testNumber, highestScore, totalQuestions, currentScore);
      
      if (mounted) setState(() {});
      
      if (currentScore > previousHighScore && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yeni rekor! Skorunuz: ${(highestScore / totalQuestions * 100).toInt()}%'),
            backgroundColor: Colors.green,
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
      if (user == null) return;
      
      final firestore = FirebaseFirestore.instance;
      final testResultRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('test_results')
          .doc('${widget.subject}_${widget.grade}_${widget.testSeriesKey}_test$testNumber');
      
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
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
    }
  }

  void _navigateToTest(int testNumber) {
    if (testNumber == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InteractiveTestScreen(
            testTitle: '${widget.testSeriesTitle} - Test $testNumber',
            assetPathPrefix: 'assets/sorular/${widget.subject}/${widget.grade}/${widget.testSeriesKey}/test$testNumber',
            answerKeyPath: 'assets/sorular/${widget.subject}/${widget.grade}/${widget.testSeriesKey}/test$testNumber/answers.json',
            totalQuestions: 5,
            gradientStart: widget.gradientStart,
            gradientEnd: widget.gradientEnd,
          ),
        ),
      ).then((result) async {
        if (result != null && result is Map<String, dynamic>) {
          final correctCount = result['correctCount'] as int?;
          final totalQuestions = result['totalQuestions'] as int?;
          
          if (correctCount != null && totalQuestions != null) {
            await _saveTestResult(testNumber, correctCount, totalQuestions);
          }
        }
        await _loadTestResults();
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
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Yakında Gelecek', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeumorphicColors.getText(context),
            )
          ),
          content: Text(
            'Test $testNumber henüz hazır değil. Şu anda sadece Test 1 aktif.',
            style: TextStyle(color: NeumorphicColors.getText(context)),
          ),
          actions: [
            NeumorphicButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tamam',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.gradientStart,
                ),
              ),
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
        final bgColor = NeumorphicColors.getBackground(context);
        final textColor = NeumorphicColors.getText(context);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      NeumorphicButton(
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(Icons.arrow_back_rounded, color: textColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.testSeriesTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      NeumorphicButton(
                        onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: _isLoadingFavorite
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isBookFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isBookFavorited ? Colors.red : textColor,
                              ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: widget.gradientStart),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Book Cover Card (Neumorphic)
                              NeumorphicContainer(
                                padding: const EdgeInsets.all(16),
                                borderRadius: 24,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    widget.coverImagePath,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Section Title
                              Row(
                                children: [
                                  NeumorphicContainer(
                                    padding: const EdgeInsets.all(8),
                                    borderRadius: 8,
                                    depth: -2,
                                    child: Icon(Icons.assignment_rounded, color: widget.gradientStart, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    languageBloc.currentLanguage == 'tr' ? 'Testler' : 'Tests',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Test List
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
                                  textColor: textColor,
                                );
                              }),
                            ],
                          ),
                        ),
                ),
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
    required Color textColor,
  }) {
    final successRate = hasResult && result != null
        ? ((result['score'] as int) / (result['totalQuestions'] as int) * 100).toInt()
        : null;
    
    final isPerfectScore = successRate == 100;
    
    String statusLabel;
    IconData statusIcon;
    Color statusColor;
    
    if (hasResult && successRate != null) {
      final score = result!['score'] as int;
      final total = result['totalQuestions'] as int;
      final incorrect = total - score;
      
      statusLabel = '$score D / $incorrect Y';
      statusIcon = isPerfectScore ? Icons.star_rounded : Icons.check_circle_rounded;
      statusColor = isPerfectScore ? Colors.amber : Colors.green;
    } else {
      if (isActive) {
        statusLabel = 'Başlat';
        statusIcon = Icons.play_arrow_rounded;
        statusColor = widget.gradientStart;
      } else {
        statusLabel = 'Kilitli';
        statusIcon = Icons.lock_rounded;
        statusColor = Colors.grey;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeumorphicButton(
        onPressed: () => _navigateToTest(testNumber),
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            // Test Number
            NeumorphicContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 12,
              depth: isActive ? -2 : 2, // Inset if active
              color: isActive ? null : Colors.grey.withValues(alpha: 0.1),
              child: Text(
                '$testNumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isActive ? widget.gradientStart : Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test $testNumber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Icon
            Icon(
              Icons.chevron_right_rounded,
              color: textColor.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
