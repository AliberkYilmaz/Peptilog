import 'package:isar/isar.dart';

part 'blood_pressure_log.g.dart';

@collection
class BloodPressureLog {
  Id id = Isar.autoIncrement;
  late int systolic;
  late int diastolic;
  int? pulse;
  late DateTime measuredAt;
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
  bool isDirty = true;
  String? userId;
}
