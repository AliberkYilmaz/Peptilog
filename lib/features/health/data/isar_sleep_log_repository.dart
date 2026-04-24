import 'package:isar/isar.dart';

import '../domain/sleep_log.dart';
import 'sleep_log_repository.dart';

class IsarSleepLogRepository implements SleepLogRepository {
  final Isar _isar;
  const IsarSleepLogRepository(this._isar);

  @override
  Future<List<SleepLog>> getAll() =>
      _isar.sleepLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<List<SleepLog>> getRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _isar.sleepLogs
        .filter()
        .isDeletedEqualTo(false)
        .dateGreaterThan(cutoff)
        .findAll();
  }

  @override
  Future<SleepLog?> getByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _isar.sleepLogs
        .filter()
        .isDeletedEqualTo(false)
        .dateBetween(dayStart, dayEnd)
        .findFirst();
  }

  @override
  Future<SleepLog?> getById(int id) => _isar.sleepLogs.get(id);

  @override
  Future<int> save(SleepLog log) =>
      _isar.writeTxn(() => _isar.sleepLogs.put(log));

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.sleepLogs.get(id);
      if (log != null) {
        log.isDeleted = true;
        log.updatedAt = DateTime.now();
        await _isar.sleepLogs.put(log);
      }
    });
  }

  @override
  Stream<List<SleepLog>> watchRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _isar.sleepLogs
        .filter()
        .isDeletedEqualTo(false)
        .dateGreaterThan(cutoff)
        .watch(fireImmediately: true);
  }
}
