import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../core/history_store.dart';
import '../core/food_item.dart';
import '../widgets/glass_card.dart';

class WeeklyHistoryScreen extends StatelessWidget {
  const WeeklyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 🔹 Monday → Sunday
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final entries = HistoryStore().allEntries.where((e) {
      final t = e.food.time;
      return !t.isBefore(_dayStart(weekStart)) && !t.isAfter(_dayEnd(weekEnd));
    }).toList();

    final Map<String, List<FoodItem>> byDay = {};
    for (final e in entries) {
      final f = e.food;
      final key = "${f.time.year}-${f.time.month}-${f.time.day}";
      byDay.putIfAbsent(key, () => []).add(f);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Weekly History")),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _weekHeader(context, weekStart, weekEnd),
          SizedBox(height: 12.h),
          ...byDay.entries.map((e) {
            final parts = e.key.split("-");
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h), // 📏 RESTORED SPACING
              child: _dayTile(context, date, e.value),
            );
          }).toList(),
          SizedBox(height: 100.h), // 📏 SPACE FOR NAV
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _weekHeader(BuildContext context, DateTime start, DateTime end) {
    return GlassCard(
      radius: 18,
      padding: EdgeInsets.all(20.r), // 📏 MORE SPACIOUS HEADER
      child: Center(
        child: Text(
          "Week: ${_fmt(start)} → ${_fmt(end)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp, // 📏 LARGER FONT
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _dayTile(BuildContext context, DateTime date, List<FoodItem> foods) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 18,
      child: ExpansionTile(
        title: Text(
          "${date.day}-${date.month}-${date.year}",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        subtitle: Text("Expand for details",
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12.sp)),
        children: foods.map((f) {
          return ListTile(
            title: Text("${_meal(f.mealType)} • ${f.name}",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text("${f.calories} kcal • ${_time(f.time)}",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- helpers ----------------

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  String _fmt(DateTime d) => "${d.day}/${d.month}/${d.year}";

  String _meal(MealType t) {
    switch (t) {
      case MealType.breakfast:
        return "Breakfast";
      case MealType.lunch:
        return "Lunch";
      case MealType.snack:
        return "Snack";
      case MealType.dinner:
        return "Dinner";
      case MealType.lateNight:
        return "Late Night";
    }
  }

  String _time(DateTime t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
}
