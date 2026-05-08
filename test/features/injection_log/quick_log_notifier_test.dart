import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:peptilog_app/core/providers/database_providers.dart';
import 'package:peptilog_app/features/injection_log/data/injection_log_repository.dart';
import 'package:peptilog_app/features/injection_log/domain/injection_log.dart';
import 'package:peptilog_app/features/peptides/data/peptide_repository.dart';
import 'package:peptilog_app/features/peptides/domain/peptide.dart';
import 'package:peptilog_app/features/injection_log/presentation/providers/quick_log_notifier.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeInjectionLogRepository implements InjectionLogRepository {
  final List<InjectionLog> saved = [];

  @override
  Future<int> save(InjectionLog log) async {
    saved.add(log);
    return saved.length;
  }

  @override
  Future<List<InjectionLog>> getAll() async => [];

  @override
  Future<List<InjectionLog>> getByDate(DateTime date) async => [];

  @override
  Future<List<InjectionLog>> getByDateRange(DateTime from, DateTime to) async =>
      [];

  @override
  Future<InjectionLog?> getById(int id) async => null;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Stream<List<InjectionLog>> watchAll() => const Stream.empty();

  @override
  Stream<List<InjectionLog>> watchByDate(DateTime date) => const Stream.empty();
}

class FakePeptideRepository implements PeptideRepository {
  @override
  Future<List<Peptide>> getAll() async => [];

  @override
  Future<List<Peptide>> getActive() async => [];

  @override
  Future<Peptide?> getById(int id) async => null;

  @override
  Future<int> save(Peptide peptide) async => 1;

  Future<void> softDelete(int id) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Stream<List<Peptide>> watchAll() => Stream.value([]);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Peptide _makePeptide({int id = 1, String name = 'BPC-157'}) {
  return Peptide()
    ..id = id
    ..name = name
    ..color = '#E8A84C'
    ..unit = 'mg'
    ..isActive = true;
}

ProviderContainer _makeContainer({
  FakeInjectionLogRepository? logRepo,
  FakePeptideRepository? peptideRepo,
}) {
  final lr = logRepo ?? FakeInjectionLogRepository();
  final pr = peptideRepo ?? FakePeptideRepository();
  return ProviderContainer(
    overrides: [
      injectionLogRepositoryProvider.overrideWithValue(lr),
      peptideRepositoryProvider.overrideWithValue(pr),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuickLogNotifier — validation', () {
    test('save() sets errorMessage to futureDate when loggedAt is in the future',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('0.5');
      notifier.setLoggedAt(DateTime.now().add(const Duration(hours: 1)));

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.errorMessage, 'futureDate');
      expect(state.saved, isFalse);
      expect(state.isSaving, isFalse);
    });

    test('save() with no peptide sets errorMessage to selectPeptide', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.setDose('0.5');

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.errorMessage, 'selectPeptide');
      expect(state.saved, isFalse);
      expect(state.isSaving, isFalse);
    });

    test('save() with empty dose sets errorMessage to invalidDose', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      // dose is '' (default)

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.errorMessage, 'invalidDose');
      expect(state.saved, isFalse);
    });

    test('save() with dose of zero sets errorMessage to invalidDose', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('0');

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.errorMessage, 'invalidDose');
      expect(state.saved, isFalse);
    });

    test('save() with negative dose sets errorMessage to invalidDose', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('-1');

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.errorMessage, 'invalidDose');
      expect(state.saved, isFalse);
    });

    test('save() with non-numeric dose sets errorMessage to invalidDose',
        () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('abc');

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.errorMessage, 'invalidDose');
      expect(state.saved, isFalse);
    });
  });

  group('QuickLogNotifier — happy path', () {
    test('save() with valid inputs calls repo.save() and sets saved=true',
        () async {
      final logRepo = FakeInjectionLogRepository();
      final container = _makeContainer(logRepo: logRepo);
      addTearDown(container.dispose);

      final peptide = _makePeptide(id: 42);
      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(peptide);
      notifier.setDose('0.5');
      notifier.setRoute('IM');
      notifier.setNotes('Test note');

      await notifier.save();

      final state = container.read(quickLogProvider);
      expect(state.saved, isTrue);
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, isNull);

      expect(logRepo.saved, hasLength(1));
      final savedLog = logRepo.saved.first;
      expect(savedLog.peptideId, 42);
      expect(savedLog.doseMg, 0.5);
      expect(savedLog.route, 'IM');
      expect(savedLog.notes, 'Test note');
    });

    test('save() trims empty notes to null', () async {
      final logRepo = FakeInjectionLogRepository();
      final container = _makeContainer(logRepo: logRepo);
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('1.0');
      notifier.setNotes('   ');

      await notifier.save();

      expect(logRepo.saved.first.notes, isNull);
    });

    test('save() defaults route to SubQ', () async {
      final logRepo = FakeInjectionLogRepository();
      final container = _makeContainer(logRepo: logRepo);
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('0.25');

      await notifier.save();

      expect(logRepo.saved.first.route, 'SubQ');
    });

    test('reset() after save clears form to initial state', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      notifier.selectPeptide(_makePeptide());
      notifier.setDose('1.0');

      await notifier.save();
      notifier.reset();

      final state = container.read(quickLogProvider);
      expect(state.saved, isFalse);
      expect(state.selectedPeptide, isNull);
      expect(state.doseText, '');
      expect(state.route, 'SubQ');
      expect(state.notes, '');
    });
  });

  group('QuickLogNotifier — selectPeptide clears error', () {
    test('selecting a peptide clears existing error', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quickLogProvider.notifier);
      // Trigger error.
      await notifier.save();
      expect(container.read(quickLogProvider).errorMessage, 'selectPeptide');

      // Selecting a peptide should clear it.
      notifier.selectPeptide(_makePeptide());
      expect(container.read(quickLogProvider).errorMessage, isNull);
    });
  });
}
