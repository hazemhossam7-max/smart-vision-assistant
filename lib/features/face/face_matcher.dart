import 'dart:math';

import 'face_database_service.dart';

class FaceMatchResult {
  const FaceMatchResult({
    required this.name,
    required this.score,
    required this.isMatch,
  });

  final String name;
  final double score;
  final bool isMatch;

  static const unknown = FaceMatchResult(
    name: 'unknown person',
    score: 0,
    isMatch: false,
  );
}

class FaceMatcher {
  const FaceMatcher({
    this.matchThreshold = 0.72,
  });

  final double matchThreshold;

  FaceMatchResult findBestMatch({
    required List<double> embedding,
    required List<RegisteredFace> registeredFaces,
  }) {
    if (embedding.isEmpty || registeredFaces.isEmpty) {
      return FaceMatchResult.unknown;
    }

    var bestName = 'unknown person';
    var bestScore = -1.0;

    for (final face in registeredFaces) {
      for (final registeredEmbedding in face.embeddings) {
        final score = cosineSimilarity(embedding, registeredEmbedding);
        if (score > bestScore) {
          bestScore = score;
          bestName = face.name;
        }
      }
    }

    if (bestScore >= matchThreshold) {
      return FaceMatchResult(
        name: bestName,
        score: bestScore,
        isMatch: true,
      );
    }

    return FaceMatchResult(
      name: 'unknown person',
      score: max(0, bestScore),
      isMatch: false,
    );
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) {
      return 0;
    }

    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var index = 0; index < a.length; index++) {
      dot += a[index] * b[index];
      normA += a[index] * a[index];
      normB += b[index] * b[index];
    }

    if (normA == 0 || normB == 0) {
      return 0;
    }

    return dot / (sqrt(normA) * sqrt(normB));
  }
}
