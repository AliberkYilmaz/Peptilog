import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../features/peptides/data/peptide_repository.dart';
import '../../features/peptides/data/isar_peptide_repository.dart';
import '../../features/injection_log/data/injection_log_repository.dart';
import '../../features/injection_log/data/isar_injection_log_repository.dart';
import '../../features/weight/data/weight_log_repository.dart'
    show WeightLogRepository;
import '../../features/weight/data/isar_weight_log_repository.dart';
import '../../features/health/data/sleep_log_repository.dart'
    show SleepLogRepository;
import '../../features/health/data/isar_sleep_log_repository.dart';
import '../../features/health/data/blood_pressure_log_repository.dart'
    show BloodPressureLogRepository;
import '../../features/health/data/isar_blood_pressure_log_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/data/isar_reminder_repository.dart';
import 'sync_providers.dart';

/// The Isar database instance. Must be overridden in ProviderScope
/// after [IsarDatabase.open()] resolves at app startup.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'isarProvider must be overridden in ProviderScope after DB init',
  );
});

final peptideRepositoryProvider = Provider<PeptideRepository>((ref) {
  final onMutated = ref.read(syncControllerProvider).onRecordWritten;
  return IsarPeptideRepository(ref.watch(isarProvider), onMutated: onMutated);
});

final injectionLogRepositoryProvider = Provider<InjectionLogRepository>((ref) {
  final onMutated = ref.read(syncControllerProvider).onRecordWritten;
  return IsarInjectionLogRepository(
    ref.watch(isarProvider),
    onMutated: onMutated,
  );
});

final weightLogRepositoryProvider = Provider<WeightLogRepository>((ref) {
  final onMutated = ref.read(syncControllerProvider).onRecordWritten;
  return IsarWeightLogRepository(
    ref.watch(isarProvider),
    onMutated: onMutated,
  );
});

final sleepLogRepositoryProvider = Provider<SleepLogRepository>((ref) {
  final onMutated = ref.read(syncControllerProvider).onRecordWritten;
  return IsarSleepLogRepository(
    ref.watch(isarProvider),
    onMutated: onMutated,
  );
});

final bloodPressureLogRepositoryProvider = Provider<BloodPressureLogRepository>(
  (ref) {
    final onMutated = ref.read(syncControllerProvider).onRecordWritten;
    return IsarBloodPressureLogRepository(
      ref.watch(isarProvider),
      onMutated: onMutated,
    );
  },
);

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final onMutated = ref.read(syncControllerProvider).onRecordWritten;
  return IsarReminderRepository(
    ref.watch(isarProvider),
    onMutated: onMutated,
  );
});
