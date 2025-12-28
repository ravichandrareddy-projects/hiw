import 'food_item.dart';

class NutritionStore {
  static final NutritionStore _instance = NutritionStore._internal();
  factory NutritionStore() => _instance;
  NutritionStore._internal();

  final List<FoodItem> _todayFoods = [];

  int totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFats = 0;

  void addFood(FoodItem food) {
    _todayFoods.add(food);
    totalCalories += food.calories;
    totalProtein += food.protein;
    totalCarbs += food.carbs;
    totalFats += food.fats;
  }

  List<FoodItem> get todayFoods => List.unmodifiable(_todayFoods);

  void resetDay() {
    _todayFoods.clear();
    totalCalories = 0;
    totalProtein = 0;
    totalCarbs = 0;
    totalFats = 0;
  }
}
