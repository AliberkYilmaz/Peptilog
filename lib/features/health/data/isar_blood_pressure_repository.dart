import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/blood_pressure_log.dart';
import 'blood_pressure_repository.dart';

class IsarBloodPressureRepository implements BloodPressureRepository {
  IsarBloodPressureRepository(this._isar);

  final Isar _isar;

  @override
  Future<int> save(BloodPressureLog log) {
    log.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.bloodPressureLogs.put(log));
  }

  @override
  Future<BloodPressureLog?> findById(int id) =>
      _isar.bloodPressureLogs.get(id);

  @override
  Future<List<BloodPressureLog>> listAll() =>
      _isar.bloodPressureLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Stream<List<BloodPressureLog>> watchAll() =>
      _isar.bloodPressureLogs
          .filter()
          .isDeletedEqualTo(false)
          .watch(fireImmediately: true);

  @override
  Future<void> delete(int id) async {
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
}

final bloodPressureRepositoryProvider =
    FutureProvider<BloodPressureRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarBloodPressureRepository(isar);
});
