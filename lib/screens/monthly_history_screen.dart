import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/history_store.dart';
import '../core/food_item.dart';

class MonthlyHistoryScreen extends StatelessWidget {
  const MonthlyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 🔹 current week start (Monday)
    final currentWeekStart =
        now.subtract(Duration(days: now.weekday - 1));

    final completedEntries = HistoryStore().allEntries.where((e) {
      return e.food.time.isBefore(currentWeekStart);
    }).toList();

    final Map<String, List<FoodItem>> byMonth = {};
    for (final e in completedEntries) {
      final f = e.food;
      final key = "${f.time.year}-${f.time.month}";
      byMonth.putIfAbsent(key, () => []).add(f);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Monthly History")),
      body: byMonth.isEmpty
          ? const Center(
              child: Text(
                "No completed weeks yet",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: byMonth.entries.map((e) {
                return _monthTile(e.key, e.value);
              }).toList(),
            ),
    );
  }

  Widget _monthTile(String key, List<FoodItem> foods) {
    final parts = key.split("-");
    final month = int.parse(parts[1]);
    final year = parts[0];

    final totalCalories =
        foods.fold<int>(0, (s, f) => s + f.calories);

    return _glass(
      ExpansionTile(
        title: Text("${_monthName(month)} $year"),
        subtitle: Text("Calories: $totalCalories kcal"),
        children: foods.map((f) {
          return ListTile(
            title: Text("${f.name} (${_meal(f.mealType)})"),
            subtitle: Text("${f.calories} kcal"),
          );
        }).toList(),
      ),
    );
  }

  String _monthName(int m) => const [
        "Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"
      ][m - 1];

  String _meal(MealType t) => t.name.toUpperCase();

  Widget _glass(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
