import 'dart:ui';
import 'package:flutter/material.dart';

// themes
import 'themes/app_theme.dart';

// screens
import 'screens/chatbot_screen.dart';
import 'screens/food_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/history_screen.dart';
import 'screens/avatar_screen.dart';

// widgets
import 'widgets/bottom_nav.dart';

// 🎄 events
import 'events/christmas/christmas_background.dart';
import 'events/christmas/christmas_config.dart';

// hive
import 'hive/hive_init.dart';

/// ✅ ONLY ONE MAIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive(); // Hive init happens once
  runApp(const HIWApp());
}

class HIWApp extends StatelessWidget {
  const HIWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HIW – Health Is Wealth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkBlueTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1;

  // -------------------------
  // AVATAR STATE
  // -------------------------
  double avatarHealth = 72;
  double avatarEnergy = 65;
  double avatarStamina = 58;

  // -------------------------
  // FOOD SCAN STATE
  // -------------------------
  ImageProvider? scannedFoodImage;
  int scannedCalories = 0;
  double scannedHealthyScore = 0;

  void _onFoodAnalyzed({
    required ImageProvider image,
    required int calories,
    required double healthyScore,
  }) {
    setState(() {
      scannedFoodImage = image;
      scannedCalories = calories;
      scannedHealthyScore = healthyScore;
      _currentIndex = 1;
    });
  }

  void _updateAvatarFromFood({
    required double health,
    required double energy,
    required double stamina,
  }) {
    setState(() {
      avatarHealth = health;
      avatarEnergy = energy;
      avatarStamina = stamina;

      scannedFoodImage = null;
      scannedCalories = 0;
      scannedHealthyScore = 0;
    });
  }

  Widget _wrapWithEvent(Widget page) {
    return ChristmasConfig.enabled
        ? ChristmasBackground(child: page)
        : page;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const ChatbotScreen(),
      FoodScreen(
        onUpdateAvatar: _updateAvatarFromFood,
        scannedImage: scannedFoodImage,
        scannedCalories: scannedCalories,
        healthyScore: scannedHealthyScore,
      ),
      ScannerScreen(onFoodAnalyzed: _onFoodAnalyzed),
      const HistoryScreen(),
      AvatarScreen(
        healthPercent: avatarHealth,
        energyPercent: avatarEnergy,
        staminaPercent: avatarStamina,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          // 🔥 PAGE CONTENT
          _wrapWithEvent(
            Padding(
              padding: const EdgeInsets.only(top: 72),
              child: pages[_currentIndex],
            ),
          ),

          // 🧊 HIW GLASS HEADER (SAFE & CORRECT)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: const Text(
                      'HIW',
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
