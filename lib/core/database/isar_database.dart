import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/peptides/domain/peptide.dart';
import '../../features/injection_log/domain/injection_log.dart';
import '../../features/weight/domain/weight_log.dart';
import '../../features/health/domain/sleep_log.dart';
import '../../features/health/domain/blood_pressure_log.dart';
import '../../features/reminders/domain/reminder.dart';

/// Singleton Isar database instance.
/// Initialise once at app startup via [IsarDatabase.open].
class IsarDatabase {
  IsarDatabase._();

  static Isar? _instance;

  static Isar get instance {
    assert(
      _instance != null,
      'IsarDatabase.open() must be called before accessing instance',
    );
    return _instance!;
  }

  static Future<Isar> open() async {
    if (_instance != null && _instance!.isOpen) return _instance!;

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [
        PeptideSchema,
        InjectionLogSchema,
        WeightLogSchema,
        SleepLogSchema,
        BloodPressureLogSchema,
        ReminderSchema,
      ],
      directory: dir.path,
      name: 'peptilog',
    );

    return _instance!;
  }
}
