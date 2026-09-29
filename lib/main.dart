import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔑 SystemNavigator

// screens
import 'screens/chatbot_screen.dart';
import 'screens/food_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/history_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/tester_code_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'auth/auth_welcome.dart';
import 'screens/mood_support_screen.dart';
import 'screens/update_log_screen.dart'; // 🆕
import 'screens/splash_screen.dart'; // 🆕 HIW brand splash
import 'package:shared_preferences/shared_preferences.dart'; // 🆕

// widgets

// widgets
import 'widgets/bottom_nav.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// hive
import 'hive/hive_init.dart';

// stores
import 'core/nutrition_store.dart';
import 'avatar/avatar_store.dart';
import 'core/app_state.dart';
import 'core/auth_service.dart'; // ☁️ Supabase swap (no-op unconfigured)
import 'core/tester_gate.dart';
import 'services/analytics_service.dart'; // 📊 Firebase-ready stub
import 'core/food_addons_config.dart'; // 🆕

// services
import 'services/notification_service.dart';
import 'services/version_service.dart';
import 'services/mood_check_scheduler.dart';
import 'services/food_recognition_service.dart'; // 🆕 ScannedItem
import 'widgets/premium_glass_card.dart'; // 🆕
import 'widgets/mood_check_overlay.dart'; // 🆕 Mood check overlay

// events manager
import 'events/event_manager.dart';
import 'core/theme_manager.dart';
import 'themes/hiw_theme.dart'; // 🆕
import 'core/food_nutrition_database.dart'; // 🆕 2.6k Food Nutrition Database

final themeManager = ThemeManager(); // Singleton

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ⚡ First frame immediately — heavy init (Hive, notifications,
  // food DB) runs behind the boot splash instead of blocking runApp,
  // which was causing 2-3s of black screen before the HIW animation.
  runApp(const HIWBootApp());
}

/// Instant boot splash: zero async deps so the first frame paints
/// immediately over the native window. Kicks off heavy init, then
/// swaps to the real app. Keeps HIW branding (no black flash).
class HIWBootApp extends StatelessWidget {
  const HIWBootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootScreen(),
    );
  }
}

class _BootScreen extends StatefulWidget {
  const _BootScreen();

  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await initHive(); // ✅ Hive init once
      NutritionStore(); // 🔥 force restore calories BEFORE UI
    } catch (_) {}
    try {
      await NotificationService().init();
    } catch (_) {}
    try {
      await VersionService.incrementVersion();
    } catch (_) {}
    try {
      await FoodNutritionDatabase()
          .init(); // 🥗 Load 2,621 food items with portions & micronutrients
    } catch (_) {}
    try {
      await ensureSupabaseAuth(); // ☁️ No-op unless dart-defines supplied
    } catch (_) {}
    try {
      await AnalyticsService().init(); // 📊 No-op until Firebase ready
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HIWApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Static brand frame — no ScreenUtil/Hive/theme deps so it paints fast.
    return const Scaffold(
      backgroundColor: Color(0xFFFBF7EF),
      body: Center(
        child: Text(
          'HIW',
          style: TextStyle(
            fontSize: 84,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Color(0xFF0B6B3A),
          ),
        ),
      ),
    );
  }
}

class HIWApp extends StatelessWidget {
  const HIWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        return ScreenUtilInit(
          designSize: const Size(393, 851),
          minTextAdapt: true,
          builder: (context, child) {
            return MaterialApp(
              title: 'HIW – Health Is Wealth',
              debugShowCheckedModeBanner: false,
              theme: themeManager.currentThemeData, // 🔥 Uses Overrides
              builder: (context, appChild) {
                // 🆕 REDUCE UI SCALE - Makes everything 15% smaller
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(
                        0.85), // 🔥 Reduced from 1.0 to fix zoom
                  ),
                  child: appChild!,
                );
              },
              home: const AppGate(), // 🔥 SINGLE ENTRY
            );
          },
        );
      },
    );
  }
}

/// 🔐 FINAL APP GATE (NO DUPLICATION, NO CONFLICT)
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    // 🆕 Brand splash first (3s, tap to skip), then the tester gate.
    if (!_splashDone) {
      return SplashScreen(
        onDone: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }
    return FutureBuilder<Widget>(
      future: _decide(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }

  Future<Widget> _decide() async {
    // 1️⃣ Tester-verified check (Activation / Dev Code only)
    final verified = await AppState.isTesterVerified();
    if (!verified) {
      return TesterCodeScreen(
        onVerified: () => setState(() {}),
      );
    }

    // 2️⃣ Mandatory login (no skip) — Supabase plugs in at the end.
    final loggedIn = await AppState.isLoggedIn();
    if (!loggedIn) {
      return AuthWelcome(
        onDone: () => setState(() {}),
      );
    }

    // 3️⃣ First-time personalization (skipped forever once done)
    final onboarded = await AppState.onboardingV1Done();
    if (!onboarded) {
      return OnboardingFlow(
        onDone: () => setState(() {}),
      );
    }

    // 3️⃣ Fully ready user
    return const MainShell();
  }
}

/// ===============================
/// MAIN APP SHELL (UNCHANGED LOGIC)
/// ===============================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1;
  bool _showUpdateLogPrompt = false;

  // -------------------------
  // STORES
  // -------------------------
  final AvatarStore _avatarStore = AvatarStore();

  double avatarHealth = 0;
  double avatarEnergy = 0;
  double avatarStamina = 0;

  // -------------------------
  // FOOD SCAN STATE
  // -------------------------
  ImageProvider? scannedFoodImage;
  String? detectedFoodLabel;
  double scannedHealthyScore = 0;
  double scannedQuantity = 1.0;
  FoodNutritionRecord? scannedNutritionRecord;
  List<ScannedItem> scannedItems = const [];

  @override
  void initState() {
    super.initState();
    _initAvatar();
    _initMoodScheduler();
    _checkUpdateLogPrompt(); // 🆕 Check if we should prompt for update log
  }

  Future<void> _checkUpdateLogPrompt() async {
    // Tester-only prompt (public release never sees it — audit §4).
    if (!(await TesterGate.isTesterMode())) return;
    final prefs = await SharedPreferences.getInstance();
    // Use a versioned key so we can prompt again for major updates if needed
    final hasSeen = prefs.getBool('has_seen_update_log_prompt_v3') ?? false;

    if (!hasSeen && mounted) {
      setState(() {
        _showUpdateLogPrompt = true;
      });
    }
  }

  Future<void> _markUpdateLogPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_update_log_prompt_v3', true);
    if (mounted) {
      setState(() {
        _showUpdateLogPrompt = false;
      });
    }
  }

  Future<void> _initAvatar() async {
    await _avatarStore.init();
    final avatar = _avatarStore.avatar;

    // 🔔 FORCE PERMISSION PROMPT ON BOOT
    await NotificationService().requestPermissions();

    setState(() {
      avatarHealth = avatar.health;
      avatarEnergy = avatar.energy;
      avatarStamina = _avatarStore.dailyStaminaPreview;
    });
  }

  // 🆕 Initialize mood check scheduler
  void _initMoodScheduler() {
    MoodCheckScheduler().init(() {
      if (mounted) {
        _showMoodCheckOverlay();
      }
    });

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final shouldShow = await MoodCheckScheduler().shouldShowMoodCheck();
      if (shouldShow && mounted) {
        _showMoodCheckOverlay();
      }
    });
  }

  // 🆕 Show mood check overlay
  void _showMoodCheckOverlay() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MoodCheckOverlay(
        onGood: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('😊 Great to hear you\'re doing well!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
        onNotGreat: () {
          Navigator.pop(context);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MoodSupportScreen(
                  initialMessage:
                      "I'm not doing so great today. Could use some support.",
                ),
              ),
            );
          }
        },
        onStruggling: () {
          Navigator.pop(context);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MoodSupportScreen(
                  initialMessage:
                      "I'm feeling really bad. I need help processing this.",
                ),
              ),
            );
          }
        },
        onDismiss: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  // -------------------------
  // SCANNER → FOOD
  // -------------------------
  void _onFoodAnalyzed({
    required ImageProvider image,
    required String label,
    required double healthyScore,
    double quantity = 1.0,
    FoodNutritionRecord? nutritionRecord,
    List<ScannedItem> items = const [],
  }) {
    // New shared result screen already saved directly — ignore ping.
    if (label == '__already_saved__') return;
    // 🔍 NORMALIZE LABEL (ML Output -> Internal Key)
    // 1. Lowercase
    // 2. Replace spaces with underscores
    String normalizedLabel = label.toLowerCase().replaceAll(' ', '_');

    // 🩹 MANUAL FIXES for misspellings or mismatches
    if (normalizedLabel == 'boild_egg') normalizedLabel = 'boiled_egg';
    if (normalizedLabel == 'noodils') normalizedLabel = 'noodles';
    if (normalizedLabel == 'mangopickle') normalizedLabel = 'mango_pickle';
    if (normalizedLabel == 'idly') normalizedLabel = 'idli';
    if (normalizedLabel == 'gulab jamun') normalizedLabel = 'gulab_jamun';

    // Debug print to help verify
    debugPrint('ML Label: $label -> Normalized: $normalizedLabel');

    setState(() {
      scannedFoodImage = image;
      detectedFoodLabel = normalizedLabel;
      scannedHealthyScore = healthyScore;
      scannedQuantity = quantity;
      scannedNutritionRecord = nutritionRecord;
      scannedItems = items;
      _currentIndex = 1;

      // 🚨 FORCE ADDONS SCREEN CHECK (only matters for legacy base-map foods;
      // foods from the nutrition database carry their own nutrition data)
      if (!foodAddons.containsKey(normalizedLabel) &&
          nutritionRecord == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Warning: No add-ons found for $label')),
        );
      }
    });
  }

  // -------------------------
  // FOOD → AVATAR
  // -------------------------
  void _updateAvatarFromFood({required int dailyRaw}) {
    _avatarStore.addDailyRaw(
      healthRaw: dailyRaw,
      energyRaw: dailyRaw,
      staminaRaw: 0,
    );

    final avatar = _avatarStore.avatar;

    setState(() {
      avatarHealth = avatar.health;
      avatarEnergy = avatar.energy;
      avatarStamina = _avatarStore.dailyStaminaPreview;

      // 🧹 CLEAR IMAGE BEFORE SWITCHING
      scannedFoodImage = null;
      detectedFoodLabel = null;
      scannedHealthyScore = 0;
      scannedQuantity = 1.0;
      scannedNutritionRecord = null;
      scannedItems = const [];

      // 🚀 SWITCH TO AVATAR TAB (Index 4)
      _currentIndex = 4;
    });
  }

  Widget _wrapWithEvent(Widget page) {
    return EventManager.wrapWithBackground(themeManager.currentThemeName, page);
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Pages are built inline inside IndexedStack so Flutter keeps them alive.
    // ScannerScreen gets isActive so camera only runs on tab 2.
    final pages = <Widget>[
      _wrapWithEvent(Padding(
          padding: EdgeInsets.only(top: 48.h), child: const ChatbotScreen())),
      _wrapWithEvent(Padding(
          padding: EdgeInsets.only(top: 48.h),
          child: FoodScreen(
            onUpdateAvatar: _updateAvatarFromFood,
            scannedImage: scannedFoodImage,
            detectedLabel: detectedFoodLabel,
            healthyScore: scannedHealthyScore,
            quantity: scannedQuantity,
            nutritionRecord: scannedNutritionRecord,
            items: scannedItems,
          ))),
      _wrapWithEvent(ScannerScreen(
        onFoodAnalyzed: _onFoodAnalyzed,
        isActive: _currentIndex == 2,
      )),
      _wrapWithEvent(Padding(
          padding: EdgeInsets.only(top: 48.h), child: const HistoryScreen())),
      _wrapWithEvent(Padding(
          padding: EdgeInsets.only(top: 48.h),
          child: AvatarScreen(
            healthPercent: avatarHealth,
            energyPercent: avatarEnergy,
            staminaPercent: avatarStamina,
          ))),
    ];

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        final hiw = HiwTheme.of(context);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_showUpdateLogPrompt) {
              await _markUpdateLogPromptSeen();
              return;
            }
            if (_currentIndex != 1) {
              setState(() => _currentIndex = 1);
              return;
            }
            // If on main tab, exit the app cleanly without crashes
            await SystemNavigator.pop();
          },
          child: Scaffold(
            extendBody: true, // 📏 ALLOWS BODY TO EXTEND BEHIND BOTTOM NAV
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
                ),

                // 🧊 PREMIUM "HIW" HEADER (hidden on scanner tab —
                // the camera has its own Scan/Text chrome there)
                if (_currentIndex != 2)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.only(top: 8.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: hiw.isMinimal
                            ? Colors.white.withValues(alpha: 0.95)
                            : (themeManager.cardColorOverride ??
                                    Colors.white)
                                .withValues(alpha: 0.12),
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            blurRadius: 10.r,
                          ),
                        ],
                      ),
                      child: Text(
                        'HIW',
                        style: TextStyle(
                          fontSize: 12.sp,
                          letterSpacing: 3.w,
                          fontWeight: FontWeight.w900,
                          color: hiw.isMinimal
                              ? hiw.inkColor
                              : (themeManager.currentThemeName == 'christmas')
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // 🆕 ONE-TIME UPDATE LOG PROMPT OVERLAY
                if (_showUpdateLogPrompt)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Center(
                          child: PremiumGlassCard(
                            padding: EdgeInsets.all(24.r),
                            borderRadius: 24.r,
                              child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_launch_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 48.sp),
                                SizedBox(height: 16.h),
                                Text(
                                  'New Updates Ready! 🚀',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: hiw.inkColor,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5.w,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Please give 5 minutes of your valuable time to see the new update logs and tester toolkit.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: hiw.mutedColor,
                                    fontSize: 13.sp,
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 24.h),

                                // Action Buttons
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.2),
                                      foregroundColor: Theme.of(context)
                                          .primaryColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r)),
                                      side: BorderSide(
                                          color: Theme.of(context)
                                              .primaryColor,
                                          width: 0.5),
                                    ),
                                    onPressed: () {
                                      _markUpdateLogPromptSeen();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const UpdateLogScreen()),
                                      );
                                    },
                                    child: const Text('Check Logs',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                TextButton(
                                  onPressed: _markUpdateLogPromptSeen,
                                  child: Text(
                                    'Got it, maybe later',
                                    style: TextStyle(
                                        color: hiw.mutedColor,
                                        fontSize: 12.sp),
                                  ),
                                ),
                              ],
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
              onTap: (i) {
                setState(() => _currentIndex = i);
              },
            ),
          ),
        );
      },
    );
  }
}
