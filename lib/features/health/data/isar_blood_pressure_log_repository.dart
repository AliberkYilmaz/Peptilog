import 'package:isar/isar.dart';

import '../domain/blood_pressure_log.dart';
import 'blood_pressure_log_repository.dart';

class IsarBloodPressureLogRepository implements BloodPressureLogRepository {
  final Isar _isar;
  const IsarBloodPressureLogRepository(this._isar);

  @override
  Future<List<BloodPressureLog>> getAll() =>
      _isar.bloodPressureLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<List<BloodPressureLog>> getRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _isar.bloodPressureLogs
        .filter()
        .isDeletedEqualTo(false)
        .measuredAtGreaterThan(cutoff)
        .findAll();
  }

  @override
  Future<BloodPressureLog?> getById(int id) => _isar.bloodPressureLogs.get(id);

  @override
  Future<int> save(BloodPressureLog log) =>
      _isar.writeTxn(() => _isar.bloodPressureLogs.put(log));

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.bloodPressureLogs.get(id);
      if (log != null) {
        log.isDeleted = true;
        log.updatedAt = DateTime.now();
        await _isar.bloodPressureLogs.put(log);
      }
    });
  }

  @override
  Stream<List<BloodPressureLog>> watchRecent(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _isar.bloodPressureLogs
        .filter()
        .isDeletedEqualTo(false)
        .measuredAtGreaterThan(cutoff)
        .watch(fireImmediately: true);
  }
}
