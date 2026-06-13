import 'package:flutter/services.dart';

class DeviceSecurityService {
  const DeviceSecurityService();

  static const _channel = MethodChannel('smart_vision_assistant/device_security');

  Future<bool> isRootRiskDetected() async {
    try {
      return await _channel.invokeMethod<bool>('isRootRiskDetected') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
