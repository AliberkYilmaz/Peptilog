import 'package:isar/isar.dart';

import '../domain/peptide.dart';
import 'peptide_repository.dart';

class IsarPeptideRepository implements PeptideRepository {
  final Isar _isar;
  final void Function()? _onMutated;

  const IsarPeptideRepository(this._isar, {void Function()? onMutated})
      : _onMutated = onMutated;

  @override
  Future<List<Peptide>> getAll() => _isar.peptides.where().findAll();

  @override
  Future<List<Peptide>> getActive() =>
      _isar.peptides.filter().isActiveEqualTo(true).findAll();

  @override
  Future<Peptide?> getById(int id) => _isar.peptides.get(id);

  @override
  Future<int> save(Peptide peptide) async {
    final result = await _isar.writeTxn(() => _isar.peptides.put(peptide));
    _onMutated?.call();
    return result;
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.peptides.delete(id));
    _onMutated?.call();
  }

  @override
  Stream<List<Peptide>> watchAll() =>
      _isar.peptides.where().watch(fireImmediately: true);
}
