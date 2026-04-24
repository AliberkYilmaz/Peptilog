import '../domain/peptide.dart';

abstract class PeptideRepository {
  Future<List<Peptide>> getAll();
  Future<List<Peptide>> getActive();
  Future<Peptide?> getById(int id);
  Future<int> save(Peptide peptide);
  Future<void> delete(int id);
  Stream<List<Peptide>> watchAll();
}
