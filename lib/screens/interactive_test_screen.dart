import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../blocs/bloc_exports.dart';
import 'local_pdf_viewer_screen.dart';
import '../services/favorites_service.dart';
import '../services/statistics_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

/// Interactive Test Screen
/// Refactored to Neumorphic Design System
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
  
  late BottomNavVisibilityBloc _bottomNavBloc;
  bool _bottomNavInitialized = false;
  
  final FavoritesService _favoritesService = FavoritesService();
  final Map<int, bool> _favoritedQuestions = {}; 
  
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
    
    if (widget.isTimed) {
      _startTimer();
    }
  }
  
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
  
  Future<void> _toggleFavorite() async {
    final questionNumber = _currentQuestionIndex + 1;
    final imagePath = '${widget.assetPathPrefix}/soru$questionNumber.png';
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!wasFavorited ? 'Favorilere Eklendi' : 'Favorilerden Çıkarıldı'),
          backgroundColor: !wasFavorited ? Colors.green : Colors.grey,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    } catch (e) {
      debugPrint('Error loading answer key: $e');
    }
  }

  @override
  void dispose() {
    _bottomNavBloc.add(const ShowBottomNav());
    _fadeController.dispose();
    super.dispose();
  }

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

  void _pauseTimer() {
    if (_isTimerRunning && !_isTimerPaused && _startTime != null) {
      final now = DateTime.now();
      final currentElapsed = now.difference(_startTime!);
      setState(() {
        _pauseTime = now;
        _isTimerPaused = true;
        _elapsedTime = currentElapsed - _totalPausedDuration;
      });
    }
  }

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

  void _toggleTimerPause() {
    if (_isTimerPaused) {
      _resumeTimer();
    } else {
      _pauseTimer();
    }
  }

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
      _loadFavoriteStatus();
    }
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _submitTest() {
    final answeredCount = _selectedAnswers.length;
    final unansweredCount = widget.totalQuestions - answeredCount;
    final textColor = NeumorphicColors.getText(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Testi Bitir', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cevaplanan: $answeredCount', style: TextStyle(color: textColor)),
              Text('Boş: $unansweredCount', style: TextStyle(color: textColor)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Devam Et'),
            ),
            NeumorphicButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showResultsScreen();
              },
              color: NeumorphicColors.accentBlue,
              child: const Text('Bitir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showResultsScreen() {
    Duration finalElapsedTime = _elapsedTime;
    
    if (widget.isTimed && _startTime != null) {
      if (_isTimerPaused && _pauseTime != null) {
        final totalElapsed = _pauseTime!.difference(_startTime!);
        finalElapsedTime = totalElapsed - _totalPausedDuration;
      } else if (_isTimerRunning && !_isTimerPaused) {
        final now = DateTime.now();
        final totalElapsed = now.difference(_startTime!);
        finalElapsedTime = totalElapsed - _totalPausedDuration;
      }
    }
    
    if (widget.isTimed && _isTimerRunning) {
      setState(() {
        _isTimerRunning = false;
      });
    }
    
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
    
    // Stats Logic (kept same)
    final subject = _extractSubjectFromPrefix(widget.assetPathPrefix);
    if (subject.isNotEmpty) {
      StatisticsService.instance.logQuizResult(subject, correctCount, widget.totalQuestions);
    }
    StatisticsService.instance.logDailyActivity(increment: _selectedAnswers.length);
    StatisticsService.instance.logTestCompleted(
      lesson: subject.isNotEmpty ? subject : 'Unknown',
      source: widget.testTitle,
      correct: correctCount,
      total: widget.totalQuestions,
    );
    
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
      if (result != null && result is Map<String, dynamic> && mounted && context.mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  String _getQuestionImagePath() {
    return '${widget.assetPathPrefix}/soru${_currentQuestionIndex + 1}.png';
  }

  String _extractSubjectFromPrefix(String prefix) {
    try {
      final parts = prefix.split('/');
      if (parts.length >= 3) {
        final subj = parts[2];
        if (subj.isNotEmpty) {
          return subj[0].toUpperCase() + subj.substring(1);
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    
                    // Question Card
                    Expanded(
                      flex: 5,
                      child: _buildQuestionCard(context),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Answer Selection
                    _buildAnswerSelectionCard(context),
                    
                    const SizedBox(height: 20),
                    
                    // Navigation
                    _buildNextButton(context),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textColor = NeumorphicColors.getText(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NeumorphicButton(
            onPressed: () {
               if (_selectedAnswers.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: NeumorphicColors.getBackground(context),
                      title: Text('Testi Bırak?', style: TextStyle(color: textColor)),
                      content: Text('Cevaplar kaydedilmeyecek.', style: TextStyle(color: textColor)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                        TextButton(
                          onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                          child: const Text('Çık', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
            },
            padding: const EdgeInsets.all(12),
            borderRadius: 12,
            child: Icon(Icons.arrow_back_rounded, color: textColor),
          ),
          
          Column(
            children: [
              Text(
                widget.testTitle,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              ),
              Text(
                'Soru ${_currentQuestionIndex + 1}/${widget.totalQuestions}',
                style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
              ),
            ],
          ),
          
          Row(
            children: [
              if (widget.isTimed)
                NeumorphicButton(
                  onPressed: _toggleTimerPause,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _isTimerPaused ? Icons.pause_rounded : Icons.timer_rounded,
                        color: NeumorphicColors.accentOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_elapsedTime),
                        style: const TextStyle(
                          color: NeumorphicColors.accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.isTimed) const SizedBox(width: 8),
               NeumorphicButton(
                onPressed: _toggleFavorite,
                padding: const EdgeInsets.all(12),
                child: Icon(
                  (_favoritedQuestions[_currentQuestionIndex] ?? false)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: (_favoritedQuestions[_currentQuestionIndex] ?? false)
                      ? Colors.redAccent
                      : textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_currentQuestionIndex + 1}.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: NeumorphicColors.getText(context)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _getQuestionImagePath(),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Görsel yüklenemedi', style: TextStyle(color: Colors.grey[600])),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSelectionCard(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: NeumorphicColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cevabınızı Seçin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NeumorphicColors.getText(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _answerOptions.map((option) => _buildAnswerButton(context, option)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(BuildContext context, String option) {
    final isSelected = _selectedAnswers[_currentQuestionIndex] == option;
    final textColor = NeumorphicColors.getText(context);
    
    return NeumorphicButton(
      onPressed: () => _selectAnswer(option),
      padding: const EdgeInsets.all(0),
      child: NeumorphicContainer(
        width: 48,
        height: 48,
        padding: EdgeInsets.zero,
        borderRadius: 12,
        depth: isSelected ? -3 : 3, // Inset if selected
        color: isSelected ? NeumorphicColors.accentBlue.withValues(alpha: 0.1) : null,
        child: Center(
          child: Text(
            option,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? NeumorphicColors.accentBlue : textColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return NeumorphicButton(
      onPressed: _currentQuestionIndex == widget.totalQuestions - 1
          ? _submitTest
          : _goToNextQuestion,
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 30,
      color: NeumorphicColors.accentBlue,
      child: Center(
        child: Text(
          _currentQuestionIndex == widget.totalQuestions - 1 ? 'TESTİ BİTİR' : 'SONRAKİ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);
    
    final answeredCount = selectedAnswers.length;
    final scorePercentage = totalQuestions > 0 ? ((correctCount / totalQuestions) * 100).toInt() : 0;
    
    // Stats calc...
    int incorrectCount = 0;
    if (correctAnswers.isNotEmpty) {
      for (var entry in selectedAnswers.entries) {
        final questionNum = (entry.key + 1).toString();
        final userAnswer = entry.value;
        final correctAnswer = correctAnswers[questionNum];
        if (correctAnswer != null && userAnswer != correctAnswer) {
          incorrectCount++;
        }
      }
    }
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Result Card
              NeumorphicContainer(
                padding: const EdgeInsets.all(32),
                borderRadius: 30,
                child: Column(
                  children: [
                    Text(
                      'Test Sonucu',
                      style: TextStyle(fontSize: 20, color: textColor.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$scorePercentage',
                      style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: gradientStart),
                    ),
                    Text(
                      'PUAN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gradientStart),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Doğru', '$correctCount', Colors.green),
                        _buildStatItem(context, 'Yanlış', '$incorrectCount', Colors.red),
                        _buildStatItem(context, 'Boş', '${totalQuestions - answeredCount}', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Actions
              if (explanationPdfPath != null)
                NeumorphicButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocalPDFViewerScreen(
                          assetPath: explanationPdfPath!,
                          title: 'Çözümler',
                        ),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: textColor),
                      const SizedBox(width: 12),
                      Text('Çözümleri Görüntüle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                ),
                
              const SizedBox(height: 16),
              
              NeumorphicButton(
                onPressed: () => Navigator.of(context).pop({
                  'correctCount': correctCount,
                  'totalQuestions': totalQuestions,
                }),
                color: gradientStart,
                child: const Center(
                  child: Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 14, color: NeumorphicColors.getText(context).withValues(alpha: 0.6))),
      ],
    );
  }
}
