import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/weight_log.dart';
import 'weight_repository.dart';

class IsarWeightRepository implements WeightRepository {
  IsarWeightRepository(this._isar);

  final Isar _isar;

  @override
  Future<int> save(WeightLog log) {
    log.updatedAt = DateTime.now();
    return _isar.writeTxn(() => _isar.weightLogs.put(log));
  }

  @override
  Future<WeightLog?> findById(int id) => _isar.weightLogs.get(id);

  @override
  Future<List<WeightLog>> listAll() =>
      _isar.weightLogs.filter().isDeletedEqualTo(false).findAll();

  @override
  Stream<List<WeightLog>> watchAll() =>
      _isar.weightLogs
          .filter()
          .isDeletedEqualTo(false)
          .watch(fireImmediately: true);

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      final log = await _isar.weightLogs.get(id);
      if (log != null) {
        log
          ..isDeleted = true
          ..updatedAt = DateTime.now();
        await _isar.weightLogs.put(log);
      }
    });
  }
}

final weightRepositoryProvider =
    FutureProvider<WeightRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarWeightRepository(isar);
});
