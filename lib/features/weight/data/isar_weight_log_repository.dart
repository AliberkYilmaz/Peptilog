import 'package:isar/isar.dart';

import '../domain/weight_log.dart';
import 'weight_log_repository.dart';

class IsarWeightLogRepository implements WeightLogRepository {
  const IsarWeightLogRepository(this._isar);
  final Isar _isar;

  @override
  Future<List<WeightLog>> getAll() =>
      _isar.weightLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<WeightLog?> getById(int id) => _isar.weightLogs.get(id);

  @override
  Future<int> save(WeightLog log) {
    log.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.weightLogs.put(log));
  }

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.weightLogs.get(id);
      if (log != null) {
        log
          ..isDeleted = true
          ..updatedAt = DateTime.now();
        await _isar.weightLogs.put(log);
      }
    });
  }

  @override
  Stream<List<WeightLog>> watchAll() => _isar.weightLogs
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
}
