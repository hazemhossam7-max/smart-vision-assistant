import '../vision/frame_metadata.dart';
import '../voice/intent_classifier.dart';

class AiResponse {
  const AiResponse({
    required this.text,
    required this.provider,
  });

  final String text;
  final String provider;
}

abstract class AiService {
  Future<AiResponse> analyzeKeyframes({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
    String? knownFaceName,
  });
}
