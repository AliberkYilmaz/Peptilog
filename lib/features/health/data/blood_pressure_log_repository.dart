import '../domain/blood_pressure_log.dart';

abstract class BloodPressureLogRepository {
  Future<List<BloodPressureLog>> getAll();
  Future<List<BloodPressureLog>> getRecent(int days);
  Future<BloodPressureLog?> getById(int id);
  Future<int> save(BloodPressureLog log);
  Future<void> softDelete(int id);
  Stream<List<BloodPressureLog>> watchRecent(int days);
}
