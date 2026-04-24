import '../domain/blood_pressure_log.dart';

abstract class BloodPressureRepository {
  Future<int> save(BloodPressureLog log);
  Future<BloodPressureLog?> findById(int id);
  Future<List<BloodPressureLog>> listAll();
  Stream<List<BloodPressureLog>> watchAll();

  /// Soft delete: sets [isDeleted] = true and updates [updatedAt].
  Future<void> delete(int id);
}
