import 'package:hive/hive.dart';
import '../core/food_item.dart';

part 'food_hive_model.g.dart';

@HiveType(typeId: 0)
class FoodHive extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int mealTypeIndex; // ✅ enum index

  @HiveField(2)
  int calories;

  @HiveField(3)
  double protein;

  @HiveField(4)
  double carbs;

  @HiveField(5)
  double fats;

  @HiveField(6)
  DateTime time;

  FoodHive({
    required this.name,
    required this.mealTypeIndex,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.time,
  });

  /// Hive → Core
  FoodItem toFoodItem() {
    return FoodItem(
      name: name,
      mealType: MealType.values[mealTypeIndex],
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      time: time,
    );
  }

  /// Core → Hive
  static FoodHive fromFoodItem(FoodItem food) {
    return FoodHive(
      name: food.name,
      mealTypeIndex: food.mealType.index,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fats: food.fats,
      time: food.time,
    );
  }
}
