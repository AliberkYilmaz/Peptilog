import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the user's PIN in the device secure enclave (Keychain / Keystore).
/// flutter_secure_storage encrypts at rest — no additional hashing needed for
/// MVP, but a production release should apply Argon2 before writing.
class PinRepository {
  const PinRepository(this._storage);

  final FlutterSecureStorage _storage;

  static const _pinKey = 'peptilog_pin';
  static const _pinSetKey = 'peptilog_pin_set';
  static const _biometricEnabledKey = 'peptilog_biometric_enabled';
  static const _onboardingSeenKey = 'peptilog_onboarding_seen';
  static const _gdprConsentKey = 'peptilog_gdpr_consent';

  Future<bool> isPinSet() async {
    final value = await _storage.read(key: _pinSetKey);
    return value == 'true';
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _pinSetKey, value: 'true');
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored == pin;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSetKey);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _onboardingSeenKey);
    return value == 'true';
  }

  Future<void> markOnboardingSeen() async {
    await _storage.write(key: _onboardingSeenKey, value: 'true');
  }

  Future<bool> hasGdprConsent() async {
    final value = await _storage.read(key: _gdprConsentKey);
    return value == 'true';
  }

  Future<void> setGdprConsent({required bool consented}) async {
    await _storage.write(
      key: _gdprConsentKey,
      value: consented ? 'true' : 'false',
    );
  }
}

const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);

final pinRepositoryProvider = Provider<PinRepository>(
  (_) => const PinRepository(FlutterSecureStorage(aOptions: _androidOptions)),
);
