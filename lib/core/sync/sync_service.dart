import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/health/data/supabase_blood_pressure_log_repository.dart';
import '../../features/health/data/supabase_sleep_log_repository.dart';
import '../../features/health/domain/blood_pressure_log.dart';
import '../../features/health/domain/sleep_log.dart';
import '../../features/injection_log/data/supabase_injection_log_repository.dart';
import '../../features/injection_log/domain/injection_log.dart';
import '../../features/peptides/data/supabase_peptide_repository.dart';
import '../../features/peptides/domain/peptide.dart';
import '../../features/reminders/data/supabase_reminder_repository.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/weight/data/supabase_weight_log_repository.dart';
import '../../features/weight/domain/weight_log.dart';

const _kLastSyncKey = 'sync.lastSyncAt';
const _kFirstSyncDoneKey = 'sync.firstSyncDone';

/// Orchestrates the full offline-first sync cycle for all entities.
///
/// Per entity (last-write-wins conflict resolution per SPEC §8.4):
///   1. Query Isar for dirty records
///   2. Push dirty records to Supabase (upsert)
///   3. Pull remote changes since lastSyncAt
///   4. Merge into Isar — remote wins when remote.updatedAt > local.updatedAt
///   5. Clear isDirty flags, persist new lastSyncAt
class SyncService {
  SyncService({
    required Isar isar,
    required SharedPreferences prefs,
    required SupabaseInjectionLogRepository injectionLogRepo,
    required SupabasePeptideRepository peptideRepo,
    required SupabaseWeightLogRepository weightLogRepo,
    required SupabaseSleepLogRepository sleepLogRepo,
    required SupabaseBloodPressureLogRepository bloodPressureLogRepo,
    required SupabaseReminderRepository reminderRepo,
  })  : _isar = isar,
        _prefs = prefs,
        _injectionLogRepo = injectionLogRepo,
        _peptideRepo = peptideRepo,
        _weightLogRepo = weightLogRepo,
        _sleepLogRepo = sleepLogRepo,
        _bloodPressureLogRepo = bloodPressureLogRepo,
        _reminderRepo = reminderRepo;

  final Isar _isar;
  final SharedPreferences _prefs;
  final SupabaseInjectionLogRepository _injectionLogRepo;
  final SupabasePeptideRepository _peptideRepo;
  final SupabaseWeightLogRepository _weightLogRepo;
  final SupabaseSleepLogRepository _sleepLogRepo;
  final SupabaseBloodPressureLogRepository _bloodPressureLogRepo;
  final SupabaseReminderRepository _reminderRepo;

  DateTime get _lastSyncAt {
    final raw = _prefs.getString(_kLastSyncKey);
    return raw != null
        ? DateTime.parse(raw)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> _setLastSyncAt(DateTime dt) =>
      _prefs.setString(_kLastSyncKey, dt.toUtc().toIso8601String());

  bool get isFirstSyncNeeded =>
      !(_prefs.getBool(_kFirstSyncDoneKey) ?? false);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Runs a full sync cycle for all entities.
  Future<void> sync(String userId) async {
    final syncStart = DateTime.now().toUtc();
    await Future.wait([
      syncInjectionLogs(userId),
      syncPeptides(userId),
      syncWeightLogs(userId),
      syncSleepLogs(userId),
      syncBloodPressureLogs(userId),
      syncReminders(userId),
    ]);
    await _setLastSyncAt(syncStart);
  }

  /// First-device / fresh-install setup. Clears local Isar data, pulls ALL
  /// records from Supabase for [userId], and marks setup complete so subsequent
  /// launches skip the full pull.
  Future<void> firstDeviceSetup(String userId) async {
    // 1. Wipe local data to avoid stale data from a previous install.
    await _isar.writeTxn(() => _isar.clear());

    // 2. Pull ALL records (epoch 0 ≡ "since forever").
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final results = await Future.wait([
      _injectionLogRepo.pullSince(epoch, userId),
      _peptideRepo.pullSince(epoch, userId),
      _weightLogRepo.pullSince(epoch, userId),
      _sleepLogRepo.pullSince(epoch, userId),
      _bloodPressureLogRepo.pullSince(epoch, userId),
      _reminderRepo.pullSince(epoch, userId),
    ]);

    // 3. Write pulled records to Isar with isDirty = false.
    await _isar.writeTxn(() async {
      await _isar.injectionLogs.putAll(results[0] as List<InjectionLog>);
      await _isar.peptides.putAll(results[1] as List<Peptide>);
      await _isar.weightLogs.putAll(results[2] as List<WeightLog>);
      await _isar.sleepLogs.putAll(results[3] as List<SleepLog>);
      await _isar.bloodPressureLogs
          .putAll(results[4] as List<BloodPressureLog>);
      await _isar.reminders.putAll(results[5] as List<Reminder>);
    });

    // 4. Mark setup done.
    final now = DateTime.now().toUtc();
    await Future.wait([
      _prefs.setBool(_kFirstSyncDoneKey, true),
      _setLastSyncAt(now),
    ]);
  }

  Future<void> syncInjectionLogs(String userId) async {
    final lastSync = _lastSyncAt;
    final dirty = await _isar.injectionLogs
        .filter()
        .isDirtyEqualTo(true)
        .findAll();
    await _injectionLogRepo.pushDirty(dirty);
    final remote = await _injectionLogRepo.pullSince(lastSync, userId);
    await _mergeInjectionLogs(dirty, remote);
  }

  Future<void> syncPeptides(String userId) async {
    final lastSync = _lastSyncAt;
    final dirty =
        await _isar.peptides.filter().isDirtyEqualTo(true).findAll();
    await _peptideRepo.pushDirty(dirty);
    final remote = await _peptideRepo.pullSince(lastSync, userId);
    await _mergePeptides(dirty, remote);
  }

  Future<void> syncWeightLogs(String userId) async {
    final lastSync = _lastSyncAt;
    final dirty =
        await _isar.weightLogs.filter().isDirtyEqualTo(true).findAll();
    await _weightLogRepo.pushDirty(dirty);
    final remote = await _weightLogRepo.pullSince(lastSync, userId);
    await _mergeWeightLogs(dirty, remote);
  }

  Future<void> syncSleepLogs(String userId) async {
    final lastSync = _lastSyncAt;
    final dirty =
        await _isar.sleepLogs.filter().isDirtyEqualTo(true).findAll();
    await _sleepLogRepo.pushDirty(dirty);
    final remote = await _sleepLogRepo.pullSince(lastSync, userId);
    await _mergeSleepLogs(dirty, remote);
  }

  Future<void> syncBloodPressureLogs(String userId) async {
    final lastSync = _lastSyncAt;
    final dirty = await _isar.bloodPressureLogs
        .filter()
        .isDirtyEqualTo(true)
        .findAll();
    await _bloodPressureLogRepo.pushDirty(dirty);
    final remote = await _bloodPressureLogRepo.pullSince(lastSync, userId);
    await _mergeBloodPressureLogs(dirty, remote);
  }

  Future<void> syncReminders(String userId) async {
    final lastSync = _lastSyncAt;
    final dirty =
        await _isar.reminders.filter().isDirtyEqualTo(true).findAll();
    await _reminderRepo.pushDirty(dirty);
    final remote = await _reminderRepo.pullSince(lastSync, userId);
    await _mergeReminders(dirty, remote);
  }

  // ---------------------------------------------------------------------------
  // Merge helpers (last-write-wins)
  // ---------------------------------------------------------------------------

  Future<void> _mergeInjectionLogs(
    List<InjectionLog> pushed,
    List<InjectionLog> remote,
  ) async {
    await _isar.writeTxn(() async {
      // Clear dirty flags on pushed records (supabaseId assigned by push).
      for (final r in pushed) {
        r.isDirty = false;
        await _isar.injectionLogs.put(r);
      }
      // Merge remote records.
      for (final rem in remote) {
        if (rem.supabaseId == null) continue;
        final local = await _isar.injectionLogs
            .filter()
            .supabaseIdEqualTo(rem.supabaseId)
            .findFirst();
        if (local == null || rem.updatedAt.isAfter(local.updatedAt)) {
          rem
            ..id = local?.id ?? Isar.autoIncrement
            ..isDirty = false;
          await _isar.injectionLogs.put(rem);
        }
      }
    });
  }

  Future<void> _mergePeptides(
    List<Peptide> pushed,
    List<Peptide> remote,
  ) async {
    await _isar.writeTxn(() async {
      for (final r in pushed) {
        r.isDirty = false;
        await _isar.peptides.put(r);
      }
      for (final rem in remote) {
        if (rem.supabaseId == null) continue;
        final local = await _isar.peptides
            .filter()
            .supabaseIdEqualTo(rem.supabaseId)
            .findFirst();
        if (local == null || rem.updatedAt.isAfter(local.updatedAt)) {
          rem
            ..id = local?.id ?? Isar.autoIncrement
            ..isDirty = false;
          await _isar.peptides.put(rem);
        }
      }
    });
  }

  Future<void> _mergeWeightLogs(
    List<WeightLog> pushed,
    List<WeightLog> remote,
  ) async {
    await _isar.writeTxn(() async {
      for (final r in pushed) {
        r.isDirty = false;
        await _isar.weightLogs.put(r);
      }
      for (final rem in remote) {
        if (rem.supabaseId == null) continue;
        final local = await _isar.weightLogs
            .filter()
            .supabaseIdEqualTo(rem.supabaseId)
            .findFirst();
        if (local == null || rem.updatedAt.isAfter(local.updatedAt)) {
          rem
            ..id = local?.id ?? Isar.autoIncrement
            ..isDirty = false;
          await _isar.weightLogs.put(rem);
        }
      }
    });
  }

  Future<void> _mergeSleepLogs(
    List<SleepLog> pushed,
    List<SleepLog> remote,
  ) async {
    await _isar.writeTxn(() async {
      for (final r in pushed) {
        r.isDirty = false;
        await _isar.sleepLogs.put(r);
      }
      for (final rem in remote) {
        if (rem.supabaseId == null) continue;
        final local = await _isar.sleepLogs
            .filter()
            .supabaseIdEqualTo(rem.supabaseId)
            .findFirst();
        if (local == null || rem.updatedAt.isAfter(local.updatedAt)) {
          rem
            ..id = local?.id ?? Isar.autoIncrement
            ..isDirty = false;
          await _isar.sleepLogs.put(rem);
        }
      }
    });
  }

  Future<void> _mergeBloodPressureLogs(
    List<BloodPressureLog> pushed,
    List<BloodPressureLog> remote,
  ) async {
    await _isar.writeTxn(() async {
      for (final r in pushed) {
        r.isDirty = false;
        await _isar.bloodPressureLogs.put(r);
      }
      for (final rem in remote) {
        if (rem.supabaseId == null) continue;
        final local = await _isar.bloodPressureLogs
            .filter()
            .supabaseIdEqualTo(rem.supabaseId)
            .findFirst();
        if (local == null || rem.updatedAt.isAfter(local.updatedAt)) {
          rem
            ..id = local?.id ?? Isar.autoIncrement
            ..isDirty = false;
          await _isar.bloodPressureLogs.put(rem);
        }
      }
    });
  }

  Future<void> _mergeReminders(
    List<Reminder> pushed,
    List<Reminder> remote,
  ) async {
    await _isar.writeTxn(() async {
      for (final r in pushed) {
        r.isDirty = false;
        await _isar.reminders.put(r);
      }
      for (final rem in remote) {
        if (rem.supabaseId == null) continue;
        final local = await _isar.reminders
            .filter()
            .supabaseIdEqualTo(rem.supabaseId)
            .findFirst();
        if (local == null || rem.updatedAt.isAfter(local.updatedAt)) {
          rem
            ..id = local?.id ?? Isar.autoIncrement
            ..isDirty = false;
          await _isar.reminders.put(rem);
        }
      }
    });
  }
}
