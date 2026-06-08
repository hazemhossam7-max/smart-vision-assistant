import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  LocalAuthService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> isDeviceAuthSupported() async {
    final supported = await _localAuthentication.isDeviceSupported();
    final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    return supported || canCheckBiometrics;
  }

  Future<bool> authenticateForSensitiveAction({String? reason}) async {
    if (!await isDeviceAuthSupported()) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason:
          reason ?? 'Authenticate to access sensitive Smart Vision settings.',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}
