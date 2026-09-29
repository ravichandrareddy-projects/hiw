// lib/core/habit_engine.dart
// Update A — habit mechanics: forgiving streaks (freezes), weekly
// challenges, transparent HIW Score. Pure Dart over existing stores.
// A "streak day" = 3+ distinct meal types (HistoryStore.hasStreak).
import 'package:hive/hive.dart';
import 'history_store.dart';
import 'nutrition_store.dart';
import 'water_store.dart';

/// Transparent 0–100 daily progress score (NOT a medical score).
/// Weights are configurable product settings.
class HiwScoreWeights {
  final double calories;
  final double protein;
  final double hydration;
  final double meals;
  const HiwScoreWeights({
    this.calories = 40,
    this.protein = 25,
    this.hydration = 20,
    this.meals = 15,
  });
}

class HiwScore {
  final int total;
  final int caloriesPart;
  final int proteinPart;
  final int hydrationPart;
  final int mealsPart;
  const HiwScore({
    required this.total,
    required this.caloriesPart,
    required this.proteinPart,
    required this.hydrationPart,
    required this.mealsPart,
  });
}

class WeeklyChallenge {
  final String id;
  final String title;
  final String subtitle;
  final int target;
  final int progress;
  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.progress,
  });

  double get ratio =>
      target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);
  bool get done => progress >= target;
}

class HabitEngine {
  static final HabitEngine _i = HabitEngine._internal();
  factory HabitEngine() => _i;
  HabitEngine._internal();

  Box get _meta => Hive.box('metaBox');

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  // ── Streaks ────────────────────────────────
  /// Current run of streak-days ending today/yesterday.
  int streakDays() {
    final store = HistoryStore();
    final now = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 90; i++) {
      final d = now.subtract(Duration(days: i));
      if (store.hasStreak(d)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  List<String> get _frozenDates {
    final v = _meta.get('freezeDates');
    if (v is List) return v.whereType<String>().toList();
    return const [];
  }

  int get _freezeUsed => _meta.get('freezeUsed', defaultValue: 0) as int;

  /// 1 freeze earned per 14 streak days. Forgiving, never punitive.
  int freezesAvailable() {
    final earned = streakDays() ~/ 14;
    final avail = earned - _freezeUsed;
    return avail < 0 ? 0 : avail;
  }

  /// Protects a missed day (defaults today). Returns false if none left.
  bool useFreeze([DateTime? day]) {
    if (freezesAvailable() <= 0) return false;
    final d = day ?? DateTime.now();
    final dates = {..._frozenDates, _dayKey(d)}.toList();
    _meta.put('freezeDates', dates);
    _meta.put('freezeUsed', _freezeUsed + 1);
    return true;
  }

  bool isProtected(DateTime d) => _frozenDates.contains(_dayKey(d));

  /// Streak that treats frozen days as kept, not broken.
  int protectedStreak() {
    final store = HistoryStore();
    final now = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 90; i++) {
      final d = now.subtract(Duration(days: i));
      if (store.hasStreak(d) || isProtected(d)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  // ── Weekly challenges (rotating, derived — no storage) ──
  WeeklyChallenge currentChallenge() {
    final now = DateTime.now();
    final week = _metaWeekKey(now);
    final defs = [
      ('Log 12 meals', 'Every log counts — breakfast to late-night snack.', 12),
      ('4 strong days', 'Days with 3+ meal types logged.', 4),
      ('20 food logs', 'Small entries beat perfect entries.', 20),
    ];
    final def = defs[_weekNumber(now) % defs.length];
    final store = HistoryStore();
    final entries = store.getWeek(now);
    int progress;
    if (def.$1.startsWith('4 strong')) {
      final days = <String>{};
      for (final e in entries) {
        days.add(_dayKey(e.food.time));
      }
      var strong = 0;
      for (final key in days) {
        final parts = key.split('-').map(int.parse).toList();
        final day = DateTime(parts[0], parts[1], parts[2]);
        if (store.hasStreak(day)) strong++;
      }
      progress = strong;
    } else {
      progress = entries.length;
    }
    return WeeklyChallenge(
      id: week,
      title: def.$1,
      subtitle: def.$2,
      target: def.$3,
      progress: progress,
    );
  }

  int _weekNumber(DateTime d) {
    final jan1 = DateTime(d.year, 1, 1);
    return (d.difference(jan1).inDays + jan1.weekday) ~/ 7;
  }

  String _metaWeekKey(DateTime d) =>
      '${d.year}-W${_weekNumber(d)}';

  // ── HIW Score ──────────────────────────────
  HiwScore scoreToday({HiwScoreWeights w = const HiwScoreWeights()}) {
    final n = NutritionStore();
    final target = n.dailyTargetCalories > 0 ? n.dailyTargetCalories : 2000;
    final consumed = n.totalCalories;
    final calPart = ((1 - (consumed - target).abs() / target)
                .clamp(0.0, 1.0) *
            w.calories)
        .round();
    final pTarget = n.proteinTargetG > 0 ? n.proteinTargetG : 60;
    double pSum = 0;
    for (final f in n.todayFoods) {
      pSum += f.protein;
    }
    final proPart =
        ((pSum / pTarget).clamp(0.0, 1.0) * w.protein).round();
    int ticks = 0;
    try {
      ticks = WaterStore().waterTicks;
    } catch (_) {}
    final hydPart =
        ((ticks / 16).clamp(0.0, 1.0) * w.hydration).round();
    final meals = n.todayFoods.map((f) => f.mealType).toSet().length;
    final mealPart =
        ((meals / 3).clamp(0.0, 1.0) * w.meals).round();
    return HiwScore(
      total: (calPart + proPart + hydPart + mealPart).clamp(0, 100),
      caloriesPart: calPart,
      proteinPart: proPart,
      hydrationPart: hydPart,
      mealsPart: mealPart,
    );
  }

  /// Logged-entry counts for the last 7 days (sparkline data).
  List<int> last7MealCounts() {
    final store = HistoryStore();
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return store.getEntriesForDate(d).length;
    });
  }
}
