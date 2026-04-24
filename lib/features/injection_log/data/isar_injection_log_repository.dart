import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/injection_log.dart';
import 'injection_log_repository.dart';

class IsarInjectionLogRepository implements InjectionLogRepository {
  final Isar _isar;
  const IsarInjectionLogRepository(this._isar);

  @override
  Future<List<InjectionLog>> getAll() =>
      _isar.injectionLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Future<List<InjectionLog>> getByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _isar.injectionLogs
        .filter()
        .isDeletedEqualTo(false)
        .loggedAtBetween(start, end)
        .findAll();
  }

  @override
  Future<List<InjectionLog>> getByDateRange(DateTime from, DateTime to) =>
      _isar.injectionLogs
          .filter()
          .isDeletedEqualTo(false)
          .loggedAtBetween(from, to)
          .findAll();

  @override
  Future<InjectionLog?> getById(int id) => _isar.injectionLogs.get(id);

  @override
  Future<int> save(InjectionLog log) =>
      _isar.writeTxn(() => _isar.injectionLogs.put(log));

  @override
  Future<void> softDelete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.injectionLogs.get(id);
      if (log != null) {
        log.isDeleted = true;
        log.updatedAt = DateTime.now();
        await _isar.injectionLogs.put(log);
      }
    });
  }

  @override
  Stream<List<InjectionLog>> watchAll() =>
      _isar.injectionLogs.filter().isDeletedEqualTo(false).watch(fireImmediately: true);

  @override
  Stream<List<InjectionLog>> watchByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _isar.injectionLogs
        .filter()
        .isDeletedEqualTo(false)
        .loggedAtBetween(start, end)
        .watch(fireImmediately: true);
  }
}

final injectionLogRepositoryProvider =
    FutureProvider<InjectionLogRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarInjectionLogRepository(isar);
});
