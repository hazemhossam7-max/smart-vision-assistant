import '../../core/constants/app_config.dart';
import '../vision/frame_metadata.dart';
import '../voice/intent_classifier.dart';
import 'ai_service.dart';

class GeminiService implements AiService {
  const GeminiService();

  @override
  Future<AiResponse> analyzeKeyframes({
    required String userCommand,
    required VisionIntent intent,
    required List<FrameMetadata> selectedFrames,
    required List<FrameMetadata> allFrames,
  }) async {
    // Placeholder for Gemini Live / Gemini multimodal integration.
    // Later, send selectedFrames file bytes plus selectedFrames.map((e) => e.toJson()).
    final hasApiKey = AppConfig.geminiApiKey.isNotEmpty;
    final selectedSummary = _selectedSummary(selectedFrames);

    return AiResponse(
      provider: hasApiKey
          ? 'gemini_placeholder_configured'
          : 'gemini_placeholder_no_key',
      text:
          'I understood your request as ${intent.label}. I captured ${allFrames.length} frames, '
          'filtered them locally, and selected ${selectedFrames.length} important keyframes. '
          '$selectedSummary This is a local demo response until Gemini is connected.',
    );
  }

  String _selectedSummary(List<FrameMetadata> frames) {
    if (frames.isEmpty) {
      return 'No frames passed the quality filters.';
    }

    final scores =
        frames.map((frame) => frame.finalScore.toStringAsFixed(2)).join(', ');
    return 'Selected frame scores: $scores.';
  }
}
