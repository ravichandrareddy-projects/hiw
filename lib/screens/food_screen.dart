import 'dart:async';
import 'package:flutter/material.dart';

// 🎄 Christmas
import '../events/christmas/christmas_glass_card.dart';

// normal widgets
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

import 'purchases_screen.dart';
import 'daily_quest_screen.dart';

// 🧠 CORE LOGIC
import '../core/nutrition_store.dart';
import '../core/health_engine.dart';

class FoodScreen extends StatefulWidget {
  final void Function({
    required double health,
    required double energy,
    required double stamina,
  }) onUpdateAvatar;

  final ImageProvider? scannedImage;
  final int scannedCalories;
  final double healthyScore;

  const FoodScreen({
    super.key,
    required this.onUpdateAvatar,
    this.scannedImage,
    this.scannedCalories = 0,
    this.healthyScore = 0,
  });

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final NutritionStore _nutritionStore = NutritionStore();
  final HealthEngine _healthEngine = HealthEngine();

  int selectedMeal = 0;
  final meals = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

  int dailyTargetCalories = 2000;

  int get remainingCalories =>
      (dailyTargetCalories - _nutritionStore.totalCalories)
          .clamp(0, 9999);

  double healthyFoodProgress = 0.6;

  ImageProvider? scannedFoodImage;
  bool _scanApplied = false;

  // 🕒 DATE & TIME
  late Timer _clock;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();

    // update every second
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => now = DateTime.now()),
    );

    if (widget.scannedImage != null && !_scanApplied) {
      scannedFoodImage = widget.scannedImage;
      healthyFoodProgress =
          (healthyFoodProgress + widget.healthyScore).clamp(0.0, 1.0);
      _scanApplied = true;
    }
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🔹 DATE | HIW | TIME (ALL GLASS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    dateText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: const Text(
                    'HIW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    timeText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              '${_greeting()}, Valtooy 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Here’s your nutrition summary for today',
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 16),

            if (scannedFoodImage != null)
              GlassCard(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image(
                    image: scannedFoodImage!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (scannedFoodImage != null) const SizedBox(height: 12),

            _mealSelector(),
            const SizedBox(height: 16),

            _nutritionCard(),

            const SizedBox(height: 24),
            const Text(
              "Today's Progress",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),

            GlassCard(
              child: Text(
                '$remainingCalories kcal remaining',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),

        // 🟢 SHOP BUTTON
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white.withOpacity(0.15),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PurchasesScreen(),
                ),
              );
            },
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
        ),

        // 🟣 QUEST BUTTON
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white.withOpacity(0.15),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyQuestScreen(),
                ),
              );
            },
            child: const Icon(Icons.flag, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _mealSelector() {
    return GlassCard(
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
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _nutritionCard() {
    return ChristmasGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${meals[selectedMeal]} Nutrition',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _pill('Calories', '${_nutritionStore.totalCalories} kcal'),
              const SizedBox(width: 8),
              _pill(
                'Protein',
                '${_nutritionStore.totalProtein.toStringAsFixed(1)} g',
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _pill(
                'Carbs',
                '${_nutritionStore.totalCarbs.toStringAsFixed(1)} g',
              ),
              const SizedBox(width: 8),
              _pill(
                'Fats',
                '${_nutritionStore.totalFats.toStringAsFixed(1)} g',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: GlassButton(
              text: 'Push To Avatar',
              icon: Icons.arrow_upward,
              onTap: () {
                widget.onUpdateAvatar(
                  health: _healthEngine.health,
                  energy: _healthEngine.energy,
                  stamina: _healthEngine.stamina,
                );
                setState(() {
                  scannedFoodImage = null;
                  _scanApplied = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Expanded(
      child: GlassCard(
        radius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFFBFD7FF)),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
