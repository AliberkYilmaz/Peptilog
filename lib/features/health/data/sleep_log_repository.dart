import '../domain/sleep_log.dart';

abstract class SleepLogRepository {
  Future<List<SleepLog>> getAll();
  Future<SleepLog?> getById(int id);
  Future<int> save(SleepLog log);
  Future<void> softDelete(int id);
  Stream<List<SleepLog>> watchAll();
}
