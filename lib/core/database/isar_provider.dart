import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/health/domain/blood_pressure_log.dart';
import '../../features/health/domain/sleep_log.dart';
import '../../features/injection_log/domain/injection_log.dart';
import '../../features/peptides/domain/peptide.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/weight/domain/weight_log.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      PeptideSchema,
      InjectionLogSchema,
      WeightLogSchema,
      SleepLogSchema,
      BloodPressureLogSchema,
      ReminderSchema,
    ],
    directory: dir.path,
  );
});
