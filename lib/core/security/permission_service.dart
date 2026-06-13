import 'package:permission_handler/permission_handler.dart';

import '../../features/voice/intent_classifier.dart';

class PermissionService {
  const PermissionService();

  Future<bool> requestMicrophone() async {
    final microphone = await Permission.microphone.request();
    if (!microphone.isGranted) {
      return false;
    }

    final speech = await Permission.speech.request();
    return speech.isGranted || speech.isLimited;
  }

  Future<bool> requestCamera() async {
    final camera = await Permission.camera.request();
    return camera.isGranted;
  }

  Future<bool> requestCameraAndMicrophone() async {
    final microphone = await requestMicrophone();
    if (!microphone) {
      return false;
    }
    return requestCamera();
  }

  Future<bool> requestLocationWhenNeeded() async {
    final fine = await Permission.locationWhenInUse.request();
    return fine.isGranted || fine.isLimited;
  }

  Future<bool> ensurePermissionsForIntent(VisionIntent intent) async {
    if (intent == VisionIntent.emergencyHelp) {
      return true;
    }

    final cameraGranted = await requestCamera();
    if (!cameraGranted) {
      return false;
    }

    if (intent == VisionIntent.navigationHelp) {
      return requestLocationWhenNeeded();
    }

    return true;
  }
}
