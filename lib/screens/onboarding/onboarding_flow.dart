// lib/screens/onboarding/onboarding_flow.dart
// First-time personalization: welcome → basics → goal → activity →
// diet → plan → reminders → region → summary → Home.
// Theme tokens only. Drafts survive Back. Deterministic GoalEngine math.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_state.dart';
import '../../core/goal_engine.dart';
import '../../core/health_profile.dart';
import '../../core/nutrition_store.dart';
import '../../services/notification_service.dart';
import '../../themes/hiw_theme.dart';
import '../../widgets/hiw_card.dart';
import 'onboarding_widgets.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingFlow({super.key, required this.onDone});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pager = PageController();
  final _state = OnboardingState();
  int _page = 0;

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  final _stateName = TextEditingController();
  final _district = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _water = TextEditingController();
  final _restrictions = TextEditingController();

  String? _basicsError;
  String? _bodyError;
  GoalResult? _plan;

  static const int _pages = 10;

  @override
  void dispose() {
    _pager.dispose();
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    _stateName.dispose();
    _district.dispose();
    _country.dispose();
    _restrictions.dispose();
    _calories.dispose();
    _protein.dispose();
    _water.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _page = i.clamp(0, _pages - 1));
    _pager.animateToPage(
      _page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _saveRestrictions() {
    _state.profile.restrictions = _restrictions.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _recalcPlan() {
    final p = _state.profile, g = _state.goals;
    if (p.age == null ||
        p.sex == null ||
        p.heightCm == null ||
        p.weightKg == null) {
      return;
    }
    setState(() {
      _plan = GoalEngine.calculate(p, g);
      final r = _plan!;
      _state.calories = r.calories;
      _state.proteinG = r.proteinG;
      _state.fatG = r.fatG;
      _state.carbsG = r.carbsG;
      _state.fiberG = r.fiberG;
      _state.waterMl = r.waterMl;
      _state.bmr = r.bmr;
      _state.tdee = r.tdee;
      _calories.text = '${r.calories}';
      _protein.text = '${r.proteinG}';
      _water.text = '${r.waterMl}';
    });
  }

  Future<void> _finish() async {
    final p = _state.profile, g = _state.goals, r = _state.reminders;
    // Editable plan values win (marked custom per §19).
    final cal = int.tryParse(_calories.text) ?? _state.calories;
    final pro = int.tryParse(_protein.text) ?? _state.proteinG;
    final wat = int.tryParse(_water.text) ?? _state.waterMl;
    final custom = await AppState.customTargets();
    final store = NutritionStore();
    if (cal != _state.calories || custom.contains('calories')) {
      store.setDailyTargetCalories(cal);
      await AppState.markTargetCustom('calories');
    } else {
      store.setDailyTargetCalories(_state.calories);
    }
    if (pro != _state.proteinG || custom.contains('protein')) {
      store.setProteinTargetG(pro);
      await AppState.markTargetCustom('protein');
    } else {
      store.setProteinTargetG(_state.proteinG);
    }
    store.setFiberTargetG(_state.fiberG);
    if (wat != _state.waterMl || custom.contains('water')) {
      store.setHydrationTargetMl(wat);
      await AppState.markTargetCustom('water');
    } else {
      store.setHydrationTargetMl(_state.waterMl);
    }

    await AppState.setUsername(
        p.name.trim().isEmpty ? 'User' : p.name.trim());
    if (p.age != null) await AppState.setAge(p.age!);
    if (p.sex != null) {
      await AppState.setSex(
          p.sex == BiologicalSex.male ? 'male' : 'female');
    }
    if (p.heightCm != null) await AppState.setHeightCm(p.heightCm!);
    if (p.weightKg != null) await AppState.setWeightKg(p.weightKg!);
    await AppState.setBodyFatPct(p.bodyFatPct);
    if (p.activity != null) {
      await AppState.setActivity(p.activity!.name);
    }
    await AppState.setGoal(g.primary.name);
    await AppState.setGoalsExtra(g.secondary.map((e) => e.name).toList());
    await AppState.setGoalWeightKg(g.goalWeightKg);
    if (p.diet != null) await AppState.setDiet(p.diet!.name);
    await AppState.setRestrictions(p.restrictions);
    await AppState.setAllergies(p.allergies);
    await AppState.setRegion(
      district: _state.region.district,
      state: _state.region.state,
      country: _state.region.country,
      manual: _state.region.manual,
    );

    // Reminders: reuse existing channels/IDs + storage keys.
    final ns = NotificationService();
    try {
      await ns.requestPermissions();
    } catch (_) {}
    await AppState.setReminderTime('breakfast', r.breakfastTime);
    await AppState.setReminderTime('lunch', r.lunchTime);
    await AppState.setReminderTime('snack', r.snackTime);
    await AppState.setReminderTime('dinner', r.dinnerTime);
    await AppState.setReminderEnabled('breakfast', r.meals);
    await AppState.setReminderEnabled('lunch', r.meals);
    await AppState.setReminderEnabled('snack', r.meals);
    await AppState.setReminderEnabled('dinner', r.meals);
    await AppState.setReminderEnabled('water', r.water);
    await AppState.setReminderEnabled('daily', r.dailyNutrition);
    await AppState.setReminderEnabled('streak', r.streak);
    try {
      if (r.meals) {
        await ns.scheduleMealNotification(
            id: 101, title: 'Breakfast time', body: 'Log your breakfast 🍳', hour: 8, minute: 0);
        await ns.scheduleMealNotification(
            id: 102, title: 'Lunch time', body: 'Log your lunch 🍱', hour: 13, minute: 0);
        await ns.scheduleMealNotification(
            id: 103, title: 'Dinner time', body: 'Log your dinner 🍲', hour: 20, minute: 0);
        await ns.scheduleMealNotification(
            id: 104, title: 'Snack time', body: 'Log your snack 🍌', hour: 17, minute: 0);
      }
      if (r.water) {
        await ns.scheduleWaterReminders(startHour: 8, startMinute: 0);
      } else {
        await ns.cancelWaterReminders();
      }
      if (r.streak) {
        await ns.scheduleStreakNudge();
      } else {
        await ns.cancelStreakNudge();
      }
    } catch (_) {}

    await AppState.setUserInfoDone(true);
    await AppState.setOnboardingV1Done(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _go(_page - 1);
      },
      child: PageView(
        controller: _pager,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _page = i),
        children: [
          _welcome(),
          _basics(),
          _body(),
          _goal(),
          _activity(),
          _diet(),
          _planPage(),
          _reminders(),
          _region(),
          _summary(),
        ],
      ),
    );
  }

  int get _shown => (_page).clamp(1, 9);
  static const int _total = 9;

  // ── 0. Welcome ──────────────────────────────
  Widget _welcome() {
    final t = HiwTheme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                'HIW',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 64.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.w,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Health starts with what you eat.',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Track your food, understand your nutrition, and build healthier habits — one meal at a time.',
                style: TextStyle(
                  color: t.mutedColor,
                  fontSize: 15.sp,
                  height: 1.55,
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: () => _go(1),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Center(
                child: Text(
                  'Your data stays on your device.',
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Basics ───────────────────────────────
  Widget _basics() {
    final t = HiwTheme.of(context);
    final p = _state.profile;
    final sexOk = p.sex != null;
    final nameOk = _name.text.trim().isNotEmpty;
    final age = int.tryParse(_age.text);
    final ageOk = age != null && age >= 10 && age <= 100;
    return OnbScaffold(
      step: _shown,
      total: _total,
      title: "Let's make HIW yours.",
      subtitle: 'First, the basics. You can skip anything optional.',
      onBack: () => _go(0),
      skipLabel: 'Skip',
      onSkip: () => _go(2),
      nextEnabled: nameOk && ageOk && sexOk,
      onNext: () {
        if (!mounted) return;
        if (!ageOk) {
          setState(() => _basicsError = 'Enter a valid age (10–100).');
          return;
        }
        p.name = _name.text.trim();
        p.age = age;
        setState(() => _basicsError = null);
        _go(2);
      },
      child: Column(
        children: [
          OnbField(
            label: 'Name / nickname',
            hint: 'What should we call you?',
            controller: _name,
            onChanged: (_) => setState(() {}),
          ),
          OnbField(
            label: 'Age',
            hint: 'Years (10–100)',
            controller: _age,
            keyboard: TextInputType.number,
            error: _basicsError,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Biological sex (for calorie math)',
              style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: OnbOption(
                  title: 'Male',
                  icon: Icons.male_rounded,
                  selected: p.sex == BiologicalSex.male,
                  onTap: () =>
                      setState(() => p.sex = BiologicalSex.male),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OnbOption(
                  title: 'Female',
                  icon: Icons.female_rounded,
                  selected: p.sex == BiologicalSex.female,
                  onTap: () =>
                      setState(() => p.sex = BiologicalSex.female),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Body ─────────────────────────────────
  Widget _body() {
    final p = _state.profile;
    final h = double.tryParse(_height.text);
    final w = double.tryParse(_weight.text);
    final hOk = h != null && h >= 100 && h <= 250;
    final wOk = w != null && w >= 25 && w <= 300;
    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'Your body, your baseline.',
      subtitle: 'Used only to estimate your starting targets.',
      onBack: () => _go(1),
      skipLabel: 'Skip',
      onSkip: () => _go(3),
      nextEnabled: hOk && wOk,
      onNext: () {
        if (!hOk || !wOk) {
          setState(() => _bodyError =
              'Height 100–250 cm, weight 25–300 kg.');
          return;
        }
        p.heightCm = h;
        p.weightKg = w;
        final gw = double.tryParse(_goalWeight.text);
        if (gw != null && gw >= 25 && gw <= 300) {
          _state.goals.goalWeightKg = gw;
        }
        setState(() => _bodyError = null);
        _recalcPlan();
        _go(3);
      },
      child: Column(
        children: [
          OnbField(
            label: 'Height',
            hint: 'cm (e.g. 175)',
            controller: _height,
            keyboard: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          OnbField(
            label: 'Current weight',
            hint: 'kg (e.g. 75)',
            controller: _weight,
            keyboard: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          OnbField(
            label: 'Goal weight (optional)',
            hint: 'kg — only if relevant',
            controller: _goalWeight,
            keyboard: TextInputType.number,
            error: _bodyError,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── 3. Goal ─────────────────────────────────
  Widget _goal() {
    final g = _state.goals;
    const icons = {
      PrimaryGoal.loseWeight: Icons.trending_down_rounded,
      PrimaryGoal.buildMuscle: Icons.fitness_center_rounded,
      PrimaryGoal.maintainWeight: Icons.balance_rounded,
      PrimaryGoal.eatHealthier: Icons.eco_rounded,
      PrimaryGoal.improveNutrition: Icons.science_outlined,
      PrimaryGoal.buildHabits: Icons.repeat_rounded,
    };
    final selectedGoals = <PrimaryGoal>{g.primary, ...g.secondary};

    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'What are you working toward?',
      subtitle: 'Select one or more goals. Tap to select or change your primary priority.',
      onBack: () => _go(2),
      nextEnabled: selectedGoals.isNotEmpty,
      onNext: () {
        _recalcPlan();
        _go(4);
      },
      child: Column(
        children: PrimaryGoal.values.map((goal) {
          final isSelected = selectedGoals.contains(goal);
          final isPrimary = g.primary == goal;
          return OnbOption(
            title: goalLabel(goal),
            icon: icons[goal],
            selected: isSelected,
            isMultiSelect: true,
            isPrimary: isPrimary,
            onTap: () => setState(() {
              if (isSelected) {
                if (selectedGoals.length > 1) {
                  selectedGoals.remove(goal);
                  g.secondary.remove(goal);
                  if (g.primary == goal) {
                    g.primary = selectedGoals.first;
                    g.secondary.remove(g.primary);
                  }
                }
              } else {
                selectedGoals.add(goal);
                if (!g.secondary.contains(goal) && g.primary != goal) {
                  g.secondary.add(goal);
                }
              }
            }),
            onPrimaryTap: () => setState(() {
              if (selectedGoals.contains(goal)) {
                if (!g.secondary.contains(g.primary) && g.primary != goal) {
                  g.secondary.add(g.primary);
                }
                g.secondary.remove(goal);
                g.primary = goal;
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  // ── 4. Activity ─────────────────────────────
  Widget _activity() {
    final p = _state.profile;
    const icons = {
      ActivityTier.sedentary: Icons.chair_outlined,
      ActivityTier.lightlyActive: Icons.directions_walk_rounded,
      ActivityTier.moderatelyActive: Icons.directions_run_rounded,
      ActivityTier.veryActive: Icons.fitness_center_rounded,
      ActivityTier.extremelyActive: Icons.bolt_rounded,
    };
    const subtitles = {
      ActivityTier.sedentary: 'Desk job, mostly resting through the day',
      ActivityTier.lightlyActive: '1–3 light walks or activities per week',
      ActivityTier.moderatelyActive: '3–5 workouts or brisk active sessions per week',
      ActivityTier.veryActive: '6–7 intense athletic training sessions per week',
      ActivityTier.extremelyActive: 'Daily heavy physical work or competitive training',
    };
    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'How active are you?',
      subtitle: 'Be honest — this tunes your baseline calorie estimate.',
      onBack: () => _go(3),
      nextEnabled: p.activity != null,
      onNext: () {
        _recalcPlan();
        _go(5);
      },
      child: Column(
        children: ActivityTier.values
            .map((a) => OnbOption(
                  title: activityLabel(a),
                  subtitle: subtitles[a],
                  icon: icons[a],
                  selected: p.activity == a,
                  onTap: () =>
                      setState(() => p.activity = a),
                ))
            .toList(),
      ),
    );
  }

  // ── 5. Diet ─────────────────────────────────
  Widget _diet() {
    final p = _state.profile;
    final t = HiwTheme.of(context);
    const primaryDiets = [
      DietPreference.vegetarian,
      DietPreference.nonVegetarian,
      DietPreference.noPreference,
    ];
    const dietIcons = {
      DietPreference.vegetarian: Icons.eco_rounded,
      DietPreference.nonVegetarian: Icons.restaurant_rounded,
      DietPreference.noPreference: Icons.all_inclusive_rounded,
      DietPreference.vegan: Icons.spa_outlined,
      DietPreference.eggetarian: Icons.egg_alt_outlined,
      DietPreference.jain: Icons.nature_people_outlined,
    };
    const dietSubtitles = {
      DietPreference.vegetarian: 'Plant-based foods, dairy, lentils, vegetables',
      DietPreference.nonVegetarian: 'Meat, poultry, seafood, eggs & plants',
      DietPreference.noPreference: 'Enjoy everything with no dietary restrictions',
    };

    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'How do you usually eat?',
      subtitle: 'Choose your main diet. You can add specific preferences below.',
      onBack: () => _go(4),
      skipLabel: 'Skip',
      onSkip: () {
        _saveRestrictions();
        _recalcPlan();
        _go(6);
      },
      onNext: () {
        _saveRestrictions();
        _recalcPlan();
        _go(6);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...primaryDiets.map((d) => OnbOption(
                title: dietLabel(d),
                subtitle: dietSubtitles[d],
                icon: dietIcons[d],
                selected: p.diet == d,
                onTap: () => setState(() => p.diet = d),
              )),
          SizedBox(height: 12.h),
          Text(
            'Extended Preferences (Optional)',
            style: TextStyle(
              color: t.inkColor,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              DietPreference.vegan,
              DietPreference.eggetarian,
              DietPreference.jain,
            ].map((d) {
              final isSel = p.diet == d;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isSel ? Colors.white : t.inkColor,
                      backgroundColor: isSel ? t.accentColor : t.cardBackground,
                      side: BorderSide(
                        color: isSel ? t.accentColor : t.cardStroke,
                        width: isSel ? 1.5 : 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () => setState(() => p.diet = d),
                    child: Text(
                      dietLabel(d),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
          OnbField(
            label: 'Allergies & Restrictions (optional)',
            hint: 'e.g. lactose, gluten, nuts — comma separated',
            controller: _restrictions,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── 6. Plan ─────────────────────────────────
  Widget _planPage() {
    final t = HiwTheme.of(context);
    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'Your HIW Plan',
      subtitle:
          'Starting targets based on your profile. You can change them anytime.',
      onBack: () => _go(5),
      nextLabel: 'Looks Good',
      onNext: () => _go(7),
      child: Column(
        children: [
          HiwCard(
            child: Column(
              children: [
                _planRow(t, 'Daily Calories',
                    _calories, 'kcal', TextInputType.number),
                _planRow(t, 'Protein Target',
                    _protein, 'g', TextInputType.number),
                _planRow(t, 'Starting Hydration',
                    _water, 'ml', TextInputType.number),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          if (_plan != null)
            Text(
              _plan!.rationale,
              style: TextStyle(
                  color: t.mutedColor, fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _planRow(HiwTheme t, String label,
      TextEditingController c, String unit, TextInputType kb) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp)),
          ),
          SizedBox(
            width: 90.w,
            child: TextField(
              controller: c,
              keyboardType: kb,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Text(unit,
              style:
                  TextStyle(color: t.mutedColor, fontSize: 12.sp)),
        ],
      ),
    );
  }

  // ── 7. Reminders ────────────────────────────
  Widget _reminders() {
    final t = HiwTheme.of(context);
    final r = _state.reminders;
    Widget toggle(String label, String sub, bool v,
        void Function(bool) set) {
      return HiwCard(
        padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label,
              style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp)),
          subtitle: Text(sub,
              style:
                  TextStyle(color: t.mutedColor, fontSize: 12.sp)),
          value: v,
          activeThumbColor: t.accentColor,
          onChanged: (b) => setState(() => set(b)),
        ),
      );
    }

    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'Want HIW to keep you on track?',
      subtitle: 'Gentle nudges only. Tune times later in Settings.',
      onBack: () => _go(6),
      skipLabel: 'Skip',
      onSkip: () {
        r
          ..water = false
          ..meals = false
          ..dailyNutrition = false
          ..streak = false;
        _go(8);
      },
      onNext: () => _go(8),
      child: Column(
        children: [
          toggle('Water Reminders', 'Hourly sips through the day',
              r.water, (b) => r.water = b),
          SizedBox(height: 10.h),
          toggle('Meal Reminders', 'Breakfast • Lunch • Snack • Dinner',
              r.meals, (b) => r.meals = b),
          SizedBox(height: 10.h),
          toggle('Daily Nutrition Reminder',
              'Evening summary of your day', r.dailyNutrition,
              (b) => r.dailyNutrition = b),
          SizedBox(height: 10.h),
          toggle('Streak Reminder', 'Protect your logging streak',
              r.streak, (b) => r.streak = b),
        ],
      ),
    );
  }

  // ── 8. Region ───────────────────────────────
  Widget _region() {
    final t = HiwTheme.of(context);
    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'Discover food around you.',
      subtitle:
          'HIW can use your approximate location to connect foods with your local region and help grow the HIW Food Index. Never continuous GPS — just district, state, country.',
      onBack: () => _go(7),
      skipLabel: 'Not Now',
      onSkip: () => _go(9),
      nextLabel: 'Continue',
      onNext: () {
        _state.region
          ..district = _district.text.trim().isEmpty
              ? null
              : _district.text.trim()
          ..state = _stateName.text.trim().isEmpty
              ? null
              : _stateName.text.trim()
          ..country = _country.text.trim().isEmpty
              ? null
              : _country.text.trim()
          ..manual = true;
        _go(9);
      },
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: t.inkColor,
                side: BorderSide(color: t.cardStroke),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                backgroundColor: t.cardBackground,
              ),
              onPressed: () async {
                final s = await Permission.locationWhenInUse.request();
                if (!mounted) return;
                if (s.isGranted) {
                  setState(() => _state.region.manual = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Location allowed — confirm your State below.')),
                  );
                } else if (s.isPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Location permission denied.'),
                      action: SnackBarAction(
                        label: 'Settings',
                        onPressed: () => openAppSettings(),
                      ),
                    ),
                  );
                }
              },
              icon: Icon(Icons.my_location_rounded, color: t.accentColor),
              label: const Text('Allow Location Permission'),
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: TextButton.icon(
              onPressed: () => openAppSettings(),
              icon: Icon(Icons.settings_outlined, size: 16.sp, color: t.mutedColor),
              label: Text(
                'Open App Location Settings',
                style: TextStyle(color: t.mutedColor, fontSize: 12.sp),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          OnbField(
            label: 'State',
            hint: 'e.g. Telangana, Maharashtra, Karnataka',
            controller: _stateName,
            onChanged: (_) => setState(() {}),
          ),
          OnbField(
            label: 'District (optional)',
            hint: 'e.g. Hyderabad, Pune, Bengaluru',
            controller: _district,
            onChanged: (_) => setState(() {}),
          ),
          OnbField(
            label: 'Country',
            hint: 'e.g. India',
            controller: _country,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ── 9. Summary ──────────────────────────────
  Widget _summary() {
    final t = HiwTheme.of(context);
    final p = _state.profile, g = _state.goals;
    Widget row(String k, String v) => Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(
            children: [
              Expanded(
                  child: Text(k,
                      style: TextStyle(
                          color: t.mutedColor, fontSize: 13.sp))),
              Text(v,
                  style: TextStyle(
                      color: t.inkColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp)),
            ],
          ),
        );
    return OnbScaffold(
      step: _shown,
      total: _total,
      title: 'Your HIW is ready.',
      subtitle: 'Built around your answers. Change anything later.',
      showBack: true,
      onBack: () => _go(8),
      nextLabel: 'Enter HIW',
      onNext: _finish,
      child: HiwCard(
        child: Column(
          children: [
            row('Primary Goal', goalLabel(g.primary)),
            row('Daily Calories', '${_state.calories} kcal'),
            row('Protein', '${_state.proteinG} g'),
            row('Water', GoalEngine.waterLabel(_state.waterMl)),
            if (p.activity != null)
              row('Activity', activityLabel(p.activity!)),
            if (p.diet != null)
              row('Diet', dietLabel(p.diet!)),
            if (g.goalWeightKg != null)
              row('Goal Weight', '${g.goalWeightKg} kg'),
          ],
        ),
      ),
    );
  }
}
