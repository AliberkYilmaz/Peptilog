import 'package:isar/isar.dart';

import '../domain/sleep_log.dart';
import 'sleep_log_repository.dart';

class IsarSleepLogRepository implements SleepLogRepository {
  const IsarSleepLogRepository(this._isar);
  final Isar _isar;

  @override
  Future<List<SleepLog>> getAll() =>
      _isar.sleepLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<SleepLog?> getById(int id) => _isar.sleepLogs.get(id);

  @override
  Future<int> save(SleepLog log) {
    log.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.sleepLogs.put(log));
  }

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.sleepLogs.get(id);
      if (log != null) {
        log
          ..isDeleted = true
          ..updatedAt = DateTime.now();
        await _isar.sleepLogs.put(log);
      }
    });
  }

  @override
  Stream<List<SleepLog>> watchAll() => _isar.sleepLogs
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
}
