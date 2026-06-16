import 'package:flutter_test/flutter_test.dart';
import 'package:smart_vision_assistant/core/security/privacy_guard_service.dart';
import 'package:smart_vision_assistant/features/vision/frame_metadata.dart';
import 'package:smart_vision_assistant/features/voice/intent_classifier.dart';

void main() {
  const service = PrivacyGuardService();

  test('rejects frames with rejection reasons', () {
    final frame = _frame(rejectionReasons: const ['blur']);

    expect(service.shouldSendFrame(frame), isFalse);
  });

  test('rejects weak low-score frames', () {
    final frame = _frame(finalScore: 0.1);

    expect(service.shouldSendFrame(frame), isFalse);
  });

  test('allows clear high-quality frames', () {
    final frame = _frame();

    expect(service.shouldSendFrame(frame), isTrue);
  });
}

FrameMetadata _frame({
  double clarityScore = 0.9,
  double brightnessAverage = 120,
  double finalScore = 0.9,
  List<String> rejectionReasons = const [],
}) {
  return FrameMetadata(
    frameId: 'frame-1',
    filePath: 'test/frame.jpg',
    index: 0,
    capturedAt: DateTime.utc(2026),
    width: 640,
    height: 480,
    intent: VisionIntent.sceneDescription,
    blurScore: 200,
    clarityScore: clarityScore,
    brightnessAverage: brightnessAverage,
    brightnessScore: 0.8,
    uniquenessScore: 0.8,
    objectScore: 0.8,
    motionScore: 0.8,
    finalScore: finalScore,
    averageHash: 'abc123',
    rejectionReasons: rejectionReasons,
  );
}
