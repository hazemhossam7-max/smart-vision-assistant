enum AiProvider {
  gemini,
  openai,
  openrouter,
  backend,
}

class AppConfig {
  const AppConfig._();

  static const captureDurationMs = int.fromEnvironment(
    'CAPTURE_DURATION_MS',
    defaultValue: 1000,
  );
  static const captureFps = int.fromEnvironment(
    'CAPTURE_FPS',
    defaultValue: 6,
  );
  static const topKeyframes = int.fromEnvironment(
    'TOP_KEYFRAMES',
    defaultValue: 3,
  );

  static const _providerName = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'gemini',
  );
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'google/gemini-2.5-flash',
  );
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static AiProvider get aiProvider {
    switch (_providerName.toLowerCase()) {
      case 'backend':
        return AiProvider.backend;
      case 'openrouter':
        return AiProvider.openrouter;
      case 'openai':
        return AiProvider.openai;
      case 'gemini':
      default:
        return AiProvider.gemini;
    }
  }
}
