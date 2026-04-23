import '../domain/auth_user.dart';

/// Abstract auth repository — all auth operations go through this interface.
/// Concrete implementation: [SupabaseAuthRepository].
abstract class AuthRepository {
  /// Stream of the current user; emits null when signed out.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the currently signed-in user, or null.
  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Initiates Apple Sign-In OAuth flow.
  Future<AuthUser> signInWithApple();

  /// Initiates Google Sign-In OAuth flow.
  Future<AuthUser> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> deleteAccount();
}
