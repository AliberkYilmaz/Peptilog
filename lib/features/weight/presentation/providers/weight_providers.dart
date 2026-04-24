import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../domain/weight_log.dart';

/// Reactive stream of all non-deleted weight logs, newest-first.
final weightLogsProvider = StreamProvider<List<WeightLog>>((ref) {
  final repo = ref.watch(weightLogRepositoryProvider);
  return repo.watchAll().map(
    (logs) => logs..sort((a, b) => b.date.compareTo(a.date)),
  );
});

/// Last 30 days of weight logs in ascending date order (for the chart).
final weightLogs30DayProvider = Provider<List<WeightLog>>((ref) {
  final logsAsync = ref.watch(weightLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      return logs
          .where((l) => l.date.isAfter(cutoff))
          .toList()
          .reversed
          .toList();
    },
    orElse: () => [],
  );
});

/// The most-recent weight log entry (for the large display number).
final latestWeightProvider = Provider<WeightLog?>((ref) {
  final logsAsync = ref.watch(weightLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) => logs.isEmpty ? null : logs.first,
    orElse: () => null,
  );
});

// ---------------------------------------------------------------------------
// Goal weight — stored in-memory (persisted across builds via keepAlive).
// ---------------------------------------------------------------------------

class GoalWeightNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  void set(double? kg) => state = kg;
}

final goalWeightProvider = NotifierProvider<GoalWeightNotifier, double?>(
  GoalWeightNotifier.new,
);

// ---------------------------------------------------------------------------
// Weight entry form state.
// ---------------------------------------------------------------------------

class WeightFormState {
  const WeightFormState({
    this.weightText = '',
    this.selectedDate,
    this.isSaving = false,
    this.saved = false,
    this.errorMessage,
  });

  final String weightText;
  final DateTime? selectedDate;
  final bool isSaving;
  final bool saved;
  final String? errorMessage;

  DateTime get effectiveDate => selectedDate ?? _today();

  WeightFormState copyWith({
    String? weightText,
    Object? selectedDate = _sentinel,
    bool? isSaving,
    bool? saved,
    Object? errorMessage = _sentinel,
  }) {
    return WeightFormState(
      weightText: weightText ?? this.weightText,
      selectedDate: selectedDate == _sentinel
          ? this.selectedDate
          : selectedDate as DateTime?,
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

const Object _sentinel = Object();

class WeightFormNotifier extends AutoDisposeNotifier<WeightFormState> {
  @override
  WeightFormState build() => const WeightFormState();

  void setWeight(String value) =>
      state = state.copyWith(weightText: value, errorMessage: null);

  void setDate(DateTime date) =>
      state = state.copyWith(selectedDate: date, errorMessage: null);

  Future<void> save() async {
    final kg = double.tryParse(state.weightText.replaceAll(',', '.'));
    if (kg == null || kg <= 0 || kg > 500) {
      state = state.copyWith(errorMessage: 'invalidWeight');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final selectedDay = state.effectiveDate;

    // Check for duplicate entry on this date.
    final existing = await ref.read(weightLogRepositoryProvider).getAll();
    final duplicate = existing.any(
      (l) =>
          l.date.year == selectedDay.year &&
          l.date.month == selectedDay.month &&
          l.date.day == selectedDay.day,
    );
    if (duplicate) {
      state = state.copyWith(isSaving: false, errorMessage: 'duplicateDate');
      return;
    }

    final log = WeightLog()
      ..weightKg = kg
      ..date = selectedDay;

    await ref.read(weightLogRepositoryProvider).save(log);
    state = state.copyWith(isSaving: false, saved: true);
  }

  void reset() => state = const WeightFormState();
}

final weightFormProvider =
    AutoDisposeNotifierProvider<WeightFormNotifier, WeightFormState>(
      WeightFormNotifier.new,
    );
