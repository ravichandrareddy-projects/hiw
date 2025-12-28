import 'dart:ui';
import 'package:flutter/material.dart';

// 🧠 CORE
import '../core/history_store.dart';
import '../core/food_item.dart';

class MonthlyHistoryScreen extends StatelessWidget {
  const MonthlyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = HistoryStore().allEntries;

    // monthKey -> foods
    final Map<String, List<FoodItem>> monthMap = {};

    for (final e in entries) {
      final f = e.food;
      final key = "${f.time.year}-${f.time.month}";
      monthMap.putIfAbsent(key, () => []).add(f);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Monthly Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: monthMap.entries.map((e) {
            return _monthTile(e.key, e.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _monthTile(String key, List<FoodItem> foods) {
    final parts = key.split("-");
    final year = parts[0];
    final month = int.parse(parts[1]);

    final totalProtein =
        foods.fold<double>(0, (s, f) => s + f.protein);

    final totalCalories =
        foods.fold<int>(0, (s, f) => s + f.calories);

    return _glass(
      ExpansionTile(
        title: Text("${_monthName(month)} $year"),
        subtitle: Text(
          "Protein: ${totalProtein.toStringAsFixed(1)} g | "
          "Calories: $totalCalories kcal",
          style: const TextStyle(fontSize: 12),
        ),
        children: foods.map((f) {
          return ListTile(
            title: Text("${_meal(f.mealType)}: ${f.name}"),
            subtitle:
                Text("${f.calories} kcal • ${f.protein}g protein"),
          );
        }).toList(),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return names[m - 1];
  }

  String _meal(MealType t) {
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
