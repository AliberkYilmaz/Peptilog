import 'package:isar/isar.dart';

part 'peptide.g.dart';

@collection
class Peptide {
  Id id = Isar.autoIncrement;
  late String name;
  late String color;
  late String unit;
  bool isActive = true;
  bool isCustom = false;
  String? supabaseId;
  DateTime updatedAt = DateTime.now();
}
