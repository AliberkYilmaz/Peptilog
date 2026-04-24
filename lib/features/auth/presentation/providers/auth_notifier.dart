import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/sync_providers.dart';
import '../../data/auth_providers.dart';

/// Notifier that drives sign-in / sign-up operations.
/// State carries the latest async result so the UI can show loading/error.
class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> _runFirstSyncIfNeeded(String userId) async {
    final syncService = ref.read(syncServiceProvider);
    if (syncService.isFirstSyncNeeded) {
      await syncService.firstDeviceSetup(userId);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      await _runFirstSyncIfNeeded(user.id);
    });
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password);
      await _runFirstSyncIfNeeded(user.id);
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signInWithApple();
      await _runFirstSyncIfNeeded(user.id);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      await _runFirstSyncIfNeeded(user.id);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }

  void clearError() => state = const AsyncData(null);
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  AuthNotifier.new,
);
