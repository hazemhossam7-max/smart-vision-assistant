import 'package:flutter_test/flutter_test.dart';
import 'package:smart_vision_assistant/features/face/face_database_service.dart';
import 'package:smart_vision_assistant/features/face/face_matcher.dart';

void main() {
  group('FaceMatcher', () {
    test('returns unknown when the database is empty', () {
      const matcher = FaceMatcher();

      final result = matcher.findBestMatch(
        embedding: const [1, 0, 0],
        registeredFaces: const [],
      );

      expect(result.isMatch, isFalse);
      expect(result.name, 'unknown person');
    });

    test('matches the closest embedding above threshold', () {
      const matcher = FaceMatcher(matchThreshold: 0.8);

      final result = matcher.findBestMatch(
        embedding: const [1, 0, 0],
        registeredFaces: const [
          RegisteredFace(
            name: 'Adham',
            embeddings: [
              [0.98, 0.02, 0],
            ],
          ),
          RegisteredFace(
            name: 'Mariam',
            embeddings: [
              [0, 1, 0],
            ],
          ),
        ],
      );

      expect(result.isMatch, isTrue);
      expect(result.name, 'Adham');
    });

    test('returns unknown when similarity is below threshold', () {
      const matcher = FaceMatcher(matchThreshold: 0.95);

      final result = matcher.findBestMatch(
        embedding: const [1, 0, 0],
        registeredFaces: const [
          RegisteredFace(
            name: 'Adham',
            embeddings: [
              [0, 1, 0],
            ],
          ),
        ],
      );

      expect(result.isMatch, isFalse);
      expect(result.name, 'unknown person');
    });
  });
}
