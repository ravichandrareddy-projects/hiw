import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:flutter/material.dart';

// normal widgets
import '../widgets/glass_card.dart';

import 'purchases_screen.dart';
import 'daily_quest_screen.dart';
import 'generic_addons_screen.dart';
import 'history_screen.dart';

// 🧠 CORE LOGIC
import '../core/nutrition_store.dart';
import '../core/health_engine.dart';
import '../core/food_item.dart';
import '../core/food_addons_config.dart';
import '../core/food_nutrition_database.dart';
import '../core/generic_nutrition_engine.dart';
import '../core/history_store.dart';
import '../services/food_recognition_service.dart';
import '../themes/hiw_theme.dart';
import '../core/water_store.dart';
import '../core/app_state.dart'; // 🆕

// 🧍 AVATAR LOGIC
import '../avatar/avatar_logic.dart';
import '../avatar/avatar_store.dart';

class FoodScreen extends StatefulWidget {
  final void Function({
    required int dailyRaw,
  }) onUpdateAvatar;

  final ImageProvider? scannedImage;
  final String? detectedLabel;
  final double healthyScore;
  final double quantity;
  final FoodNutritionRecord? nutritionRecord;

  /// Every distinct item from the scan (dosa + chutney + sambar …).
  final List<ScannedItem> items;

  const FoodScreen({
    super.key,
    required this.onUpdateAvatar,
    this.scannedImage,
    this.detectedLabel,
    this.healthyScore = 0,
    this.quantity = 1.0,
    this.nutritionRecord,
    this.items = const [],
  });

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final NutritionStore _nutritionStore = NutritionStore();
  final HealthEngine _healthEngine = HealthEngine();
  final WaterStore _waterStore = WaterStore();
  final AvatarStore _avatarStore = AvatarStore();

  int selectedMeal =
      _mealIndexNow(); // 🕐 auto-set from device time at field init

  /// Static helper — safe to call at field-initializer level (before initState)
  static int _mealIndexNow() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return 0; // Breakfast
    if (h >= 11 && h < 16) return 1; // Lunch
    if (h >= 16 && h < 19) return 2; // Snack
    return 3; // Dinner
  }

  bool _showMoreNutrition = false; // 🆕 Expandable micronutrients
  final meals = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
  String _displayName = 'User'; // 👤 DYNAMIC NAME

  late int dailyTargetCalories;

  int get remainingCalories =>
      (dailyTargetCalories - _nutritionStore.totalCalories).clamp(0, 9999);

  /// Active-day streak from the history store (drives Lv badge + streak card).
  int _activeStreak() {
    final store = HistoryStore();
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      if (store.hasStreak(d)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  ImageProvider? scannedFoodImage;
  bool _scanApplied = false;

  String? detectedFoodLabel;
  double _scanQuantity = 1.0;
  FoodNutritionRecord? _scanRecord;
  List<ScannedItem> _scanItems = const [];
  int _lastAddedCount = 0;
  FoodItem? confirmedFood;

  late Timer _clock;
  DateTime now = DateTime.now();

  // =============================
  // MEAL AUTO DETECTION
  // =============================
  MealType _mealFromTime(DateTime time) {
    final h = time.hour;
    if (h >= 5 && h < 11) return MealType.breakfast;
    if (h >= 11 && h < 16) return MealType.lunch;
    if (h >= 16 && h < 19) return MealType.snack;
    return MealType.dinner;
  }

  @override
  void initState() {
    super.initState();

    dailyTargetCalories = _nutritionStore.dailyTargetCalories;
    if (dailyTargetCalories <= 0) {
      dailyTargetCalories = 2000;
      _nutritionStore.setDailyTargetCalories(2000);
    }

    Future.microtask(() async {
      await _waterStore.init();
      await _avatarStore.init();
      final name = await AppState.getUsername();
      if (name != null) {
        setState(() => _displayName = name);
      }
    });

    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => now = DateTime.now()),
    );

    if (widget.scannedImage != null && !_scanApplied) {
      scannedFoodImage = widget.scannedImage;
      detectedFoodLabel = widget.detectedLabel;
      _scanQuantity = widget.quantity;
      _scanRecord = widget.nutritionRecord;
      _scanItems = widget.items;
      selectedMeal = _mealFromTime(DateTime.now()).index;
      _scanApplied = true;
    }
  }

  @override
  void didUpdateWidget(covariant FoodScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔔 PARENT CLEARED THE IMAGE (PTA CLICKED)
    if (widget.scannedImage == null && oldWidget.scannedImage != null) {
      setState(() {
        scannedFoodImage = null;
        detectedFoodLabel = null;
        _scanQuantity = 1.0;
        _scanRecord = null;
        _scanItems = const [];
        confirmedFood = null;
        _lastAddedCount = 0;
        _scanApplied = false;
      });
    }
    // 🔔 NEW SCAN ARRIVED
    else if (widget.scannedImage != null &&
        widget.scannedImage != oldWidget.scannedImage) {
      setState(() {
        scannedFoodImage = widget.scannedImage;
        detectedFoodLabel = widget.detectedLabel;
        _scanQuantity = widget.quantity;
        _scanRecord = widget.nutritionRecord;
        _scanItems = widget.items;
        confirmedFood = null; // reset confirmation
        _lastAddedCount = 0;
        selectedMeal = _mealFromTime(DateTime.now()).index;
        _scanApplied = true;
      });
    }
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  // =============================
  // HEADER HELPERS
  // =============================
  String _greeting() {
    final h = now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get dateText => '${now.day.toString().padLeft(2, '0')} '
      '${const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][now.month - 1]}';

  String get timeText => '${now.hour % 12 == 0 ? 12 : now.hour % 12}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')} '
      '${now.hour >= 12 ? 'PM' : 'AM'}';

  // =============================
  // PER MEAL TOTALS
  // =============================
  ({
    int calories,
    double protein,
    double carbs,
    double fats,
    double fiber,
    double vitaminA,
    double vitaminC,
    double vitaminB6,
    double calcium,
    double iron,
    double potassium,
    double magnesium,
    double sodium,
    double zinc,
  }) _totalsForSelectedMeal() {
    final meal = MealType.values[selectedMeal];
    final foods =
        _nutritionStore.todayFoods.where((f) => f.mealType == meal).toList();

    return (
      calories: foods.fold(0, (s, f) => s + f.calories),
      protein: foods.fold(0.0, (s, f) => s + f.protein),
      carbs: foods.fold(0.0, (s, f) => s + f.carbs),
      fats: foods.fold(0.0, (s, f) => s + f.fats),
      fiber: foods.fold(0.0, (s, f) => s + f.fiber),
      vitaminA: foods.fold(0.0, (s, f) => s + f.vitaminA),
      vitaminC: foods.fold(0.0, (s, f) => s + f.vitaminC),
      vitaminB6: foods.fold(0.0, (s, f) => s + f.vitaminB6),
      calcium: foods.fold(0.0, (s, f) => s + f.calcium),
      iron: foods.fold(0.0, (s, f) => s + f.iron),
      potassium: foods.fold(0.0, (s, f) => s + f.potassium),
      magnesium: foods.fold(0.0, (s, f) => s + f.magnesium),
      sodium: foods.fold(0.0, (s, f) => s + f.sodium),
      zinc: foods.fold(0.0, (s, f) => s + f.zinc),
    );
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          physics: const BouncingScrollPhysics(),
          children: [
            _header(),
            SizedBox(height: 6.h),

            if (scannedFoodImage != null) _foodImage(),

            if (scannedFoodImage != null && detectedFoodLabel != null)
              _addonsEntry(),

            SizedBox(height: 4.h),
            _mealSelector(),
            SizedBox(height: 4.h),
            _nutritionCard(),
            SizedBox(height: 4.h),
            _calorieBar(), // 📊 big calorie progress bar
            SizedBox(height: 4.h),
            // 💧 WATER + 🔥 STREAK (side by side, equal height)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _waterCard()),
                  SizedBox(width: 8.w),
                  Expanded(child: _streakCard()),
                ],
              ),
            ),
            SizedBox(height: 80.h), // 📏 EXTRA BOTTOM SPACE
          ],
        ),
        _shopButton(),
        _questButton(),
      ],
    );
  }

  // =============================
  // NUTRITION CARD — NEW LAYOUT
  // =============================
  Widget _nutritionCard() {
    final totals = _totalsForSelectedMeal();
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;
    final accentColor = Theme.of(context).primaryColor;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + progress bar ──
          Builder(builder: (_) {
            // Weighted target per meal (% of daily calories)
            const weights = [0.25, 0.35, 0.15, 0.25]; // B / L / S / D
            final mealTarget =
                (dailyTargetCalories * weights[selectedMeal]).round();
            final consumed = totals.calories;
            final progress = (consumed / mealTarget).clamp(0.0, 1.0);
            final overGoal = consumed > mealTarget;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: title + food name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meals[selectedMeal]} Nutrition',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17.sp,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (_lastAddedCount > 1 && confirmedFood != null)
                        Text('$_lastAddedCount items added ✓',
                            style: TextStyle(
                                color: accentColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500))
                      else if (confirmedFood != null)
                        Text(confirmedFood!.name,
                            style: TextStyle(
                                color: accentColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500))
                      else if (detectedFoodLabel != null)
                        Text(detectedFoodLabel!,
                            style: TextStyle(
                                color: accentColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

                // Right: compact progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$consumed',
                            style: TextStyle(
                              color: overGoal ? Colors.orangeAccent : textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: ' / $mealTarget kcal',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Builder(builder: (context) {
                      final tb = HiwTheme.of(context);
                      return SizedBox(
                        width: 130.w,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, anim, _) =>
                                LinearProgressIndicator(
                              value: anim,
                              minHeight: 10,
                              backgroundColor: tb.isMinimal
                                  ? Colors.black.withValues(alpha: 0.08)
                                  : Colors.white
                                      .withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                overGoal
                                    ? Colors.orangeAccent
                                    : accentColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            );
          }),
          SizedBox(height: 6.h),

          // ── Calories row ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.3), width: 1.w),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.orangeAccent, size: 16),
                SizedBox(width: 6.w),
                Text(
                  'Calories',
                  style: TextStyle(color: subColor, fontSize: 12.sp),
                ),
                const Spacer(),
                Text(
                  '${totals.calories} kcal',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.sp,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),

          // ── 2×2 Nutrient Grid (plain Column+Row, no implicit GridView padding) ──
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _nutrientGridCard(
                          icon: Icons.grain_rounded,
                          iconColor: Colors.amberAccent,
                          label: 'Carbs',
                          value: totals.carbs.toStringAsFixed(1))),
                  SizedBox(width: 7.w),
                  Expanded(
                      child: _nutrientGridCard(
                          icon: Icons.fitness_center_rounded,
                          iconColor: Colors.lightBlueAccent,
                          label: 'Protein',
                          value: totals.protein.toStringAsFixed(1))),
                ],
              ),
              SizedBox(height: 7.h),
              Row(
                children: [
                  Expanded(
                      child: _nutrientGridCard(
                          icon: Icons.water_drop_rounded,
                          iconColor: Colors.pinkAccent,
                          label: 'Fats',
                          value: totals.fats.toStringAsFixed(1))),
                  SizedBox(width: 7.w),
                  Expanded(
                      child: _nutrientGridCard(
                          icon: Icons.eco_rounded,
                          iconColor: Colors.greenAccent,
                          label: 'Fiber',
                          value: totals.fiber.toStringAsFixed(1))),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ── Expandable micronutrients ──
          GestureDetector(
            onTap: () =>
                setState(() => _showMoreNutrition = !_showMoreNutrition),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10),
              decoration: BoxDecoration(
                color: t.isMinimal
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                    color: t.isMinimal
                        ? t.cardStroke
                        : Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showMoreNutrition ? 'Hide  ▲' : 'More Nutrition  ▼',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Micronutrients list (expanded) ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _showMoreNutrition
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Column(
                children: [
                  _microRow(
                      Icons.visibility_rounded,
                      'Vitamin A',
                      '${totals.vitaminA.toStringAsFixed(1)} µg',
                      Colors.orangeAccent),
                  _microRow(
                      Icons.water_rounded,
                      'Vitamin C',
                      '${totals.vitaminC.toStringAsFixed(1)} mg',
                      Colors.lightGreenAccent),
                  _microRow(
                      Icons.science_rounded,
                      'Vitamin B6',
                      '${totals.vitaminB6.toStringAsFixed(2)} mg',
                      Colors.purpleAccent),
                  _microRow(
                      Icons.density_medium_rounded,
                      'Calcium',
                      '${totals.calcium.toStringAsFixed(1)} mg',
                      Colors.cyanAccent),
                  _microRow(Icons.bloodtype_rounded, 'Iron',
                      '${totals.iron.toStringAsFixed(1)} mg', Colors.redAccent),
                  _microRow(
                      Icons.bolt_rounded,
                      'Potassium',
                      '${totals.potassium.toStringAsFixed(1)} mg',
                      Colors.yellowAccent),
                  _microRow(
                      Icons.hexagon_rounded,
                      'Magnesium',
                      '${totals.magnesium.toStringAsFixed(1)} mg',
                      Colors.tealAccent),
                  _microRow(
                      Icons.waves_rounded,
                      'Sodium',
                      '${totals.sodium.toStringAsFixed(1)} mg',
                      Colors.blueAccent),
                  _microRow(
                      Icons.bubble_chart_rounded,
                      'Zinc',
                      '${totals.zinc.toStringAsFixed(1)} mg',
                      Colors.amberAccent),
                  SizedBox(height: 4.h),
                  Text(
                    '* Based on base food values — addons may vary',
                    style: TextStyle(color: subColor, fontSize: 10.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          SizedBox(height: 8.h),

          // ── Push To Avatar ──
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                if (confirmedFood == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add food first before pushing to avatar'),
                    ),
                  );
                  return;
                }

                final quality = widget.healthyScore >= 50
                    ? FoodQuality.healthy
                    : FoodQuality.junk;

                final result = AvatarLogic.calculateHealthEnergy(
                  mealQuality: quality,
                  totalDailyCalories: _nutritionStore.totalCalories,
                  targetCalories: dailyTargetCalories,
                  weeklyJunkCount: _avatarStore.weeklyJunkCount,
                  mealIndex: selectedMeal,
                  currentTime: DateTime.now(),
                );

                _avatarStore.applyHealthEnergy(
                  healthDelta: result.healthDelta,
                  energyBase: result.energyBase,
                  energyBonus: result.energyBonus,
                  isBonusEligible: result.isBonusEligible,
                  junkConsumed: result.junkConsumed,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avatar updated')),
                );

                setState(() {
                  confirmedFood = null;
                  _lastAddedCount = 0;
                  scannedFoodImage = null;
                  detectedFoodLabel = null;
                  _scanQuantity = 1.0;
                  _scanRecord = null;
                  widget.onUpdateAvatar(dailyRaw: 0);
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
                decoration: BoxDecoration(
                  // Signature blue action gradient in every theme.
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A86FF), Color(0xFF00E5FF)],
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                  border: t.isMinimal
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A86FF)
                          .withValues(alpha: 0.35),
                      blurRadius: 14.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward,
                        color: Colors.white, size: 17),
                    SizedBox(width: 7.w),
                    Text(
                      'Push To Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small grid card for Carbs/Protein/Fats/Fiber (macro-tinted) ──
  Widget _nutrientGridCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final t = HiwTheme.of(context);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

    // Tinted glass in dark themes, soft tint wash in Plain.
    final bg = t.isMinimal
        ? iconColor.withValues(alpha: 0.08)
        : iconColor.withValues(alpha: 0.12);
    final stroke = iconColor.withValues(alpha: t.isMinimal ? 0.4 : 0.3);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: stroke,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.12),
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$value g',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Single micronutrient row ──
  Widget _microRow(IconData icon, String name, String value, Color color) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child:
                Text(name, style: TextStyle(color: subColor, fontSize: 13.sp)),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // 💧 WATER (compact, shares row with streak)
  // =============================
  Widget _waterCard() {
    final count = _waterStore.waterTicks;
    final isMax = count >= 16;
    final muted =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded,
                  color: Colors.lightBlueAccent, size: 18),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Water Intake',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '$count / 16 glasses',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 3.w,
            runSpacing: 5.h,
            children: List.generate(16, (i) {
              final filled = i < count;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  filled
                      ? Icons.water_drop_rounded
                      : Icons.water_drop_outlined,
                  size: 14,
                  color: filled ? Colors.lightBlueAccent : muted,
                ),
              );
            }),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMax ? Colors.grey : Colors.blueAccent,
                ),
                onPressed: isMax
                    ? null
                    : () async {
                        final last = _waterStore.lastLoggedTime;
                        final now = DateTime.now();

                        // Check logic: if never drank or >60 mins
                        if (last == null ||
                            now.difference(last).inMinutes >= 60) {
                          // 🛑 AWAIT RESULT
                          final success = await _waterStore.logWater();

                          if (success) {
                            _avatarStore.addStaminaFromWater();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '💧 Water logged! Stamina increased'),
                                  backgroundColor: Colors.blueAccent,
                                ),
                              );
                            }
                          }
                        } else {
                          // ⏳ COOLDOWN
                          final remaining = 60 - now.difference(last).inMinutes;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '⏳ Wait $remaining minutes to drink again'),
                              ),
                            );
                          }
                        }

                        if (context.mounted) setState(() {});
                      },
                child: Text(isMax ? 'Limit Reached' : 'I drank water',
                    style: TextStyle(fontSize: 12.sp)),
              ),
            ),
          if (isMax) ...[
            SizedBox(height: 8.h),
            Text(
              'Great job! You reached your daily hydration goal. 🎉',
              style: TextStyle(color: Colors.tealAccent, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  // =============================
  // 🔥 TODAY'S STREAK (week dots, tap → history)
  // =============================
  Widget _streakCard() {
    final accent = Theme.of(context).primaryColor;
    final muted =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;
    final ink =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final streak = _activeStreak();
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final store = HistoryStore();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('History',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(
                  color: Theme.of(context).iconTheme.color),
            ),
            body: const HistoryScreen(),
          ),
        ),
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Colors.orangeAccent, size: 16),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    'Today\'s Streak',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: muted, size: 16),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$streak day${streak == 1 ? '' : 's'}',
                    key: ValueKey(streak),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                const Spacer(),
                Text('🌱', style: TextStyle(fontSize: 20.sp)),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final date = monday.add(Duration(days: i));
                final isFuture = date.isAfter(
                    DateTime(today.year, today.month, today.day));
                final done = !isFuture && store.hasStreak(date);
                return AnimatedContainer(
                  duration: Duration(milliseconds: 250 + i * 90),
                  curve: Curves.easeOutBack,
                  width: 20.w,
                  height: 20.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? accent
                        : muted.withValues(alpha: 0.18),
                  ),
                  child: Text(
                    dayLetters[i],
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: done
                          ? (accent.computeLuminance() > 0.4
                              ? Colors.black
                              : Colors.white)
                          : muted,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // =============================
  // REMAINING UI (UNCHANGED)
  // =============================
  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 📅 DATE (LEFT)
              GlassCard(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Text(
                  dateText,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ),

              // ⏱️ TIME WITH SECONDS (RIGHT)
              GlassCard(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Text(
                  timeText,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // 👋 GREETING + AVATAR LEVEL
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, $_displayName 👋',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Here\'s your nutrition summary for today',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              _avatarBadge(),
            ],
          ),
        ],
      );

  Widget _avatarBadge() {
    final accent = Theme.of(context).primaryColor;
    final level = _activeStreak() <= 0 ? 1 : _activeStreak();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 56.w,
          height: 56.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.15),
            border: Border.all(color: accent, width: 2.w),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 12.r,
              ),
            ],
          ),
          child: Icon(Icons.person_rounded,
              color: accent, size: 30.r),
        ),
        Positioned(
          bottom: -8.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Lv. $level',
              style: TextStyle(
                color: accent.computeLuminance() > 0.4
                    ? Colors.black
                    : Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _foodImage() => GlassCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image(
            image: scannedFoodImage!,
            height: 160.h,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );

  /// Builds the FoodItem that gets added to today's totals.
  /// - Foods from the 2.6k nutrition database use their real per-100g values
  ///   scaled by the vision-estimated portion (fixes the old "+0 kcal" bug).
  /// - Legacy base-map foods use the addons engine, also portion-scaled.
  /// - Addon extras (sides/choices) stack on top in both cases.
  FoodItem _buildConfirmedFood(Map<String, dynamic> addons) {
    final meal = MealType.values[selectedMeal];
    final record = _scanRecord;
    if (record != null) {
      final base = record.toFoodItem(
        quantityMultiplier: _scanQuantity,
        overrideMealType: meal,
      );
      if (addons.isEmpty) return base;
      return applyAddonExtras(base: base, addons: addons);
    }
    return scaledByQuantity(
      calculateFoodFromAddons(
        foodLabel: detectedFoodLabel!,
        addons: addons,
        mealType: meal,
      ),
      _scanQuantity,
    );
  }

  void _confirmAndAddFood(FoodItem food) {
    _confirmAndAddFoods([food]);
  }

  void _confirmAndAddFoods(List<FoodItem> foods) {
    for (final food in foods) {
      _nutritionStore.addFood(food);
      _healthEngine.applyFood(food);
      HistoryStore().addFood(food);
    }

    setState(() {
      confirmedFood = foods.first;
      _lastAddedCount = foods.length;
      scannedFoodImage = null;
      detectedFoodLabel = null;
      _scanQuantity = 1.0;
      _scanRecord = null;
      _scanItems = const [];
      _scanApplied = false;
    });
  }

  /// snake_case key used by the legacy base map + addons config.
  String _normLabel(String name) {
    var n = name.toLowerCase().replaceAll(' ', '_');
    if (n == 'boild_egg') n = 'boiled_egg';
    if (n == 'noodils') n = 'noodles';
    if (n == 'mangopickle') n = 'mango_pickle';
    if (n == 'idly') n = 'idli';
    if (n == 'gulab jamun') n = 'gulab_jamun';
    return n;
  }

  /// One FoodItem per detected combo item (dosa, chutney, sambar …),
  /// each with its own record values + portion quantity.
  FoodItem _foodForItem(ScannedItem item, MealType meal) {
    final qty = item.quantity <= 0 ? 1.0 : item.quantity;
    if (item.record != null) {
      return item.record!
          .toFoodItem(quantityMultiplier: qty, overrideMealType: meal);
    }
    return scaledByQuantity(
      calculateFoodFromAddons(
        foodLabel: _normLabel(item.name),
        addons: const {},
        mealType: meal,
      ),
      qty,
    );
  }
  Widget _addonsEntry() {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    final bool hasAddons = foodAddons.containsKey(detectedFoodLabel);
    final edible = _scanItems.where((i) => i.isEdible).toList();
    final bool isCombo = edible.length > 1;
    final int comboKcal = isCombo
        ? edible
            .map((i) => _foodForItem(i, MealType.values[selectedMeal]).calories)
            .fold(0, (a, b) => a + b)
        : 0;
    final String cleanTitle = detectedFoodLabel!
        .split('_')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');

    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        leading: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            gradient: t.isMinimal
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF3A86FF)],
                  ),
            color: t.isMinimal ? accent : null,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (t.isMinimal ? accent : Colors.cyanAccent)
                    .withValues(alpha: 0.35),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          isCombo
              ? 'Add ${edible.length} items 🍱'
              : (hasAddons
                  ? 'Customize & Add $cleanTitle'
                  : 'Quick Add $cleanTitle'),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
          ),
        ),
        subtitle: Text(
          isCombo
              ? '${edible.map((i) => i.name).join(', ')} • ≈$comboKcal kcal'
              : (hasAddons
                  ? 'Adjust portions, sides & extras'
                  : 'Add directly to today\'s meal journal'),
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70,
            fontSize: 12.sp,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: t.isMinimal
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            hasAddons ? Icons.tune_rounded : Icons.add_circle_outline_rounded,
            size: 20,
            color: t.isMinimal ? accent : Colors.cyanAccent,
          ),
        ),
        onTap: () async {
          if (isCombo) {            // 🍱 COMBO PLATE: add every detected food at once, each with
            // its own nutrition values + portion quantity.
            final meal = MealType.values[selectedMeal];
            final foods = edible.map((i) => _foodForItem(i, meal)).toList();
            _confirmAndAddFoods(foods);
            if (context.mounted) {
              final total =
                  foods.fold(0, (sum, f) => sum + f.calories);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${foods.length} items added to ${meals[selectedMeal]} • ≈$total kcal 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
          if (hasAddons) {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => GenericAddonsScreen(
                  foodLabel: detectedFoodLabel!,
                  addons: foodAddons[detectedFoodLabel!]!,
                ),
              ),
            );

            if (result != null) {
              final food = _buildConfirmedFood(result);

              _confirmAndAddFood(food);
            }
          } else {
            final food = _buildConfirmedFood({});

            _confirmAndAddFood(food);
          }
        },
      ),
      // ⚖️ PORTION STEPPER (single item): plates/spoons control.
      // Combo plates keep each item's AI-estimated portion.
      if (!isCombo)
        Padding(
          padding:
              EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline),
                color: accent,
                onPressed: _scanQuantity > 0.5
                    ? () => setState(() => _scanQuantity =
                        ((_scanQuantity - 0.5) * 10).round() / 10)
                    : null,
              ),
              Expanded(
                child: Text(
                  'Portion ${_scanQuantity.toStringAsFixed(1)}× • ≈${_buildConfirmedFood({}).calories} kcal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color ??
                        Colors.white70,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline),
                color: accent,
                onPressed: _scanQuantity < 3.0
                    ? () => setState(() => _scanQuantity =
                        ((_scanQuantity + 0.5) * 10).round() / 10)
                    : null,
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  // =============================
  // 📊 BIG CALORIE BAR
  // =============================
  Widget _calorieBar() {
    final consumed = _nutritionStore.totalCalories;
    final target = dailyTargetCalories;
    final remaining = (target - consumed).clamp(0, target);
    final progress = (consumed / target).clamp(0.0, 1.0);
    final t = HiwTheme.of(context);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

    // 🔴 red = barely eaten → 🟡 amber mid → 🟢 green = goal hit
    final barColor = progress > 0.8
        ? Colors.greenAccent
        : progress > 0.4
            ? Colors.amberAccent
            : Colors.redAccent;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Calories',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                '$remaining kcal left',
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, anim, _) => ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: anim,
                minHeight: 16,
                backgroundColor: t.isMinimal
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$consumed consumed',
                style: TextStyle(color: subColor, fontSize: 11.sp),
              ),
              Text(
                '$target goal',
                style: TextStyle(color: subColor, fontSize: 11.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shopButton() => Positioned(
        right: 20,
        bottom: 95, // 📏 ABOVE BOTTOM NAV
        child: FloatingActionButton(
          heroTag: 'shop_fab',
          backgroundColor:
              Colors.orange.withValues(alpha: 0.8), // 🎨 FESTIVE ORANGE
          elevation: 4,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchasesScreen()),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
        ),
      );

  Widget _questButton() => Positioned(
        left: 20,
        bottom: 95,
        child: FloatingActionButton(
          heroTag: 'quest_fab',
          backgroundColor: Colors.cyan.withValues(alpha: 0.8),
          elevation: 4,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyQuestScreen()),
          ),
          child: const Icon(Icons.flag, color: Colors.white, size: 24),
        ),
      );

  static const _mealIcons = [
    Icons.wb_sunny_outlined, // Breakfast
    Icons.restaurant_rounded, // Lunch
    Icons.coffee_outlined, // Snack
    Icons.dinner_dining_rounded, // Dinner
  ];

  Widget _mealSelector() {
    final accent = Theme.of(context).primaryColor;
    final muted =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;
    return GlassCard(
      padding: EdgeInsets.all(6.r),
      child: Row(
        children: List.generate(meals.length, (i) {
          final selected = selectedMeal == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedMeal = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.72),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 12.r,
                            spreadRadius: 1.r,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _mealIcons[i],
                      size: 15,
                      color: selected ? Colors.white : muted,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        meals[i],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.sp,
                          color: selected ? Colors.white : muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
