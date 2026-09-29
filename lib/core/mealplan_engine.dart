// lib/core/mealplan_engine.dart — deterministic AI-free meal plans.
// Picks real DB foods per slot, scaled to meal distribution. The LLM may
// explain the plan; these numbers are the source of truth.
import 'food_item.dart'; // MealType + FoodItem
import 'food_nutrition_database.dart';
import 'health_profile.dart';

class PlannedMeal {
  final MealType meal;
  final FoodNutritionRecord record;
  final double quantity;
  final FoodItem item;
  const PlannedMeal({
    required this.meal,
    required this.record,
    required this.quantity,
    required this.item,
  });
}

class DayPlan {
  final List<PlannedMeal> meals;
  final int calories;
  final double protein;
  const DayPlan({
    required this.meals,
    required this.calories,
    required this.protein,
  });
}

class MealPlanEngine {
  /// Meal distribution (configurable product settings, spec §17).
  static const Map<MealType, double> distribution = {
    MealType.breakfast: 0.25,
    MealType.lunch: 0.30,
    MealType.snack: 0.15,
    MealType.dinner: 0.30,
  };

  static bool _dietOk(FoodNutritionRecord r, DietPreference? diet) {
    if (diet == null || diet == DietPreference.noPreference) {
      return true;
    }
    final d = r.diet.toLowerCase();
    switch (diet) {
      case DietPreference.vegetarian:
      case DietPreference.jain:
        return d == 'veg';
      case DietPreference.vegan:
        return d == 'vegan' || d == 'veg';
      case DietPreference.eggetarian:
        return d != 'non-veg' && d != 'nonveg';
      case DietPreference.nonVegetarian:
        return true;
      case DietPreference.noPreference:
        return true;
    }
  }

  /// Deterministic: same inputs + date produce the same plan.
  static DayPlan build({
    required int calorieTarget,
    DietPreference? diet,
    DateTime? date,
  }) {
    final db = FoodNutritionDatabase();
    final day = date ?? DateTime.now();
    final seed =
        day.year * 1000 + day.month * 40 + day.day + calorieTarget;
    final planned = <PlannedMeal>[];
    var i = 0;
    for (final entry in distribution.entries) {
      final slotKcal = calorieTarget * entry.value;
      final pool = db.records.where((r) {
        final mt = r.mealType.toLowerCase();
        final mealName = entry.key.name.toLowerCase();
        final match = mt.contains(mealName) ||
            (entry.key == MealType.snack && mt.contains('snack')) ||
            (entry.key == MealType.lunch && mt.contains('lunch')) ||
            (entry.key == MealType.breakfast &&
                mt.contains('break')) ||
            (entry.key == MealType.dinner && mt.contains('dinner'));
        return match && _dietOk(r, diet);
      }).toList();
      final fallback =
          db.records.where((r) => _dietOk(r, diet)).toList();
      final list = pool.isNotEmpty ? pool : fallback;
      if (list.isEmpty) continue;
      list.sort((a, b) => a.name.compareTo(b.name));
      final rec = list[(seed + i * 37) % list.length];
      i++;
      // Quantity so this serving ≈ slot calories (0.5–2.0 servings).
      final perServing =
          rec.caloriesPer100g * rec.servingWeightG / 100.0;
      final qty = perServing <= 0
          ? 1.0
          : (slotKcal / perServing).clamp(0.5, 2.0);
      planned.add(PlannedMeal(
        meal: entry.key,
        record: rec,
        quantity: double.parse(qty.toStringAsFixed(2)),
        item: rec.toFoodItem(
          quantityMultiplier: qty,
          overrideMealType: entry.key,
        ),
      ));
    }
    return DayPlan(
      meals: planned,
      calories: planned.fold(0, (a, m) => a + m.item.calories),
      protein: double.parse(
          planned.fold(0.0, (a, m) => a + m.item.protein).toStringAsFixed(1)),
    );
  }
}
