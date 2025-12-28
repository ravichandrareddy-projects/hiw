import 'package:hive/hive.dart';

part 'history_hive_model.g.dart';

@HiveType(typeId: 1)
class HistoryHive extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  int calories;

  @HiveField(2)
  double protein;

  @HiveField(3)
  double carbs;

  @HiveField(4)
  double fats;

  HistoryHive({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}
