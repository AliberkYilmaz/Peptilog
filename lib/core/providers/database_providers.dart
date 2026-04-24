import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../features/peptides/data/peptide_repository.dart';
import '../../features/peptides/data/isar_peptide_repository.dart';
import '../../features/injection_log/data/injection_log_repository.dart';
import '../../features/injection_log/data/isar_injection_log_repository.dart';
import '../../features/weight/data/weight_log_repository.dart';
import '../../features/weight/data/isar_weight_log_repository.dart';
import '../../features/health/data/sleep_log_repository.dart';
import '../../features/health/data/isar_sleep_log_repository.dart';
import '../../features/health/data/blood_pressure_log_repository.dart';
import '../../features/health/data/isar_blood_pressure_log_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/data/isar_reminder_repository.dart';

/// The Isar database instance. Must be overridden in ProviderScope
/// after [IsarDatabase.open()] resolves at app startup.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in ProviderScope after DB init');
});

final peptideRepositoryProvider = Provider<PeptideRepository>((ref) {
  return IsarPeptideRepository(ref.watch(isarProvider));
});

final injectionLogRepositoryProvider = Provider<InjectionLogRepository>((ref) {
  return IsarInjectionLogRepository(ref.watch(isarProvider));
});

final weightLogRepositoryProvider = Provider<WeightLogRepository>((ref) {
  return IsarWeightLogRepository(ref.watch(isarProvider));
});

final sleepLogRepositoryProvider = Provider<SleepLogRepository>((ref) {
  return IsarSleepLogRepository(ref.watch(isarProvider));
});

final bloodPressureLogRepositoryProvider = Provider<BloodPressureLogRepository>((ref) {
  return IsarBloodPressureLogRepository(ref.watch(isarProvider));
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return IsarReminderRepository(ref.watch(isarProvider));
});
