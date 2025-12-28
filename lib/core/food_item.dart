enum MealType { breakfast, lunch, snack, dinner, lateNight }

class FoodItem {
  final String name;
  final MealType mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime time;

  FoodItem({
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}
