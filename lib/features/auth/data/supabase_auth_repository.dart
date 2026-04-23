import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_user.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthUser?> get authStateChanges => _client.auth.onAuthStateChange.map(
        (event) => _mapUser(event.session?.user),
      );

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _requireUser(res.user);
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    return _requireUser(res.user);
  }

  @override
  Future<AuthUser> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'com.peptilog.app://auth/callback',
    );
    // After redirect, the session is set — return the current user.
    return _requireUser(_client.auth.currentUser);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.peptilog.app://auth/callback',
    );
    return _requireUser(_client.auth.currentUser);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<void> deleteAccount() async {
    // Calls the Supabase Edge Function that deletes auth.users entry.
    // The Edge Function handles cascading deletes via RLS + ON DELETE CASCADE.
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }

  // ---------------------------------------------------------------------------

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['full_name'] as String?,
    );
  }

  AuthUser _requireUser(User? user) {
    if (user == null) throw const _AuthException('Auth returned no user.');
    return _mapUser(user)!;
  }
}

class _AuthException implements Exception {
  const _AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}
