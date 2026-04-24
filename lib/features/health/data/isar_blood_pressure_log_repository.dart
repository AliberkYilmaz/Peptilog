import 'package:isar/isar.dart';

import '../domain/blood_pressure_log.dart';
import 'blood_pressure_log_repository.dart';

class IsarBloodPressureLogRepository implements BloodPressureLogRepository {
  final Isar _isar;
  final void Function()? _onMutated;

  const IsarBloodPressureLogRepository(this._isar, {void Function()? onMutated})
      : _onMutated = onMutated;

  @override
  Future<List<BloodPressureLog>> getAll() =>
      _isar.bloodPressureLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<BloodPressureLog?> getById(int id) => _isar.bloodPressureLogs.get(id);

  @override
  Future<int> save(BloodPressureLog log) async {
    log.updatedAt = DateTime.now();
    final result =
        await _isar.writeTxn(() => _isar.bloodPressureLogs.put(log));
    _onMutated?.call();
    return result;
  }

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.bloodPressureLogs.get(id);
      if (log != null) {
        log
          ..isDeleted = true
          ..updatedAt = DateTime.now();
        await _isar.bloodPressureLogs.put(log);
      }
    });
    _onMutated?.call();
  }

  @override
  Stream<List<BloodPressureLog>> watchAll() => _isar.bloodPressureLogs
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
}
