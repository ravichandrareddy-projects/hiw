import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'food_item.dart';

class FoodNutritionRecord {
  final String name;
  final String region;
  final String diet;
  final String mealType;
  final String servingUnit;
  final int servingWeightG;
  final int caloriesPer100g;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final double fiberG;
  final double healthyScore;

  // Micronutrients per 100g
  final double vitaminAUg;
  final double vitaminCMg;
  final double vitaminB6Mg;
  final double calciumMg;
  final double ironMg;
  final double potassiumMg;
  final double magnesiumMg;
  final double sodiumMg;
  final double zincMg;

  const FoodNutritionRecord({
    required this.name,
    required this.region,
    required this.diet,
    required this.mealType,
    required this.servingUnit,
    required this.servingWeightG,
    required this.caloriesPer100g,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.fiberG,
    required this.healthyScore,
    required this.vitaminAUg,
    required this.vitaminCMg,
    required this.vitaminB6Mg,
    required this.calciumMg,
    required this.ironMg,
    required this.potassiumMg,
    required this.magnesiumMg,
    required this.sodiumMg,
    required this.zincMg,
  });

  factory FoodNutritionRecord.fromJson(Map<String, dynamic> json) {
    final micros = json['micronutrients_per_100g'] as Map<String, dynamic>? ?? {};
    return FoodNutritionRecord(
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? 'India',
      diet: json['diet'] as String? ?? 'Veg',
      mealType: json['meal_type'] as String? ?? 'Lunch',
      servingUnit: json['serving_unit'] as String? ?? '1 serving',
      servingWeightG: (json['serving_weight_g'] as num?)?.toInt() ?? 150,
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toInt() ?? 100,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatsG: (json['fats_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      healthyScore: (json['healthy_score'] as num?)?.toDouble() ?? 75.0,
      vitaminAUg: (micros['vitamin_a_ug'] as num?)?.toDouble() ?? 0.0,
      vitaminCMg: (micros['vitamin_c_mg'] as num?)?.toDouble() ?? 0.0,
      vitaminB6Mg: (micros['vitamin_b6_mg'] as num?)?.toDouble() ?? 0.0,
      calciumMg: (micros['calcium_mg'] as num?)?.toDouble() ?? 0.0,
      ironMg: (micros['iron_mg'] as num?)?.toDouble() ?? 0.0,
      potassiumMg: (micros['potassium_mg'] as num?)?.toDouble() ?? 0.0,
      magnesiumMg: (micros['magnesium_mg'] as num?)?.toDouble() ?? 0.0,
      sodiumMg: (micros['sodium_mg'] as num?)?.toDouble() ?? 0.0,
      zincMg: (micros['zinc_mg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to FoodItem scaled by portion quantity
  FoodItem toFoodItem({double quantityMultiplier = 1.0, MealType? overrideMealType}) {
    final effectiveGrams = servingWeightG * quantityMultiplier;
    final factor = effectiveGrams / 100.0;

    MealType mType = overrideMealType ?? MealType.lunch;
    if (overrideMealType == null) {
      final mt = mealType.toLowerCase();
      if (mt.contains('break')) {
        mType = MealType.breakfast;
      } else if (mt.contains('dinner')) {
        mType = MealType.dinner;
      } else if (mt.contains('snack')) {
        mType = MealType.snack;
      }
    }

    return FoodItem(
      name: name,
      mealType: mType,
      calories: (caloriesPer100g * factor).round(),
      protein: double.parse((proteinG * factor).toStringAsFixed(1)),
      carbs: double.parse((carbsG * factor).toStringAsFixed(1)),
      fats: double.parse((fatsG * factor).toStringAsFixed(1)),
      fiber: double.parse((fiberG * factor).toStringAsFixed(1)),
      vitaminA: double.parse((vitaminAUg * factor).toStringAsFixed(1)),
      vitaminC: double.parse((vitaminCMg * factor).toStringAsFixed(1)),
      vitaminB6: double.parse((vitaminB6Mg * factor).toStringAsFixed(2)),
      calcium: double.parse((calciumMg * factor).toStringAsFixed(1)),
      iron: double.parse((ironMg * factor).toStringAsFixed(1)),
      potassium: double.parse((potassiumMg * factor).toStringAsFixed(1)),
      magnesium: double.parse((magnesiumMg * factor).toStringAsFixed(1)),
      sodium: double.parse((sodiumMg * factor).toStringAsFixed(1)),
      zinc: double.parse((zincMg * factor).toStringAsFixed(1)),
    );
  }
}

class FoodNutritionDatabase {
  static final FoodNutritionDatabase _instance = FoodNutritionDatabase._internal();
  factory FoodNutritionDatabase() => _instance;
  FoodNutritionDatabase._internal();

  final List<FoodNutritionRecord> _records = [];
  final Map<String, FoodNutritionRecord> _exactIndex = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  int get count => _records.length;
  List<FoodNutritionRecord> get records => List.unmodifiable(_records);

  /// Load database from bundled JSON asset
  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/food_nutrition_db.json');
      final List<dynamic> list = json.decode(jsonString);
      _records.clear();
      _exactIndex.clear();

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final record = FoodNutritionRecord.fromJson(item);
          _records.add(record);
          _exactIndex[record.name.toLowerCase().trim()] = record;
        }
      }
      _isLoaded = true;
    } catch (e) {
      // Fallback if asset loading fails or in test environments
      _isLoaded = false;
    }
  }

  /// Initialize directly from JSON string (helpful for testing)
  void initWithJsonString(String jsonString) {
    final List<dynamic> list = json.decode(jsonString);
    _records.clear();
    _exactIndex.clear();
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final record = FoodNutritionRecord.fromJson(item);
        _records.add(record);
        _exactIndex[record.name.toLowerCase().trim()] = record;
      }
    }
    _isLoaded = true;
  }

  /// Best match lookup (exact, normalized, or fuzzy substring)
  FoodNutritionRecord? findMatch(String query) {
    if (query.isEmpty) return null;
    final q = query.toLowerCase().trim();

    // 1. Exact match
    if (_exactIndex.containsKey(q)) {
      return _exactIndex[q];
    }

    // 2. Contains search
    for (final entry in _exactIndex.entries) {
      if (entry.key.contains(q) || q.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. Keyword token overlap
    final qTokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
    FoodNutritionRecord? bestRecord;
    int maxMatches = 0;

    for (final record in _records) {
      final rTokens = record.name.toLowerCase().split(RegExp(r'\s+')).toSet();
      final common = qTokens.intersection(rTokens).length;
      if (common > maxMatches) {
        maxMatches = common;
        bestRecord = record;
      }
    }

    return maxMatches > 0 ? bestRecord : null;
  }
}
