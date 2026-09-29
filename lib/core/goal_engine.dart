// lib/core/goal_engine.dart
// Deterministic personalization engine (spec §§1–26). Pure Dart.
// The LLM may EXPLAIN results; it must NEVER compute them.

import 'health_profile.dart';

/// Tunable product settings — not universal physiological rules.
class GoalTuning {
  final double deficitKcal; // weight-loss daily deficit
  final double surplusKcal; // muscle/weight-gain daily surplus
  final double proteinBase; // g/kg general baseline
  final double proteinActive; // g/kg weight-management range mid
  final double proteinMuscle; // g/kg resistance/muscle target
  final double fatRatio; // fraction of calories from fat
  final int fiberG; // starting reference
  final int glassMl; // configurable glass size
  final double minCalories; // safety floor
  final double maxCalories; // safety ceiling

  const GoalTuning({
    this.deficitKcal = 400,
    this.surplusKcal = 300,
    this.proteinBase = 0.8,
    this.proteinActive = 1.4,
    this.proteinMuscle = 1.6,
    this.fatRatio = 0.28,
    this.fiberG = 25,
    this.glassMl = 250,
    this.minCalories = 1200,
    this.maxCalories = 5000,
  });
}

class GoalResult {
  final double bmr;
  final String bmrMethod; // 'mifflin' | 'katch'
  final double tdee;
  final int calories; // display-rounded
  final int proteinG;
  final int fatG;
  final int carbsG;
  final int fiberG;
  final int waterMl; // "Starting hydration target"
  final String rationale;
  static const String version = 'hiw-goal-v1';

  const GoalResult({
    required this.bmr,
    required this.bmrMethod,
    required this.tdee,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
    required this.waterMl,
    required this.rationale,
  });
}

class GoalEngine {
  static double activityFactor(ActivityTier a) {
    switch (a) {
      case ActivityTier.sedentary:
        return 1.20;
      case ActivityTier.lightlyActive:
        return 1.375;
      case ActivityTier.moderatelyActive:
        return 1.55;
      case ActivityTier.veryActive:
        return 1.725;
      case ActivityTier.extremelyActive:
        return 1.90;
    }
  }

  /// Full pipeline: profile → BMR → TDEE → goal calories → macros →
  /// fiber + hydration. Keeps full precision; rounds only for display.
  static GoalResult calculate(
    UserProfile p,
    GoalModel g, {
    GoalTuning tuning = const GoalTuning(),
  }) {
    final age = (p.age ?? 25).clamp(10, 100);
    final height = (p.heightCm ?? 170).clamp(100.0, 250.0);
    final weight = (p.weightKg ?? 70).clamp(25.0, 300.0);
    final activity =
        p.activity ?? ActivityTier.moderatelyActive;

    // 1–2. BMR: Katch-McArdle only with valid body-fat %, else Mifflin.
    double bmr;
    String method;
    final bf = p.bodyFatPct;
    if (bf != null && bf > 2 && bf < 70) {
      final lbm = weight * (1 - bf / 100);
      bmr = 370 + 21.6 * lbm;
      method = 'katch';
    } else if (p.sex == BiologicalSex.female) {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
      method = 'mifflin';
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
      method = 'mifflin';
    }

    // 3. TDEE.
    final tdee = bmr * activityFactor(activity);

    // 4. Goal-adjusted calories (safety-checked, configurable).
    double target;
    switch (g.primary) {
      case PrimaryGoal.loseWeight:
        target = tdee - tuning.deficitKcal;
        break;
      case PrimaryGoal.buildMuscle:
        target = tdee + tuning.surplusKcal;
        break;
      case PrimaryGoal.maintainWeight:
      case PrimaryGoal.eatHealthier:
      case PrimaryGoal.improveNutrition:
      case PrimaryGoal.buildHabits:
        target = tdee;
        break;
    }
    target = target.clamp(tuning.minCalories, tuning.maxCalories);

    // 5. Protein by context (g/kg), never forced to the top for everyone.
    double perKg = tuning.proteinBase;
    if (g.primary == PrimaryGoal.buildMuscle) {
      perKg = tuning.proteinMuscle;
    } else if (g.primary == PrimaryGoal.loseWeight ||
        g.primary == PrimaryGoal.improveNutrition) {
      perKg = tuning.proteinActive;
    }
    final proteinG = weight * perKg;
    final proteinCal = proteinG * 4;

    // 6–7. Fat ratio, carbs get the remainder (never negative).
    var fatCal = target * tuning.fatRatio;
    var carbCal = target - proteinCal - fatCal;
    var fatRatio = tuning.fatRatio;
    if (carbCal < 0) {
      // Rebalance: shrink fat share until carbs fit (min 10% carbs).
      fatRatio = 0.35;
      fatCal = target * fatRatio;
      carbCal = target - proteinCal - fatCal;
      if (carbCal < target * 0.10) {
        carbCal = target * 0.10;
        fatCal = target - proteinCal - carbCal;
      }
    }
    final fatG = fatCal / 9;
    final carbsG = carbCal / 4;

    // 8. Macro validation (protein*4 + fat*9 + carbs*4 ≈ target).
    assert(
      ((proteinG * 4 + fatG * 9 + carbsG * 4) - target).abs() <
          target * 0.02 + 5,
      'macro allocation does not sum to target',
    );

    // 10. Hydration: reference total-water scaled, stored as STARTING target.
    // Spec refs (19–30): male 3.7L / female 2.7L total water incl. food.
    // MVP: configurable starting drinking-water target ≈ 60% of total.
    final totalWaterMl =
        (p.sex == BiologicalSex.female ? 2700 : 3700).toDouble();
    final waterMl = totalWaterMl * 0.6;

    int round10(double v) => (v / 10).round() * 10;
    int round5(double v) => (v / 5).round() * 5;

    return GoalResult(
      bmr: bmr,
      bmrMethod: method,
      tdee: tdee,
      calories: round10(target),
      proteinG: round5(proteinG),
      fatG: round5(fatG),
      carbsG: round5(carbsG),
      fiberG: tuning.fiberG,
      waterMl: (waterMl / 50).round() * 50,
      rationale:
          'Based on your profile (${goalLabel(g.primary).toLowerCase()}, ${activityLabel(activity).toLowerCase()}). Starting targets — change anytime.',
    );
  }

  /// Congenial display helpers (§24).
  static String kcalLabel(int kcal) => '$kcal kcal';
  static String gramsLabel(int g, String noun) => '$g g $noun';
  static String waterLabel(int ml) =>
      ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)} L' : '$ml ml';
}
