import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../peptides/domain/peptide.dart';
import '../../domain/reminder.dart';

/// Reactive stream of all reminders (including soft-deleted for sync purposes).
/// UI should filter with `where((r) => !r.isDeleted)`.
final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchAll();
});

/// Reactive stream of active (non-deleted) peptides — used to populate the
/// reminder form's peptide selector.
final activePeptidesProvider = StreamProvider<List<Peptide>>((ref) {
  return ref
      .watch(peptideRepositoryProvider)
      .watchAll()
      .map((list) => list.where((p) => p.isActive && !p.isDeleted).toList());
});
