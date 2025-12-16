import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import '../services/llm_config.dart';
import '../blocs/bloc_exports.dart';
import '../models/user_profile.dart';
import 'typewriter_text.dart';
import '../services/quest_service.dart';

/// AI Study Assistant Widget - Simplified Chat Interface
/// 
/// This widget provides a simple Q&A chat interface with personalization.
/// Students can ask questions and receive personalized answers based on their profile.
class AIAssistantWidget extends StatefulWidget {
  final String? selectedText;
  final String? userName;
  final UserProfile? userProfile;
  final VoidCallback? onClose;

  const AIAssistantWidget({
    super.key,
    this.selectedText,
    this.userName,
    this.userProfile,
    this.onClose,
  });

  @override
  State<AIAssistantWidget> createState() => _AIAssistantWidgetState();
}

class _AIAssistantWidgetState extends State<AIAssistantWidget> with TickerProviderStateMixin {
  final LLMService _llmService = LLMService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _hasShownGreeting = false;
  final List<AnimationController> _bubbleControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeLLM();
    _showGreeting();
  }

  Future<void> _initializeLLM() async {
    final apiKey = LLMConfig.getApiKey();
    
    try {
      await _llmService.initialize(apiKey);
      
      // Set user profile for personalized responses
      if (widget.userProfile != null) {
        _llmService.setUserProfile(widget.userProfile);
        debugPrint('✅ User profile set for AI: ${widget.userProfile!.displayName}');
      }
      
      debugPrint('✅ AI Assistant initialized successfully');
    } catch (e) {
      debugPrint('❌ AI Assistant initialization failed: $e');
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'error',
            'message': 'AI servisi başlatılamadı. Hata: ${e.toString()}\n\nLütfen API anahtarının doğru yapılandırıldığından emin olun.',
            'timestamp': DateTime.now(),
          });
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
          'controller': _createBubbleController(),
        });
        _hasShownGreeting = true;
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    for (var controller in _bubbleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _createBubbleController() {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bubbleControllers.add(controller);
    controller.forward();
    return controller;
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
        'controller': _createBubbleController(),
      });
      _isLoading = true;
    });
    // Event: user engaged with AI
    QuestService.instance.onAiInteracted();

    // Clear input
    _questionController.clear();

    // Scroll to bottom
    _scrollToBottom();

    try {
      final languageBloc = context.read<LanguageBloc>();
      final selectedContext = widget.selectedText ?? 'Genel öğrenci sorusu';
      
      debugPrint('🤖 Sending question to AI: $question');
      debugPrint('📄 Context: ${selectedContext.substring(0, selectedContext.length > 100 ? 100 : selectedContext.length)}');
      
      final answer = await _llmService.answerQuestion(
        question,
        selectedContext,
        language: languageBloc.currentLanguage,
      );

      debugPrint('✅ Received AI response: ${answer.answer.substring(0, answer.answer.length > 100 ? 100 : answer.answer.length)}...');

      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'ai',
            'message': answer.answer,
            'sourceReference': answer.sourceReference,
            'timestamp': DateTime.now(),
            'controller': _createBubbleController(),
            'useTypewriter': true,
          });
          _isLoading = false;
        });
        // Event: AI responded (counts as interaction)
        QuestService.instance.onAiInteracted();

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ AI Error: $e');
      final errorDetails = _llmService.getLastError() ?? e.toString();
      debugPrint('🔍 Detailed error: $errorDetails');
      
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'error',
            'message': 'Bir hata oluştu: ${e.toString()}\n\nLütfen API anahtarınızı kontrol edin veya internet bağlantınızı doğrulayın.',
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Asistan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatHistory.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                
                final message = _chatHistory[index];
                return _buildChatBubble(message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
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
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: 'Sorunuzu yazın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleAskQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _handleAskQuestion,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final type = message['type'] as String;
    final text = message['message'] as String;
    final sourceRef = message['sourceReference'] as String?;
    final controller = message['controller'] as AnimationController?;
    final useTypewriter = message['useTypewriter'] as bool? ?? false;
    
    final isUser = type == 'user';
    final isError = type == 'error';

    final scaleAnimation = controller != null
        ? Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          )
        : null;

    final slideAnimation = controller != null
        ? Tween<Offset>(begin: Offset(isUser ? 0.3 : -0.3, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOut),
          )
        : null;

    Widget bubble = Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                      ],
                    )
                  : null,
              color: isUser
                  ? null
                  : isError
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
              ),
              boxShadow: [
                if (isUser)
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: !isUser && useTypewriter
                ? TypewriterText(
                    text: text,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontSize: 15,
                    ),
                    duration: const Duration(milliseconds: 20),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontSize: 15,
                    ),
                  ),
          ),
          if (sourceRef != null && sourceRef.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                '📚 Kaynak: $sourceRef',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );

    if (scaleAnimation != null && slideAnimation != null) {
      bubble = SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: controller!,
            child: bubble,
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF667eea),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Düşünüyorum...'),
          ],
        ),
      ),
    );
  }
}
