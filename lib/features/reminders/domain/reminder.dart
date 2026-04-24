import 'package:isar/isar.dart';

part 'reminder.g.dart';

@collection
class Reminder {
  Id id = Isar.autoIncrement;
  late int peptideId;
  late String daysOfWeek;
  late String time;
  bool isActive = true;
  int? notificationId;
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
  bool isDirty = true;
  String? userId;
}
