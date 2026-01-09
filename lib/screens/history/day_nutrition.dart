//libs/screens/history/day_nutrition
import 'nutrition_models.dart';
import 'meal_time.dart';

class DayNutrition {
  final DateTime date;

  MealNutrition? breakfast;
  MealNutrition? lunch;
  MealNutrition? snack;
  MealNutrition? dinner;

  DayNutrition(this.date);

  /// Add or combine meal nutrition safely (IMMUTABLE)
  void addMeal(MealType type, MealNutrition nutrition) {
    switch (type) {
      case MealType.breakfast:
        breakfast = breakfast == null
            ? nutrition
            : breakfast!.combine(nutrition);
        break;

      case MealType.lunch:
        lunch = lunch == null
            ? nutrition
            : lunch!.combine(nutrition);
        break;

      case MealType.snack:
        snack = snack == null
            ? nutrition
            : snack!.combine(nutrition);
        break;

      case MealType.dinner:
        dinner = dinner == null
            ? nutrition
            : dinner!.combine(nutrition);
        break;
    }
  }

  // -------------------------
  // TOTAL MACROS (FOR UI)
  // -------------------------
  int get totalCalories => _sum((m) => m.calories);
  int get totalProtein => _sum((m) => m.protein);
  int get totalCarbs => _sum((m) => m.carbs);
  int get totalFats => _sum((m) => m.fats);

  // -------------------------
  // WEIGHTED HEALTH SCORE
  // -------------------------
  double get avgHealthyScore {
    final meals = _meals;
    final totalCalories =
        meals.fold(0, (a, m) => a + m.calories);

    if (totalCalories == 0) return 0;

    return meals.fold(
          0.0,
          (sum, m) =>
              sum + (m.healthyScore * m.calories),
        ) /
        totalCalories;
  }

  // -------------------------
  // HELPERS
  // -------------------------
  List<MealNutrition> get _meals =>
      [breakfast, lunch, snack, dinner]
          .whereType<MealNutrition>()
          .toList();

  int _sum(int Function(MealNutrition m) f) =>
      _meals.fold(0, (a, b) => a + f(b));
}
