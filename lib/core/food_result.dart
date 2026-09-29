// lib/core/food_result.dart
// Normalized result model shared by Camera mode + Text mode.
// Both paths converge: FoodRecognitionResult -> FoodCustomization -> MealEntry.
import 'package:flutter/material.dart';
import 'food_item.dart';
import 'food_nutrition_database.dart';
import '../services/food_recognition_service.dart';

/// Confidence below this → show "Is this correct?" + candidates.
const double kFoodConfidenceThreshold = 0.75;

/// Scan duration bounds — UI never fakes long waits.
/// Kept tiny (anti-flicker only); result shows the moment AI returns.
const Duration kMinScanDuration = Duration(milliseconds: 500);
const Duration kMaxScanDuration = Duration(seconds: 5);

enum FoodMatchStatus { matched, lowConfidence, notFood, noMatch }

enum FoodSource { db, aiCamera, aiText, custom }

class FoodCandidate {
  final String displayName;
  final double confidence;
  final FoodNutritionRecord? record;
  const FoodCandidate({
    required this.displayName,
    required this.confidence,
    this.record,
  });
}

class FoodRecognitionResult {
  final String canonicalFoodId;
  final String displayName;
  final double confidence; // 0..1
  final FoodMatchStatus status;
  final FoodSource source;

  final ImageProvider? image;
  final String? imagePath;

  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final double fiber;

  final String servingLabel;
  final int servingWeightG;
  final double quantity;

  MealType mealType;
  final FoodNutritionRecord? record;
  final List<FoodCandidate> alternatives;
  final List<ScannedItem> items;
  // Multi-food: one entry per distinct edible item with known nutrition
  // (Food A, Food B, Food C), each with its own portion. Empty = single.
  final List<FoodRecognitionResult> components;

  FoodRecognitionResult({
    required this.canonicalFoodId,
    required this.displayName,
    required this.confidence,
    required this.status,
    required this.source,
    this.image,
    this.imagePath,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
    required this.servingLabel,
    required this.servingWeightG,
    required this.quantity,
    required this.mealType,
    this.record,
    this.alternatives = const [],
    this.items = const [],
    this.components = const [],
  });

  bool get isLowConfidence =>
      status == FoodMatchStatus.lowConfidence ||
      confidence < kFoodConfidenceThreshold;

  bool get isCombo => components.length > 1;

  /// Build from camera AI RecognitionResult.
  factory FoodRecognitionResult.fromRecognition(
    RecognitionResult r, {
    ImageProvider? image,
    String? imagePath,
    MealType mealType = MealType.lunch,
    List<FoodCandidate> alternatives = const [],
  }) {
    final conf = (r.healthyScore / 100.0).clamp(0.0, 1.0);
    FoodMatchStatus status;
    if (r.isNotFood || !r.isFood) {
      status = FoodMatchStatus.notFood;
    } else if (!r.isInDataset || r.nutritionRecord == null) {
      status = FoodMatchStatus.noMatch;
    } else if (conf < kFoodConfidenceThreshold) {
      status = FoodMatchStatus.lowConfidence;
    } else {
      status = FoodMatchStatus.matched;
    }
    final rec = r.nutritionRecord;
    FoodItem? scaled;
    if (rec != null) {
      scaled = rec.toFoodItem(
        quantityMultiplier: r.estimatedQuantity,
        overrideMealType: mealType,
      );
    }
    final id = rec?.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_') ??
        r.itemName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    // Multi-food: one component per distinct edible item with DB nutrition.
    final comps = <FoodRecognitionResult>[];
    for (final item in r.items) {
      if (!item.isEdible || item.record == null) continue;
      final q = item.quantity <= 0 ? 1.0 : item.quantity.clamp(0.25, 3.0);
      comps.add(FoodRecognitionResult.fromRecord(
        item.record!,
        quantity: q,
        mealType: mealType,
        source: FoodSource.aiCamera,
      ));
    }
    // Top-level nutrition = combined totals when several foods share a plate.
    var cal = scaled?.calories ?? 0;
    var p = scaled?.protein ?? 0.0;
    var c = scaled?.carbs ?? 0.0;
    var f = scaled?.fats ?? 0.0;
    var fib = scaled?.fiber ?? 0.0;
    if (comps.length > 1) {
      cal = comps.fold(0, (a, e) => a + e.calories);
      p = comps.fold(0.0, (a, e) => a + e.protein);
      c = comps.fold(0.0, (a, e) => a + e.carbs);
      f = comps.fold(0.0, (a, e) => a + e.fats);
      fib = comps.fold(0.0, (a, e) => a + e.fiber);
    }
    return FoodRecognitionResult(
      canonicalFoodId: id,
      displayName: rec?.name ?? r.itemName,
      confidence: conf,
      status: status,
      source: FoodSource.aiCamera,
      image: image,
      imagePath: imagePath,
      calories: cal,
      protein: double.parse(p.toStringAsFixed(1)),
      carbs: double.parse(c.toStringAsFixed(1)),
      fats: double.parse(f.toStringAsFixed(1)),
      fiber: double.parse(fib.toStringAsFixed(1)),
      servingLabel: rec?.servingUnit ?? r.servingUnit ?? '1 serving',
      servingWeightG: rec?.servingWeightG ?? 150,
      quantity: r.estimatedQuantity,
      mealType: mealType,
      record: rec,
      alternatives: alternatives,
      items: r.items,
      components: comps,
    );
  }

  /// Build from a local DB record (Text mode selection).
  factory FoodRecognitionResult.fromRecord(
    FoodNutritionRecord rec, {
    ImageProvider? image,
    String? imagePath,
    double quantity = 1.0,
    MealType mealType = MealType.lunch,
    FoodSource source = FoodSource.db,
    double? confidence,
  }) {
    final scaled = rec.toFoodItem(
      quantityMultiplier: quantity,
      overrideMealType: mealType,
    );
    final conf = confidence ?? (rec.healthyScore / 100.0).clamp(0.0, 1.0);
    return FoodRecognitionResult(
      canonicalFoodId:
          rec.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
      displayName: rec.name,
      confidence: conf,
      status: conf < kFoodConfidenceThreshold
          ? FoodMatchStatus.lowConfidence
          : FoodMatchStatus.matched,
      source: source,
      image: image,
      imagePath: imagePath,
      calories: scaled.calories,
      protein: scaled.protein,
      carbs: scaled.carbs,
      fats: scaled.fats,
      fiber: scaled.fiber,
      servingLabel: rec.servingUnit,
      servingWeightG: rec.servingWeightG,
      quantity: quantity,
      mealType: mealType,
      record: rec,
    );
  }

  /// Recompute nutrition for a new quantity/weight without static tables.
  FoodRecognitionResult copyWithPortion({
    double? quantity,
    int? weightG,
    MealType? mealType,
    Map<String, dynamic>? addons,
  }) {
    // Addon extras are applied by the caller via engine; here we scale base.
    final q = quantity ?? this.quantity;
    final w = weightG ?? servingWeightG;
    int cal = calories;
    double p = protein, c = carbs, f = fats, fib = fiber;
    if (record != null) {
      // weight-driven: factor = (w * q-ish) / 100.
      // quantity here means number of servings; weight is per-serving.
      final factor = (w * q) / 100.0;
      cal = (record!.caloriesPer100g * factor).round();
      p = double.parse((record!.proteinG * factor).toStringAsFixed(1));
      c = double.parse((record!.carbsG * factor).toStringAsFixed(1));
      f = double.parse((record!.fatsG * factor).toStringAsFixed(1));
      fib = double.parse((record!.fiberG * factor).toStringAsFixed(1));
    }
    return FoodRecognitionResult(
      canonicalFoodId: canonicalFoodId,
      displayName: displayName,
      confidence: confidence,
      status: status,
      source: source,
      image: image,
      imagePath: imagePath,
      calories: cal,
      protein: p,
      carbs: c,
      fats: f,
      fiber: fib,
      servingLabel: servingLabel,
      servingWeightG: w,
      quantity: q,
      mealType: mealType ?? this.mealType,
      record: record,
      alternatives: alternatives,
      items: items,
      components: components,
    );
  }

  /// Final FoodItem for the existing meal pipeline.
  FoodItem toFoodItem() {
    return FoodItem(
      name: displayName,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      fiber: fiber,
    );
  }

  /// Combo save: one FoodItem per component (each keeps its own portion).
  List<FoodItem> toFoodItems() {
    if (!isCombo) return [toFoodItem()];
    return components.map((e) => e.toFoodItem()).toList();
  }

  /// Free-tier plate cap: keep the first [n] foods, totals recombined.
  FoodRecognitionResult truncated(int n) {
    if (!isCombo || components.length <= n) return this;
    final kept = components.sublist(0, n);
    double sum(double Function(FoodRecognitionResult) f) =>
        kept.fold(0.0, (a, e) => a + f(e));
    return FoodRecognitionResult(
      canonicalFoodId: canonicalFoodId,
      displayName: displayName,
      confidence: confidence,
      status: status,
      source: source,
      image: image,
      imagePath: imagePath,
      calories: kept.fold(0, (a, e) => a + e.calories),
      protein: double.parse(sum((e) => e.protein).toStringAsFixed(1)),
      carbs: double.parse(sum((e) => e.carbs).toStringAsFixed(1)),
      fats: double.parse(sum((e) => e.fats).toStringAsFixed(1)),
      fiber: double.parse(sum((e) => e.fiber).toStringAsFixed(1)),
      servingLabel: servingLabel,
      servingWeightG: servingWeightG,
      quantity: quantity,
      mealType: mealType,
      record: record,
      alternatives: alternatives,
      items: items,
      components: kept,
    );
  }

  String get mealLabel {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.snack:
        return 'Snack';
      case MealType.dinner:
        return 'Dinner';
      case MealType.lateNight:
        return 'Snack';
    }
  }
}

/// Time-based meal hint (used when entering scanner without a preselected meal).
MealType mealTypeFromTime(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 11) return MealType.breakfast;
  if (h >= 11 && h < 16) return MealType.lunch;
  if (h >= 16 && h < 19) return MealType.snack;
  return MealType.dinner;
}

/// DB record meal_type string → MealType hint.
MealType mealTypeFromRecord(FoodNutritionRecord rec) {
  final mt = rec.mealType.toLowerCase();
  if (mt.contains('break')) return MealType.breakfast;
  if (mt.contains('dinner')) return MealType.dinner;
  if (mt.contains('snack')) return MealType.snack;
  return MealType.lunch;
}
