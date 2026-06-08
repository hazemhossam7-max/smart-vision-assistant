import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> writeString(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> readString(String key) {
    return _storage.read(key: key);
  }

  Future<void> writeBool(String key, bool value) {
    return writeString(key, value ? 'true' : 'false');
  }

  Future<bool> readBool(String key, {bool defaultValue = false}) async {
    final value = await readString(key);
    if (value == null) {
      return defaultValue;
    }
    return value.toLowerCase() == 'true';
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> clearAll() {
    return _storage.deleteAll();
  }
}
