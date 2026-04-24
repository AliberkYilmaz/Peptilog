import 'package:isar/isar.dart';

part 'weight_log.g.dart';

@collection
class WeightLog {
  Id id = Isar.autoIncrement;
  late double weightKg;
  late DateTime date;
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
  bool isDirty = true;
  String? userId;
}
