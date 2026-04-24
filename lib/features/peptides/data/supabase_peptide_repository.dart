import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/supabase_sync_repo.dart';
import '../domain/peptide.dart';

class SupabasePeptideRepository implements SupabaseSyncRepo<Peptide> {
  SupabasePeptideRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'peptides';
  static const _uuid = Uuid();

  @override
  Future<void> pushDirty(List<Peptide> records) async {
    if (records.isEmpty) return;
    for (final r in records) {
      r.supabaseId ??= _uuid.v4();
    }
    await _client
        .from(_table)
        .upsert(records.map(_toJson).toList(), onConflict: 'id');
  }

  @override
  Future<List<Peptide>> pullSince(DateTime lastSync, String userId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', lastSync.toUtc().toIso8601String());
    return rows.map(_fromJson).toList();
  }

  static Map<String, dynamic> _toJson(Peptide r) => {
    'id': r.supabaseId,
    'user_id': r.userId,
    'name': r.name,
    'color': r.color,
    'unit': r.unit,
    'is_active': r.isActive,
    'is_custom': r.isCustom,
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'is_deleted': r.isDeleted,
  };

  static Peptide _fromJson(Map<String, dynamic> json) => Peptide()
    ..supabaseId = json['id'] as String?
    ..userId = json['user_id'] as String?
    ..name = json['name'] as String
    ..color = json['color'] as String
    ..unit = json['unit'] as String
    ..isActive = json['is_active'] as bool? ?? true
    ..isCustom = json['is_custom'] as bool? ?? false
    ..updatedAt = DateTime.parse(json['updated_at'] as String)
    ..isDeleted = json['is_deleted'] as bool? ?? false
    ..isDirty = false;
}
