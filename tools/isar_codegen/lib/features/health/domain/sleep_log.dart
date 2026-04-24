import 'package:isar/isar.dart';

part 'sleep_log.g.dart';

@collection
class SleepLog {
  Id id = Isar.autoIncrement;
  late double hours;
  int? qualityRating;
  late DateTime date;
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
}
