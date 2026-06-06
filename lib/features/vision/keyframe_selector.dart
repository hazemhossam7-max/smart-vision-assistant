import 'frame_metadata.dart';

class KeyframeSelector {
  const KeyframeSelector();

  List<FrameMetadata> selectTopFrames({
    required List<FrameMetadata> frames,
    required int topK,
  }) {
    final acceptedFrames = frames.where((frame) => !frame.isRejected).toList()
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));

    if (acceptedFrames.isNotEmpty) {
      return acceptedFrames.take(topK).toList(growable: false);
    }

    final fallbackFrames = List<FrameMetadata>.from(frames)
      ..sort((a, b) => b.finalScore.compareTo(a.finalScore));
    return fallbackFrames.take(topK).toList(growable: false);
  }
}
