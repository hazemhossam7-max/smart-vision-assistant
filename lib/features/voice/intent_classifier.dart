enum VisionIntent {
  sceneDescription,
  obstacleDetection,
  textReading,
  objectSearch,
  navigationHelp,
  currencyRecognition,
  emergencyHelp,
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
    return _containsAny(text, const ['send my location', 'share my location', 'with location']);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
