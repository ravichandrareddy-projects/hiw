import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/core/goal_engine.dart';
import 'package:hiw/core/health_profile.dart';

void main() {
  UserProfile specExample() => UserProfile(
        age: 25,
        sex: BiologicalSex.male,
        heightCm: 175,
        weightKg: 75,
        activity: ActivityTier.moderatelyActive,
      );

  test('Spec example: BMR/TDEE/maintain calories', () {
    final r = GoalEngine.calculate(
      specExample(),
      GoalModel(primary: PrimaryGoal.maintainWeight),
    );
    // BMR = 750 + 1093.75 - 125 + 5 = 1723.75; TDEE = x1.55 = 2671.8
    expect(r.bmr, closeTo(1723.75, 0.01));
    expect(r.bmrMethod, 'mifflin');
    expect(r.tdee, closeTo(2671.81, 0.1));
    expect(r.calories, 2670);
  });

  test('Macro validation: protein*4 + fat*9 + carbs*4 ≈ target', () {
    for (final goal in PrimaryGoal.values) {
      final r = GoalEngine.calculate(
        specExample(),
        GoalModel(primary: goal),
      );
      final sum = r.proteinG * 4 + r.fatG * 9 + r.carbsG * 4;
      expect((sum - r.calories).abs() <= r.calories * 0.02 + 5, true);
      expect(r.carbsG > 0, true);
    }
  });

  test('Lose weight subtracts deficit; muscle adds surplus', () {
    final base = GoalEngine.calculate(
      specExample(),
      GoalModel(primary: PrimaryGoal.maintainWeight),
    );
    final loss = GoalEngine.calculate(
      specExample(),
      GoalModel(primary: PrimaryGoal.loseWeight),
    );
    final gain = GoalEngine.calculate(
      specExample(),
      GoalModel(primary: PrimaryGoal.buildMuscle),
    );
    expect(loss.calories, base.calories - 400);
    expect(gain.calories, base.calories + 300);
  });

  test('Katch-McArdle only with valid body fat', () {
    final p = specExample()..bodyFatPct = 20;
    final r = GoalEngine.calculate(
      p,
      GoalModel(primary: PrimaryGoal.maintainWeight),
    );
    // LBM = 60; BMR = 370 + 21.6*60 = 1666
    expect(r.bmrMethod, 'katch');
    expect(r.bmr, closeTo(1666.0, 0.5));
  });

  test('Protein scales by context; fiber + water labeled', () {
    final base = GoalEngine.calculate(
      specExample(),
      GoalModel(primary: PrimaryGoal.eatHealthier),
    );
    expect(base.proteinG, 60); // 75kg x 0.8
    final muscle = GoalEngine.calculate(
      specExample(),
      GoalModel(primary: PrimaryGoal.buildMuscle),
    );
    expect(muscle.proteinG, 120); // 75kg x 1.6
    expect(base.fiberG, 25);
    expect(base.waterMl, 2200); // 3700 x 0.6 = 2220 → nearest 50
  });

  test('Female BMR uses -161 constant', () {
    final p = specExample()
      ..sex = BiologicalSex.female;
    final r = GoalEngine.calculate(
      p,
      GoalModel(primary: PrimaryGoal.maintainWeight),
    );
    // 750 + 1093.75 - 125 - 161 = 1557.75
    expect(r.bmr, closeTo(1557.75, 0.01));
  });
}
