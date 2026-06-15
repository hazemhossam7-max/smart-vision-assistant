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

    test('detects face registration commands and extracts names', () {
      final classifier = IntentClassifier();

      expect(
        classifier.classify('Register this face as Adham'),
        VisionIntent.faceRegistration,
      );
      expect(
        classifier.classify('Remember this person'),
        VisionIntent.faceRegistration,
      );
      expect(
        classifier.classify('Please register the person as Adham.'),
        VisionIntent.faceRegistration,
      );
      expect(
        classifier.classify('Save this man as Adham'),
        VisionIntent.faceRegistration,
      );
      expect(
        classifier.extractFaceRegistrationName('This is Adham'),
        'Adham',
      );
      expect(
        classifier.extractFaceRegistrationName('This person is Adham'),
        'Adham',
      );
    });

    test('detects face recognition commands before obstacle commands', () {
      final classifier = IntentClassifier();

      expect(
        classifier.classify('Who is in front of me?'),
        VisionIntent.faceRecognition,
      );
      expect(
        classifier.classify('Who is infront of me?'),
        VisionIntent.faceRecognition,
      );
      expect(
        classifier.classify('Who is in-front of me?'),
        VisionIntent.faceRecognition,
      );
      expect(
        classifier.classify('Who is shouting in front of me?'),
        VisionIntent.faceRecognition,
      );
      expect(
        classifier.classify('Who is near me?'),
        VisionIntent.faceRecognition,
      );
      expect(
        classifier.classify('Who is this?'),
        VisionIntent.faceRecognition,
      );
      expect(
        classifier.classify('Describe the person in front of me'),
        VisionIntent.faceRecognition,
      );
    });
  });
}
