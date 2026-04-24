import '../domain/sleep_log.dart';

abstract class SleepLogRepository {
  Future<List<SleepLog>> getAll();
  Future<List<SleepLog>> getRecent(int days);
  Future<SleepLog?> getByDate(DateTime date);
  Future<SleepLog?> getById(int id);
  Future<int> save(SleepLog log);
  Future<void> softDelete(int id);
  Stream<List<SleepLog>> watchRecent(int days);
}
