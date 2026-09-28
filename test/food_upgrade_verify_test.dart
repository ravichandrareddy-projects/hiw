import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/core/food_nutrition_database.dart';
import 'package:hiw/core/food_search_service.dart';
import 'package:hiw/core/food_result.dart';
import 'package:hiw/core/food_item.dart';

void main() {
  test('DB-first fuzzy search resolves aliases, no duplicates', () async {
    final db = FoodNutritionDatabase();
    db.initWithJsonString('''
    [
      {"name": "Pesarattu", "region": "India", "diet": "Veg", "meal_type": "Breakfast",
       "serving_unit": "1 dosa", "serving_weight_g": 100, "calories_per_100g": 165,
       "protein_g": 6.0, "carbs_g": 28.0, "fats_g": 3.0, "fiber_g": 3.0, "healthy_score": 82.0,
       "micronutrients_per_100g": {}},
      {"name": "Chicken Biryani", "region": "India", "diet": "Non-Veg", "meal_type": "Lunch",
       "serving_unit": "1 bowl", "serving_weight_g": 250, "calories_per_100g": 195,
       "protein_g": 12.0, "carbs_g": 22.0, "fats_g": 6.0, "fiber_g": 1.2, "healthy_score": 55.0,
       "micronutrients_per_100g": {}}
    ]''');
    final svc = FoodSearchService()..clearCache();
    final a = svc.search('pesara dosa');
    final b = svc.search('Pesarattu');
    final c = svc.search('moong dal dosa');
    final d = svc.search('biryani');
    expect(a.isNotEmpty, true);
    expect(a.first.record.name, 'Pesarattu');
    expect(b.first.record.name, 'Pesarattu');
    expect(c.first.record.name, 'Pesarattu');
    expect(d.first.record.name.contains('Biryani'), true);
    expect(svc.search(''), isEmpty);
  });

  test('Nutrition recalculates dynamically with portion', () async {
    final db = FoodNutritionDatabase();
    // reuse loaded db from previous test (singleton)
    final rec = db.records.firstWhere((r) => r.name == 'Chicken Biryani');
    final base = FoodRecognitionResult.fromRecord(rec, quantity: 1.0);
    expect(base.calories, 488); // 195 * 2.5
    final half = base.copyWithPortion(quantity: 0.5);
    expect(half.calories, 244);
    final heavy = base.copyWithPortion(quantity: 2.0);
    expect(heavy.calories, 975);
    expect(heavy.protein, closeTo(60.0, 0.2));
  });

  test('Combo plate combines per-food portions', () async {
    final db = FoodNutritionDatabase();
    final dosa = db.records.firstWhere((r) => r.name == 'Pesarattu');
    final biryani =
        db.records.firstWhere((r) => r.name == 'Chicken Biryani');
    final r = FoodRecognitionResult(
      canonicalFoodId: 'combo',
      displayName: 'Pesarattu',
      confidence: 0.9,
      status: FoodMatchStatus.matched,
      source: FoodSource.aiCamera,
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      fiber: 0,
      servingLabel: 'plate',
      servingWeightG: 100,
      quantity: 1.0,
      mealType: MealType.lunch,
      components: [
        FoodRecognitionResult.fromRecord(dosa, quantity: 1.0),
        FoodRecognitionResult.fromRecord(biryani, quantity: 0.5),
      ],
    );
    expect(r.isCombo, true);
    // 165 + 488/2 = 409
    final total = r.components.fold(0, (a, e) => a + e.calories);
    expect(total, 165 + 244);
    final items = r.toFoodItems();
    expect(items.length, 2);
    expect(items[1].calories, 244);
    // single still returns one item
    final single = FoodRecognitionResult.fromRecord(dosa);
    expect(single.isCombo, false);
    expect(single.toFoodItems().length, 1);
  });

  test('Low confidence threshold flags correctly', () {
    expect(0.92 >= kFoodConfidenceThreshold, true);
    expect(0.58 >= kFoodConfidenceThreshold, false);
    expect(mealTypeFromTime(DateTime(2026, 1, 1, 8)).name, 'breakfast');
    expect(mealTypeFromTime(DateTime(2026, 1, 1, 13)).name, 'lunch');
    expect(mealTypeFromTime(DateTime(2026, 1, 1, 21)).name, 'dinner');
  });
}
