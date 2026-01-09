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
}
