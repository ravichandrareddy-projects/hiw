class AddonNutrition {
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final double fiber;

  const AddonNutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.fiber = 0.0,
  });
}

const Map<String, AddonNutrition> addonNutritionRules = {
  // -------- COMMON SIDES --------
  'sambar': AddonNutrition(
    calories: 60,
    protein: 4,
    carbs: 6,
    fats: 2,
    fiber: 2.0,
  ),

  'chutney': AddonNutrition(
    calories: 40,
    fats: 4,
    fiber: 0.5,
  ),

  // -------- FAST FOOD EXTRAS --------
  'extra_cheese': AddonNutrition(
    calories: 120,
    protein: 6,
    fats: 10,
    fiber: 0.0,
  ),

  'chicken': AddonNutrition(
    calories: 150,
    protein: 18,
    fats: 6,
    fiber: 0.0,
  ),

  'egg': AddonNutrition(
    calories: 70,
    protein: 6,
    fats: 5,
    fiber: 0.0,
  ),

  // -------- SAUCES --------
  'ketchup': AddonNutrition(
    calories: 20,
    carbs: 5,
    fiber: 0.1,
  ),

  'potato_curry': AddonNutrition(
    calories: 110,
    protein: 3,
    carbs: 15,
    fats: 4,
    fiber: 2.0,
  ),

  // -------- DRINKS --------
  'soft_drinks': AddonNutrition(
    calories: 140,
    carbs: 35,
    fiber: 0.0,
  ),

  // -------- SHARED RESULT ADD-ONS (spec examples) --------
  'ghee': AddonNutrition(calories: 45, fats: 5),
  'oil': AddonNutrition(calories: 40, fats: 4.5),
  'butter': AddonNutrition(calories: 35, protein: 0.2, fats: 4),
  'raita': AddonNutrition(calories: 35, protein: 2, carbs: 4, fats: 1.5, fiber: 0.5),
  'extra_rice': AddonNutrition(calories: 130, protein: 2.5, carbs: 28, fats: 0.3, fiber: 0.5),
  'extra_chicken': AddonNutrition(calories: 150, protein: 18, fats: 8),
};
