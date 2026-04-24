import 'package:isar/isar.dart';

import '../domain/blood_pressure_log.dart';
import 'blood_pressure_log_repository.dart';

class IsarBloodPressureLogRepository implements BloodPressureLogRepository {
  const IsarBloodPressureLogRepository(this._isar);
  final Isar _isar;

  @override
  Future<List<BloodPressureLog>> getAll() =>
      _isar.bloodPressureLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<BloodPressureLog?> getById(int id) => _isar.bloodPressureLogs.get(id);

  @override
  Future<int> save(BloodPressureLog log) {
    log.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.bloodPressureLogs.put(log));
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
  }

  @override
  Stream<List<BloodPressureLog>> watchAll() => _isar.bloodPressureLogs
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
}
