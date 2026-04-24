import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/sleep_log.dart';
import 'sleep_repository.dart';

class IsarSleepRepository implements SleepRepository {
  IsarSleepRepository(this._isar);

  final Isar _isar;

  @override
  Future<int> save(SleepLog log) {
    log.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.sleepLogs.put(log));
  }

  @override
  Future<SleepLog?> findById(int id) => _isar.sleepLogs.get(id);

  @override
  Future<List<SleepLog>> listAll() =>
      _isar.sleepLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Stream<List<SleepLog>> watchAll() =>
      _isar.sleepLogs
          .filter()
          .isDeletedEqualTo(false)
          .watch(fireImmediately: true);

  @override
  Future<void> delete(int id) async {
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
}

final sleepRepositoryProvider =
    FutureProvider<SleepRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarSleepRepository(isar);
});
