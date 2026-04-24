import '../domain/weight_log.dart';

abstract class WeightRepository {
  Future<int> save(WeightLog log);
  Future<WeightLog?> findById(int id);
  Future<List<WeightLog>> listAll();
  Stream<List<WeightLog>> watchAll();

  /// Soft delete: sets [isDeleted] = true and updates [updatedAt].
  Future<void> delete(int id);
}
