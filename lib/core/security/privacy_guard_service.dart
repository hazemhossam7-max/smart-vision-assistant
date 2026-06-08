import '../../features/vision/frame_metadata.dart';
import '../../features/voice/intent_classifier.dart';
import '../constants/quality_thresholds.dart';

class PrivacyGuardService {
  const PrivacyGuardService({
    this.minFinalScore = 0.25,
  });

  final double minFinalScore;

  bool shouldSendFrame(FrameMetadata frame) {
    if (frame.rejectionReasons.isNotEmpty) {
      return false;
    }
    if (frame.clarityScore < QualityThresholds.minClarityScore) {
      return false;
    }
    if (frame.brightnessAverage < QualityThresholds.minBrightnessAverage) {
      return false;
    }
    if (frame.brightnessAverage > QualityThresholds.maxBrightnessAverage) {
      return false;
    }
    if (frame.finalScore < minFinalScore) {
      return false;
    }
    return true;
  }

  List<FrameMetadata> filterSafeKeyframes(List<FrameMetadata> selectedFrames) {
    return selectedFrames.where(shouldSendFrame).toList(growable: false);
  }

  String buildPrivacyWarningForIntent(VisionIntent intent) {
    switch (intent) {
      case VisionIntent.textReading:
        return 'This may send an image of text to the AI. Avoid private documents.';
      case VisionIntent.navigationHelp:
        return 'Camera frames may be sent to the AI for navigation help. I cannot guarantee safety.';
      case VisionIntent.sceneDescription:
        return 'Selected camera frames may be sent to the AI for scene description.';
      case VisionIntent.objectSearch:
        return 'Selected camera frames may be sent to the AI to search for the object.';
      case VisionIntent.obstacleDetection:
        return 'Selected camera frames may be sent to the AI for obstacle detection.';
      case VisionIntent.currencyRecognition:
        return 'Selected camera frames may be sent to the AI for currency recognition.';
    }
  }
}
