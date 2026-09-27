// lib/avatar/avatar_logic.dart
// for MealType enum if needed, or pass int/string

enum FoodQuality { healthy, junk }

class HealthEnergyDelta {
  final double healthDelta;
  final double energyDelta; // This is TOTAL (Base + Bonus if applicable)
  final double energyBase; // Just the base
  final double energyBonus; // Potential bonus (0 if not eligible time-wise)
  final bool junkConsumed;
  final bool isBonusEligible; // True if Dinner or > 8:30 PM

  HealthEnergyDelta({
    required this.healthDelta,
    required this.energyDelta,
    required this.energyBase,
    required this.energyBonus,
    required this.junkConsumed,
    required this.isBonusEligible,
  });
}

class AvatarLogic {
  /// CALLED ON "PUSH TO AVATAR"
  static HealthEnergyDelta calculateHealthEnergy({
    required FoodQuality mealQuality,
    required int totalDailyCalories,
    required int targetCalories,
    required int weeklyJunkCount,
    required int mealIndex, // 0-3 (Breakfast..Dinner)
    required DateTime currentTime,
  }) {
    double healthDelta = 0;

    // -------------------------
    // HEALTH (UNCHANGED)
    // -------------------------
    if (mealQuality == FoodQuality.healthy) {
      healthDelta = 3.2;
    } else {
      if (weeklyJunkCount < 2) {
        healthDelta = 0; // free chances
      } else {
        healthDelta = -2; // soft penalty
      }
    }

    // -------------------------
    // ENERGY: PART 1 (PER MEAL)
    // -------------------------
    // Base energy per meal = 100 / 26 meals/week = ~3.85
    const double baseEnergy = 3.85;

    // -------------------------
    // ENERGY: PART 2 (DAILY BONUS)
    // -------------------------
    // Rules:
    // - Trigger: Meal is DINNER (index 3) OR Time is > 20:30 (8:30 PM)
    // - Target: 2000 (margin 200)

    double calculatedBonus = 0;

    // Check if "Dinner" (3) OR Time > 8:30 PM
    final isDinner = mealIndex == 3;
    final isLate = currentTime.hour > 20 ||
        (currentTime.hour == 20 && currentTime.minute >= 30);
    final isBonusEligible = isDinner || isLate;

    if (isBonusEligible) {
      final diff = (totalDailyCalories - targetCalories).abs();

      // GOLD ZONE: +/- 200 (e.g. 1800 - 2200)
      if (diff <= 200) {
        calculatedBonus = 10.0;
      }
      // SILVER ZONE: +/- 400 (e.g. 1600-1800 OR 2200-2400)
      else if (diff <= 400) {
        calculatedBonus = 5.0;
      }
      // MISSED
      else {
        calculatedBonus = -5.0;
      }
    }

    return HealthEnergyDelta(
      healthDelta: healthDelta,
      energyDelta:
          baseEnergy + calculatedBonus, // This might be used for display
      energyBase: baseEnergy,
      energyBonus: calculatedBonus,
      junkConsumed: mealQuality == FoodQuality.junk,
      isBonusEligible: isBonusEligible,
    );
  }
}
