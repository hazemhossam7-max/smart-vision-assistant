import '../../core/constants/app_config.dart';
import '../vision/frame_metadata.dart';
import '../voice/intent_classifier.dart';
import 'ai_service.dart';

class OpenAiService implements AiService {
  const OpenAiService();

  @override
  Future<AiResponse> analyzeKeyframes({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
    String? knownFaceName,
  }) async {
    // Placeholder for OpenAI Realtime / multimodal integration.
    // Keep only the top keyframes in the request payload to preserve the project focus.
    final hasApiKey = AppConfig.openAiApiKey.isNotEmpty;

    return AiResponse(
      provider: hasApiKey
          ? 'openai_placeholder_configured'
          : 'openai_placeholder_no_key',
      text:
          'OpenAI placeholder result. Command: "$userCommand". Intent: ${intent.label}. '
          '${_faceSummary(knownFaceName)}'
          'The local computer vision pipeline selected ${selectedFrames.length} of '
          '${allFrames.length} captured frames for the future API request.',
    );
  }

  String _faceSummary(String? knownFaceName) {
    final name = knownFaceName?.trim();
    if (name == null || name.isEmpty) {
      return '';
    }
    if (name.toLowerCase() == 'unknown person') {
      return 'Local face recognition did not match a saved person. ';
    }
    return 'Known face detected: $name. ';
  }
}
