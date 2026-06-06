import 'package:image/image.dart' as img;

import '../voice/intent_classifier.dart';
import '../../core/utils/score_utils.dart';

class ObjectDetectorStub {
  const ObjectDetectorStub();

  double estimateObjectImportance({
    required img.Image image,
    required VisionIntent intent,
  }) {
    final centerContrast = _centerContrastScore(image);
    final edgeDensity = _edgeDensityScore(image);

    switch (intent) {
      case VisionIntent.objectSearch:
        return clamp01(0.45 + centerContrast * 0.35 + edgeDensity * 0.20);
      case VisionIntent.obstacleDetection:
      case VisionIntent.navigationHelp:
        return clamp01(0.35 + centerContrast * 0.25 + edgeDensity * 0.40);
      case VisionIntent.textReading:
        return clamp01(0.25 + edgeDensity * 0.55 + centerContrast * 0.20);
      case VisionIntent.currencyRecognition:
        return clamp01(0.40 + centerContrast * 0.35 + edgeDensity * 0.25);
      case VisionIntent.sceneDescription:
        return clamp01(0.30 + centerContrast * 0.35 + edgeDensity * 0.35);
    }
  }

  double _centerContrastScore(img.Image image) {
    final startX = (image.width * 0.30).round();
    final endX = (image.width * 0.70).round();
    final startY = (image.height * 0.30).round();
    final endY = (image.height * 0.70).round();

    var centerSum = 0.0;
    var centerCount = 0;
    var outsideSum = 0.0;
    var outsideCount = 0;
    final step = _samplingStep(image);

    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final luminance = _luminance(image.getPixel(x, y));
        final isCenter = x >= startX && x <= endX && y >= startY && y <= endY;
        if (isCenter) {
          centerSum += luminance;
          centerCount++;
        } else {
          outsideSum += luminance;
          outsideCount++;
        }
      }
    }

    if (centerCount == 0 || outsideCount == 0) {
      return 0.5;
    }

    final centerAvg = centerSum / centerCount;
    final outsideAvg = outsideSum / outsideCount;
    return clamp01((centerAvg - outsideAvg).abs() / 128.0);
  }

  double _edgeDensityScore(img.Image image) {
    final step = _samplingStep(image);
    var edges = 0;
    var samples = 0;

    for (var y = step; y < image.height - step; y += step) {
      for (var x = step; x < image.width - step; x += step) {
        final current = _luminance(image.getPixel(x, y));
        final right = _luminance(image.getPixel(x + step, y));
        final down = _luminance(image.getPixel(x, y + step));
        final gradient = (current - right).abs() + (current - down).abs();

        if (gradient > 38) {
          edges++;
        }
        samples++;
      }
    }

    if (samples == 0) {
      return 0;
    }

    return clamp01(edges / samples / 0.35);
  }

  int _samplingStep(img.Image image) {
    return (image.width > 1000 || image.height > 1000) ? 8 : 4;
  }

  double _luminance(img.Pixel pixel) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }
}
