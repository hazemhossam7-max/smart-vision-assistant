import 'dart:math';

import 'package:camera/camera.dart';

import 'camera_service.dart';

class FrameCaptureService {
  FrameCaptureService(this._cameraService);

  final CameraService _cameraService;

  Future<List<XFile>> captureBurst({
    required Duration duration,
    required int fps,
  }) async {
    if (!_cameraService.isInitialized) {
      throw StateError('Camera must be initialized before capturing frames.');
    }

    final safeFps = max(1, fps);
    final frameCount =
        max(1, (duration.inMilliseconds / 1000 * safeFps).round());
    final interval = Duration(milliseconds: (1000 / safeFps).round());
    final frames = <XFile>[];

    for (var index = 0; index < frameCount; index++) {
      final startedAt = DateTime.now();
      final capturedFrame = await _cameraService.captureFrame();
      frames.add(capturedFrame);

      final elapsed = DateTime.now().difference(startedAt);
      final remainingDelay = interval - elapsed;
      if (remainingDelay.inMilliseconds > 0 && index < frameCount - 1) {
        await Future<void>.delayed(remainingDelay);
      }
    }

    return frames;
  }
}
