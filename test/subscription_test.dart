import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/core/fasting_engine.dart';
import 'package:hiw/core/mealplan_engine.dart';
import 'package:hiw/core/subscription/plan.dart';

void main() {
  test('Plan config is the single source of prices/limits', () {
    expect(PlanConfig.monthlyLabel, '₹119/month');
    expect(PlanConfig.annualLabel, '₹899/year');
    expect(PlanConfig.trialDays, 7);
    expect(PlanConfig.freeScansPerMonth, 40);
    expect(PlanConfig.freeBarcodePerMonth, 20);
    expect(PlanConfig.freeChatPerDay, 5);
    expect(PlanConfig.freeComboFoods, 3);
  });

  test('Fasting presets + progress math', () {
    expect(FastPreset.list.length, 5);
    final start = DateTime(2026, 1, 1, 20, 0);
    final mid = DateTime(2026, 1, 2, 4, 0); // 8h into 16h
    expect(
      FastingEngine.progress(start, 16 * 60, mid),
      closeTo(0.5, 0.001),
    );
    expect(
      FastingEngine.progress(start, 16 * 60, start),
      0.0,
    );
    expect(
      FastingEngine.remainingLabel(start, 16 * 60, mid),
      '08:00:00',
    );
  });

  test('Meal distribution sums to 1.0', () {
    final sum = MealPlanEngine.distribution.values
        .fold(0.0, (a, b) => a + b);
    expect(sum, closeTo(1.0, 0.0001));
  });
}
