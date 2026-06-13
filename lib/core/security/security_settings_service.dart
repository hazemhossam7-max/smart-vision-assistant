import 'secure_storage_service.dart';

class SecuritySettingsService {
  const SecuritySettingsService({
    SecureStorageService storage = const SecureStorageService(),
  }) : _storage = storage;

  static const privacyModeEnabledKey = 'privacy_mode_enabled';
  static const cloudConsentGivenKey = 'cloud_consent_given';
  static const saveHistoryEnabledKey = 'save_history_enabled';
  static const biometricLockEnabledKey = 'biometric_lock_enabled';
  static const guardianPhoneNumberKey = 'guardian_phone_number';
  static const sensitiveDocumentWarningEnabledKey =
      'sensitive_document_warning_enabled';

  final SecureStorageService _storage;

  Future<bool> isPrivacyModeEnabled() {
    return _storage.readBool(privacyModeEnabledKey, defaultValue: true);
  }

  Future<void> setPrivacyModeEnabled(bool value) {
    return _storage.writeBool(privacyModeEnabledKey, value);
  }

  Future<bool> hasCloudConsent() {
    return _storage.readBool(cloudConsentGivenKey, defaultValue: false);
  }

  Future<void> setCloudConsentGiven(bool value) {
    return _storage.writeBool(cloudConsentGivenKey, value);
  }

  Future<bool> isSaveHistoryEnabled() {
    return _storage.readBool(saveHistoryEnabledKey, defaultValue: false);
  }

  Future<void> setSaveHistoryEnabled(bool value) {
    return _storage.writeBool(saveHistoryEnabledKey, value);
  }

  Future<bool> isBiometricLockEnabled() {
    return _storage.readBool(biometricLockEnabledKey, defaultValue: false);
  }

  Future<void> setBiometricLockEnabled(bool value) {
    return _storage.writeBool(biometricLockEnabledKey, value);
  }

  Future<bool> isSensitiveDocumentWarningEnabled() {
    return _storage.readBool(
      sensitiveDocumentWarningEnabledKey,
      defaultValue: true,
    );
  }

  Future<void> setSensitiveDocumentWarningEnabled(bool value) {
    return _storage.writeBool(sensitiveDocumentWarningEnabledKey, value);
  }

  Future<String?> readGuardianPhoneNumber() {
    return _storage.readString(guardianPhoneNumberKey);
  }

  Future<void> setGuardianPhoneNumber(String value) {
    return _storage.writeString(guardianPhoneNumberKey, value);
  }

  Future<void> clearSecuritySettings() {
    return _storage.clearAll();
  }
}
