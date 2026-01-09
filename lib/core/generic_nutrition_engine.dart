//lib/core/generic_nutrition_engine.dart
import 'food_nutrition_base.dart';
import 'addon_nutrition_rules.dart';
import 'food_item.dart';

FoodItem calculateFoodFromAddons({
  required String foodLabel,
  required Map<String, dynamic> addons,
  required MealType mealType,
}) {
  final base = baseNutritionMap[foodLabel];

  if (base == null) {
    // fallback safety
    return FoodItem(
      name: foodLabel,
      mealType: mealType,
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
    );
  }

  int calories = base.calories;
  double protein = base.protein;
  double carbs = base.carbs;
  double fats = base.fats;

  addons.forEach((key, value) {
    if (value is int) {
      // counter (e.g., number of dosa)
      calories *= value;
      protein *= value;
      carbs *= value;
      fats *= value;
    } 
    else if (value is String) {
      // single choice
      final rule = addonNutritionRules[value];
      if (rule != null) {
        calories += rule.calories;
        protein += rule.protein;
        carbs += rule.carbs;
        fats += rule.fats;
      }
    } 
    else if (value is Set<String>) {
      // multi choice
      for (final v in value) {
        final rule = addonNutritionRules[v];
        if (rule != null) {
          calories += rule.calories;
          protein += rule.protein;
          carbs += rule.carbs;
          fats += rule.fats;
        }
      }
    }
  });

  return FoodItem(
    name: foodLabel,
    mealType: mealType,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fats: fats,
  );
}
