// lib/screens/mealplan_screen.dart — Pro: deterministic day meal plan.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/food_item.dart';
import '../core/history_store.dart';
import '../core/mealplan_engine.dart';
import '../core/health_profile.dart';
import '../core/nutrition_store.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../services/analytics_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';
import '../widgets/limit_sheet.dart';
import 'paywall_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late DayPlan _plan;
  late int _target;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    final store = NutritionStore();
    _target =
        store.dailyTargetCalories > 0 ? store.dailyTargetCalories : 2000;
    // Diet-aware build (fixed P2 ending): was calorie-only before.
    _plan = MealPlanEngine.build(calorieTarget: _target);
    _loadDiet();
    _guardPro();
  }

  Future<void> _loadDiet() async {
    final dietName = await AppState.getDiet();
    DietPreference? diet;
    if (dietName != null) {
      for (final d in DietPreference.values) {
        if (d.name == dietName) diet = d;
      }
    }
    if (diet != null && mounted) {
      setState(() {
        _plan = MealPlanEngine.build(calorieTarget: _target, diet: diet);
      });
    }
  }

  Future<void> _guardPro() async {
    if (await EntitlementStore.canUse(Feature.mealPlans)) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showLimitSheet(
        context,
        title: 'Meal plans live in HIW Pro',
        usedLabel: 'Free stays generous — plans are Pro',
        resetLabel: 'anytime — upgrade when ready',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
              feature: 'Meal plans live in HIW Pro.'),
        ),
      );
    });
  }

  Future<void> _logDay() async {
    if (_logging) return;
    setState(() => _logging = true);
    try {
      for (final m in _plan.meals) {
        NutritionStore().addFood(m.item);
        HistoryStore().addFood(m.item);
      }
      AnalyticsService().log('mealplan_log');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planned day logged 🍱')),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Today's Meal Plan",
          style: TextStyle(
              color: t.inkColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Column(
            children: [
              HiwCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _stat(t, '${_plan.calories}',
                          '/ $_target kcal'),
                    ),
                    Expanded(
                      child: _stat(t, '${_plan.protein}',
                          'g protein'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Built from your targets + diet. Deterministic — same day, same plan.',
                style:
                    TextStyle(color: t.mutedColor, fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              ..._plan.meals.map((m) => Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: HiwCard(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: t.accentColor
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              _mealIcon(m.meal),
                              color: t.accentColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.record.name,
                                  style: TextStyle(
                                    color: t.inkColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                Text(
                                  '${m.meal.name} • ${m.quantity}× ${m.record.servingUnit} • ${m.item.calories} kcal',
                                  style: TextStyle(
                                      color: t.mutedColor,
                                      fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentColor,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: _logging ? null : _logDay,
                  child: Text(
                    _logging ? 'Logging...' : 'Log This Day',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(HiwTheme t, String v, String label) => Column(
        children: [
          Text(
            v,
            style: TextStyle(
              color: t.inkColor,
              fontWeight: FontWeight.w900,
              fontSize: 22.sp,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: t.mutedColor, fontSize: 12.sp),
          ),
        ],
      );

  IconData _mealIcon(MealType m) {
    switch (m) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.light_mode_rounded;
      case MealType.snack:
        return Icons.cookie_outlined;
      case MealType.dinner:
        return Icons.nightlight_round;
      case MealType.lateNight:
        return Icons.bedtime_rounded;
    }
  }
}
