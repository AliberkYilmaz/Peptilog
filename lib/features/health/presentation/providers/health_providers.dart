import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../domain/blood_pressure_log.dart';
import '../../domain/sleep_log.dart';

// ---------------------------------------------------------------------------
// Sleep providers
// ---------------------------------------------------------------------------

/// Reactive stream of all non-deleted sleep logs, newest-first.
final sleepLogsProvider = StreamProvider<List<SleepLog>>((ref) {
  final repo = ref.watch(sleepLogRepositoryProvider);
  return repo.watchAll().map(
    (logs) => logs..sort((a, b) => b.date.compareTo(a.date)),
  );
});

/// Last 30 days of sleep logs in ascending date order (for the chart).
final sleepLogs30DayProvider = Provider<List<SleepLog>>((ref) {
  final logsAsync = ref.watch(sleepLogsProvider);
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

/// The most-recent sleep log (for the hero display).
final latestSleepProvider = Provider<SleepLog?>((ref) {
  final logsAsync = ref.watch(sleepLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) => logs.isEmpty ? null : logs.first,
    orElse: () => null,
  );
});

// ---------------------------------------------------------------------------
// Sleep entry form
// ---------------------------------------------------------------------------

class SleepFormState {
  const SleepFormState({
    this.hoursText = '',
    this.qualityRating,
    this.selectedDate,
    this.isSaving = false,
    this.saved = false,
    this.errorMessage,
  });

  final String hoursText;
  final int? qualityRating;
  final DateTime? selectedDate;
  final bool isSaving;
  final bool saved;
  final String? errorMessage;

  DateTime get effectiveDate {
    final now = DateTime.now();
    return selectedDate ?? DateTime(now.year, now.month, now.day);
  }

  SleepFormState copyWith({
    String? hoursText,
    Object? qualityRating = _sentinel,
    Object? selectedDate = _sentinel,
    bool? isSaving,
    bool? saved,
    Object? errorMessage = _sentinel,
  }) {
    return SleepFormState(
      hoursText: hoursText ?? this.hoursText,
      qualityRating: qualityRating == _sentinel
          ? this.qualityRating
          : qualityRating as int?,
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

class SleepFormNotifier extends AutoDisposeNotifier<SleepFormState> {
  @override
  SleepFormState build() => const SleepFormState();

  void setHours(String value) =>
      state = state.copyWith(hoursText: value, errorMessage: null);

  void setQuality(int rating) =>
      state = state.copyWith(qualityRating: rating, errorMessage: null);

  void setDate(DateTime date) =>
      state = state.copyWith(selectedDate: date, errorMessage: null);

  Future<void> save() async {
    final hours = double.tryParse(state.hoursText.replaceAll(',', '.'));
    if (hours == null || hours < 0.5 || hours > 24) {
      state = state.copyWith(errorMessage: 'invalidHours');
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final log = SleepLog()
      ..hours = hours
      ..qualityRating = state.qualityRating
      ..date = state.effectiveDate;

    await ref.read(sleepLogRepositoryProvider).save(log);
    state = state.copyWith(isSaving: false, saved: true);
  }

  void reset() => state = const SleepFormState();
}

final sleepFormProvider =
    AutoDisposeNotifierProvider<SleepFormNotifier, SleepFormState>(
      SleepFormNotifier.new,
    );

// ---------------------------------------------------------------------------
// Blood pressure providers
// ---------------------------------------------------------------------------

/// Reactive stream of all non-deleted BP logs, newest-first.
final bloodPressureLogsProvider = StreamProvider<List<BloodPressureLog>>((ref) {
  final repo = ref.watch(bloodPressureLogRepositoryProvider);
  return repo.watchAll().map(
    (logs) => logs..sort((a, b) => b.measuredAt.compareTo(a.measuredAt)),
  );
});

/// Last 30 days of BP logs in ascending order (for the chart).
final bloodPressureLogs30DayProvider = Provider<List<BloodPressureLog>>((ref) {
  final logsAsync = ref.watch(bloodPressureLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      return logs
          .where((l) => l.measuredAt.isAfter(cutoff))
          .toList()
          .reversed
          .toList();
    },
    orElse: () => [],
  );
});

/// Most-recent BP log (for hero display).
final latestBloodPressureProvider = Provider<BloodPressureLog?>((ref) {
  final logsAsync = ref.watch(bloodPressureLogsProvider);
  return logsAsync.maybeWhen(
    data: (logs) => logs.isEmpty ? null : logs.first,
    orElse: () => null,
  );
});

// ---------------------------------------------------------------------------
// Blood pressure entry form
// ---------------------------------------------------------------------------

class BpFormState {
  const BpFormState({
    this.systolicText = '',
    this.diastolicText = '',
    this.pulseText = '',
    this.selectedDate,
    this.isSaving = false,
    this.saved = false,
    this.errorMessage,
  });

  final String systolicText;
  final String diastolicText;
  final String pulseText;
  final DateTime? selectedDate;
  final bool isSaving;
  final bool saved;
  final String? errorMessage;

  DateTime get effectiveDate {
    return selectedDate ?? DateTime.now();
  }

  BpFormState copyWith({
    String? systolicText,
    String? diastolicText,
    String? pulseText,
    Object? selectedDate = _sentinel,
    bool? isSaving,
    bool? saved,
    Object? errorMessage = _sentinel,
  }) {
    return BpFormState(
      systolicText: systolicText ?? this.systolicText,
      diastolicText: diastolicText ?? this.diastolicText,
      pulseText: pulseText ?? this.pulseText,
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

class BpFormNotifier extends AutoDisposeNotifier<BpFormState> {
  @override
  BpFormState build() => const BpFormState();

  void setSystolic(String value) =>
      state = state.copyWith(systolicText: value, errorMessage: null);

  void setDiastolic(String value) =>
      state = state.copyWith(diastolicText: value, errorMessage: null);

  void setPulse(String value) =>
      state = state.copyWith(pulseText: value, errorMessage: null);

  void setDate(DateTime date) =>
      state = state.copyWith(selectedDate: date, errorMessage: null);

  Future<void> save() async {
    final systolic = int.tryParse(state.systolicText.trim());
    if (systolic == null || systolic < 60 || systolic > 250) {
      state = state.copyWith(errorMessage: 'invalidSystolic');
      return;
    }
    final diastolic = int.tryParse(state.diastolicText.trim());
    if (diastolic == null || diastolic < 40 || diastolic > 150) {
      state = state.copyWith(errorMessage: 'invalidDiastolic');
      return;
    }
    final pulse = state.pulseText.trim().isEmpty
        ? null
        : int.tryParse(state.pulseText.trim());

    state = state.copyWith(isSaving: true, errorMessage: null);

    final log = BloodPressureLog()
      ..systolic = systolic
      ..diastolic = diastolic
      ..pulse = pulse
      ..measuredAt = state.effectiveDate;

    await ref.read(bloodPressureLogRepositoryProvider).save(log);
    state = state.copyWith(isSaving: false, saved: true);
  }

  void reset() => state = const BpFormState();
}

final bpFormProvider = AutoDisposeNotifierProvider<BpFormNotifier, BpFormState>(
  BpFormNotifier.new,
);

const Object _sentinel = Object();
