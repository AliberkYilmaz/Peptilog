import 'package:isar/isar.dart';

import '../domain/weight_log.dart';
import 'weight_log_repository.dart';

class IsarWeightLogRepository implements WeightLogRepository {
  final Isar _isar;
  final void Function()? _onMutated;
  final String? Function()? _getCurrentUserId;

  const IsarWeightLogRepository(
    this._isar, {
    void Function()? onMutated,
    String? Function()? getCurrentUserId,
  })  : _onMutated = onMutated,
        _getCurrentUserId = getCurrentUserId;

  @override
  Future<List<WeightLog>> getAll() =>
      _isar.weightLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<WeightLog?> getById(int id) => _isar.weightLogs.get(id);

  @override
  Future<int> save(WeightLog log) async {
    log
      ..userId ??= _getCurrentUserId?.call()
      ..updatedAt = DateTime.now();
    final result = await _isar.writeTxn(() => _isar.weightLogs.put(log));
    _onMutated?.call();
    return result;
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
    _onMutated?.call();
  }

  @override
  Stream<List<WeightLog>> watchAll() => _isar.weightLogs
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
}
