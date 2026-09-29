// lib/screens/profile_edit_screen.dart
// Edit anything onboarding collected. Writes the same keys + stores,
// recalculates only non-customized targets (spec §19).
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/goal_engine.dart';
import '../core/health_profile.dart';
import '../core/nutrition_store.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../themes/hiw_theme.dart';
import '../widgets/limit_sheet.dart';
import 'onboarding/onboarding_widgets.dart';
import 'paywall_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _water = TextEditingController();
  BiologicalSex? _sex;
  ActivityTier? _activity;
  PrimaryGoal? _goal;
  DietPreference? _diet;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _name.text = (await AppState.getUsername()) ?? '';
    final age = await AppState.getAge();
    if (age != null) _age.text = '$age';
    final sex = await AppState.getSex();
    if (sex == 'male') _sex = BiologicalSex.male;
    if (sex == 'female') _sex = BiologicalSex.female;
    final h = await AppState.getHeightCm();
    if (h != null) _height.text = '$h';
    final w = await AppState.getWeightKg();
    if (w != null) _weight.text = '$w';
    final act = await AppState.getActivity();
    if (act != null) {
      for (final a in ActivityTier.values) {
        if (a.name == act) _activity = a;
      }
    }
    final gl = await AppState.getGoal();
    if (gl != null) {
      for (final g in PrimaryGoal.values) {
        if (g.name == gl) _goal = g;
      }
    }
    final diet = await AppState.getDiet();
    if (diet != null) {
      for (final d in DietPreference.values) {
        if (d.name == diet) _diet = d;
      }
    }
    final store = NutritionStore();
    if (store.dailyTargetCalories > 0) {
      _calories.text = '${store.dailyTargetCalories}';
    }
    if (store.proteinTargetG > 0) {
      _protein.text = '${store.proteinTargetG}';
    }
    if (store.hydrationTargetMl > 0) {
      _water.text = '${store.hydrationTargetMl}';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final age = int.tryParse(_age.text);
    final h = double.tryParse(_height.text);
    final w = double.tryParse(_weight.text);
    if (age != null && (age < 10 || age > 100)) {
      setState(() => _error = 'Age must be 10–100.');
      return;
    }
    if (h != null && (h < 100 || h > 250)) {
      setState(() => _error = 'Height must be 100–250 cm.');
      return;
    }
    if (w != null && (w < 25 || w > 300)) {
      setState(() => _error = 'Weight must be 25–300 kg.');
      return;
    }
    setState(() => _error = null);

    final name = _name.text.trim();
    if (name.isNotEmpty) await AppState.setUsername(name);
    if (age != null) await AppState.setAge(age);
    if (_sex != null) {
      await AppState.setSex(
          _sex == BiologicalSex.male ? 'male' : 'female');
    }
    if (h != null) await AppState.setHeightCm(h);
    if (w != null) await AppState.setWeightKg(w);
    if (_activity != null) {
      await AppState.setActivity(_activity!.name);
    }
    if (_goal != null) await AppState.setGoal(_goal!.name);
    if (_diet != null) await AppState.setDiet(_diet!.name);

    // Direct target edits are Pro custom macros (§19 + freemium).
    // Profile fields above always save; only the target block is gated.
    final store = NutritionStore();
    final cal = int.tryParse(_calories.text);
    final pro = int.tryParse(_protein.text);
    final wat = int.tryParse(_water.text);
    final wantsCustom = (cal != null && cal != store.dailyTargetCalories) ||
        (pro != null && pro != store.proteinTargetG) ||
        (wat != null && wat != store.hydrationTargetMl);
    if (wantsCustom &&
        !(await EntitlementStore.canUse(Feature.customMacros))) {
      if (!mounted) return;
      await showLimitSheet(
        context,
        title: 'Custom targets live in HIW Pro',
        usedLabel: 'Free uses your plan targets — custom is Pro',
        resetLabel: 'anytime — upgrade when ready',
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
              feature: 'Custom macro targets live in HIW Pro.'),
        ),
      );
      return;
    }
    if (cal != null && cal >= 800 && cal <= 8000) {
      // Only overwrite when changed (recalc fills the rest).
      if (cal != store.dailyTargetCalories) {
        store.setDailyTargetCalories(cal);
        await AppState.markTargetCustom('calories');
      }
    }
    if (pro != null && pro >= 10 && pro <= 500) {
      if (pro != store.proteinTargetG) {
        store.setProteinTargetG(pro);
        await AppState.markTargetCustom('protein');
      }
    }
    if (wat != null && wat >= 500 && wat <= 8000) {
      if (wat != store.hydrationTargetMl) {
        store.setHydrationTargetMl(wat);
        await AppState.markTargetCustom('water');
      }
    }

    // Recalculate non-customized targets from the updated profile.
    final custom = await AppState.customTargets();
    if (age != null && h != null && w != null) {
      final p = UserProfile(
        age: age,
        sex: _sex,
        heightCm: h,
        weightKg: w,
        activity: _activity,
      );
      final g = GoalModel(
          primary: _goal ?? PrimaryGoal.eatHealthier);
      final r = GoalEngine.calculate(p, g);
      if (!custom.contains('calories') && cal == null) {
        store.setDailyTargetCalories(r.calories);
      }
      if (!custom.contains('protein') && pro == null) {
        store.setProteinTargetG(r.proteinG);
      }
      if (!custom.contains('water') && wat == null) {
        store.setHydrationTargetMl(r.waterMl);
      }
      if (store.fiberTargetG <= 0) {
        store.setFiberTargetG(r.fiberG);
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _calories.dispose();
    _protein.dispose();
    _water.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'My Health Profile',
          style: TextStyle(
              color: t.inkColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnbField(
                  label: 'Name', hint: 'Nickname', controller: _name),
              Row(
                children: [
                  Expanded(
                    child: OnbField(
                        label: 'Age',
                        hint: 'Years',
                        controller: _age,
                        keyboard: TextInputType.number),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OnbField(
                        label: 'Height (cm)',
                        hint: '175',
                        controller: _height,
                        keyboard: TextInputType.number),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OnbField(
                        label: 'Weight (kg)',
                        hint: '75',
                        controller: _weight,
                        keyboard: TextInputType.number),
                  ),
                ],
              ),
              _sectionLabel(t, 'Biological sex'),
              Row(
                children: [
                  Expanded(
                    child: OnbOption(
                      title: 'Male',
                      selected: _sex == BiologicalSex.male,
                      onTap: () => setState(
                          () => _sex = BiologicalSex.male),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OnbOption(
                      title: 'Female',
                      selected: _sex == BiologicalSex.female,
                      onTap: () => setState(
                          () => _sex = BiologicalSex.female),
                    ),
                  ),
                ],
              ),
              _sectionLabel(t, 'Primary goal'),
              ...PrimaryGoal.values.map((g) => OnbOption(
                    title: goalLabel(g),
                    selected: _goal == g,
                    onTap: () => setState(() => _goal = g),
                  )),
              _sectionLabel(t, 'Activity'),
              ...ActivityTier.values.map((a) => OnbOption(
                    title: activityLabel(a),
                    selected: _activity == a,
                    onTap: () =>
                        setState(() => _activity = a),
                  )),
              _sectionLabel(t, 'Diet'),
              ...DietPreference.values.map((d) => OnbOption(
                    title: dietLabel(d),
                    selected: _diet == d,
                    onTap: () => setState(() => _diet = d),
                  )),
              _sectionLabel(t, 'Daily targets (edit = yours forever)'),
              OnbField(
                  label: 'Calories (kcal)',
                  hint: '2000',
                  controller: _calories,
                  keyboard: TextInputType.number),
              OnbField(
                  label: 'Protein (g)',
                  hint: '75',
                  controller: _protein,
                  keyboard: TextInputType.number),
              OnbField(
                label: 'Water (ml)',
                hint: '2200',
                controller: _water,
                keyboard: TextInputType.number,
                error: _error,
              ),
              SizedBox(height: 8.h),
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
                  onPressed: _save,
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                        fontSize: 16.sp,
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

  Widget _sectionLabel(HiwTheme t, String s) => Padding(
        padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
        child: Text(
          s,
          style: TextStyle(
              color: t.inkColor,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp),
        ),
      );
}
