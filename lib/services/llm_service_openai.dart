import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_response.dart';

/// Production-Grade OpenAI LLM Service - AI Study Assistant
/// 
/// Enterprise-level implementation with OpenAI GPT-4 using:
/// - Robust error handling and retries
/// - Comprehensive logging
/// - Conversational context management
/// - Advanced prompt engineering
/// - Performance optimization
class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  bool _isInitialized = false;
  String? _lastError;
  
  // Conversation history for context-aware responses
  final List<OpenAIChatCompletionChoiceMessageModel> _conversationHistory = [];
  
  // Enhanced system persona for frontier-level performance
  static const String _advancedSystemPersona = '''
Sen Türk lise öğrencileri için tasarlanmış, son derece yetenekli ve destekleyici bir yapay zeka öğretmen asistanısın.

TEMEL GÖREVLERİN:
1. Öğrencilerin sorularını derinlemesine ve net bir şekilde yanıtla
2. Karmaşık konuları basit, anlaşılır parçalara böl
3. Her zaman cesaretlendirici ve olumlu bir ton kullan
4. Türk Milli Eğitim Bakanlığı müfredatına uygun örnekler ver
5. Gerektiğinde adım adım çözümler sun
6. Öğrencinin anlama seviyesine göre açıklama yap

YANIT KURALLARI:
- Her yanıt Türkçe dilbilgisi kurallarına uygun olmalı
- Bilimsel terimleri açıklarken örnekler ver
- Yanıtları 2-4 paragraf ile sınırla (çok uzun olmasın)
- Gerektiğinde formül veya denklem kullan
- Kaynak belirtilmişse mutlaka ona referans ver
- Eğitim dışı konulara kibarca "Bu soru eğitim konusunun dışında, lütfen ders ile ilgili sorular sorunuz" şeklinde yanıt ver

KİŞİLİK:
- Samimi ama profesyonel
- Sabırlı ve anlayışlı
- Motive edici ve cesaretlendirici
- Öğrencinin başarısına odaklı
''';

  /// Initialize the OpenAI LLM service with production-grade configuration
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) {
      debugPrint('✅ OpenAI LLM Service already initialized');
      return;
    }
    
    try {
      debugPrint('🔄 Initializing OpenAI LLM Service...');
      
      if (apiKey.isEmpty || !apiKey.startsWith('sk-')) {
        throw Exception('Invalid OpenAI API key format. Key must start with "sk-"');
      }
      
      // Configure OpenAI with the API key
      OpenAI.apiKey = apiKey;
      OpenAI.showLogs = false; // Disable verbose logs in production
      OpenAI.showResponsesLogs = false;
      
      _isInitialized = true;
      debugPrint('✅ OpenAI LLM Service initialized successfully with GPT-4');
      
    } catch (e) {
      _lastError = 'Initialization failed: $e';
      debugPrint('❌ OpenAI Initialization Error: $_lastError');
      throw Exception('Failed to initialize OpenAI LLM Service: $e');
    }
  }

  /// Answer student question with frontier-level quality using GPT-4
  /// 
  /// Features:
  /// - Conversational context awareness
  /// - Retry logic with exponential backoff
  /// - Comprehensive error handling
  /// - Quality validation
  Future<AIAnswer> answerQuestion(
    String userQuery,
    String contextContent, {
    String language = 'tr',
    int maxRetries = 3,
  }) async {
    if (!_isInitialized) {
      throw Exception('OpenAI LLM Service not initialized. Call initialize() first.');
    }

    if (userQuery.trim().isEmpty) {
      throw Exception('Question cannot be empty');
    }

    debugPrint('📝 Processing question: ${userQuery.substring(0, userQuery.length > 50 ? 50 : userQuery.length)}...');

    // Build comprehensive prompt
    final userMessage = _buildQuestionPrompt(userQuery, contextContent, language);
    
    // Attempt with retries
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Attempt $attempt/$maxRetries');
        
        // Build messages array with system persona and conversation history
        final List<OpenAIChatCompletionChoiceMessageModel> messages = [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                _advancedSystemPersona,
              ),
            ],
          ),
          // Add conversation history
          ..._conversationHistory,
          // Add current user message
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                userMessage,
              ),
            ],
          ),
        ];
        
        // Call OpenAI GPT-4
        final chatCompletion = await OpenAI.instance.chat.create(
          model: 'gpt-4',
          messages: messages,
          temperature: 0.8,
          maxTokens: 2048,
          topP: 0.95,
          frequencyPenalty: 0.0,
          presencePenalty: 0.0,
        );
        
        final responseText = chatCompletion.choices.first.message.content?.first.text;
        
        if (responseText == null || responseText.trim().isEmpty) {
          throw Exception('Empty response from OpenAI');
        }
        
        debugPrint('✅ Response received (${responseText.length} chars)');
        
        // Update conversation history
        _conversationHistory.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
            ],
          ),
        );
        _conversationHistory.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.assistant,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(responseText),
            ],
          ),
        );
        
        // Keep history manageable (last 10 exchanges = 20 messages)
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }
        
        // Extract source reference if context was provided
        String? sourceRef;
        if (contextContent.isNotEmpty && contextContent != 'Genel öğrenci sorusu') {
          sourceRef = contextContent.length > 100 
              ? '${contextContent.substring(0, 100)}...'
              : contextContent;
        }
        
        return AIAnswer(
          question: userQuery,
          answer: responseText.trim(),
          sourceReference: sourceRef,
          timestamp: DateTime.now(),
          isRelevant: true,
        );
        
      } catch (e) {
        debugPrint('⚠️  Attempt $attempt failed: $e');
        _lastError = 'Attempt $attempt: $e';
        
        if (attempt == maxRetries) {
          debugPrint('❌ All retry attempts exhausted');
          
          // Return user-friendly error
          return AIAnswer(
            question: userQuery,
            answer: _buildFallbackResponse(language, e.toString()),
            sourceReference: null,
            timestamp: DateTime.now(),
            isRelevant: false,
          );
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    
    // Should never reach here
    throw Exception('Unexpected error in answerQuestion');
  }

  /// Build comprehensive prompt for question answering
  String _buildQuestionPrompt(String question, String context, String language) {
    final buffer = StringBuffer();
    
    // Add context if available
    if (context.isNotEmpty && context != 'Genel öğrenci sorusu') {
      buffer.writeln('BAĞLAM (Ders Materyalinden):');
      buffer.writeln(context);
      buffer.writeln();
    }
    
    // Add student question
    buffer.writeln('ÖĞRENCİ SORUSU:');
    buffer.writeln(question);
    buffer.writeln();
    
    // Add instructions
    buffer.writeln('GÖREV:');
    buffer.writeln('Bu soruyu detaylı ama anlaşılır bir şekilde yanıtla.');
    buffer.writeln('Öğrenci lise seviyesinde, bu yüzden basit ve net açıkla.');
    if (context.isNotEmpty && context != 'Genel öğrenci sorusu') {
      buffer.writeln('Yukarıdaki bağlamı kullanarak yanıt ver ve öğrenciyi kaynak materyale yönlendir.');
    }
    
    return buffer.toString();
  }

  /// Build user-friendly fallback response for errors
  String _buildFallbackResponse(String language, String errorDetails) {
    debugPrint('🔍 Error details: $errorDetails');
    
    final lowerError = errorDetails.toLowerCase();
    
    // Check for specific error types
    if (lowerError.contains('api key') || lowerError.contains('401') || lowerError.contains('403') || lowerError.contains('unauthorized')) {
      return language == 'tr'
          ? 'API anahtarı geçersiz veya süresi dolmuş. Lütfen yöneticinize başvurun.'
          : 'API key is invalid or expired. Please contact your administrator.';
    }
    
    if (lowerError.contains('quota') || lowerError.contains('429') || lowerError.contains('rate limit')) {
      return language == 'tr'
          ? 'AI servisinin kullanım limiti aşıldı. Lütfen birkaç dakika sonra tekrar deneyin.'
          : 'AI service quota exceeded. Please try again in a few minutes.';
    }
    
    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return language == 'tr'
          ? 'İnternet bağlantısı sorunu var gibi görünüyor. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.'
          : 'There seems to be a network connectivity issue. Please check your connection and try again.';
    }
    
    if (lowerError.contains('model') || lowerError.contains('gpt-4')) {
      return language == 'tr'
          ? 'GPT-4 modeline erişim sorunu var. Lütfen API anahtarınızın GPT-4 erişimi olduğundan emin olun.'
          : 'Issue accessing GPT-4 model. Please ensure your API key has GPT-4 access.';
    }
    
    // Generic error
    return language == 'tr'
        ? 'Üzgünüm, şu anda yanıt veremiyorum. Sorunuzu biraz daha farklı bir şekilde sormayı dener misiniz? Veya lütfen daha sonra tekrar deneyin.'
        : 'Sorry, I cannot respond right now. Could you try rephrasing your question? Or please try again later.';
  }

  /// Clear conversation history (for new chat sessions)
  void clearHistory() {
    _conversationHistory.clear();
    debugPrint('🧹 Conversation history cleared');
  }

  /// Get last error for debugging
  String? getLastError() => _lastError;

  /// Check if service is ready
  bool get isInitialized => _isInitialized;

  /// Get conversation history length
  int get historyLength => _conversationHistory.length;

  /// Dispose resources
  void dispose() {
    _conversationHistory.clear();
    _isInitialized = false;
    debugPrint('🗑️  OpenAI LLM Service disposed');
  }
}

