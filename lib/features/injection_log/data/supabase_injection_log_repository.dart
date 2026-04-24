import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/supabase_sync_repo.dart';
import '../domain/injection_log.dart';

class SupabaseInjectionLogRepository
    implements SupabaseSyncRepo<InjectionLog> {
  SupabaseInjectionLogRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'injection_logs';
  static const _uuid = Uuid();

  @override
  Future<void> pushDirty(List<InjectionLog> records) async {
    if (records.isEmpty) return;
    for (final r in records) {
      r.supabaseId ??= _uuid.v4();
    }
    await _client.from(_table).upsert(
          records.map(_toJson).toList(),
          onConflict: 'id',
        );
  }

  @override
  Future<List<InjectionLog>> pullSince(
    DateTime lastSync,
    String userId,
  ) async {
    final List<Map<String, dynamic>> rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', lastSync.toUtc().toIso8601String());
    return rows.map(_fromJson).toList();
  }

  static Map<String, dynamic> _toJson(InjectionLog r) => {
        'id': r.supabaseId,
        'user_id': r.userId,
        'peptide_id': r.peptideId,
        'dose_mg': r.doseMg,
        'route': r.route,
        'units': r.units,
        'notes': r.notes,
        'logged_at': r.loggedAt.toUtc().toIso8601String(),
        'created_at': r.createdAt.toUtc().toIso8601String(),
        'updated_at': r.updatedAt.toUtc().toIso8601String(),
        'is_deleted': r.isDeleted,
      };

  static InjectionLog _fromJson(Map<String, dynamic> json) {
    final log = InjectionLog()
      ..supabaseId = json['id'] as String?
      ..userId = json['user_id'] as String?
      ..peptideId = json['peptide_id'] as int
      ..doseMg = (json['dose_mg'] as num).toDouble()
      ..route = json['route'] as String
      ..units = (json['units'] as num?)?.toDouble()
      ..notes = json['notes'] as String?
      ..loggedAt = DateTime.parse(json['logged_at'] as String)
      ..updatedAt = DateTime.parse(json['updated_at'] as String)
      ..isDeleted = json['is_deleted'] as bool? ?? false
      ..isDirty = false;
    final createdAt = json['created_at'];
    if (createdAt != null) {
      log.createdAt = DateTime.parse(createdAt as String);
    }
    return log;
  }
}
