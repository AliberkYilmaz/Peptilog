import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/peptide.dart';
import 'peptide_repository.dart';

class IsarPeptideRepository implements PeptideRepository {
  final Isar _isar;
  const IsarPeptideRepository(this._isar);

  @override
  Future<List<Peptide>> getAll() => _isar.peptides.where().findAll();

  @override
  Future<List<Peptide>> getActive() =>
      _isar.peptides.filter().isActiveEqualTo(true).findAll();

  @override
  Future<Peptide?> getById(int id) => _isar.peptides.get(id);

  @override
  Future<int> save(Peptide peptide) =>
      _isar.writeTxn(() => _isar.peptides.put(peptide));

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.peptides.delete(id));
  }

  @override
  Stream<List<Peptide>> watchAll() =>
      _isar.peptides.where().watch(fireImmediately: true);
}

final peptideRepositoryProvider = FutureProvider<PeptideRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return IsarPeptideRepository(isar);
});
