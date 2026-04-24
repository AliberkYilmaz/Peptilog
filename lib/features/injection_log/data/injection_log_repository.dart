import '../domain/injection_log.dart';

abstract class InjectionLogRepository {
  Future<List<InjectionLog>> getAll();
  Future<List<InjectionLog>> getByDate(DateTime date);
  Future<List<InjectionLog>> getByDateRange(DateTime from, DateTime to);
  Future<InjectionLog?> getById(int id);
  Future<int> save(InjectionLog log);
  Future<void> softDelete(int id);
  Stream<List<InjectionLog>> watchAll();
  Stream<List<InjectionLog>> watchByDate(DateTime date);
}
