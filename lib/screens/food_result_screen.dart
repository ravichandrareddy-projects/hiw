// lib/screens/food_result_screen.dart
// SHARED result + customization screen for Camera mode + Text mode.
// Both produce FoodRecognitionResult and feed the same meal pipeline.
// Glassmorphism, theme tokens only — no hardcoded theme colors.
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/food_item.dart';
import '../core/food_result.dart';
import '../core/nutrition_store.dart';
import '../core/history_store.dart';
import '../core/health_engine.dart';
import '../core/addon_nutrition_rules.dart';
import '../core/serving_catalog.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';

class FoodResultScreen extends StatefulWidget {
  final FoodRecognitionResult initial;
  final VoidCallback? onReplaceImage;
  const FoodResultScreen({
    super.key,
    required this.initial,
    this.onReplaceImage,
  });

  @override
  State<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends State<FoodResultScreen> {
  late double _quantity;
  late int _weightG;
  late MealType _meal;
  late FoodRecognitionResult _live;
  // Combo: one quantity per detected food sharing the plate.
  late List<double> _comboQty;
  final Set<String> _addons = {};
  bool _isSaving = false;
  String? _savedKey;

  late FoodServingSpec _servingSpec;
  int _selectedCount = 1;
  ServingSizeOption? _selectedSize;

  // Common add-on ids → try engine rules first, fallback table below.
  static const List<Map<String, String>> kAddonChoices = [
    {'id': 'ghee', 'label': 'Ghee'},
    {'id': 'oil', 'label': 'Oil'},
    {'id': 'butter', 'label': 'Butter'},
    {'id': 'chutney', 'label': 'Chutney'},
    {'id': 'sambar', 'label': 'Sambar'},
    {'id': 'raita', 'label': 'Raita'},
    {'id': 'extra_rice', 'label': 'Extra rice'},
    {'id': 'extra_chicken', 'label': 'Extra chicken'},
  ];

  static const Map<String, List<double>> kAddonFallback = {
    // cal, protein, carbs, fats, fiber
    'ghee': [45, 0, 0, 5, 0],
    'oil': [40, 0, 0, 4.5, 0],
    'butter': [35, 0.2, 0, 4, 0],
    'chutney': [40, 1, 6, 2, 1],
    'sambar': [60, 3, 9, 2, 2],
    'raita': [35, 2, 4, 1.5, 0.5],
    'extra_rice': [130, 2.5, 28, 0.3, 0.5],
    'extra_chicken': [150, 18, 0, 8, 0],
  };

  @override
  void initState() {
    super.initState();
    _servingSpec = ServingCatalog.getSpec(
      widget.initial.displayName,
      record: widget.initial.record,
    );
    _selectedCount = _servingSpec.countOptions.first;
    _selectedSize = _servingSpec.sizeOptions.firstWhere(
      (s) => (s.multiplier - 1.0).abs() < 0.05,
      orElse: () => _servingSpec.sizeOptions.first,
    );

    _quantity = (_selectedCount * _selectedSize!.multiplier).clamp(0.25, 6.0);
    _weightG = widget.initial.servingWeightG > 0
        ? widget.initial.servingWeightG
        : (_selectedSize!.defaultWeightG * _selectedCount);
    _meal = widget.initial.mealType;
    _comboQty = widget.initial.components
        .map((e) => e.quantity.clamp(0.25, 3.0))
        .toList();
    _live = _recalc();
  }

  FoodRecognitionResult _recalc() {
    // Combo plate: recompute each food with its own portion, then combine.
    if (widget.initial.isCombo) {
      final updated = <FoodRecognitionResult>[];
      for (var i = 0; i < widget.initial.components.length; i++) {
        updated.add(widget.initial.components[i].copyWithPortion(
          quantity: _comboQty[i],
          mealType: _meal,
        ));
      }
      rRound(double v) => double.parse(v.toStringAsFixed(1));
      return FoodRecognitionResult(
        canonicalFoodId: widget.initial.canonicalFoodId,
        displayName: widget.initial.displayName,
        confidence: widget.initial.confidence,
        status: widget.initial.status,
        source: widget.initial.source,
        image: widget.initial.image,
        imagePath: widget.initial.imagePath,
        calories: updated.fold(0, (a, e) => a + e.calories),
        protein: rRound(updated.fold(0.0, (a, e) => a + e.protein)),
        carbs: rRound(updated.fold(0.0, (a, e) => a + e.carbs)),
        fats: rRound(updated.fold(0.0, (a, e) => a + e.fats)),
        fiber: rRound(updated.fold(0.0, (a, e) => a + e.fiber)),
        servingLabel: widget.initial.servingLabel,
        servingWeightG: widget.initial.servingWeightG,
        quantity: widget.initial.quantity,
        mealType: _meal,
        record: widget.initial.record,
        alternatives: widget.initial.alternatives,
        items: widget.initial.items,
        components: updated,
      );
    }
    var r = widget.initial.copyWithPortion(
      quantity: _quantity,
      weightG: _weightG,
      mealType: _meal,
    );
    // Dynamic add-on stacking from contextual catalog & rules
    var cal = r.calories;
    var p = r.protein, c = r.carbs, f = r.fats, fib = r.fiber;
    for (final id in _addons) {
      final spec = _servingSpec.contextualAddons.where((a) => a.id == id).firstOrNull;
      if (spec != null) {
        cal += spec.calories;
        p += spec.protein;
        c += spec.carbs;
        f += spec.fats;
        fib += spec.fiber;
      } else {
        final rule = addonNutritionRules[id];
        if (rule != null) {
          cal += rule.calories;
          p += rule.protein;
          c += rule.carbs;
          f += rule.fats;
          fib += rule.fiber;
        } else if (kAddonFallback.containsKey(id)) {
          final v = kAddonFallback[id]!;
          cal += v[0].round();
          p += v[1];
          c += v[2];
          f += v[3];
          fib += v[4];
        }
      }
    }
    return FoodRecognitionResult(
      canonicalFoodId: r.canonicalFoodId,
      displayName: r.displayName,
      confidence: r.confidence,
      status: r.status,
      source: r.source,
      image: r.image,
      imagePath: r.imagePath,
      calories: cal,
      protein: double.parse(p.toStringAsFixed(1)),
      carbs: double.parse(c.toStringAsFixed(1)),
      fats: double.parse(f.toStringAsFixed(1)),
      fiber: double.parse(fib.toStringAsFixed(1)),
      servingLabel: r.servingLabel,
      servingWeightG: r.servingWeightG,
      quantity: r.quantity,
      mealType: r.mealType,
      record: r.record,
      alternatives: r.alternatives,
      items: r.items,
      components: r.components,
    );
  }

  String get _portionSummary {
    if (_selectedSize != null) {
      final unit = _selectedCount == 1 ? _servingSpec.unitName : (_servingSpec.unitName.endsWith('s') ? _servingSpec.unitName : '${_servingSpec.unitName}s');
      return '$_selectedCount $unit • $_weightG g';
    }
    return '${_quantity.toStringAsFixed(1)}× • $_weightG g';
  }

  String get _portionSubtitle {
    final countLabel = '$_selectedCount ${_selectedCount == 1 ? _servingSpec.unitName : (_servingSpec.unitName.endsWith('s') ? _servingSpec.unitName : '${_servingSpec.unitName}s')}';
    if (_selectedSize != null) {
      return '$countLabel (${_selectedSize!.label}) • $_weightG g';
    }
    return '$countLabel • $_weightG g';
  }

  String get _addonsSubtitle {
    if (_addons.isEmpty) {
      return _servingSpec.contextualAddons.isNotEmpty
          ? _servingSpec.contextualAddons.take(3).map((a) => a.label.split(' (').first).join(', ')
          : 'Ghee, Chutney, Sambar...';
    }
    final labels = _addons.map((id) {
      final spec = _servingSpec.contextualAddons.where((a) => a.id == id).firstOrNull;
      if (spec != null) return spec.label.split(' (').first;
      final fb = kAddonChoices.where((a) => a['id'] == id).firstOrNull;
      return fb?['label'] ?? id;
    }).toList();
    return labels.join(', ');
  }

  Future<void> _openPortionSheet() async {
    final t = HiwTheme.of(context);
    int count = _selectedCount;
    ServingSizeOption? size = _selectedSize;
    double w = _weightG.toDouble();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
              decoration: BoxDecoration(
                color: t.cardBackground,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: t.cardStroke),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: t.mutedColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portion & Serving Size',
                                style: TextStyle(
                                  color: t.inkColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _live.displayName,
                                style: TextStyle(
                                  color: t.mutedColor,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: t.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                                color: t.accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${w.round()} g',
                            style: TextStyle(
                              color: t.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // 1. COUNT SELECTION (e.g. 1, 2, 3... dosas or pieces)
                    Text(
                      _servingSpec.countLabel,
                      style: TextStyle(
                        color: t.inkColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _servingSpec.countOptions.map((c) {
                        final isSel = count == c;
                        final label = '$c ${_servingSpec.unitName}${c > 1 && !_servingSpec.unitName.endsWith('s') ? 's' : ''}';
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              setSheet(() {
                                count = c;
                                final base = size?.defaultWeightG ?? _servingSpec.baseWeightG;
                                w = (base * count).toDouble().clamp(30.0, 1000.0);
                              });
                            }
                          },
                          selectedColor: t.accentColor.withValues(alpha: 0.2),
                          backgroundColor: t.cardBackground,
                          labelStyle: TextStyle(
                            color: isSel ? t.accentColor : t.inkColor,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13.sp,
                          ),
                          side: BorderSide(
                            color: isSel ? t.accentColor : t.cardStroke,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),

                    // 2. SIZE SELECTION (e.g. Small / Medium / Large / Paper)
                    if (_servingSpec.sizeOptions.isNotEmpty) ...[
                      Text(
                        'Serving Size / Variety',
                        style: TextStyle(
                          color: t.inkColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _servingSpec.sizeOptions.map((s) {
                          final isSel = size?.label == s.label;
                          return ChoiceChip(
                            label: Text(s.label),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) {
                                setSheet(() {
                                  size = s;
                                  w = (s.defaultWeightG * count).toDouble().clamp(30.0, 1000.0);
                                });
                              }
                            },
                            selectedColor: t.accentColor.withValues(alpha: 0.2),
                            backgroundColor: t.cardBackground,
                            labelStyle: TextStyle(
                              color: isSel ? t.accentColor : t.inkColor,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                            side: BorderSide(
                              color: isSel ? t.accentColor : t.cardStroke,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // 3. FINE-TUNE WEIGHT SLIDER
                    Row(
                      children: [
                        Text(
                          'Fine-Tune Weight',
                          style: TextStyle(
                            color: t.inkColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${w.round()} g',
                          style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: t.accentColor,
                        thumbColor: t.accentColor,
                      ),
                      child: Slider(
                        min: 30,
                        max: 800,
                        divisions: 77,
                        value: w.clamp(30.0, 800.0),
                        onChanged: (v) => setSheet(() => w = v),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // DONE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Apply Portion',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    setState(() {
      _selectedCount = count;
      _selectedSize = size;
      _weightG = w.round();
      final base = _servingSpec.baseWeightG > 0 ? _servingSpec.baseWeightG : 150;
      _quantity = (_weightG / base).clamp(0.2, 10.0);
      _live = _recalc();
    });
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, HiwTheme t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: t.accentColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color: t.accentColor.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: t.accentColor, size: 18.sp),
      ),
    );
  }

  Future<void> _openAddonsSheet() async {
    final t = HiwTheme.of(context);
    final selected = Set<String>.from(_addons);
    final addonsList = _servingSpec.contextualAddons.isNotEmpty
        ? _servingSpec.contextualAddons
        : kAddonChoices.map((a) => CatalogAddonOption(
              id: a['id']!,
              label: a['label']!,
              calories: kAddonFallback[a['id']]?[0].round() ?? 40,
              protein: kAddonFallback[a['id']]?[1] ?? 1.0,
              carbs: kAddonFallback[a['id']]?[2] ?? 3.0,
              fats: kAddonFallback[a['id']]?[3] ?? 2.0,
              fiber: kAddonFallback[a['id']]?[4] ?? 0.5,
            )).toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
              decoration: BoxDecoration(
                color: t.cardBackground,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: t.cardStroke),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: t.mutedColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Add-ons & Sides',
                      style: TextStyle(
                        color: t.inkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Contextual options for ${_live.displayName}',
                      style: TextStyle(
                        color: t.mutedColor,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ...addonsList.map((a) {
                      final on = selected.contains(a.id);
                      return GestureDetector(
                        onTap: () => setSheet(() => on
                            ? selected.remove(a.id)
                            : selected.add(a.id)),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: on
                                ? t.accentColor.withValues(alpha: 0.14)
                                : t.cardBackground,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: on
                                  ? t.accentColor
                                  : t.cardStroke,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                on
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: on ? t.accentColor : t.mutedColor,
                                size: 22.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.label,
                                      style: TextStyle(
                                          color: t.inkColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '+${a.calories} kcal  •  P: ${a.protein}g  •  F: ${a.fats}g',
                                      style: TextStyle(
                                          color: t.mutedColor,
                                          fontSize: 11.5.sp),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Save Add-ons',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    setState(() {
      _addons
        ..clear()
        ..addAll(selected);
      _live = _recalc();
    });
  }

  Future<void> _addToMeal() async {
    if (_isSaving) return; // double-submit protection
    setState(() => _isSaving = true);
    try {
      final key =
          '${_live.canonicalFoodId}_${_live.calories}_${DateTime.now().millisecondsSinceEpoch ~/ 2000}';
      if (_savedKey == key) return;
      _savedKey = key;

      // Combo plate → one FoodItem per food, same meal, same pipeline.
      final foods = _live.isCombo
          ? _live.toFoodItems()
          : [
              FoodItem(
                name: _live.displayName,
                mealType: _live.mealType,
                calories: _live.calories,
                protein: _live.protein,
                carbs: _live.carbs,
                fats: _live.fats,
                fiber: _live.fiber,
              )
            ];
      for (final food in foods) {
        NutritionStore().addFood(food);
        try {
          HealthEngine().applyFood(food);
        } catch (_) {}
        HistoryStore().addFood(food);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(foods.length > 1
                ? 'Added ${foods.length} items to ${_live.mealLabel} • ${_live.calories} kcal'
                : 'Added to ${_live.mealLabel} • ${foods.first.calories} kcal')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pct = (_live.confidence * 100).round();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: t.inkColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 24.h),
          child: Column(
            children: [
              // ── HERO IMAGE (theme-matched glass frame) ──
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: t.cardStroke, width: 1),
                      boxShadow: t.cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: _heroImage(),
                    ),
                  ),
                  Positioned(
                    right: 12.w,
                    bottom: 12.h,
                    child: GestureDetector(
                      onTap: widget.onReplaceImage,
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: t.isMinimal
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(color: t.cardStroke),
                        ),
                        child: Icon(Icons.edit_rounded,
                            size: 16.sp, color: t.accentColor),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                _live.isCombo
                    ? '${_live.components.length} items on your plate'
                    : _live.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
              ),
              if (_live.isCombo) ...[
                SizedBox(height: 4.h),
                Text(
                  _live.components.map((e) => e.displayName).join(' • '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 13.sp),
                ),
              ],
              SizedBox(height: 8.h),
              // Confidence / combo / low-confidence state
              if (_live.isCombo) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: scheme.secondary
                            .withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Combo plate • ${_live.calories} kcal total',
                    style: TextStyle(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ] else if (_live.isLowConfidence) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: t.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: t.accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Is this correct?  $pct% match',
                    style: TextStyle(
                      color: t.accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                if (_live.alternatives.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: _live.alternatives
                        .take(4)
                        .map((a) => ActionChip(
                              backgroundColor:
                                  t.cardBackground,
                              side: BorderSide(color: t.cardStroke),
                              label: Text(a.displayName,
                                  style: TextStyle(
                                      color: t.inkColor,
                                      fontSize: 12.sp)),
                              onPressed: () {},
                            ))
                        .toList(),
                  ),
                ],
              ] else
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color:
                            scheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 15.sp, color: scheme.primary),
                      SizedBox(width: 6.w),
                      Text(
                        '$pct% match',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 14.h),
              // ── MEAL PILLS (glass, theme-matched) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _mealPill(MealType.breakfast, 'Breakfast',
                      Icons.wb_sunny_outlined, t),
                  SizedBox(width: 8.w),
                  _mealPill(MealType.lunch, 'Lunch',
                      Icons.light_mode_rounded, t),
                  SizedBox(width: 8.w),
                  _mealPill(MealType.snack, 'Snack',
                      Icons.shopping_bag_outlined, t),
                  SizedBox(width: 8.w),
                  _mealPill(MealType.dinner, 'Dinner',
                      Icons.nightlight_round, t),
                ],
              ),
              SizedBox(height: 14.h),
              // ── NUTRITION CARDS (theme-tinted glass) ──
              Row(
                children: [
                  _nutriCard('${_live.calories}', 'kcal',
                      Icons.local_fire_department_rounded,
                      scheme.primary, t),
                  SizedBox(width: 8.w),
                  _nutriCard(
                      '${_live.carbs.toStringAsFixed(0)}g',
                      'Carbs',
                      Icons.grass_rounded,
                      scheme.secondary,
                      t),
                  SizedBox(width: 8.w),
                  _nutriCard('${_live.protein.toStringAsFixed(0)}g',
                      'Protein', Icons.fitness_center_rounded,
                      scheme.tertiary, t),
                  SizedBox(width: 8.w),
                  _nutriCard('${_live.fats.toStringAsFixed(0)}g',
                      'Fats', Icons.water_drop_rounded,
                      scheme.primary, t),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _nutriCard('${_live.fiber.toStringAsFixed(0)}g',
                      'Fiber', Icons.eco_rounded,
                      scheme.secondary, t),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 3,
                    child: HiwCard(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Icon(Icons.scale_rounded,
                              color: t.mutedColor, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _live.isCombo
                                  ? '${_live.components.length} foods • combined'
                                  : _portionSummary,
                              style: TextStyle(
                                  color: t.inkColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (_live.isCombo) ...[
                // ── COMBO: per-food portions, combined totals ──
                ..._live.components.asMap().entries.map((entry) {
                  final i = entry.key;
                  final comp = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: HiwCard(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 10.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(comp.displayName,
                                    style: TextStyle(
                                        color: t.inkColor,
                                        fontWeight:
                                            FontWeight.w700,
                                        fontSize: 14.sp)),
                                SizedBox(height: 2.h),
                                Text(
                                  '${comp.servingLabel} • ${comp.calories} kcal',
                                  style: TextStyle(
                                      color: t.mutedColor,
                                      fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ),
                          _stepBtn(Icons.remove_rounded, () {
                            if (_comboQty[i] > 0.25) {
                              setState(() {
                                _comboQty[i] =
                                    double.parse(
                                        (_comboQty[i] - 0.25)
                                            .toStringAsFixed(2));
                                _live = _recalc();
                              });
                            }
                          }, t),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w),
                            child: Text(
                              '${_comboQty[i].toStringAsFixed(2)}×',
                              style: TextStyle(
                                  color: t.inkColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp),
                            ),
                          ),
                          _stepBtn(Icons.add_rounded, () {
                            if (_comboQty[i] < 3.0) {
                              setState(() {
                                _comboQty[i] =
                                    double.parse(
                                        (_comboQty[i] + 0.25)
                                            .toStringAsFixed(2));
                                _live = _recalc();
                              });
                            }
                          }, t),
                        ],
                      ),
                    ),
                  );
                }),
                // Foods seen but not in the database are listed, not logged.
                ...widget.initial.items
                    .where((e) => e.isEdible && e.record == null)
                    .map((e) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: HiwCard(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h),
                            child: Row(
                              children: [
                                Icon(
                                    Icons.help_outline_rounded,
                                    color: t.mutedColor,
                                    size: 20.sp),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    '${e.name} — not in database, skipped',
                                    style: TextStyle(
                                        color: t.mutedColor,
                                        fontSize: 13.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
              ] else ...[
                // ── PORTION ROW ──
                HiwCard(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 6.h),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.soup_kitchen_outlined,
                        color: t.mutedColor),
                    title: Text('Portion & Serving',
                        style: TextStyle(
                            color: t.inkColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp)),
                    subtitle: Text(
                      _portionSubtitle,
                      style: TextStyle(
                          color: t.mutedColor, fontSize: 13.sp),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: t.mutedColor),
                    onTap: _openPortionSheet,
                  ),
                ),
                SizedBox(height: 10.h),
                // ── ADD-ONS ROW ──
                HiwCard(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 6.h),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: t.cardStroke),
                      ),
                      child: Icon(Icons.add_rounded,
                          color: t.inkColor, size: 18.sp),
                    ),
                    title: Text('Add-ons & Sides',
                        style: TextStyle(
                            color: t.inkColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp)),
                    subtitle: Text(
                      _addonsSubtitle,
                      style: TextStyle(
                          color: t.mutedColor, fontSize: 13.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: t.mutedColor),
                    onTap: _openAddonsSheet,
                  ),
                ),
              ],
              SizedBox(height: 18.h),
              // ── PRIMARY CTA (dynamic meal, double-tap safe) ──
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        t.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: t.accentColor.withValues(alpha: 0.35),
                        blurRadius: 18.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18.r)),
                    ),
                    onPressed: _isSaving ? null : _addToMeal,
                    child: _isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child:
                                const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded),
                              SizedBox(width: 8.w),
                              Text(
                                _live.isCombo
                                    ? 'Add ${_live.components.length} items to ${_live.mealLabel}'
                                    : 'Add to ${_live.mealLabel}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroImage() {
    if (_live.image != null) {
      return Image(
        image: _live.image!,
        height: 240.h,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    if (_live.imagePath != null && _live.imagePath!.isNotEmpty) {
      final f = File(_live.imagePath!);
      if (f.existsSync()) {
        return Image.file(
          f,
          height: 240.h,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
    final t = HiwTheme.of(context);
    return Container(
      height: 240.h,
      width: double.infinity,
      color: t.cardBackground,
      child: Icon(Icons.restaurant_rounded,
          size: 64.sp, color: t.mutedColor),
    );
  }

  Widget _mealPill(
      MealType m, String label, IconData icon, HiwTheme t) {
    final selected = _meal == m;
    return GestureDetector(
      onTap: () => setState(() {
        _meal = m;
        _live = _recalc();
      }),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? t.accentColor.withValues(alpha: 0.16)
              : t.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? t.accentColor
                : t.cardStroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14.sp,
                color: selected
                    ? t.accentColor
                    : t.mutedColor),
            SizedBox(width: 4.w),
            Text(label,
                style: TextStyle(
                  color:
                      selected ? t.accentColor : t.mutedColor,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11.sp,
                )),
          ],
        ),
      ),
    );
  }

  Widget _nutriCard(String value, String label, IconData icon,
      Color tint, HiwTheme t) {
    return Expanded(
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: t.isMinimal ? 0.1 : 0.16),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: tint.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: tint, size: 20.sp),
            SizedBox(height: 6.h),
            Text(value,
                style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp)),
            Text(label,
                style: TextStyle(
                    color: t.mutedColor, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}
