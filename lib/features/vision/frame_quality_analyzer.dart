import 'dart:math';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import '../../core/constants/frame_scoring_weights.dart';
import '../../core/constants/quality_thresholds.dart';
import '../../core/utils/score_utils.dart';
import '../voice/intent_classifier.dart';
import 'frame_metadata.dart';
import 'object_detector_stub.dart';

class FrameQualityAnalyzer {
  FrameQualityAnalyzer({
    ObjectDetectorStub objectDetector = const ObjectDetectorStub(),
  }) : _objectDetector = objectDetector;

  final ObjectDetectorStub _objectDetector;

  Future<FrameMetadata> analyzeFrame({
    required XFile frameFile,
    required int index,
    required VisionIntent intent,
    FrameMetadata? previousFrame,
  }) async {
    final bytes = await frameFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw FormatException('Could not decode frame ${frameFile.path}.');
    }

    // Blur score: Laplacian variance is higher when edges are sharper.
    final blurScore = _laplacianVariance(image);
    final clarityScore = clamp01(blurScore / 1200.0);

    // Brightness score: frames close to balanced mid-light are preferred.
    final brightnessAverage = _averageBrightness(image);
    final brightnessScore =
        clamp01(1 - ((brightnessAverage - 128).abs() / 128));

    // Average hash is a compact visual fingerprint used for duplicate and motion checks.
    final averageHash = _averageHash(image);
    final uniquenessScore =
        _compareHashToPrevious(averageHash, previousFrame?.averageHash);
    final motionScore = _motionScore(averageHash, previousFrame?.averageHash);

    // Object score is currently heuristic, but the API is ready for ML object detection.
    final objectScore = _objectDetector.estimateObjectImportance(
      image: image,
      intent: intent,
    );

    // Required weighted importance formula.
    final finalScore = FrameScoringWeights.clarity * clarityScore +
        FrameScoringWeights.brightness * brightnessScore +
        FrameScoringWeights.uniqueness * uniquenessScore +
        FrameScoringWeights.objectImportance * objectScore +
        FrameScoringWeights.motion * motionScore;

    final rejectionReasons = _rejectionReasons(
      clarityScore: clarityScore,
      brightnessAverage: brightnessAverage,
      uniquenessScore: uniquenessScore,
      previousFrame: previousFrame,
    );

    return FrameMetadata(
      frameId: 'frame_${DateTime.now().microsecondsSinceEpoch}_$index',
      filePath: frameFile.path,
      index: index,
      capturedAt: DateTime.now(),
      width: image.width,
      height: image.height,
      intent: intent,
      blurScore: blurScore,
      clarityScore: clarityScore,
      brightnessAverage: brightnessAverage,
      brightnessScore: brightnessScore,
      uniquenessScore: uniquenessScore,
      objectScore: objectScore,
      motionScore: motionScore,
      finalScore: clamp01(finalScore),
      averageHash: averageHash,
      rejectionReasons: rejectionReasons,
    );
  }

  double _laplacianVariance(img.Image image) {
    final step = (image.width > 1000 || image.height > 1000) ? 6 : 3;
    final values = <double>[];

    for (var y = step; y < image.height - step; y += step) {
      for (var x = step; x < image.width - step; x += step) {
        final center = _luminance(image.getPixel(x, y));
        final left = _luminance(image.getPixel(x - step, y));
        final right = _luminance(image.getPixel(x + step, y));
        final up = _luminance(image.getPixel(x, y - step));
        final down = _luminance(image.getPixel(x, y + step));
        values.add((4 * center) - left - right - up - down);
      }
    }

    if (values.isEmpty) {
      return 0;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
            .map((value) => pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return variance;
  }

  double _averageBrightness(img.Image image) {
    final step = (image.width > 1000 || image.height > 1000) ? 8 : 4;
    var sum = 0.0;
    var count = 0;

    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        sum += _luminance(image.getPixel(x, y));
        count++;
      }
    }

    if (count == 0) {
      return 0;
    }

    return sum / count;
  }

  String _averageHash(img.Image image) {
    final resized = img.copyResize(image, width: 8, height: 8);
    final brightnessValues = <double>[];

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        brightnessValues.add(_luminance(resized.getPixel(x, y)));
      }
    }

    final average =
        brightnessValues.reduce((a, b) => a + b) / brightnessValues.length;
    return brightnessValues.map((value) => value >= average ? '1' : '0').join();
  }

  double _compareHashToPrevious(String hash, String? previousHash) {
    if (previousHash == null || previousHash.length != hash.length) {
      return 1;
    }

    final distance = _hammingDistance(hash, previousHash) / hash.length;
    return clamp01(distance / 0.35);
  }

  double _motionScore(String hash, String? previousHash) {
    if (previousHash == null || previousHash.length != hash.length) {
      return 0.5;
    }

    final distance = _hammingDistance(hash, previousHash) / hash.length;
    return clamp01(distance / 0.45);
  }

  int _hammingDistance(String a, String b) {
    var distance = 0;
    for (var index = 0; index < min(a.length, b.length); index++) {
      if (a[index] != b[index]) {
        distance++;
      }
    }
    return distance + (a.length - b.length).abs();
  }

  List<String> _rejectionReasons({
    required double clarityScore,
    required double brightnessAverage,
    required double uniquenessScore,
    required FrameMetadata? previousFrame,
  }) {
    final reasons = <String>[];

    if (clarityScore < QualityThresholds.minClarityScore) {
      reasons.add('blurry');
    }
    if (brightnessAverage < QualityThresholds.minBrightnessAverage) {
      reasons.add('too_dark');
    }
    if (brightnessAverage > QualityThresholds.maxBrightnessAverage) {
      reasons.add('too_bright');
    }
    if (previousFrame != null &&
        uniquenessScore < QualityThresholds.minUniquenessScore) {
      reasons.add('duplicate');
    }

    return reasons;
  }

  double _luminance(img.Pixel pixel) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }
}
