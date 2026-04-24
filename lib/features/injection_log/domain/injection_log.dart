import 'package:isar/isar.dart';

part 'injection_log.g.dart';

@collection
class InjectionLog {
  Id id = Isar.autoIncrement;
  late int peptideId;
  late double doseMg;
  late String route;
  double? units;
  String? notes;
  late DateTime loggedAt;
  DateTime createdAt = DateTime.now();
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
  bool isDeleted = false;
  bool isDirty = true;
  String? userId;
}
