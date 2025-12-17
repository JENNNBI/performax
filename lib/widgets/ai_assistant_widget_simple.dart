import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import '../services/llm_config.dart';
import '../services/quest_service.dart';
import '../blocs/bloc_exports.dart';

/// AI Study Assistant Widget - Simplified Chat Interface
/// 
/// This widget provides a simple Q&A chat interface.
/// Students can ask questions and receive personalized answers.
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

class _AIAssistantWidgetState extends State<AIAssistantWidget> {
  final LLMService _llmService = LLMService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _hasShownGreeting = false;

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'error',
            'message': 'AI servisi başlatılamadı. Lütfen API anahtarını kontrol edin.',
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
        });
        _hasShownGreeting = true;
      });
    }
  }

  @override
  void dispose() {
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

        _scrollToBottom();
      }
      // Event: AI responded (counts as interaction)
      QuestService.instance.onAiInteracted();
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'error',
            'message': 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.',
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
    
    final isUser = type == 'user';
    final isError = type == 'error';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
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
              ),
              child: Text(
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
      ),
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
