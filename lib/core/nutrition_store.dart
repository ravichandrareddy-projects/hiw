import 'package:hive/hive.dart';
import 'food_item.dart';
import '../hive/food_hive_model.dart';

class NutritionStore {
  static final NutritionStore _instance = NutritionStore._internal();
  factory NutritionStore() => _instance;

  NutritionStore._internal() {
    _loadFromHive();
  }

  final List<FoodItem> _todayFoods = [];

  int totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFats = 0;

  // 🔹 Hive box
  late Box<FoodHive> _foodBox;

  // =============================
  // LOAD FROM HIVE (APP START)
  // AUTO-RESET IF DAY CHANGED
  // =============================
  void _loadFromHive() {
    _foodBox = Hive.box<FoodHive>('foodBox');

    _todayFoods.clear();
    totalCalories = 0;
    totalProtein = 0;
    totalCarbs = 0;
    totalFats = 0;

    final now = DateTime.now();

    for (final hiveFood in _foodBox.values) {
      final food = hiveFood.toFoodItem();

      // 🔥 IGNORE OLD DAY FOOD
      if (!_isSameDay(food.time, now)) {
        continue;
      }

      _todayFoods.add(food);
      totalCalories += food.calories;
      totalProtein += food.protein;
      totalCarbs += food.carbs;
      totalFats += food.fats;
    }

    // 🔥 CLEAN OLD DATA FROM HIVE (OPTIONAL BUT GOOD)
    _cleanupOldHiveEntries(now);
  }

  // =============================
  // ADD FOOD (UI → STORE → HIVE)
  // =============================
  void addFood(FoodItem food) {
    final now = DateTime.now();

    // 🔥 DAY CHANGED WHILE APP OPEN
    if (!_isSameDay(food.time, now)) {
      resetDay();
    }

    _todayFoods.add(food);
    totalCalories += food.calories;
    totalProtein += food.protein;
    totalCarbs += food.carbs;
    totalFats += food.fats;

    _foodBox.add(FoodHive.fromFoodItem(food));
  }

  // =============================
  // USED BY FOOD SCREEN
  // =============================
  List<FoodItem> get todayFoods => List.unmodifiable(_todayFoods);

  // =============================
  // RESET DAY (MANUAL / MIDNIGHT)
  // =============================
  void resetDay() {
    _todayFoods.clear();
    totalCalories = 0;
    totalProtein = 0;
    totalCarbs = 0;
    totalFats = 0;

    _foodBox.clear();
  }

  // =============================
  // HELPERS
  // =============================
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _cleanupOldHiveEntries(DateTime now) {
    final keysToDelete = <dynamic>[];

    for (final entry in _foodBox.toMap().entries) {
      final food = entry.value.toFoodItem();
      if (!_isSameDay(food.time, now)) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      _foodBox.deleteAll(keysToDelete);
    }
  }
}
