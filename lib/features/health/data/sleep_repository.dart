import '../domain/sleep_log.dart';

abstract class SleepRepository {
  Future<int> save(SleepLog log);
  Future<SleepLog?> findById(int id);
  Future<List<SleepLog>> listAll();
  Stream<List<SleepLog>> watchAll();

  /// Soft delete: sets [isDeleted] = true and updates [updatedAt].
  Future<void> delete(int id);
}
