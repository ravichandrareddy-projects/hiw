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
      fiber: 0,
    );
  }

  int calories    = base.calories;
  double protein  = base.protein;
  double carbs    = base.carbs;
  double fats     = base.fats;
  double fiber    = base.fiber;

  final withExtras = applyAddonExtras(
    base: FoodItem(
      name: foodLabel,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      fiber: fiber,
    ),
    addons: addons,
  );

  return FoodItem(
    name: foodLabel,
    mealType: mealType,
    calories: withExtras.calories,
    protein: withExtras.protein,
    carbs: withExtras.carbs,
    fats: withExtras.fats,
    fiber: withExtras.fiber,
    // 🆕 Micronutrients come from base (not scaled by addons for simplicity)
    vitaminA:   base.vitaminA,
    vitaminC:   base.vitaminC,
    vitaminB6:  base.vitaminB6,
    calcium:    base.calcium,
    iron:       base.iron,
    potassium:  base.potassium,
    magnesium:  base.magnesium,
    sodium:     base.sodium,
    zinc:       base.zinc,
  );
}

/// Adds addon extras (sides, choices, counters) on top of ANY base FoodItem.
/// Used for foods from the 2.6k nutrition database that have no legacy base entry.
FoodItem applyAddonExtras({
  required FoodItem base,
  required Map<String, dynamic> addons,
}) {
  int calories = base.calories;
  double protein = base.protein;
  double carbs = base.carbs;
  double fats = base.fats;
  double fiber = base.fiber;

  addons.forEach((key, value) {
    if (value is bool) {
      // toggle (e.g. extra ghee on/off) — no-op when off.
      return;
    } else if (value is int) {
      // counter (e.g., number of dosa)
      calories *= value;
      protein  *= value;
      carbs    *= value;
      fats     *= value;
      fiber    *= value;
    } else if (value is String) {
      // single choice
      final rule = addonNutritionRules[value];
      if (rule != null) {
        calories += rule.calories;
        protein  += rule.protein;
        carbs    += rule.carbs;
        fats     += rule.fats;
        fiber    += rule.fiber;
      }
    } else if (value is Set<String>) {
      // multi choice
      for (final v in value) {
        final rule = addonNutritionRules[v];
        if (rule != null) {
          calories += rule.calories;
          protein  += rule.protein;
          carbs    += rule.carbs;
          fats     += rule.fats;
          fiber    += rule.fiber;
        }
      }
    }
  });

  return FoodItem(
    name: base.name,
    mealType: base.mealType,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fats: fats,
    fiber: fiber,
    time: base.time,
    vitaminA: base.vitaminA,
    vitaminC: base.vitaminC,
    vitaminB6: base.vitaminB6,
    calcium: base.calcium,
    iron: base.iron,
    potassium: base.potassium,
    magnesium: base.magnesium,
    sodium: base.sodium,
    zinc: base.zinc,
  );
}

/// Scales every nutrient of [food] by the vision-estimated portion [quantity]
/// (1.0 = standard serving). Quantity of 1.0 returns the item unchanged.
FoodItem scaledByQuantity(FoodItem food, double quantity) {
  if (quantity <= 0 || (quantity - 1.0).abs() < 0.001) return food;
  double s(double v) => double.parse((v * quantity).toStringAsFixed(1));
  double s2(double v) => double.parse((v * quantity).toStringAsFixed(2));
  return FoodItem(
    name: food.name,
    mealType: food.mealType,
    calories: (food.calories * quantity).round(),
    protein: s(food.protein),
    carbs: s(food.carbs),
    fats: s(food.fats),
    fiber: s(food.fiber),
    time: food.time,
    vitaminA: s(food.vitaminA),
    vitaminC: s(food.vitaminC),
    vitaminB6: s2(food.vitaminB6),
    calcium: s(food.calcium),
    iron: s(food.iron),
    potassium: s(food.potassium),
    magnesium: s(food.magnesium),
    sodium: s(food.sodium),
    zinc: s(food.zinc),
  );
}
