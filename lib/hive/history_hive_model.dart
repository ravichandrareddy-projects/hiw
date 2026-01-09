import 'package:hive/hive.dart';

part 'history_hive_model.g.dart';

@HiveType(typeId: 1)
class HistoryHive extends HiveObject {
  @HiveField(0)
  String foodName;

  @HiveField(1)
  int mealTypeIndex; // MealType.index

  @HiveField(2)
  int calories;

  @HiveField(3)
  DateTime time;

  HistoryHive({
    required this.foodName,
    required this.mealTypeIndex,
    required this.calories,
    required this.time,
  });
}
