import 'package:hive/hive.dart';
import '../hive/history_hive_model.dart';
import 'food_item.dart';

class HistoryEntry {
  final FoodItem food;
  HistoryEntry(this.food);
}

class HistoryStore {
  static final HistoryStore _instance = HistoryStore._internal();
  factory HistoryStore() => _instance;
  HistoryStore._internal();

  final Box<HistoryHive> _box = Hive.box<HistoryHive>('historyBox');

  // -------------------------
  // ADD ENTRY (PERMANENT)
  // -------------------------
  void addFood(FoodItem food) {
    final hiveItem = HistoryHive(
      foodName: food.name,
      mealTypeIndex: food.mealType.index,
      calories: food.calories,
      time: food.time,
    );
    _box.add(hiveItem);
  }

  // -------------------------
  // ALL HISTORY
  // -------------------------
  List<HistoryEntry> get allEntries {
    return _box.values.map((h) {
      return HistoryEntry(
        FoodItem(
          name: h.foodName,
          mealType: MealType.values[h.mealTypeIndex],
          calories: h.calories,
          protein: 0,
          carbs: 0,
          fats: 0,
          time: h.time,
        ),
      );
    }).toList();
  }

  // -------------------------
  // DATE HELPERS
  // -------------------------
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // -------------------------
  // DAILY FILTER
  // -------------------------
  List<HistoryEntry> getEntriesForDate(DateTime date) {
    return allEntries.where((e) => _isSameDay(e.food.time, date)).toList();
  }

  // -------------------------
  // STREAK LOGIC
  // -------------------------
  bool hasStreak(DateTime date) {
    final entries = getEntriesForDate(date);
    final uniqueMealTypes = entries.map((e) => e.food.mealType).toSet();
    // Streak = At least 3 different meal types (e.g. Breakfast, Lunch, Dinner)
    return uniqueMealTypes.length >= 3;
  }

  // -------------------------
  // DAILY STATS
  // -------------------------
  Map<String, double> getStatsForDate(DateTime date) {
    final entries = getEntriesForDate(date);
    double totalCalories = 0;
    double totalProtein = 0;
    int healthyCount = 0;

    for (var e in entries) {
      totalCalories += e.food.calories;
      totalProtein += e.food.protein;

      // Logic: <= 500 cal counts as "Healthy" (simplification)
      if (e.food.calories <= 500) {
        healthyCount++;
      }
    }

    double healthyPercent = 0;
    if (entries.isNotEmpty) {
      healthyPercent = (healthyCount / entries.length) * 100;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'healthyPercent': healthyPercent,
      'junkPercent': 100 - healthyPercent, // inverse for chart
    };
  }

  // -------------------------
  // WEEK FILTER
  // -------------------------
  List<HistoryEntry> getWeek(DateTime now) {
    final start =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final end = start.add(const Duration(days: 7));

    return allEntries
        .where((e) =>
            e.food.time.isAfter(start) &&
            e.food.time.isBefore(end))
        .toList();
  }

  // -------------------------
  // 🛠️ DEV TOOLS: STREAK HACK
  // -------------------------
  Future<void> clearHistory() async {
    await _box.clear();
  }

  void seedStreak(int days) {
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      
      // Need 3 unique meals to trigger 'hasStreak'
      final meals = [
        {'name': 'Healthy Oats', 'type': MealType.breakfast, 'cal': 350},
        {'name': 'Grilled Chicken', 'type': MealType.lunch, 'cal': 450},
        {'name': 'Salmon Salad', 'type': MealType.dinner, 'cal': 400},
      ];

      for (var m in meals) {
        addFood(FoodItem(
          name: m['name'] as String,
          mealType: m['type'] as MealType,
          calories: m['cal'] as int,
          protein: 30,
          carbs: 40,
          fats: 15,
          time: DateTime(date.year, date.month, date.day, 8 + (meals.indexOf(m) * 5)), // 8 AM, 1 PM, 6 PM
        ));
      }
    }
  }
}
