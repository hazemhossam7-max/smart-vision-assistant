import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = const [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<bool> initialize() async {
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      return false;
    }

    _availableCameras = await availableCameras();
    if (_availableCameras.isEmpty) {
      return false;
    }

    final backCamera = _availableCameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _availableCameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await controller.initialize();
    await controller.setFlashMode(FlashMode.off);
    _controller = controller;
    return true;
  }

  Future<XFile> captureFrame() async {
    final activeController = _controller;
    if (activeController == null || !activeController.value.isInitialized) {
      throw StateError('Camera is not initialized.');
    }

    return activeController.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
