import '../domain/weight_log.dart';

abstract class WeightLogRepository {
  Future<List<WeightLog>> getAll();
  Future<List<WeightLog>> getRecent(int days);
  Future<WeightLog?> getByDate(DateTime date);
  Future<WeightLog?> getById(int id);
  Future<int> save(WeightLog log);
  Future<void> softDelete(int id);
  Stream<List<WeightLog>> watchRecent(int days);
}
