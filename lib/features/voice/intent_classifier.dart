enum VisionIntent {
  sceneDescription,
  obstacleDetection,
  textReading,
  objectSearch,
  navigationHelp,
  currencyRecognition,
  emergencyHelp,
  faceRegistration,
  faceRecognition,
}

extension VisionIntentLabel on VisionIntent {
  String get label {
    switch (this) {
      case VisionIntent.sceneDescription:
        return 'scene_description';
      case VisionIntent.obstacleDetection:
        return 'obstacle_detection';
      case VisionIntent.textReading:
        return 'text_reading';
      case VisionIntent.objectSearch:
        return 'object_search';
      case VisionIntent.navigationHelp:
        return 'navigation_help';
      case VisionIntent.currencyRecognition:
        return 'currency_recognition';
      case VisionIntent.emergencyHelp:
        return 'emergency_help';
      case VisionIntent.faceRegistration:
        return 'face_registration';
      case VisionIntent.faceRecognition:
        return 'face_recognition';
    }
  }
}

class IntentClassifier {
  VisionIntent classify(String command) {
    final text = command.toLowerCase();

    if (_containsAny(text, const [
      'help me',
      'emergency',
      'sos',
      'call my guardian',
      'send my location',
      'i need help',
    ])) {
      return VisionIntent.emergencyHelp;
    }

    if (extractFaceRegistrationName(command) != null ||
        _containsAny(text, const [
          'register this face',
          'save this face',
          'remember this person',
          'remember this face',
          'save this person',
        ])) {
      return VisionIntent.faceRegistration;
    }

    if (_containsAny(text, const [
      'who is in front of me',
      'who is standing in front of me',
      'who is here',
      'who is beside me',
      'who is next to me',
      'who is shouting in front of me',
      'describe the person in front of me',
      'describe this person',
      'identify this person',
      'recognize this person',
    ])) {
      return VisionIntent.faceRecognition;
    }

    if (_containsAny(text, const [
      'currency',
      'money',
      'cash',
      'banknote',
      'bank note',
      'bill',
      'note',
      'egyptian pound',
      'egp',
      'pound',
      'count money',
      'how much money',
      'how much cash',
    ])) {
      return VisionIntent.currencyRecognition;
    }

    if (_containsAny(text, const [
      'read',
      'text',
      'sign',
      'document',
      'letter',
      'menu',
      'book',
      'ocr',
    ])) {
      return VisionIntent.textReading;
    }

    if (_containsAny(text, const [
      'find',
      'where is',
      'search',
      'look for',
      'locate',
      'my keys',
      'bottle',
      'phone',
    ])) {
      return VisionIntent.objectSearch;
    }

    if (_containsAny(text, const [
      'obstacle',
      'avoid',
      'in front',
      'danger',
      'block',
      'stairs',
      'hole',
    ])) {
      return VisionIntent.obstacleDetection;
    }

    if (_containsAny(text, const [
      'navigate',
      'go to',
      'direction',
      'left',
      'right',
      'cross',
      'path',
      'way',
    ])) {
      return VisionIntent.navigationHelp;
    }

    return VisionIntent.sceneDescription;
  }

  bool wantsEmergencyLocation(String command) {
    final text = command.toLowerCase();
    return _containsAny(
        text, const ['send my location', 'share my location', 'with location']);
  }

  String? extractFaceRegistrationName(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final patterns = [
      RegExp(
        r'^(?:please\s+)?(?:register|save|remember)\s+(?:this\s+)?(?:face|person)\s+as\s+(.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:please\s+)?this\s+is\s+(.+)$',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(trimmed);
      final name = match?.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        return _cleanName(name);
      }
    }

    return null;
  }

  String _cleanName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
