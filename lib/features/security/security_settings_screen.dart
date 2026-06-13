import 'package:flutter/material.dart';

import '../../core/security/device_security_service.dart';
import '../../core/security/local_auth_service.dart';
import '../../core/security/security_audit_logger.dart';
import '../../core/security/security_settings_service.dart';
import '../../core/security/temporary_frame_cleanup_service.dart';
import '../vision/frame_metadata.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({
    super.key,
    this.knownFrames = const [],
    SecuritySettingsService settingsService = const SecuritySettingsService(),
    TemporaryFrameCleanupService cleanupService = const TemporaryFrameCleanupService(),
    DeviceSecurityService deviceSecurityService = const DeviceSecurityService(),
    SecurityAuditLogger auditLogger = const SecurityAuditLogger(),
    LocalAuthService? localAuthService,
  })  : _settingsService = settingsService,
        _cleanupService = cleanupService,
        _deviceSecurityService = deviceSecurityService,
        _auditLogger = auditLogger,
        _localAuthService = localAuthService;

  final List<FrameMetadata> knownFrames;
  final SecuritySettingsService _settingsService;
  final TemporaryFrameCleanupService _cleanupService;
  final DeviceSecurityService _deviceSecurityService;
  final SecurityAuditLogger _auditLogger;
  final LocalAuthService? _localAuthService;

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late final LocalAuthService _localAuthService;
  late final TextEditingController _guardianPhoneController;

  bool _loading = true;
  bool _privacyModeEnabled = true;
  bool _cloudConsentGiven = false;
  bool _saveHistoryEnabled = false;
  bool _biometricLockEnabled = false;
  bool _rootRiskDetected = false;
  bool _sensitiveDocumentWarningEnabled = true;

  @override
  void initState() {
    super.initState();
    _localAuthService = widget._localAuthService ?? LocalAuthService();
    _guardianPhoneController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final values = await Future.wait<bool>([
      widget._settingsService.isPrivacyModeEnabled(),
      widget._settingsService.hasCloudConsent(),
      widget._settingsService.isSaveHistoryEnabled(),
      widget._settingsService.isBiometricLockEnabled(),
      widget._deviceSecurityService.isRootRiskDetected(),
      widget._settingsService.isSensitiveDocumentWarningEnabled(),
    ]);
    final guardianPhone = await widget._settingsService.readGuardianPhoneNumber();

    if (!mounted) {
      return;
    }

    setState(() {
      _privacyModeEnabled = values[0];
      _cloudConsentGiven = values[1];
      _saveHistoryEnabled = values[2] && !values[4];
      _biometricLockEnabled = values[3];
      _rootRiskDetected = values[4];
      _sensitiveDocumentWarningEnabled = values[5];
      _guardianPhoneController.text = guardianPhone ?? '';
      _loading = false;
    });

    if (values[2] && values[4]) {
      await widget._settingsService.setSaveHistoryEnabled(false);
    }
  }

  Future<void> _setPrivacyMode(bool value) async {
    if (!value && _biometricLockEnabled && !await _authenticate()) {
      return;
    }

    await widget._settingsService.setPrivacyModeEnabled(value);
    widget._auditLogger.logSecuritySettingChanged(settingName: 'privacy_mode');
    if (!mounted) {
      return;
    }
    setState(() => _privacyModeEnabled = value);
  }

  Future<void> _setSaveHistory(bool value) async {
    if (value && _rootRiskDetected) {
      _showMessage('Save History is disabled because root risk was detected.');
      return;
    }

    if (value && !await _authenticate()) {
      return;
    }

    await widget._settingsService.setSaveHistoryEnabled(value);
    widget._auditLogger.logSecuritySettingChanged(settingName: 'save_history');
    if (!mounted) {
      return;
    }
    setState(() => _saveHistoryEnabled = value);
  }

  Future<void> _setBiometricLock(bool value) async {
    if (value && !await _localAuthService.isDeviceAuthSupported()) {
      _showMessage('Device lock is not available on this device.');
      return;
    }

    if (value && !await _authenticate()) {
      return;
    }

    await widget._settingsService.setBiometricLockEnabled(value);
    widget._auditLogger.logSecuritySettingChanged(settingName: 'biometric_lock');
    if (!mounted) {
      return;
    }
    setState(() => _biometricLockEnabled = value);
  }

  Future<void> _setSensitiveDocumentWarning(bool value) async {
    await widget._settingsService.setSensitiveDocumentWarningEnabled(value);
    widget._auditLogger.logSecuritySettingChanged(
      settingName: 'sensitive_document_warning',
    );
    if (!mounted) {
      return;
    }
    setState(() => _sensitiveDocumentWarningEnabled = value);
  }

  Future<void> _saveGuardianPhone() async {
    if (!await _authenticate()) {
      return;
    }

    await widget._settingsService.setGuardianPhoneNumber(
      _guardianPhoneController.text.trim(),
    );
    widget._auditLogger.logSecuritySettingChanged(settingName: 'guardian_phone');
    _showMessage('Guardian contact saved.');
  }

  Future<void> _deleteLocalData() async {
    if (_biometricLockEnabled && !await _authenticate()) {
      return;
    }

    await widget._cleanupService.deleteTemporaryFrameFiles(widget.knownFrames);
    await widget._settingsService.clearSecuritySettings();
    if (!mounted) {
      return;
    }
    _showMessage('Local privacy settings and temporary frame files were cleared.');
    await _loadSettings();
  }

  Future<bool> _authenticate() {
    return _localAuthService.authenticateForSensitiveAction(
      reason: 'Authenticate to change sensitive Smart Vision settings.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _guardianPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security & Privacy')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Semantics(
                  label: 'Privacy Mode toggle',
                  hint: 'Privacy Mode is on by default and avoids saving image history.',
                  child: SwitchListTile(
                    title: const Text('Privacy Mode'),
                    subtitle: const Text('Avoid saving image history and clear temporary frames.'),
                    value: _privacyModeEnabled,
                    onChanged: _setPrivacyMode,
                  ),
                ),
                Semantics(
                  label: 'Save History toggle',
                  hint: _rootRiskDetected
                      ? 'Disabled because root risk was detected.'
                      : 'Requires authentication when enabled.',
                  child: SwitchListTile(
                    title: const Text('Save History'),
                    subtitle: Text(
                      _rootRiskDetected
                          ? 'Disabled because this device may be rooted.'
                          : 'Off by default. Enable only if you want local history later.',
                    ),
                    value: _saveHistoryEnabled,
                    onChanged: _rootRiskDetected ? null : _setSaveHistory,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Sensitive Document Warning'),
                  subtitle: const Text('Warn before analyzing IDs, cards, passwords, or medical papers.'),
                  value: _sensitiveDocumentWarningEnabled,
                  onChanged: _setSensitiveDocumentWarning,
                ),
                ListTile(
                  title: const Text('Cloud Consent'),
                  subtitle: Text(_cloudConsentGiven ? 'Given' : 'Not given'),
                ),
                ListTile(
                  title: const Text('Device Integrity'),
                  subtitle: Text(
                    _rootRiskDetected
                        ? 'Root risk detected. Avoid storing sensitive data on this device.'
                        : 'No root risk detected by basic checks.',
                  ),
                ),
                Semantics(
                  label: 'Biometric or phone lock toggle',
                  hint: 'Protect sensitive settings with device authentication.',
                  child: SwitchListTile(
                    title: const Text('Biometric or Phone Lock'),
                    subtitle: const Text('Use device authentication for sensitive settings.'),
                    value: _biometricLockEnabled,
                    onChanged: _setBiometricLock,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _guardianPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Guardian phone number',
                    helperText: 'Used only to open call or SMS confirmation.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _saveGuardianPhone,
                  child: const Text('Save Guardian Contact'),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _deleteLocalData,
                  child: const Text('Delete Local Data'),
                ),
              ],
            ),
    );
  }
}
