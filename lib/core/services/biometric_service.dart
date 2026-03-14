import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Manages biometric authentication for app unlock.
///
/// On supported devices, the app can require fingerprint/face unlock
/// when resuming from background after the lock delay has elapsed.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device supports biometric authentication.
  Future<bool> get isAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the list of available biometric types (fingerprint, face, etc.).
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Prompts the user for biometric authentication.
  ///
  /// Returns `true` if authenticated successfully.
  /// Returns `false` if authentication failed or was cancelled.
  Future<bool> authenticate({
    String reason = 'Authenticate to access ParkFlow Manager',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // If biometrics fail, allow device PIN/password as fallback
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
