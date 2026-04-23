/// Minimal domain entity representing an authenticated user.
/// Decoupled from Supabase — the repository maps to/from this.
class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;
}
