// lib/avatar/avatar_logic.dart

enum FoodQuality { healthy, junk }

class DailyAvatarInput {
  final List<FoodQuality> meals; // meals eaten today
  final int calories;            // total calories today
  final int waterTicks;          // 🆕 hourly water confirmations
  final bool isSaturday;         // half-day logic

  DailyAvatarInput({
    required this.meals,
    required this.calories,
    required this.waterTicks,
    required this.isSaturday,
  });
}

class AvatarLogic {
  static const int maxRawPerDay = 4;
  static const int maxRawSaturday = 2;
  static const int weeklyMaxRaw = 26;
  static const int weeklyMaxStat = 83;
  static const int targetCalories = 2000;

  /// Returns raw points earned today (0 → 4 or 2)
  static int calculateDailyRaw(DailyAvatarInput input) {
    int raw = 0;

    // -------------------------
    // HEALTH (food quality)
    // -------------------------
    for (final meal in input.meals) {
      if (meal == FoodQuality.healthy) raw += 1;
      if (meal == FoodQuality.junk) raw -= 1;
    }

    // -------------------------
    // ENERGY (calorie balance)
    // -------------------------
    final diff = (input.calories - targetCalories).abs();
    if (diff <= 200) {
      raw += 1;
    } else {
      raw -= 1;
    }

    // -------------------------
    // STAMINA (hydration - HOURLY)
    // -------------------------
    if (input.waterTicks >= 6) {
      raw += 1; // well hydrated day
    } else if (input.waterTicks >= 3) {
      raw += 0; // neutral
    } else {
      raw -= 2; // dehydration penalty
    }

    // -------------------------
    // Clamp per day
    // -------------------------
    final max = input.isSaturday ? maxRawSaturday : maxRawPerDay;
    return raw.clamp(0, max);
  }

  /// Convert weekly raw → final stat (0 → 83)
  static int scaleWeeklyRawToStat(int weeklyRaw) {
    final scaled =
        (weeklyRaw / weeklyMaxRaw) * weeklyMaxStat;
    return scaled.round().clamp(0, weeklyMaxStat);
  }
}
