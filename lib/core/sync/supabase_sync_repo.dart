/// Generic interface for pushing dirty local records to Supabase and pulling
/// remote changes since a given timestamp.
abstract class SupabaseSyncRepo<T> {
  /// Upserts [records] to Supabase. Records without a [supabaseId] will have
  /// a UUID assigned in-place (mutating the object) so the caller can persist
  /// the new id back to Isar.
  Future<void> pushDirty(List<T> records);

  /// Returns all remote records with `updated_at >= lastSync` for [userId].
  Future<List<T>> pullSince(DateTime lastSync, String userId);
}
