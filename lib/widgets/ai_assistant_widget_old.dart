import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import '../services/llm_config.dart';
import '../models/ai_response.dart';
import '../blocs/bloc_exports.dart';

/// AI Study Assistant Widget
/// 
/// This widget provides an interactive AI assistant interface for Q&A.
/// Students can ask questions and receive personalized answers.
/// 
/// Designed for contextual help and interactive learning
class AIAssistantWidget extends StatefulWidget {
  final String? selectedText;
  final String? userName;
  final VoidCallback? onClose;

  const AIAssistantWidget({
    super.key,
    this.selectedText,
    this.userName,
    this.onClose,
  });

  @override
  State<AIAssistantWidget> createState() => _AIAssistantWidgetState();
}

class _AIAssistantWidgetState extends State<AIAssistantWidget> 
    with SingleTickerProviderStateMixin {
  final LLMService _llmService = LLMService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  AIAnswer? _currentAnswer;
  AISummary? _currentSummary;
  AIQuizItem? _currentQuiz;
  int? _selectedQuizAnswer;
  bool _showQuizResult = false;
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _hasShownGreeting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLLM();
    _showGreeting();
  }

  Future<void> _initializeLLM() async {
    // Get API key from configuration
    final apiKey = LLMConfig.getApiKey();
    
    try {
      await _llmService.initialize(apiKey);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize AI: $e';
        });
      }
    }
  }

  void _showGreeting() {
    if (!_hasShownGreeting) {
      final userName = widget.userName ?? 'Öğrenci';
      setState(() {
        _chatHistory.add({
          'type': 'ai',
          'message': 'Sana nasıl yardımcı olabilirim $userName?',
          'timestamp': DateTime.now(),
        });
        _hasShownGreeting = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAskQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    // Add user message to chat
    setState(() {
      _chatHistory.add({
        'type': 'user',
        'message': question,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
      _error = null;
    });

    // Clear input
    _questionController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final languageBloc = context.read<LanguageBloc>();
      final selectedContext = widget.selectedText ?? 'Genel soru';
      
      final answer = await _llmService.answerQuestion(
        question,
        selectedContext,
        language: languageBloc.currentLanguage,
      );

      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'ai',
            'message': answer.answer,
            'sourceReference': answer.sourceReference,
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });

        // Scroll to bottom after AI response
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        if (!answer.isRelevant) {
          _showErrorSnackBar('Bu soru eğitim konusuyla ilgili değil');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'error',
            'message': 'Üzgünüm, bir hata oluştu: ${e.toString()}',
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGenerateSummary() async {
    final selectedContext = widget.selectedText ?? '';
    if (selectedContext.isEmpty || selectedContext.length < 50) {
      _showErrorSnackBar('Lütfen daha uzun bir metin seçin (en az 50 karakter)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _currentSummary = null;
    });

    try {
      final languageBloc = context.read<LanguageBloc>();
      final summary = await _llmService.generateSummary(
        selectedContext,
        language: languageBloc.currentLanguage,
      );

      if (mounted) {
        setState(() {
          _currentSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGenerateQuiz(String topic, QuizDifficulty difficulty) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentQuiz = null;
      _selectedQuizAnswer = null;
      _showQuizResult = false;
    });

    try {
      final languageBloc = context.read<LanguageBloc>();
      final quiz = await _llmService.createQuizItem(
        topic,
        difficulty,
        language: languageBloc.currentLanguage,
      );

      if (mounted) {
        setState(() {
          _currentQuiz = quiz;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Yapay Zeka Asistanı',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Selected Text Preview
              if (widget.selectedText != null && widget.selectedText!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.text_snippet, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.selectedText!.length > 100
                              ? '${widget.selectedText!.substring(0, 100)}...'
                              : widget.selectedText!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.question_answer), text: 'Soru Sor'),
                  Tab(icon: Icon(Icons.summarize), text: 'Özet'),
                  Tab(icon: Icon(Icons.quiz), text: 'Test'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuestionTab(),
                    _buildSummaryTab(),
                    _buildQuizTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seçtiğiniz metin hakkında soru sorun',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: 'Sorunuzu buraya yazın...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.help_outline),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAskQuestion,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isLoading ? 'İşleniyor...' : 'Gönder'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (_currentAnswer != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildAnswerCard(_currentAnswer!),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(AIAnswer answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                'Yanıt:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(answer.answer, style: const TextStyle(fontSize: 15)),
          if (answer.sourceReference != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kaynak: ${answer.sourceReference}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seçtiğiniz metnin özetini oluşturun',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGenerateSummary,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isLoading ? 'Özet Oluşturuluyor...' : 'Özet Oluştur'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (_currentSummary != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildSummaryCard(_currentSummary!),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AISummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.purple[700]),
              const SizedBox(width: 8),
              const Text(
                'Anahtar Kavramlar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...summary.keyPoints.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.value, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          const Text(
            'Özet:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(summary.fullSummary, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konuyla ilgili test sorusu oluşturun',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuizButton('Biyoloji', QuizDifficulty.easy, Colors.green),
              _buildQuizButton('Fizik', QuizDifficulty.medium, Colors.blue),
              _buildQuizButton('Kimya', QuizDifficulty.medium, Colors.orange),
              _buildQuizButton('Matematik', QuizDifficulty.hard, Colors.red),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          if (_currentQuiz != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildQuizCard(_currentQuiz!),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizButton(String topic, QuizDifficulty difficulty, Color color) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _handleGenerateQuiz(topic, difficulty),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(topic),
    );
  }

  Widget _buildQuizCard(AIQuizItem quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quiz.question,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...quiz.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedQuizAnswer == index;
            final isCorrect = index == quiz.correctAnswerIndex;
            final showResult = _showQuizResult;

            Color? backgroundColor;
            Color? borderColor;
            
            if (showResult) {
              if (isCorrect) {
                backgroundColor = Colors.green.withValues(alpha: 0.2);
                borderColor = Colors.green;
              } else if (isSelected) {
                backgroundColor = Colors.red.withValues(alpha: 0.2);
                borderColor = Colors.red;
              }
            } else if (isSelected) {
              backgroundColor = Colors.blue.withValues(alpha: 0.2);
              borderColor = Colors.blue;
            }

            return GestureDetector(
              onTap: showResult ? null : () {
                setState(() {
                  _selectedQuizAnswer = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    if (showResult && isCorrect)
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (showResult && !isCorrect && isSelected)
                      const Icon(Icons.cancel, color: Colors.red),
                    if (!showResult && isSelected)
                      const Icon(Icons.radio_button_checked, color: Colors.blue),
                    if (!showResult && !isSelected)
                      const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(option)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (!_showQuizResult)
            ElevatedButton(
              onPressed: _selectedQuizAnswer == null ? null : () {
                setState(() {
                  _showQuizResult = true;
                });
              },
              child: const Text('Kontrol Et'),
            ),
          if (_showQuizResult)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Açıklama:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(quiz.explanation),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentQuiz = null;
                        _selectedQuizAnswer = null;
                        _showQuizResult = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeni Soru'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

