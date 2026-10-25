import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/core/food_nutrition_database.dart';
import 'package:hiw/core/food_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Country Categorized Database Tests', () {
    test('Categories metadata parses properly', () {
      final jsonSample = jsonEncode([
        {
          'id': 'india',
          'name': 'Indian Cuisine',
          'country': 'India',
          'flag': '🇮🇳',
          'count': 31638,
          'description': 'IFCT, INDB & regional dishes',
          'asset': 'assets/food_data/india.json',
        },
        {
          'id': 'usa',
          'name': 'American / USA',
          'country': 'USA',
          'flag': '🇺🇸',
          'count': 31957,
          'description': 'USDA SR Legacy database',
          'asset': 'assets/food_data/usa.json',
        }
      ]);

      final List<dynamic> list = jsonDecode(jsonSample);
      final categories = list.map((e) => FoodCategoryMeta.fromJson(e)).toList();

      expect(categories.length, 2);
      expect(categories[0].id, 'india');
      expect(categories[0].count, 31638);
      expect(categories[1].id, 'usa');
      expect(categories[1].count, 31957);
    });

    test('FoodNutritionRecord parses categorized country records with macros & micros', () {
      final raw = {
        'name': 'Sushi Roll California',
        'region': 'Japan',
        'diet': 'Non-Veg',
        'meal_type': 'Lunch',
        'serving_unit': '1 roll (6 pieces)',
        'serving_weight_g': 180,
        'calories_per_100g': 145,
        'protein_g': 4.2,
        'carbs_g': 24.5,
        'fats_g': 3.1,
        'fiber_g': 1.8,
        'healthy_score': 82.0,
        'micronutrients_per_100g': {
          'vitamin_a_ug': 25.0,
          'vitamin_c_mg': 2.0,
          'vitamin_b6_mg': 0.12,
          'calcium_mg': 22.0,
          'iron_mg': 1.1,
          'potassium_mg': 140.0,
          'magnesium_mg': 18.0,
          'sodium_mg': 320.0,
          'zinc_mg': 0.8,
        }
      };

      final record = FoodNutritionRecord.fromJson(raw);
      expect(record.name, 'Sushi Roll California');
      expect(record.region, 'Japan');
      expect(record.caloriesPer100g, 145);
      expect(record.proteinG, 4.2);
      expect(record.carbsG, 24.5);
      expect(record.sodiumMg, 320.0);

      final foodItem = record.toFoodItem();
      expect(foodItem.name, 'Sushi Roll California');
      expect(foodItem.calories, (145 * 1.8).round());
    });

    test('FoodSearchService category filtering', () {
      final db = FoodNutritionDatabase();
      final sample = jsonEncode([
        {
          'name': 'Masala Dosa',
          'region': 'India',
          'diet': 'Veg',
          'meal_type': 'Breakfast',
          'serving_unit': '1 dosa',
          'serving_weight_g': 120,
          'calories_per_100g': 165,
          'protein_g': 4.0,
          'carbs_g': 28.0,
          'fats_g': 4.5,
          'fiber_g': 2.0,
          'healthy_score': 78.0,
        },
        {
          'name': 'Classic Cheeseburger',
          'region': 'USA',
          'diet': 'Non-Veg',
          'meal_type': 'Lunch',
          'serving_unit': '1 burger',
          'serving_weight_g': 200,
          'calories_per_100g': 280,
          'protein_g': 15.0,
          'carbs_g': 22.0,
          'fats_g': 14.0,
          'fiber_g': 1.2,
          'healthy_score': 55.0,
        }
      ]);

      db.initWithJsonString(sample);
      final svc = FoodSearchService();
      svc.clearCache();

      // Search with Indian category
      final indianHits = svc.search('Dosa', category: 'India');
      expect(indianHits.isNotEmpty, true);
      expect(indianHits.first.record.name, 'Masala Dosa');

      // Filtered search should not return USA burger
      final burgerInIndia = svc.search('Cheeseburger', category: 'India');
      expect(burgerInIndia.isEmpty, true);

      // Search with USA category
      final usaHits = svc.search('Cheeseburger', category: 'USA');
      expect(usaHits.isNotEmpty, true);
      expect(usaHits.first.record.name, 'Classic Cheeseburger');
    });
  });
}
