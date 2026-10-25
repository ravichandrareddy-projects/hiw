// lib/core/health_profile.dart
// Personalization domain models: profile, goals, reminders, region,
// plus transient onboarding drafts. Pure Dart — no widgets, no I/O.
// Consumed later by NutritionEngine / GoalEngine / HabitEngine /
// ProgressionEngine / FoodIndexEngine.

enum BiologicalSex { male, female }

enum ActivityTier {
  sedentary, // 1.20
  lightlyActive, // 1.375
  moderatelyActive, // 1.55
  veryActive, // 1.725
  extremelyActive, // 1.90
}

enum PrimaryGoal {
  loseWeight,
  buildMuscle,
  maintainWeight,
  eatHealthier,
  improveNutrition,
  buildHabits,
}

enum DietPreference {
  vegetarian,
  eggetarian,
  nonVegetarian,
  vegan,
  jain,
  noPreference,
}

class UserProfile {
  String name;
  int? age;
  BiologicalSex? sex;
  double? heightCm;
  double? weightKg;
  double? bodyFatPct; // optional; enables Katch-McArdle when valid
  ActivityTier? activity;
  DietPreference? diet;
  List<String> restrictions;
  List<String> allergies;

  UserProfile({
    this.name = '',
    this.age,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.bodyFatPct,
    this.activity,
    this.diet,
    List<String>? restrictions,
    List<String>? allergies,
  })  : restrictions = restrictions ?? [],
        allergies = allergies ?? [];

  bool get hasBasics =>
      name.trim().isNotEmpty &&
      age != null &&
      sex != null &&
      heightCm != null &&
      weightKg != null;
}

class GoalModel {
  PrimaryGoal primary;
  List<PrimaryGoal> secondary;
  double? goalWeightKg;
  // Per-target user overrides (never silently overwritten, spec §19).
  bool caloriesCustom;
  bool proteinCustom;
  bool waterCustom;

  GoalModel({
    this.primary = PrimaryGoal.eatHealthier,
    List<PrimaryGoal>? secondary,
    this.goalWeightKg,
    this.caloriesCustom = false,
    this.proteinCustom = false,
    this.waterCustom = false,
  }) : secondary = secondary ?? [];
}

class ReminderPreferences {
  bool water;
  bool meals;
  bool dailyNutrition;
  bool streak;
  // HH:mm strings reused by the existing reminder storage.
  String breakfastTime;
  String lunchTime;
  String snackTime;
  String dinnerTime;

  ReminderPreferences({
    this.water = true,
    this.meals = true,
    this.dailyNutrition = true,
    this.streak = true,
    this.breakfastTime = '08:00',
    this.lunchTime = '13:00',
    this.snackTime = '17:00',
    this.dinnerTime = '20:00',
  });
}

class RegionalPreferences {
  String? district;
  String? state;
  String? country;
  bool manual;

  RegionalPreferences({
    this.district,
    this.state,
    this.country,
    this.manual = true,
  });

  bool get hasRegion =>
      (state ?? '').isNotEmpty && (country ?? '').isNotEmpty;
}

/// Transient drafts held by the onboarding coordinator so Back never
/// loses already-entered information.
class OnboardingState {
  final UserProfile profile = UserProfile();
  final GoalModel goals = GoalModel();
  final ReminderPreferences reminders = ReminderPreferences();
  final RegionalPreferences region = RegionalPreferences();

  // Editable plan preview (recomputed by GoalEngine, adjustable by user).
  int calories = 2000;
  int proteinG = 75;
  int fatG = 65;
  int carbsG = 250;
  int fiberG = 25;
  int waterMl = 2200;
  double? bmr;
  double? tdee;

  int stepIndex = 0;
}

String goalLabel(PrimaryGoal g) {
  switch (g) {
    case PrimaryGoal.loseWeight:
      return 'Lose Weight';
    case PrimaryGoal.buildMuscle:
      return 'Build Muscle';
    case PrimaryGoal.maintainWeight:
      return 'Maintain Weight';
    case PrimaryGoal.eatHealthier:
      return 'Eat Healthier';
    case PrimaryGoal.improveNutrition:
      return 'Improve Nutrition';
    case PrimaryGoal.buildHabits:
      return 'Build Better Daily Habits';
  }
}

String activityLabel(ActivityTier a) {
  switch (a) {
    case ActivityTier.sedentary:
      return 'Mostly Sedentary';
    case ActivityTier.lightlyActive:
      return 'Lightly Active';
    case ActivityTier.moderatelyActive:
      return 'Moderately Active';
    case ActivityTier.veryActive:
      return 'Very Active';
    case ActivityTier.extremelyActive:
      return 'Extremely Active';
  }
}

String dietLabel(DietPreference d) {
  switch (d) {
    case DietPreference.vegetarian:
      return 'Vegetarian';
    case DietPreference.eggetarian:
      return 'Eggetarian';
    case DietPreference.nonVegetarian:
      return 'Non-Vegetarian';
    case DietPreference.vegan:
      return 'Vegan';
    case DietPreference.jain:
      return 'Jain';
    case DietPreference.noPreference:
      return 'Both / No Restriction';
  }
}
