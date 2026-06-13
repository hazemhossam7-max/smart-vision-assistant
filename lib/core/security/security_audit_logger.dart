import 'package:flutter/foundation.dart';

class SecurityAuditLogger {
  const SecurityAuditLogger();

  void logPermissionEvent({required String permission, required bool granted}) {
    _log('permission_event', {'permission': permission, 'granted': granted});
  }

  void logAiRequest({
    required String provider,
    required String intent,
    required int selectedFrameCount,
  }) {
    _log('ai_request', {
      'provider': provider,
      'intent': intent,
      'selectedFrameCount': selectedFrameCount,
    });
  }

  void logFrameRejected({required String reason}) {
    _log('frame_rejected', {'reason': reason});
  }

  void logCloudConsent({required bool accepted}) {
    _log('cloud_consent', {'accepted': accepted});
  }

  void logEmergencyTriggered({required bool locationIncluded}) {
    _log('emergency_triggered', {'locationIncluded': locationIncluded});
  }

  void logSecuritySettingChanged({required String settingName}) {
    _log('security_setting_changed', {'settingName': settingName});
  }

  void logBackendError({required String provider, required int? statusCode}) {
    _log('backend_error', {'provider': provider, 'statusCode': statusCode});
  }

  void _log(String event, Map<String, Object?> fields) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('security_audit ${_safeFields({'event': event, ...fields})}');
  }

  Map<String, Object?> _safeFields(Map<String, Object?> fields) {
    return fields.map((key, value) {
      if (value is String) {
        return MapEntry(key, _redact(value));
      }
      return MapEntry(key, value);
    });
  }

  String _redact(String value) {
    return value
        .replaceAll(RegExp(r'[A-Za-z0-9+/=]{80,}'), '[redacted_blob]')
        .replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), '[redacted_key]')
        .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer [redacted]');
  }
}
