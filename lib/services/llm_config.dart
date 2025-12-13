// LLM Configuration Service
// 
// Manages API keys and configuration for the LLM service.
// In production, this should integrate with secure storage solutions.

/// LLM Configuration Service
/// 
/// Manages API keys and configuration for the LLM service.
/// In production, this should integrate with secure storage solutions.
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMConfig {
  static const String _defaultApiKey = '';
  
  /// Get the OpenAI API key
  /// 
  /// PRODUCTION DEPLOYMENT:
  /// This key is configured for OpenAI GPT-4 access.
  /// 
  /// For enhanced security in production:
  /// 1. Use flutter_dotenv or secure key storage
  /// 2. Implement backend proxy to hide key from client
  /// 3. Set up rate limiting and usage monitoring
  /// 4. Rotate keys periodically
  static String getApiKey() {
    return dotenv.env['OPENAI_API_KEY'] ?? _defaultApiKey;
  }
  
  /// Check if API key is configured
  static bool isConfigured() {
    final key = getApiKey();
    return key.isNotEmpty;
  }
  
  /// Get configuration status message
  static String getConfigStatusMessage(String language) {
    if (isConfigured()) {
      return language == 'tr'
          ? 'AI Asistan hazır'
          : 'AI Assistant ready';
    } else {
      return language == 'tr'
          ? 'AI Asistan yapılandırılmamış. API anahtarı gerekiyor.'
          : 'AI Assistant not configured. API key required.';
    }
  }
}
