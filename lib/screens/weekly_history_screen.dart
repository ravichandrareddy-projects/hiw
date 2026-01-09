import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/history_store.dart';
import '../core/food_item.dart';

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
      return !t.isBefore(_dayStart(weekStart)) &&
          !t.isAfter(_dayEnd(weekEnd));
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
        padding: const EdgeInsets.all(16),
        children: [
          _weekHeader(weekStart, weekEnd),
          const SizedBox(height: 12),
          ...byDay.entries.map((e) {
            final parts = e.key.split("-");
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            return _dayTile(date, e.value);
          }).toList(),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _weekHeader(DateTime start, DateTime end) {
    return _glass(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Week: ${_fmt(start)} → ${_fmt(end)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _dayTile(DateTime date, List<FoodItem> foods) {
    return _glass(
      ExpansionTile(
        title: Text(
          "${date.day}-${date.month}-${date.year}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: foods.map((f) {
          return ListTile(
            title: Text("${_meal(f.mealType)} • ${f.name}"),
            subtitle: Text("${f.calories} kcal • ${_time(f.time)}"),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- helpers ----------------

  DateTime _dayStart(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  String _fmt(DateTime d) =>
      "${d.day}/${d.month}/${d.year}";

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
