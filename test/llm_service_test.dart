import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:performax/services/llm_service.dart';
import 'package:performax/services/llm_config.dart';
import 'package:performax/models/ai_response.dart';

/// LLM Service Integration Tests - Production Version
/// 
/// These tests verify the production-grade LLM service functionality.
/// NOTE: These tests require a valid OpenAI API key to run.
/// 
/// To run these tests:
/// 1. Set your API key in lib/services/llm_config.dart
/// 2. Run: flutter test test/llm_service_test.dart
/// 
/// WARNING: These tests make real API calls and may count against your quota.

void main() {
  group('Production LLM Service Tests', () {
    late LLMService llmService;

    setUp(() {
      llmService = LLMService();
    });

    test('Service initialization', () async {
      final apiKey = LLMConfig.getApiKey();
      
      // Skip test if API key is not configured
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(apiKey);
      expect(llmService.isInitialized, true);
    });

    test('Answer question - Basic biology', () async {
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(LLMConfig.getApiKey());

      const question = 'Hücre nedir?';
      const context = 'Genel öğrenci sorusu';

      final answer = await llmService.answerQuestion(
        question,
        context,
        language: 'tr',
      );

      expect(answer, isA<AIAnswer>());
      expect(answer.answer.isNotEmpty, true);
      expect(answer.answer.length, greaterThan(50)); // Should be detailed
      
      debugPrint('\n✅ Basic Question Test Results:');
      debugPrint('Question: $question');
      debugPrint('Answer: ${answer.answer}');
      debugPrint('Answer length: ${answer.answer.length} chars');
    });

    test('Answer question with context', () async {
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(LLMConfig.getApiKey());

      const context = '''
      Fotosentez, bitkilerin ışık enerjisini kimyasal enerjiye dönüştürdüğü bir süreçtir. 
      Bu süreç kloroplastlarda gerçekleşir ve klorofil pigmenti tarafından ışık enerjisi 
      yakalanır. Fotosentezin genel denklemi: 6CO2 + 6H2O + ışık → C6H12O6 + 6O2'dir.
      ''';

      const question = 'Fotosentez hangi organelde gerçekleşir?';

      final answer = await llmService.answerQuestion(
        question,
        context,
        language: 'tr',
      );

      expect(answer, isA<AIAnswer>());
      expect(answer.isRelevant, true);
      expect(answer.answer.isNotEmpty, true);
      
      debugPrint('\n✅ Q&A Test Results:');
      debugPrint('Question: $question');
      debugPrint('Answer: ${answer.answer}');
      if (answer.sourceReference != null) {
        debugPrint('Source Reference: ${answer.sourceReference}');
      }
    });

    test('Answer question - Multi-turn conversation', () async {
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(LLMConfig.getApiKey());

      // First question
      const question1 = 'Fotosentez nedir?';
      final answer1 = await llmService.answerQuestion(
        question1,
        'Genel öğrenci sorusu',
        language: 'tr',
      );

      expect(answer1.answer.isNotEmpty, true);
      debugPrint('\n✅ Multi-turn Conversation Test:');
      debugPrint('Q1: $question1');
      debugPrint('A1: ${answer1.answer.substring(0, 100)}...');

      // Follow-up question (tests conversational context)
      const question2 = 'Hangi organelde gerçekleşir?';
      final answer2 = await llmService.answerQuestion(
        question2,
        'Genel öğrenci sorusu',
        language: 'tr',
      );

      expect(answer2.answer.isNotEmpty, true);
      debugPrint('Q2: $question2');
      debugPrint('A2: ${answer2.answer.substring(0, 100)}...');
      debugPrint('Conversation history: ${llmService.historyLength} messages');
    });

    test('Handle empty question gracefully', () async {
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(LLMConfig.getApiKey());

      expect(
        () => llmService.answerQuestion('', 'context'),
        throwsException,
      );
      
      debugPrint('\n✅ Empty question handling verified');
    });

    test('Retry mechanism test', () async {
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(LLMConfig.getApiKey());

      // Test with max retries parameter
      final answer = await llmService.answerQuestion(
        'Test sorusu',
        'Test bağlamı',
        language: 'tr',
        maxRetries: 3,
      );

      expect(answer, isA<AIAnswer>());
      expect(answer.answer.isNotEmpty, true);
      
      debugPrint('\n✅ Retry mechanism test passed');
      debugPrint('Answer received: ${answer.answer.substring(0, 50)}...');
    });

    test('Conversation history management', () async {
      if (!LLMConfig.isConfigured()) {
        debugPrint('⚠️  Skipping test: API key not configured');
        return;
      }

      await llmService.initialize(LLMConfig.getApiKey());

      // Clear any existing history
      llmService.clearHistory();
      expect(llmService.historyLength, 0);

      // Add some conversation
      await llmService.answerQuestion('Soru 1', 'Bağlam 1', language: 'tr');
      expect(llmService.historyLength, greaterThan(0));

      await llmService.answerQuestion('Soru 2', 'Bağlam 2', language: 'tr');
      expect(llmService.historyLength, greaterThan(0));

      // Clear history
      llmService.clearHistory();
      expect(llmService.historyLength, 0);

      debugPrint('\n✅ Conversation history management test passed');
      debugPrint('History cleared successfully');
    });

    test('Configuration check', () {
      final isConfigured = LLMConfig.isConfigured();
      final statusMessage = LLMConfig.getConfigStatusMessage('tr');
      
      debugPrint('\n📋 Configuration Status:');
      debugPrint('  Configured: $isConfigured');
      debugPrint('  Status: $statusMessage');
      
      if (!isConfigured) {
        debugPrint('\n⚠️  To enable LLM features:');
        debugPrint('  1. Get API key from: https://makersuite.google.com/app/apikey');
        debugPrint('  2. Update lib/services/llm_config.dart');
        debugPrint('  3. Run tests again');
      }
    });
  });
}

