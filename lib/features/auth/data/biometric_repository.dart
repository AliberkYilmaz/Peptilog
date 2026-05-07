import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:peptilog_app/main.dart' show talker;

/// Wraps local_auth to provide biometric availability checks and authentication.
class BiometricRepository {
  BiometricRepository(this._auth);

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e, st) {
      talker.warning('biometric.isAvailable failed', e, st);
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e, st) {
      talker.warning('biometric.getAvailableBiometrics failed', e, st);
      return [];
    }
  }

  /// Returns true when the user successfully authenticates.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e, st) {
      talker.handle(e, st, 'biometric.authenticate');
      return false;
    }
  }
}

final biometricRepositoryProvider = Provider<BiometricRepository>(
  (_) => BiometricRepository(LocalAuthentication()),
);
