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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        // Solid Blue Gradient Background (as per reference image)
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1976D2), // Bright Blue (top)
            Color(0xFF1565C0), // Medium Blue
            Color(0xFF0D47A1), // Deep Blue (bottom)
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header - Clean & Simple (as per reference)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                // Alfred Full-Body Standing Image
                Image.asset(
                  'assets/images/AI.png',
                  height: 120, // Large and prominent (as per reference)
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF00e5ff),
                            Color(0xFF00b8d4),
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // "Alfred" Text
                const Text(
                  'Alfred',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Close Button (Clean white X)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2), // Subtle background
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatHistory.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                
                final message = _chatHistory[index];
                return _buildChatBubble(message, isDark);
              },
            ),
          ),

          // Input Area - Capsule Shape (as per reference)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Capsule-Shaped Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.6), // Translucent dark blue
                        borderRadius: BorderRadius.circular(30), // Capsule shape
                        border: Border.all(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.4), // Subtle blue glow border
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _questionController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Sorunuzu yazın...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleAskQuestion(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bright Cyan Circular Send Button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E5FF), // Bright Neon Cyan
                          Color(0xFF00B8D4), // Deep Cyan
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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

  Widget _buildChatBubble(Map<String, dynamic> message, bool isDark) {
    final type = message['type'] as String;
    final text = message['message'] as String;
    final sourceRef = message['sourceReference'] as String?;
    final controller = message['controller'] as AnimationController?;
    final useTypewriter = message['useTypewriter'] as bool? ?? false;
    
    final isUser = type == 'user';

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
      margin: const EdgeInsets.only(bottom: 16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              // Simple solid colors (as per reference image)
              color: isUser
                  ? const Color(0xFF1E88E5).withValues(alpha: 0.9) // Bright blue for user
                  : const Color(0xFF2C3E50).withValues(alpha: 0.85), // Dark blue-grey for AI (as per reference)
              borderRadius: BorderRadius.circular(20),
            ),
            child: !isUser && useTypewriter
                ? TypewriterText(
                    text: text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    duration: const Duration(milliseconds: 20),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
          ),
          if (sourceRef != null && sourceRef.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
              child: Text(
                '📚 Kaynak: $sourceRef',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50).withValues(alpha: 0.85), // Match AI bubble color
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00E5FF), // Bright cyan
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Düşünüyorum...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
