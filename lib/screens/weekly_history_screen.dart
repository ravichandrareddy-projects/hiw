import 'dart:ui';
import 'package:flutter/material.dart';

// 🧠 CORE LOGIC
import '../core/history_store.dart';
import '../core/food_item.dart';

class WeeklyHistoryScreen extends StatelessWidget {
  const WeeklyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entries = HistoryStore().getWeek(now);

    // Group by date (yyyy-mm-dd)
    final Map<String, List<FoodItem>> byDay = {};
    for (final e in entries) {
      final food = e.food;
      final key =
          "${food.time.year}-${food.time.month}-${food.time.day}";
      byDay.putIfAbsent(key, () => []).add(food);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Weekly History")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: _glassWeek(byDay),
      ),
    );
  }

  // -------------------------
  // WEEK CONTAINER
  // -------------------------
  Widget _glassWeek(Map<String, List<FoodItem>> byDay) {
    return _glassContainer(
      ExpansionTile(
        title: Text(_weekLabel()),
        children: byDay.entries.map((entry) {
          final date = DateTime.parse(entry.key);
          return _day(date, entry.value);
        }).toList(),
      ),
    );
  }

  // -------------------------
  // DAY TILE
  // -------------------------
  Widget _day(DateTime date, List<FoodItem> foods) {
    final dayName =
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][date.weekday - 1];
    final dateLabel = "${date.day}-${date.month}-${date.year}";

    return _glassContainer(
      ExpansionTile(
        title: Text("$dayName | $dateLabel"),
        children: foods.map((f) {
          return ListTile(
            title: Text("${_mealLabel(f.mealType)}: ${f.name}"),
            subtitle: Text(
              "${f.calories} kcal | ${_timeLabel(f.time)}",
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------
  // HELPERS
  // -------------------------
  String _weekLabel() {
    final now = DateTime.now();
    final start =
        now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return "Week ${start.day}-${start.month} → ${end.day}-${end.month}";
  }

  String _mealLabel(MealType t) {
    switch (t) {
      case MealType.breakfast:
        return "BF";
      case MealType.lunch:
        return "LU";
      case MealType.snack:
        return "SN";
      case MealType.dinner:
        return "DIN";
      case MealType.lateNight:
        return "LN";
    }
  }

  String _timeLabel(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  // -------------------------
  // GLASS CONTAINER
  // -------------------------
  Widget _glassContainer(Widget child) {
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
