import 'food_item.dart';

class HistoryEntry {
  final FoodItem food;
  HistoryEntry(this.food);
}

class HistoryStore {
  static final HistoryStore _instance = HistoryStore._internal();
  factory HistoryStore() => _instance;
  HistoryStore._internal();

  final List<HistoryEntry> _entries = [];

  void addFood(FoodItem food) {
    _entries.add(HistoryEntry(food));
  }

  List<HistoryEntry> get allEntries => List.unmodifiable(_entries);

  /// 🔹 Get entries for a specific week (calendar-based)
  List<HistoryEntry> getWeek(DateTime date) {
    final startOfWeek =
        date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _entries.where((e) {
      return e.food.time.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
             e.food.time.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  /// 🔹 Get entries for a month
  List<HistoryEntry> getMonth(int year, int month) {
    return _entries.where((e) {
      return e.food.time.year == year &&
             e.food.time.month == month;
    }).toList();
  }
}
