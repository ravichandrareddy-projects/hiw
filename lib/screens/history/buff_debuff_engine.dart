import 'meal_time.dart';

/// Immutable impact result
class AvatarImpact {
  final double health;
  final double energy;
  final double stamina;

  const AvatarImpact({
    required this.health,
    required this.energy,
    required this.stamina,
  });

  /// Combine impacts safely (for multiple meals/day)
  AvatarImpact combine(AvatarImpact other) {
    return AvatarImpact(
      health: (health + other.health).clamp(-100, 100),
      energy: (energy + other.energy).clamp(-100, 100),
      stamina: (stamina + other.stamina).clamp(-100, 100),
    );
  }
}

/// -------------------------
/// CORE FORMULA (PURE FUNCTION)
/// -------------------------
AvatarImpact calculateImpact({
  required int calories,
  required double healthyScore, // 0 → 1
  required MealType mealType,
  required DateTime time,
}) {
  double health = 0;
  double energy = 0;
  double stamina = 0;

  // -------------------------
  // 1️⃣ FOOD QUALITY IMPACT
  // -------------------------
  if (healthyScore >= 0.8) {
    health += 6;
    energy += 4;
  } else if (healthyScore >= 0.5) {
    health += 3;
    energy += 2;
  } else if (healthyScore < 0.3) {
    health -= 5;
    stamina -= 4;
  }

  // -------------------------
  // 2️⃣ CALORIE BALANCE
  // -------------------------
  if (calories < 200) {
    energy -= 2; // under-eating
  } else if (calories > 900) {
    stamina -= 4; // overeating
  }

  // -------------------------
  // 3️⃣ MEAL TIME EFFECT
  // -------------------------
  final isLateNight = time.hour >= 21;
  final isBreakfast = mealType == MealType.breakfast;

  if (isLateNight) {
    if (healthyScore < 0.5) {
      stamina -= 6;
      energy -= 4;
    } else {
      stamina -= 2; // soft penalty
    }
  }

  if (isBreakfast && healthyScore >= 0.6) {
    energy += 3; // good breakfast bonus
  }

  // -------------------------
  // FINAL CLAMP (PER MEAL)
  // -------------------------
  return AvatarImpact(
    health: health.clamp(-10, 10),
    energy: energy.clamp(-10, 10),
    stamina: stamina.clamp(-10, 10),
  );
}
