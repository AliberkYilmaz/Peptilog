import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/supabase_sync_repo.dart';
import '../domain/sleep_log.dart';

class SupabaseSleepLogRepository implements SupabaseSyncRepo<SleepLog> {
  SupabaseSleepLogRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'sleep_logs';
  static const _uuid = Uuid();

  @override
  Future<void> pushDirty(List<SleepLog> records) async {
    if (records.isEmpty) return;
    for (final r in records) {
      r.supabaseId ??= _uuid.v4();
    }
    await _client
        .from(_table)
        .upsert(records.map(_toJson).toList(), onConflict: 'id');
  }

  @override
  Future<List<SleepLog>> pullSince(DateTime lastSync, String userId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', lastSync.toUtc().toIso8601String());
    return rows.map(_fromJson).toList();
  }

  static Map<String, dynamic> _toJson(SleepLog r) => {
    'id': r.supabaseId,
    'user_id': r.userId,
    'hours': r.hours,
    'quality_rating': r.qualityRating,
    'date': r.date.toUtc().toIso8601String(),
    'created_at': r.createdAt.toUtc().toIso8601String(),
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'is_deleted': r.isDeleted,
  };

  static SleepLog _fromJson(Map<String, dynamic> json) {
    final log = SleepLog()
      ..supabaseId = json['id'] as String?
      ..userId = json['user_id'] as String?
      ..hours = (json['hours'] as num).toDouble()
      ..qualityRating = json['quality_rating'] as int?
      ..date = DateTime.parse(json['date'] as String)
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
