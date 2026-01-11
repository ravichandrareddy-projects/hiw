// lib/avatar/avatar_logic.dart

enum FoodQuality { healthy, junk }

class HealthEnergyDelta {
  final double healthDelta;
  final double energyDelta;
  final bool junkConsumed;

  HealthEnergyDelta({
    required this.healthDelta,
    required this.energyDelta,
    required this.junkConsumed,
  });
}

class AvatarLogic {
  static const int targetCalories = 2000;

  /// CALLED ON "PUSH TO AVATAR"
  static HealthEnergyDelta calculateHealthEnergy({
    required FoodQuality mealQuality,
    required int totalDailyCalories,
    required int weeklyJunkCount,
  }) {
    double healthDelta = 0;
    double energyDelta = 0;

    // -------------------------
    // HEALTH (MEAL BASED)
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
    // ENERGY (DAILY BASED)
    // -------------------------
    final diff = (totalDailyCalories - targetCalories).abs();
    if (diff <= 200) {
      energyDelta = 3;
    } else {
      energyDelta = -3;
    }

    return HealthEnergyDelta(
      healthDelta: healthDelta,
      energyDelta: energyDelta,
      junkConsumed: mealQuality == FoodQuality.junk,
    );
  }
}
