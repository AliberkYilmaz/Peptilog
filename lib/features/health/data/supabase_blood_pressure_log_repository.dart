import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/supabase_sync_repo.dart';
import '../domain/blood_pressure_log.dart';

class SupabaseBloodPressureLogRepository
    implements SupabaseSyncRepo<BloodPressureLog> {
  SupabaseBloodPressureLogRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'blood_pressure_logs';
  static const _uuid = Uuid();

  @override
  Future<void> pushDirty(List<BloodPressureLog> records) async {
    if (records.isEmpty) return;
    for (final r in records) {
      r.supabaseId ??= _uuid.v4();
    }
    await _client
        .from(_table)
        .upsert(records.map(_toJson).toList(), onConflict: 'id');
  }

  @override
  Future<List<BloodPressureLog>> pullSince(
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

  static Map<String, dynamic> _toJson(BloodPressureLog r) => {
    'id': r.supabaseId,
    'user_id': r.userId,
    'systolic': r.systolic,
    'diastolic': r.diastolic,
    'pulse': r.pulse,
    'measured_at': r.measuredAt.toUtc().toIso8601String(),
    'created_at': r.createdAt.toUtc().toIso8601String(),
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'is_deleted': r.isDeleted,
  };

  static BloodPressureLog _fromJson(Map<String, dynamic> json) {
    final log = BloodPressureLog()
      ..supabaseId = json['id'] as String?
      ..userId = json['user_id'] as String?
      ..systolic = json['systolic'] as int
      ..diastolic = json['diastolic'] as int
      ..pulse = json['pulse'] as int?
      ..measuredAt = DateTime.parse(json['measured_at'] as String)
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
