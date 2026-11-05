import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth;
  bool _isAuthenticating = false;

  BiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  Future<bool> canAuthenticate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return _auth.getAvailableBiometrics();
  }

  // This code for authenticating the user via biometric hardware or device PIN
  Future<bool> authenticate({String reason = 'Unlock Infinity Vault'}) async {
    if (_isAuthenticating) return false;
    _isAuthenticating = true;
    try {
      final available = await canAuthenticate();
      if (!available) return true;

      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }
}
