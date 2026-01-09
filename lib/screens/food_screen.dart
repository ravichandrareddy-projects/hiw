import 'dart:async';
import 'package:flutter/material.dart';

// 🎄 Christmas
import '../events/christmas/christmas_glass_card.dart';

// normal widgets
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

import 'purchases_screen.dart';
import 'daily_quest_screen.dart';
import 'generic_addons_screen.dart';

// 🧠 CORE LOGIC
import '../core/nutrition_store.dart';
import '../core/health_engine.dart';
import '../core/food_item.dart';
import '../core/food_addons_config.dart';
import '../core/generic_nutrition_engine.dart';
import '../core/history_store.dart';
import '../core/water_store.dart';

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

  const FoodScreen({
    super.key,
    required this.onUpdateAvatar,
    this.scannedImage,
    this.detectedLabel,
    this.healthyScore = 0,
  });

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final NutritionStore _nutritionStore = NutritionStore();
  final HealthEngine _healthEngine = HealthEngine();
  final WaterStore _waterStore = WaterStore();
  final AvatarStore _avatarStore = AvatarStore();

  int selectedMeal = 0;
  final meals = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

  int dailyTargetCalories = 2000;

  int get remainingCalories =>
      (dailyTargetCalories - _nutritionStore.totalCalories)
          .clamp(0, 9999);

  ImageProvider? scannedFoodImage;
  bool _scanApplied = false;

  String? detectedFoodLabel;
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

    // ✅ SAFE INIT — NO DOUBLE OPEN
    Future.microtask(() async {
      await _waterStore.init();

      await _avatarStore.init();
    });

    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => now = DateTime.now()),
    );

    if (widget.scannedImage != null && !_scanApplied) {
      scannedFoodImage = widget.scannedImage;
      detectedFoodLabel = widget.detectedLabel;
      selectedMeal = _mealFromTime(DateTime.now()).index;
      _scanApplied = true;
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

  String get dateText =>
      '${now.day.toString().padLeft(2, '0')} '
      '${const [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ][now.month - 1]}';

  String get timeText =>
      '${now.hour % 12 == 0 ? 12 : now.hour % 12}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')} '
      '${now.hour >= 12 ? 'PM' : 'AM'}';

  // =============================
  // PER MEAL TOTALS
  // =============================
  ({int calories, double protein, double carbs, double fats})
      _totalsForSelectedMeal() {
    final meal = MealType.values[selectedMeal];
    final foods = _nutritionStore.todayFoods
        .where((f) => f.mealType == meal)
        .toList();

    return (
      calories: foods.fold(0, (s, f) => s + f.calories),
      protein: foods.fold(0.0, (s, f) => s + f.protein),
      carbs: foods.fold(0.0, (s, f) => s + f.carbs),
      fats: foods.fold(0.0, (s, f) => s + f.fats),
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
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 16),

            if (scannedFoodImage != null) _foodImage(),

            if (scannedFoodImage != null &&
                detectedFoodLabel != null &&
                foodAddons.containsKey(detectedFoodLabel))
              _addonsEntry(),

            const SizedBox(height: 16),
            _mealSelector(),
            const SizedBox(height: 16),
            _nutritionCard(),
            const SizedBox(height: 16),

            // 💧 WATER
            _waterCard(),

            const SizedBox(height: 24),
            _progressCard(),
            const SizedBox(height: 120),
          ],
        ),
        _shopButton(),
        _questButton(),
      ],
    );
  }

  // =============================
  // SECTIONS
  // =============================
  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(dateText,
                    style: const TextStyle(color: Colors.white70)),
              ),
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: const Text(
                  'HIW',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
              ),
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(timeText,
                    style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${_greeting()}, Valtooy 👋',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Here’s your nutrition summary for today',
              style: TextStyle(color: Colors.white70)),
        ],
      );

  Widget _foodImage() => GlassCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image(
            image: scannedFoodImage!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget _addonsEntry() => GlassCard(
        child: ListTile(
          leading: const Icon(Icons.restaurant, color: Colors.white),
          title: Text(
            'Customize ${detectedFoodLabel!.toUpperCase()}',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.white70),
          onTap: () async {
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
              final food = calculateFoodFromAddons(
                foodLabel: detectedFoodLabel!,
                addons: result,
                mealType: MealType.values[selectedMeal],
              );

              _nutritionStore.addFood(food);
              _healthEngine.applyFood(food);
              HistoryStore().addFood(food);

              setState(() {
                confirmedFood = food;
                scannedFoodImage = null;
                detectedFoodLabel = null;
                _scanApplied = false;
              });
            }
          },
        ),
      );

  Widget _nutritionCard() {
    final totals = _totalsForSelectedMeal();

    return ChristmasGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${meals[selectedMeal]} Nutrition',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            children: [
              _pill('Calories', '${totals.calories} kcal'),
              const SizedBox(width: 8),
              _pill('Protein', '${totals.protein.toStringAsFixed(1)} g'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pill('Carbs', '${totals.carbs.toStringAsFixed(1)} g'),
              const SizedBox(width: 8),
              _pill('Fats', '${totals.fats.toStringAsFixed(1)} g'),
            ],
          ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GlassButton(
              text: 'Push To Avatar',
              icon: Icons.arrow_upward,
              onTap: () {
                if (confirmedFood == null) return;

                final dailyRaw = AvatarLogic.calculateDailyRaw(
                  DailyAvatarInput(
                    meals: [
                      widget.healthyScore >= 0.5
                          ? FoodQuality.healthy
                          : FoodQuality.junk,
                    ],
                    calories: _nutritionStore.totalCalories,
                    waterTicks: _waterStore.waterTicks,
                    isSaturday:
                        DateTime.now().weekday == DateTime.saturday,
                  ),
                );

                widget.onUpdateAvatar(dailyRaw: dailyRaw);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // 💧 WATER (ONLY STAMINA SOURCE)
  // =============================
  Widget _waterCard() => GlassCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '💧 Water Intake',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              child: const Text('I drank water'),
              onPressed: () {
                final last = _waterStore.lastLoggedTime;
                final now = DateTime.now();

                if (last == null ||
                    now.difference(last).inMinutes >= 60) {
                  _waterStore.logWater();
                  _avatarStore.addStaminaFromWater();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('💧 Water logged! Stamina increased')),
                  );
                } else {
                  final remaining =
                      60 - now.difference(last).inMinutes;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '⏳ Wait $remaining minutes to drink again'),
                    ),
                  );
                }

                setState(() {});
              },
            ),
          ],
        ),
      );

  Widget _progressCard() => GlassCard(
        child: Text(
          '$remainingCalories kcal remaining',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
      );

  Widget _shopButton() => Positioned(
        right: 16,
        bottom: 16,
        child: FloatingActionButton(
          backgroundColor: Colors.white.withOpacity(0.15),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchasesScreen()),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
      );

  Widget _questButton() => Positioned(
        left: 16,
        bottom: 16,
        child: FloatingActionButton(
          backgroundColor: Colors.white.withOpacity(0.15),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyQuestScreen()),
          ),
          child: const Icon(Icons.flag, color: Colors.white),
        ),
      );

  Widget _mealSelector() => GlassCard(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: List.generate(meals.length, (i) {
            final selected = selectedMeal == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedMeal = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.cyanAccent.withOpacity(0.30)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      meals[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );

  Widget _pill(String label, String value) => Expanded(
        child: GlassCard(
          radius: 14,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFBFD7FF))),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
