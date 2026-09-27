import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../core/history_store.dart';
import '../core/food_item.dart';
import '../widgets/glass_card.dart';

class MonthlyHistoryScreen extends StatelessWidget {
  const MonthlyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 🔹 current week start (Monday)
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));

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
          ? Center(
              child: Text(
                "No completed weeks yet",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                ...byMonth.entries.map((e) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _monthTile(context, e.key, e.value),
                  );
                }).toList(),
                SizedBox(height: 100.h),
              ],
            ),
    );
  }

  Widget _monthTile(BuildContext context, String key, List<FoodItem> foods) {
    final parts = key.split("-");
    final month = int.parse(parts[1]);
    final year = parts[0];

    final totalCalories = foods.fold<int>(0, (s, f) => s + f.calories);

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 18,
      child: ExpansionTile(
        title: Text("${_monthName(month)} $year",
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold)),
        subtitle: Text("Calories: $totalCalories kcal",
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color)),
        children: foods.map((f) {
          return ListTile(
            title: Text("${f.name} (${_meal(f.mealType)})",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text("${f.calories} kcal",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
          );
        }).toList(),
      ),
    );
  }

  String _monthName(int m) => const [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ][m - 1];

  String _meal(MealType t) => t.name.toUpperCase();
}
