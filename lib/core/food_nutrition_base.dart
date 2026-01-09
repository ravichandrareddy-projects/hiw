class BaseNutrition {
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final bool isHealthy;

  const BaseNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.isHealthy,
  });
}

const Map<String, BaseNutrition> baseNutritionMap = {
  // -------- HEALTHY --------
  'boiled_egg': BaseNutrition(calories: 78, protein: 6, carbs: 1, fats: 5, isHealthy: true),
  'omelette': BaseNutrition(calories: 120, protein: 8, carbs: 2, fats: 9, isHealthy: true),
  'idli': BaseNutrition(calories: 70, protein: 2, carbs: 14, fats: 1, isHealthy: true),
  'dosa': BaseNutrition(calories: 160, protein: 4, carbs: 30, fats: 3, isHealthy: true),
  'dal_curry': BaseNutrition(calories: 180, protein: 9, carbs: 20, fats: 5, isHealthy: true),
  'roti': BaseNutrition(calories: 110, protein: 3, carbs: 20, fats: 2, isHealthy: true),
  'rice': BaseNutrition(calories: 200, protein: 4, carbs: 45, fats: 1, isHealthy: true),
  'sambar': BaseNutrition(calories: 90, protein: 4, carbs: 12, fats: 2, isHealthy: true),

  // -------- JUNK / HEAVY --------
  'chicken_biryani': BaseNutrition(calories: 450, protein: 20, carbs: 55, fats: 18, isHealthy: false),
  'burger': BaseNutrition(calories: 300, protein: 12, carbs: 30, fats: 15, isHealthy: false),
  'pizza': BaseNutrition(calories: 350, protein: 14, carbs: 36, fats: 16, isHealthy: false),
  'noodles': BaseNutrition(calories: 280, protein: 7, carbs: 40, fats: 10, isHealthy: false),
  'puri': BaseNutrition(calories: 150, protein: 3, carbs: 20, fats: 7, isHealthy: false),
  'vada': BaseNutrition(calories: 140, protein: 3, carbs: 18, fats: 6, isHealthy: false),
  'samosa': BaseNutrition(calories: 180, protein: 4, carbs: 25, fats: 8, isHealthy: false),
  'gulab_jamun': BaseNutrition(calories: 150, protein: 2, carbs: 30, fats: 5, isHealthy: false),
  'jalebi': BaseNutrition(calories: 170, protein: 2, carbs: 35, fats: 6, isHealthy: false),
  'soft_drinks': BaseNutrition(calories: 140, protein: 0, carbs: 35, fats: 0, isHealthy: false),
  'mango_pickle': BaseNutrition(calories: 90, protein: 1, carbs: 10, fats: 6, isHealthy: false),
};
