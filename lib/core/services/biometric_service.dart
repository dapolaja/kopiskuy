import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  // cek device support
  Future<bool> isAvailable() async {
    bool canCheck = await auth.canCheckBiometrics;
    bool isSupported = await auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  // authenticate
  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Scan fingerprint untuk login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }
}
