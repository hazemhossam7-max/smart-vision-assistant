import '../../core/constants/app_config.dart';
import 'ai_service.dart';
import 'gemini_service.dart';
import 'openai_service.dart';
import 'openrouter_service.dart';

class AiServiceFactory {
  const AiServiceFactory._();

  static AiService create() {
    switch (AppConfig.aiProvider) {
      case AiProvider.openrouter:
        return const OpenRouterService();
      case AiProvider.openai:
        return const OpenAiService();
      case AiProvider.gemini:
        return const GeminiService();
    }
  }
}
