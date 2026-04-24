import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/supabase_sync_repo.dart';
import '../domain/reminder.dart';

class SupabaseReminderRepository implements SupabaseSyncRepo<Reminder> {
  SupabaseReminderRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'reminders';
  static const _uuid = Uuid();

  @override
  Future<void> pushDirty(List<Reminder> records) async {
    if (records.isEmpty) return;
    for (final r in records) {
      r.supabaseId ??= _uuid.v4();
    }
    await _client
        .from(_table)
        .upsert(records.map(_toJson).toList(), onConflict: 'id');
  }

  @override
  Future<List<Reminder>> pullSince(DateTime lastSync, String userId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', lastSync.toUtc().toIso8601String());
    return rows.map(_fromJson).toList();
  }

  static Map<String, dynamic> _toJson(Reminder r) => {
    'id': r.supabaseId,
    'user_id': r.userId,
    'peptide_id': r.peptideId,
    'days_of_week': r.daysOfWeek,
    'time': r.time,
    'is_active': r.isActive,
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'is_deleted': r.isDeleted,
  };

  static Reminder _fromJson(Map<String, dynamic> json) => Reminder()
    ..supabaseId = json['id'] as String?
    ..userId = json['user_id'] as String?
    ..peptideId = json['peptide_id'] as int
    ..daysOfWeek = json['days_of_week'] as String
    ..time = json['time'] as String
    ..isActive = json['is_active'] as bool? ?? true
    ..updatedAt = DateTime.parse(json['updated_at'] as String)
    ..isDeleted = json['is_deleted'] as bool? ?? false
    ..isDirty = false;
}
