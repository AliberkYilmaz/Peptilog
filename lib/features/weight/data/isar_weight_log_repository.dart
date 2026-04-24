import 'package:isar/isar.dart';

import '../domain/weight_log.dart';
import 'weight_log_repository.dart';

class IsarWeightLogRepository implements WeightLogRepository {
  final Isar _isar;
  const IsarWeightLogRepository(this._isar);

  @override
  Future<List<WeightLog>> getAll() =>
      _isar.weightLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<List<WeightLog>> getRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _isar.weightLogs
        .filter()
        .isDeletedEqualTo(false)
        .dateGreaterThan(cutoff)
        .findAll();
  }

  @override
  Future<WeightLog?> getByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _isar.weightLogs
        .filter()
        .isDeletedEqualTo(false)
        .dateBetween(dayStart, dayEnd)
        .findFirst();
  }

  @override
  Future<WeightLog?> getById(int id) => _isar.weightLogs.get(id);

  @override
  Future<int> save(WeightLog log) =>
      _isar.writeTxn(() => _isar.weightLogs.put(log));

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.weightLogs.get(id);
      if (log != null) {
        log.isDeleted = true;
        log.updatedAt = DateTime.now();
        await _isar.weightLogs.put(log);
      }
    });
  }

  @override
  Stream<List<WeightLog>> watchRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _isar.weightLogs
        .filter()
        .isDeletedEqualTo(false)
        .dateGreaterThan(cutoff)
        .watch(fireImmediately: true);
  }
}
