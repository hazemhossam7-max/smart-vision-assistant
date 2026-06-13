import 'package:url_launcher/url_launcher.dart';

import '../../core/security/security_settings_service.dart';

class EmergencyService {
  const EmergencyService({
    SecuritySettingsService settingsService = const SecuritySettingsService(),
  }) : _settingsService = settingsService;

  final SecuritySettingsService _settingsService;

  Future<EmergencyResult> triggerEmergency({bool includeLocation = false}) async {
    final phoneNumber = await _settingsService.readGuardianPhoneNumber();
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return const EmergencyResult(
        opened: false,
        message: 'No guardian contact is saved. Please add one in Security and Privacy settings.',
      );
    }

    if (includeLocation) {
      return sendEmergencySms(includeLocation: true);
    }

    return callGuardian();
  }

  Future<EmergencyResult> callGuardian() async {
    final phoneNumber = await _settingsService.readGuardianPhoneNumber();
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return const EmergencyResult(
        opened: false,
        message: 'No guardian contact is saved. Please add one in Security and Privacy settings.',
      );
    }

    final uri = Uri(scheme: 'tel', path: phoneNumber.trim());
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return EmergencyResult(
      opened: opened,
      message: opened
          ? 'Emergency mode opened. Please confirm the call on your phone.'
          : 'Could not open the phone app.',
    );
  }

  Future<EmergencyResult> sendEmergencySms({bool includeLocation = false}) async {
    final phoneNumber = await _settingsService.readGuardianPhoneNumber();
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return const EmergencyResult(
        opened: false,
        message: 'No guardian contact is saved. Please add one in Security and Privacy settings.',
      );
    }

    final body = includeLocation
        ? 'I need help. Please contact me. Location sharing is not configured in this demo build.'
        : 'I need help. Please contact me.';
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber.trim(),
      queryParameters: {'body': body},
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return EmergencyResult(
      opened: opened,
      message: opened
          ? 'Emergency mode opened. Please confirm the message on your phone.'
          : 'Could not open the messages app.',
    );
  }
}

class EmergencyResult {
  const EmergencyResult({required this.opened, required this.message});

  final bool opened;
  final String message;
}
