import '../constants/app_config.dart';

class LoggerService {
  const LoggerService();

  static final _redactionPatterns = <RegExp>[
    RegExp(r'sk-or-v1-[A-Za-z0-9_-]+'),
    RegExp(r'(OPENROUTER_API_KEY|OPENAI_API_KEY|GEMINI_API_KEY|BACKEND_CLIENT_TOKEN)\s*[:=]\s*[^\s,}]+', caseSensitive: false),
    RegExp(r'data:image\/[^;]+;base64,[A-Za-z0-9+/=]+'),
    RegExp(r'"base64Image"\s*:\s*"[A-Za-z0-9+/=]+"'),
  ];

  void info(String message) {
    if (AppConfig.productionBuild) {
      return;
    }

    // Kept as a single injectable place so demo logging can later move to Crashlytics/Sentry.
    // ignore: avoid_print
    print('[SmartVision] ${_redact(message)}');
  }

  String _redact(String message) {
    var redacted = message;
    for (final pattern in _redactionPatterns) {
      redacted = redacted.replaceAllMapped(pattern, (match) {
        final text = match.group(0) ?? '';
        final keyMatch = RegExp(
          r'^(OPENROUTER_API_KEY|OPENAI_API_KEY|GEMINI_API_KEY|BACKEND_CLIENT_TOKEN)',
          caseSensitive: false,
        ).firstMatch(text);
        if (keyMatch != null) {
          return '${keyMatch.group(1)}=[REDACTED]';
        }
        return '[REDACTED]';
      });
    }
    return redacted;
  }
}
