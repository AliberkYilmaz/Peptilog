import 'package:isar/isar.dart';

import '../domain/sleep_log.dart';
import 'sleep_log_repository.dart';

class IsarSleepLogRepository implements SleepLogRepository {
  final Isar _isar;
  final void Function()? _onMutated;
  final String? Function()? _getCurrentUserId;

  const IsarSleepLogRepository(
    this._isar, {
    void Function()? onMutated,
    String? Function()? getCurrentUserId,
  })  : _onMutated = onMutated,
        _getCurrentUserId = getCurrentUserId;

  @override
  Future<List<SleepLog>> getAll() =>
      _isar.sleepLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<SleepLog?> getById(int id) => _isar.sleepLogs.get(id);

  @override
  Future<int> save(SleepLog log) async {
    log
      ..userId ??= _getCurrentUserId?.call()
      ..updatedAt = DateTime.now();
    final result = await _isar.writeTxn(() => _isar.sleepLogs.put(log));
    _onMutated?.call();
    return result;
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
    _onMutated?.call();
  }

  @override
  Stream<List<SleepLog>> watchAll() => _isar.sleepLogs
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
}
