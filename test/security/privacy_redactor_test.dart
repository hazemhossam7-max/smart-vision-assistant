import 'package:flutter_test/flutter_test.dart';
import 'package:smart_vision_assistant/features/vision/frame_metadata.dart';
import 'package:smart_vision_assistant/features/vision/privacy_redactor.dart';
import 'package:smart_vision_assistant/features/voice/intent_classifier.dart';

void main() {
  const redactor = PrivacyRedactor();

  test('returns frames unchanged when privacy mode is disabled', () async {
    final frames = [_frame()];

    final result = await redactor.redactIfNeeded(
      frames: frames,
      intent: VisionIntent.sceneDescription,
      privacyModeEnabled: false,
    );

    expect(result, same(frames));
  });

  test('returns an immutable frame list when privacy mode is enabled', () async {
    final frames = [_frame()];

    final result = await redactor.redactIfNeeded(
      frames: frames,
      intent: VisionIntent.textReading,
      privacyModeEnabled: true,
    );

    expect(result.single.frameId, 'frame-1');
    expect(() => result.add(_frame()), throwsUnsupportedError);
  });
}

FrameMetadata _frame() {
  return FrameMetadata(
    frameId: 'frame-1',
    filePath: 'test/frame.jpg',
    index: 0,
    capturedAt: DateTime.utc(2026),
    width: 640,
    height: 480,
    intent: VisionIntent.sceneDescription,
    blurScore: 200,
    clarityScore: 0.9,
    brightnessAverage: 120,
    brightnessScore: 0.8,
    uniquenessScore: 0.8,
    objectScore: 0.8,
    motionScore: 0.8,
    finalScore: 0.9,
    averageHash: 'abc123',
    rejectionReasons: const [],
  );
}
