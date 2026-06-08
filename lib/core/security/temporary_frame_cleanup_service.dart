import 'dart:io';

import '../../features/vision/frame_metadata.dart';

class TemporaryFrameCleanupService {
  const TemporaryFrameCleanupService();

  Future<void> deleteTemporaryFrameFiles(List<FrameMetadata> frames) async {
    final seenPaths = <String>{};

    for (final frame in frames) {
      final path = frame.filePath;
      if (path.isEmpty || !seenPaths.add(path)) {
        continue;
      }

      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Cleanup should never interrupt the accessibility flow.
      }
    }
  }
}
