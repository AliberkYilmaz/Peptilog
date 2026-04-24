import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../peptides/domain/peptide.dart';
import '../../domain/injection_log.dart';

/// State for the Quick Log form.
class QuickLogState {
  final Peptide? selectedPeptide;
  final String doseText;
  final String route; // 'SubQ' or 'IM'
  final String notes;
  final DateTime loggedAt;
  final bool isSaving;
  final String? errorMessage;
  final bool saved;

  QuickLogState({
    this.selectedPeptide,
    this.doseText = '',
    this.route = 'SubQ',
    this.notes = '',
    DateTime? loggedAt,
    this.isSaving = false,
    this.errorMessage,
    this.saved = false,
  }) : loggedAt = loggedAt ?? DateTime.now();

  QuickLogState copyWith({
    Object? selectedPeptide = _sentinel,
    String? doseText,
    String? route,
    String? notes,
    DateTime? loggedAt,
    bool? isSaving,
    Object? errorMessage = _sentinel,
    bool? saved,
  }) {
    return QuickLogState(
      selectedPeptide: selectedPeptide == _sentinel
          ? this.selectedPeptide
          : selectedPeptide as Peptide?,
      doseText: doseText ?? this.doseText,
      route: route ?? this.route,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      saved: saved ?? this.saved,
    );
  }
}

// Sentinel for nullable copyWith fields.
const Object _sentinel = Object();

/// Provider for active peptides, updated reactively via Isar watch.
final activePeptidesProvider = StreamProvider<List<Peptide>>((ref) {
  final repo = ref.watch(peptideRepositoryProvider);
  return repo.watchAll().map((list) => list.where((p) => p.isActive).toList());
});

/// Notifier that manages Quick Log form state.
class QuickLogNotifier extends AutoDisposeNotifier<QuickLogState> {
  @override
  QuickLogState build() => QuickLogState();

  void selectPeptide(Peptide peptide) {
    state = state.copyWith(selectedPeptide: peptide, errorMessage: null);
  }

  void setDose(String value) {
    state = state.copyWith(doseText: value, errorMessage: null);
  }

  void setRoute(String route) {
    state = state.copyWith(route: route);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setLoggedAt(DateTime dt) {
    state = state.copyWith(loggedAt: dt);
  }

  /// Validates inputs, writes [InjectionLog] to Isar, and marks saved.
  Future<void> save() async {
    if (state.selectedPeptide == null) {
      state = state.copyWith(errorMessage: 'selectPeptide');
      return;
    }
    final dose = double.tryParse(state.doseText);
    if (dose == null || dose <= 0) {
      state = state.copyWith(errorMessage: 'invalidDose');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final log = InjectionLog()
      ..peptideId = state.selectedPeptide!.id
      ..doseMg = dose
      ..route = state.route
      ..notes = state.notes.trim().isEmpty ? null : state.notes.trim()
      ..loggedAt = state.loggedAt;

    await ref.read(injectionLogRepositoryProvider).save(log);

    state = state.copyWith(isSaving: false, saved: true);
  }

  /// Resets form to initial state (call after save confirmation shown).
  void reset() {
    state = QuickLogState();
  }
}

final quickLogProvider =
    AutoDisposeNotifierProvider<QuickLogNotifier, QuickLogState>(
      QuickLogNotifier.new,
    );
