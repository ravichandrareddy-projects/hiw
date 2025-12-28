import 'package:hive/hive.dart';

part 'food_hive_model.g.dart';

@HiveType(typeId: 0)
class FoodHive extends HiveObject {
  @HiveField(0)
  String meal;

  @HiveField(1)
  int calories;

  @HiveField(2)
  double protein;

  @HiveField(3)
  double carbs;

  @HiveField(4)
  double fats;

  @HiveField(5)
  DateTime time;

  FoodHive({
    required this.meal,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.time,
  });
}
