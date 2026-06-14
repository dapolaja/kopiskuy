import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth =
      LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final bool canCheck =
          await auth.canCheckBiometrics;

      final bool isSupported =
          await auth.isDeviceSupported();

      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool isAuthenticated =
          await auth.authenticate(
        localizedReason:
            'Scan fingerprint untuk login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }

  Future<List<BiometricType>>
  getAvailableBiometrics() async {
    return await auth.getAvailableBiometrics();
  }
}