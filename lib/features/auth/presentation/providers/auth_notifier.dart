import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peptilog_app/main.dart' show talker;

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

  Future<void> signInWithApple() => _signInWithOAuth(
    () => ref.read(authRepositoryProvider).signInWithApple(),
  );

  Future<void> signInWithGoogle() => _signInWithOAuth(
    () => ref.read(authRepositoryProvider).signInWithGoogle(),
  );

  /// OAuth flows open an external browser; the actual sign-in completes via
  /// deep-link callback handled by supabase_flutter, which fires the auth
  /// state stream listened to by the router. The "Auth returned no user"
  /// exception thrown immediately after `signInWithOAuth` is expected and
  /// must be suppressed — otherwise the UI shows it as a real error before
  /// the user has even finished the consent flow in the browser.
  Future<void> _signInWithOAuth(Future<dynamic> Function() openOAuth) async {
    state = const AsyncLoading();
    try {
      final user = await openOAuth();
      if (user != null) {
        await _runFirstSyncIfNeeded(user.id);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      if (e.toString().contains('Auth returned no user')) {
        talker.info('OAuth in progress — waiting for auth state stream');
        state = const AsyncData(null);
      } else {
        talker.handle(e, st, 'signInWithOAuth');
        state = AsyncError(e, st);
      }
    }
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
