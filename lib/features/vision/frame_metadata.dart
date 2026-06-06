import '../voice/intent_classifier.dart';

class FrameMetadata {
  const FrameMetadata({
    required this.frameId,
    required this.filePath,
    required this.index,
    required this.capturedAt,
    required this.width,
    required this.height,
    required this.intent,
    required this.blurScore,
    required this.clarityScore,
    required this.brightnessAverage,
    required this.brightnessScore,
    required this.uniquenessScore,
    required this.objectScore,
    required this.motionScore,
    required this.finalScore,
    required this.averageHash,
    required this.rejectionReasons,
  });

  final String frameId;
  final String filePath;
  final int index;
  final DateTime capturedAt;
  final int width;
  final int height;
  final VisionIntent intent;
  final double blurScore;
  final double clarityScore;
  final double brightnessAverage;
  final double brightnessScore;
  final double uniquenessScore;
  final double objectScore;
  final double motionScore;
  final double finalScore;
  final String averageHash;
  final List<String> rejectionReasons;

  bool get isRejected => rejectionReasons.isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'frame_id': frameId,
      'file_path': filePath,
      'index': index,
      'captured_at': capturedAt.toIso8601String(),
      'width': width,
      'height': height,
      'intent': intent.label,
      'blur_score_laplacian_variance': blurScore,
      'clarity_score': clarityScore,
      'brightness_average': brightnessAverage,
      'brightness_score': brightnessScore,
      'uniqueness_score': uniquenessScore,
      'object_score': objectScore,
      'motion_score': motionScore,
      'final_score': finalScore,
      'is_rejected': isRejected,
      'rejection_reasons': rejectionReasons,
    };
  }
}
