import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../blocs/bloc_exports.dart';
import 'local_pdf_viewer_screen.dart';
import '../services/favorites_service.dart';

/// Interactive Test Screen
/// Displays question images with selectable answer options
/// Supports sequential navigation (Previous/Next)
/// Includes automated scoring with answer key
class InteractiveTestScreen extends StatefulWidget {
  final String testTitle;
  final String assetPathPrefix;
  final String? answerKeyPath;
  final int totalQuestions;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isTimed;
  
  const InteractiveTestScreen({
    super.key,
    required this.testTitle,
    required this.assetPathPrefix,
    this.answerKeyPath,
    required this.totalQuestions,
    required this.gradientStart,
    required this.gradientEnd,
    this.isTimed = false,
  });

  @override
  State<InteractiveTestScreen> createState() => _InteractiveTestScreenState();
}

class _InteractiveTestScreenState extends State<InteractiveTestScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {}; // questionIndex -> answer (A, B, C, D, E)
  Map<String, String> _correctAnswers = {}; // questionNumber -> correct answer
  String? _explanationPdfPath;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Answer options
  final List<String> _answerOptions = ['A', 'B', 'C', 'D', 'E'];
  
  // Reference to the BLoC for safe disposal
  late BottomNavVisibilityBloc _bottomNavBloc;
  bool _bottomNavInitialized = false;
  
  // Favorites service
  final FavoritesService _favoritesService = FavoritesService();
  final Map<int, bool> _favoritedQuestions = {}; // questionIndex -> isFavorited
  
  // Timer state
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _totalPausedDuration = Duration.zero;
  bool _isTimerPaused = false;
  bool _isTimerRunning = false;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _loadAnswerKey();
    _loadFavoriteStatus();
    
    // Start timer if timed mode is enabled
    if (widget.isTimed) {
      _startTimer();
    }
  }
  
  /// Load favorite status for current question
  Future<void> _loadFavoriteStatus() async {
    final isFavorited = await _favoritesService.isQuestionFavorited(
      testName: widget.testTitle,
      questionNumber: _currentQuestionIndex + 1,
    );
    
    if (mounted) {
      setState(() {
        _favoritedQuestions[_currentQuestionIndex] = isFavorited;
      });
    }
  }
  
  /// Toggle favorite for current question
  Future<void> _toggleFavorite() async {
    final questionNumber = _currentQuestionIndex + 1;
    // Ensure proper path format: assetPathPrefix already includes test1, so we just add /soruX.png
    // assetPathPrefix = 'assets/sorular/matematik/tyt/ens_problemler/test1'
    // Result should be: 'assets/sorular/matematik/tyt/ens_problemler/test1/soru3.png'
    final imagePath = '${widget.assetPathPrefix}/soru$questionNumber.png';
    debugPrint('📸 Favorite image path: $imagePath');
    final userAnswer = _selectedAnswers[_currentQuestionIndex];
    final correctAnswer = _correctAnswers[questionNumber.toString()];
    
    final success = await _favoritesService.toggleFavorite(
      questionNumber: questionNumber,
      imagePath: imagePath,
      testName: widget.testTitle,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
    );
    
    if (success && mounted) {
      final wasFavorited = _favoritedQuestions[_currentQuestionIndex] ?? false;
      
      setState(() {
        _favoritedQuestions[_currentQuestionIndex] = !wasFavorited;
      });
      
      // Show feedback
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 2),
        content: AwesomeSnackbarContent(
          title: !wasFavorited ? 'Favorilere Eklendi!' : 'Favorilerden Çıkarıldı',
          message: !wasFavorited 
              ? 'Soru $questionNumber favorilerinize eklendi.'
              : 'Soru $questionNumber favorilerinizden çıkarıldı.',
          contentType: !wasFavorited ? ContentType.success : ContentType.help,
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Save BLoC reference and hide bottom nav only once
    if (!_bottomNavInitialized) {
      _bottomNavBloc = context.read<BottomNavVisibilityBloc>();
      _bottomNavBloc.add(const HideBottomNav());
      _bottomNavInitialized = true;
    }
  }
  
  Future<void> _loadAnswerKey() async {
    if (widget.answerKeyPath == null) return;
    
    try {
      final String jsonString = await rootBundle.loadString(widget.answerKeyPath!);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      setState(() {
        _correctAnswers = Map<String, String>.from(data['answers'] ?? {});
        _explanationPdfPath = data['explanation_pdf'];
      });
      
      debugPrint('✅ Answer key loaded: $_correctAnswers');
    } catch (e) {
      debugPrint('❌ Error loading answer key: $e');
    }
  }

  @override
  void dispose() {
    // Restore bottom navigation bar when leaving test screen
    _bottomNavBloc.add(const ShowBottomNav());
    _fadeController.dispose();
    super.dispose();
  }

  /// Start the timer
  void _startTimer() {
    if (!_isTimerRunning && !_isTimerPaused) {
      setState(() {
        _startTime = DateTime.now();
        _isTimerRunning = true;
        _isTimerPaused = false;
      });
      _updateTimer();
    }
  }

  /// Pause the timer
  void _pauseTimer() {
    if (_isTimerRunning && !_isTimerPaused && _startTime != null) {
      final now = DateTime.now();
      final currentElapsed = now.difference(_startTime!);
      setState(() {
        _pauseTime = now;
        _isTimerPaused = true;
        // Update elapsed time to current value at pause moment
        _elapsedTime = currentElapsed - _totalPausedDuration;
      });
    }
  }

  /// Resume the timer
  void _resumeTimer() {
    if (_isTimerRunning && _isTimerPaused && _pauseTime != null && _startTime != null) {
      final now = DateTime.now();
      final pauseDuration = now.difference(_pauseTime!);
      setState(() {
        _totalPausedDuration += pauseDuration;
        _pauseTime = null;
        _isTimerPaused = false;
      });
      _updateTimer();
    }
  }

  /// Toggle pause/resume
  void _toggleTimerPause() {
    if (_isTimerPaused) {
      _resumeTimer();
    } else {
      _pauseTimer();
    }
  }

  /// Update timer display
  void _updateTimer() {
    if (_isTimerRunning && !_isTimerPaused && _startTime != null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isTimerRunning && !_isTimerPaused) {
          final now = DateTime.now();
          final totalElapsed = now.difference(_startTime!);
          setState(() {
            _elapsedTime = totalElapsed - _totalPausedDuration;
          });
          _updateTimer();
        }
      });
    }
  }

  /// Get formatted time string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.totalQuestions - 1) {
      setState(() {
        _fadeController.reset();
        _currentQuestionIndex++;
      });
      _fadeController.forward();
      _loadFavoriteStatus(); // Load favorite status for new question
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _fadeController.reset();
        _currentQuestionIndex--;
      });
      _fadeController.forward();
      _loadFavoriteStatus(); // Load favorite status for new question
    }
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
    
    // Show visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('$answer şıkkı seçildi'),
          ],
        ),
        backgroundColor: widget.gradientStart,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _submitTest() {
    final answeredCount = _selectedAnswers.length;
    final unansweredCount = widget.totalQuestions - answeredCount;
    
    // Calculate score if answer key is available
    int correctCount = 0;
    int incorrectCount = 0;
    
    if (_correctAnswers.isNotEmpty) {
      for (var entry in _selectedAnswers.entries) {
        final questionNum = (entry.key + 1).toString();
        final userAnswer = entry.value;
        final correctAnswer = _correctAnswers[questionNum];
        
        if (correctAnswer != null && userAnswer == correctAnswer) {
          correctCount++;
        } else if (correctAnswer != null) {
          incorrectCount++;
        }
      }
    }
    
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
                child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Testi Bitir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test özeti:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(Icons.check_circle_rounded, 'Cevaplanan', '$answeredCount soru', Colors.green),
              const SizedBox(height: 8),
              _buildSummaryRow(Icons.radio_button_unchecked_rounded, 'Boş', '$unansweredCount soru', Colors.orange),
              
              if (_correctAnswers.isNotEmpty && answeredCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.gradientStart.withValues(alpha: 0.1), widget.gradientEnd.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.gradientStart.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(Icons.check_rounded, 'Doğru', '$correctCount', Colors.green[700]!),
                      const SizedBox(height: 6),
                      _buildSummaryRow(Icons.close_rounded, 'Yanlış', '$incorrectCount', Colors.red[700]!),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              if (unansweredCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bazı sorular cevaplanmadı',
                          style: TextStyle(fontSize: 13, color: Colors.orange[900], fontWeight: FontWeight.w500),
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
              child: const Text('Devam Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showResultsScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.gradientStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Bitir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showResultsScreen() {
    // Calculate final elapsed time before stopping timer
    Duration finalElapsedTime = _elapsedTime;
    
    if (widget.isTimed && _startTime != null) {
      if (_isTimerPaused && _pauseTime != null) {
        // Timer is paused - calculate elapsed time up to pause point
        final totalElapsed = _pauseTime!.difference(_startTime!);
        finalElapsedTime = totalElapsed - _totalPausedDuration;
      } else if (_isTimerRunning && !_isTimerPaused) {
        // Timer is running - calculate current elapsed time
        final now = DateTime.now();
        final totalElapsed = now.difference(_startTime!);
        finalElapsedTime = totalElapsed - _totalPausedDuration;
      }
    }
    
    // Stop timer when submitting test
    if (widget.isTimed && _isTimerRunning) {
      setState(() {
        _isTimerRunning = false;
      });
    }
    
    // Calculate results to return
    int correctCount = 0;
    if (_correctAnswers.isNotEmpty) {
      for (var entry in _selectedAnswers.entries) {
        final questionNum = (entry.key + 1).toString();
        final userAnswer = entry.value;
        final correctAnswer = _correctAnswers[questionNum];
        
        if (correctAnswer != null && userAnswer == correctAnswer) {
          correctCount++;
        }
      }
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TestResultsScreen(
          testTitle: widget.testTitle,
          totalQuestions: widget.totalQuestions,
          selectedAnswers: _selectedAnswers,
          correctAnswers: _correctAnswers,
          correctCount: correctCount,
          explanationPdfPath: _explanationPdfPath != null 
              ? '${widget.assetPathPrefix}/$_explanationPdfPath'
              : null,
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          elapsedTime: widget.isTimed ? finalElapsedTime : null,
        ),
      ),
    ).then((result) {
      // When returning from results screen, pass data back to test selection screen
      if (result != null && result is Map<String, dynamic> && mounted && context.mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  String _getQuestionImagePath() {
    return '${widget.assetPathPrefix}/soru${_currentQuestionIndex + 1}.png';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
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
              onPressed: () {
                if (_selectedAnswers.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Testi Bırak?'),
                      content: const Text('Teste verdiğiniz cevaplar kaydedilmeyecek. Devam etmek istiyor musunuz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Çık', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.testTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Soru ${_currentQuestionIndex + 1}/${widget.totalQuestions}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
            actions: [
              // TIMER WIDGET - TOP RIGHT (if timed mode)
              if (widget.isTimed)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isTimerPaused 
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: _toggleTimerPause,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isTimerPaused ? Icons.pause_rounded : Icons.timer_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(_elapsedTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // FAVORITE BUTTON
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_favoritedQuestions[_currentQuestionIndex] ?? false)
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    (_favoritedQuestions[_currentQuestionIndex] ?? false)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: (_favoritedQuestions[_currentQuestionIndex] ?? false)
                        ? Colors.red[300]
                        : Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _toggleFavorite,
                tooltip: 'Favorilere Ekle/Çıkar',
              ),
              const SizedBox(width: 8),
              // Answer counter
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white.withValues(alpha: 0.9), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedAnswers.length}/${widget.totalQuestions}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / widget.totalQuestions,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(widget.gradientStart),
                minHeight: 4,
              ),
              
              // Question Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question Image Card
                        Container(
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
                              _getQuestionImagePath(),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Soru ${_currentQuestionIndex + 1} yüklenemedi',
                                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Answer Options Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fact_check_rounded, color: widget.gradientStart, size: 24),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Cevabınızı Seçin',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Answer Options
                              ..._answerOptions.map((option) => _buildAnswerOption(option)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 100), // Space for navigation buttons
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildNavigationBar(),
        );
      },
    );
  }

  Widget _buildAnswerOption(String option) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == option;
    
    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? widget.gradientStart.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? widget.gradientStart : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.gradientStart.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Option Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(colors: [widget.gradientStart, widget.gradientEnd])
                    : null,
                color: isSelected ? null : Colors.grey[300],
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Option Label
            Expanded(
              child: Text(
                'Şık $option',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? widget.gradientStart : Colors.grey[800],
                ),
              ),
            ),
            
            // Check Icon
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: widget.gradientStart,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Önceki', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: _currentQuestionIndex > 0 ? Colors.grey[800] : Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Next or Submit Button
            Expanded(
              flex: _currentQuestionIndex == widget.totalQuestions - 1 ? 2 : 1,
              child: ElevatedButton.icon(
                onPressed: _currentQuestionIndex == widget.totalQuestions - 1
                    ? _submitTest
                    : _goToNextQuestion,
                icon: Icon(
                  _currentQuestionIndex == widget.totalQuestions - 1
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _currentQuestionIndex == widget.totalQuestions - 1 ? 'Testi Bitir' : 'Sonraki',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentQuestionIndex == widget.totalQuestions - 1
                      ? Colors.green[600]
                      : widget.gradientStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test Results Screen
class _TestResultsScreen extends StatelessWidget {
  final String testTitle;
  final int totalQuestions;
  final Map<int, String> selectedAnswers;
  final Map<String, String> correctAnswers;
  final int correctCount;
  final String? explanationPdfPath;
  final Color gradientStart;
  final Color gradientEnd;
  final Duration? elapsedTime;
  
  const _TestResultsScreen({
    required this.testTitle,
    required this.totalQuestions,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.correctCount,
    this.explanationPdfPath,
    required this.gradientStart,
    required this.gradientEnd,
    this.elapsedTime,
  });

  /// Get formatted time string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final answeredCount = selectedAnswers.length;
    final completionPercentage = ((answeredCount / totalQuestions) * 100).toInt();
    
    // Calculate detailed score
    int incorrectCount = 0;
    Map<int, bool> questionResults = {}; // questionIndex -> isCorrect
    
    if (correctAnswers.isNotEmpty) {
      for (var entry in selectedAnswers.entries) {
        final questionNum = (entry.key + 1).toString();
        final userAnswer = entry.value;
        final correctAnswer = correctAnswers[questionNum];
        
        if (correctAnswer != null && userAnswer == correctAnswer) {
          questionResults[entry.key] = true;
        } else if (correctAnswer != null) {
          incorrectCount++;
          questionResults[entry.key] = false;
        }
      }
    }
    
    final hasScoring = correctAnswers.isNotEmpty;
    final scorePercentage = hasScoring && answeredCount > 0 
        ? ((correctCount / totalQuestions) * 100).toInt() 
        : completionPercentage;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: gradientStart,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
          ),
        ),
        title: const Text('Test Sonucu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: gradientStart.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    hasScoring && correctCount >= totalQuestions * 0.7 
                        ? Icons.emoji_events_rounded 
                        : hasScoring && correctCount >= totalQuestions * 0.5
                            ? Icons.star_rounded
                            : Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  if (hasScoring) ...[
                    Text(
                      'Puanınız: $scorePercentage',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Elapsed time display (beneath score metric)
                    if (elapsedTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Toplam Süre: ${_formatDuration(elapsedTime!)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$correctCount doğru, $incorrectCount yanlış',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Net: ${(correctCount - (incorrectCount * 0.25)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ] else ...[
                    Text(
                      '$completionPercentage% Tamamlandı',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Elapsed time display (beneath completion percentage)
                    if (elapsedTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Toplam Süre: ${_formatDuration(elapsedTime!)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$answeredCount / $totalQuestions soru cevaplanmış',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Detailed Results
            if (hasScoring && questionResults.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_rounded, color: gradientStart, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Soru Detayları',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(totalQuestions, (index) {
                      final questionNum = (index + 1).toString();
                      final userAnswer = selectedAnswers[index];
                      final correctAnswer = correctAnswers[questionNum];
                      final isCorrect = questionResults[index];
                      final isUnanswered = userAnswer == null;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isUnanswered 
                                    ? Colors.grey[200]
                                    : isCorrect == true
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  questionNum,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isUnanswered
                                        ? Colors.grey[600]
                                        : isCorrect == true
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (!isUnanswered)
                                        Icon(
                                          isCorrect == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                          size: 18,
                                          color: isCorrect == true ? Colors.green[700] : Colors.red[700],
                                        ),
                                      if (!isUnanswered) const SizedBox(width: 6),
                                      Text(
                                        isUnanswered
                                            ? 'Boş'
                                            : isCorrect == true
                                                ? 'Doğru'
                                                : 'Yanlış',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isUnanswered
                                              ? Colors.grey[700]
                                              : isCorrect == true
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isUnanswered) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      isCorrect == true
                                          ? 'Cevabınız: $userAnswer ✓'
                                          : 'Cevabınız: $userAnswer • Doğru: $correctAnswer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            
            if (hasScoring && questionResults.isNotEmpty)
              const SizedBox(height: 24),
            
            // View Solutions Button
            if (explanationPdfPath != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocalPDFViewerScreen(
                        assetPath: explanationPdfPath!,
                        title: 'Çözümler',
                        gradientStart: gradientStart,
                        gradientEnd: gradientEnd,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Çözümleri Görüntüle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gradientStart,
                  side: BorderSide(color: gradientStart, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            
            if (explanationPdfPath != null)
              const SizedBox(height: 16),
            
            // Back Button
            ElevatedButton.icon(
              onPressed: () {
                // Return test results to previous screen
                Navigator.of(context).pop({
                  'correctCount': correctCount,
                  'totalQuestions': totalQuestions,
                  'answeredCount': answeredCount,
                });
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Geri Dön', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: gradientStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

