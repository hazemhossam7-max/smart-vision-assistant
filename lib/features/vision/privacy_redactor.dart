import '../voice/intent_classifier.dart';
import 'frame_metadata.dart';

class PrivacyRedactor {
  const PrivacyRedactor();

  Future<List<FrameMetadata>> redactIfNeeded({
    required List<FrameMetadata> frames,
    required VisionIntent intent,
    required bool privacyModeEnabled,
  }) async {
    if (!privacyModeEnabled) {
      return frames;
    }

    // TODO: Add on-device face detection and sensitive text redaction before
    // public production release. Good candidates are ML Kit face detection and
    // on-device OCR/PII detection. This scaffold intentionally returns the
    // existing frames unchanged so it does not corrupt the current camera,
    // keyframe, and backend upload pipeline before real redaction is added.
    return List<FrameMetadata>.unmodifiable(frames);
  }
}
