import 'package:flutter_test/flutter_test.dart';
import 'package:smart_vision_assistant/features/voice/intent_classifier.dart';

void main() {
  group('IntentClassifier', () {
    test('detects Egyptian currency commands', () {
      final classifier = IntentClassifier();

      expect(
        classifier.classify('How much money is in front of me?'),
        VisionIntent.currencyRecognition,
      );
      expect(
        classifier.classify('Count this Egyptian pound cash'),
        VisionIntent.currencyRecognition,
      );
    });
  });
}
