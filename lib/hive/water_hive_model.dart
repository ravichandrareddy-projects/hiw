import 'package:hive/hive.dart';

part 'water_hive_model.g.dart';

@HiveType(typeId: 7) // ⚠️ make sure this ID is UNIQUE
class WaterHive extends HiveObject {
  @HiveField(0)
  bool drankWater;

  @HiveField(1)
  DateTime date;

  WaterHive({
    required this.drankWater,
    required this.date,
  });
}