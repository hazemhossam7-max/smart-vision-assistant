class AiSafetyModerationResult {
  const AiSafetyModerationResult({
    required this.allowed,
    required this.message,
  });

  final bool allowed;
  final String message;
}

class AiSafetyModerationService {
  const AiSafetyModerationService();

  static const _blockedCommandPatterns = <String>[
    'make a weapon',
    'build a bomb',
    'bypass security',
    'steal',
    'harm yourself',
    'hurt someone',
  ];

  static const _safetySensitiveResponsePatterns = <String>[
    'guaranteed safe',
    'definitely safe to cross',
    'ignore traffic',
    'you can run across',
  ];

  AiSafetyModerationResult moderateUserCommand(String command) {
    final text = command.toLowerCase();
    final blocked = _blockedCommandPatterns.any(text.contains);
    if (blocked) {
      return const AiSafetyModerationResult(
        allowed: false,
        message: 'I cannot help with that request.',
      );
    }

    return const AiSafetyModerationResult(
      allowed: true,
      message: '',
    );
  }

  String moderateAssistantResponse(String response) {
    final lower = response.toLowerCase();
    final risky = _safetySensitiveResponsePatterns.any(lower.contains);
    if (!risky) {
      return response;
    }

    return '$response Please verify carefully and do not rely on this as a safety guarantee.';
  }
}
