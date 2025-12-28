class MealNutrition {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final double healthyScore; // 0 → 1

  const MealNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.healthyScore,
  });

  MealNutrition combine(MealNutrition other) {
    final totalCalories = calories + other.calories;

    return MealNutrition(
      calories: totalCalories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fats: fats + other.fats,
      healthyScore: totalCalories == 0
          ? 0
          : ((healthyScore * calories) +
                  (other.healthyScore * other.calories)) /
              totalCalories,
    );
  }
}
