import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peptilog_app/main.dart' show talker;

import '../../data/biometric_repository.dart';
import '../../data/pin_repository.dart';

/// Async provider — true when the user's PIN has been verified this session.
/// Reset on sign-out or app resume.
final pinVerifiedProvider = StateProvider<bool>((_) => false);

class PinNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> setup(String pin) async {
    state = const AsyncLoading();
    try {
      await ref.read(pinRepositoryProvider).setPin(pin);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      talker.handle(e, st, 'pin.setup');
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> verify(String pin) async {
    state = const AsyncLoading();
    try {
      final ok = await ref.read(pinRepositoryProvider).verifyPin(pin);
      if (ok) ref.read(pinVerifiedProvider.notifier).state = true;
      state = const AsyncData(null);
      return ok;
    } catch (e, st) {
      talker.handle(e, st, 'pin.verify');
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> verifyWithBiometrics(String reason) async {
    final ok = await ref
        .read(biometricRepositoryProvider)
        .authenticate(localizedReason: reason);
    if (ok) ref.read(pinVerifiedProvider.notifier).state = true;
    return ok;
  }

  Future<bool> isPinSet() => ref.read(pinRepositoryProvider).isPinSet();
}

final pinNotifierProvider = AsyncNotifierProvider<PinNotifier, void>(
  PinNotifier.new,
);
