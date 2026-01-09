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

// avatar hive + store
import 'avatar/avatar_store.dart';

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
  // AVATAR STORE (SINGLE SOURCE)
  // -------------------------
  final AvatarStore _avatarStore = AvatarStore();

  double avatarHealth = 0;
  double avatarEnergy = 0;
  double avatarStamina = 0; // 🔥 DAILY stamina preview

  // -------------------------
  // FOOD SCAN STATE
  // -------------------------
  ImageProvider? scannedFoodImage;
  String? detectedFoodLabel;
  double scannedHealthyScore = 0;

  // -------------------------
  // INIT
  // -------------------------
  @override
  void initState() {
    super.initState();
    _initAvatar();
  }

  Future<void> _initAvatar() async {
    await _avatarStore.init();

    final avatar = _avatarStore.avatar;

setState(() {
  avatarHealth = avatar.health;
  avatarEnergy = avatar.energy;
  avatarStamina = _avatarStore.dailyStaminaPreview; // ✅ LIVE WATER
});

  }

  // -------------------------
  // CALLED FROM SCANNER
  // -------------------------
  void _onFoodAnalyzed({
    required ImageProvider image,
    required String label,
    required double healthyScore,
  }) {
    setState(() {
      scannedFoodImage = image;
      detectedFoodLabel = label;
      scannedHealthyScore = healthyScore;
      _currentIndex = 1; // jump to Food tab
    });
  }

  // -------------------------
  // CALLED FROM FOOD SCREEN
  // -------------------------
  // FOOD → HEALTH + ENERGY ONLY
  void _updateAvatarFromFood({
    required int dailyRaw,
  }) {
    _avatarStore.addDailyRaw(
      healthRaw: dailyRaw,
      energyRaw: dailyRaw,
      staminaRaw: 0, // ❌ stamina NOT from food
    );

    final avatar = _avatarStore.avatar;

    setState(() {
      avatarHealth = avatar.health;
      avatarEnergy = avatar.energy;
      avatarStamina = _avatarStore.dailyStaminaPreview;

      scannedFoodImage = null;
      detectedFoodLabel = null;
      scannedHealthyScore = 0;
    });
  }

  // -------------------------
  // UI WRAPPER
  // -------------------------
  Widget _wrapWithEvent(Widget page) {
    return ChristmasConfig.enabled
        ? ChristmasBackground(child: page)
        : page;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const ChatbotScreen(),

      /// 🍽 FOOD
      FoodScreen(
        onUpdateAvatar: _updateAvatarFromFood,
        scannedImage: scannedFoodImage,
        detectedLabel: detectedFoodLabel,
        healthyScore: scannedHealthyScore,
      ),

      /// 📸 SCANNER
      ScannerScreen(onFoodAnalyzed: _onFoodAnalyzed),

      const HistoryScreen(),

      /// 🧍 AVATAR
      AvatarScreen(
        healthPercent: avatarHealth,
        energyPercent: avatarEnergy,
        staminaPercent: avatarStamina, // ✅ DAILY stamina
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          _wrapWithEvent(
            Padding(
              padding: const EdgeInsets.only(top: 72),
              child: pages[_currentIndex],
            ),
          ),

          // 🧊 HEADER
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
