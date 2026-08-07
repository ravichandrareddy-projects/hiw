import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔑 SystemNavigator

// theme
import 'themes/app_theme.dart';

// screens
import 'screens/chatbot_screen.dart';
import 'screens/food_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/history_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/tester_code_screen.dart';
import 'screens/mood_support_screen.dart'; 
import 'screens/update_log_screen.dart'; // 🆕
import 'package:shared_preferences/shared_preferences.dart'; // 🆕

// widgets

// widgets
import 'widgets/bottom_nav.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🎄 events
import 'events/christmas/christmas_background.dart';
import 'events/christmas/christmas_config.dart';

// hive
import 'hive/hive_init.dart';

// stores
import 'core/nutrition_store.dart';
import 'avatar/avatar_store.dart';
import 'core/app_state.dart';
import 'core/food_addons_config.dart'; // 🆕

// services
import 'services/notification_service.dart';
import 'services/version_service.dart';
import 'services/mood_check_scheduler.dart'; 
import 'widgets/premium_glass_card.dart'; // 🆕
import 'widgets/mood_check_overlay.dart'; // 🆕 Mood check overlay

// events manager
import 'events/event_manager.dart';
import 'core/theme_manager.dart'; // 🆕

final themeManager = ThemeManager(); // Singleton

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive(); // ✅ Hive init once
  NutritionStore(); // 🔥 force restore calories BEFORE UI
  await NotificationService().init();
  await VersionService.incrementVersion();
  runApp(const HIWApp());
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
                    textScaleFactor: 0.85, // 🔥 Reduced from 1.0 to fix zoom
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
  @override
  Widget build(BuildContext context) {
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
    final nutritionStore = NutritionStore();

    // 1️⃣ Tester-verified check (Activation / Dev Code only)
    final verified = await AppState.isTesterVerified();
    if (!verified) {
      return TesterCodeScreen(
        onVerified: () => setState(() {}),
      );
    }

    // 2️⃣ Fully ready user
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

  @override
  void initState() {
    super.initState();
    _initAvatar();
    _initMoodScheduler(); 
    _checkUpdateLogPrompt(); // 🆕 Check if we should prompt for update log
  }

  Future<void> _checkUpdateLogPrompt() async {
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
    // Note: The scheduler callback requires BuildContext, but we can't pass it directly
    // Instead, we'll use a periodic check in the widget lifecycle
    // The scheduler will mark when it's time, and we check in didChangeDependencies
    MoodCheckScheduler().init((context) {
      // This callback won't be used since we don't have context here
      // We'll check shouldShowMoodCheck() periodically instead
    });
    
    // Check if we should show mood check on startup
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
                  initialMessage: "I'm not doing so great today. Could use some support.",
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
                  initialMessage: "I'm feeling really bad. I need help processing this.",
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
  }) {
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
      _currentIndex = 1;

      // 🚨 FORCE ADDONS SCREEN CHECK
      if (!foodAddons.containsKey(normalizedLabel)) {
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
      _wrapWithEvent(Padding(padding: EdgeInsets.only(top: 48.h), child: const ChatbotScreen())),
      _wrapWithEvent(Padding(padding: EdgeInsets.only(top: 48.h), child: FoodScreen(
        onUpdateAvatar: _updateAvatarFromFood,
        scannedImage: scannedFoodImage,
        detectedLabel: detectedFoodLabel,
        healthyScore: scannedHealthyScore,
      ))),
      _wrapWithEvent(ScannerScreen(
        onFoodAnalyzed: _onFoodAnalyzed,
        isActive: _currentIndex == 2,
      )),
      _wrapWithEvent(Padding(padding: EdgeInsets.only(top: 48.h), child: const HistoryScreen())),
      _wrapWithEvent(Padding(padding: EdgeInsets.only(top: 48.h), child: AvatarScreen(
        healthPercent: avatarHealth,
        energyPercent: avatarEnergy,
        staminaPercent: avatarStamina,
      ))),
    ];


    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
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

          // 🧊 PREMIUM "HIW" HEADER
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: (themeManager.currentThemeName == 'sankranti' || themeManager.currentThemeName == 'default')
                      ? (themeManager.cardColorOverride ?? Colors.white).withOpacity(themeManager.opacityOverride + 0.1)
                      : (themeManager.cardColorOverride ?? Colors.white).withOpacity(0.12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.35),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                    color: (themeManager.currentThemeName == 'christmas') 
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
                  color: Colors.black.withOpacity(0.4),
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Center(
                    child: PremiumGlassCard(
                      padding: EdgeInsets.all(24.r),
                      borderRadius: 24.r,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch_rounded, color: Colors.tealAccent, size: 48.sp),
                          SizedBox(height: 16.h),
                          Text(
                            'New Updates Ready! 🚀',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
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
                              color: Colors.white.withOpacity(0.7),
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
                                backgroundColor: Colors.tealAccent.withOpacity(0.2),
                                foregroundColor: Colors.tealAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                side: BorderSide(color: Colors.tealAccent, width: 0.5),
                              ),
                              onPressed: () {
                                _markUpdateLogPromptSeen();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const UpdateLogScreen()),
                                );
                              },
                              child: Text('Check Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextButton(
                            onPressed: _markUpdateLogPromptSeen,
                            child: Text(
                              'Got it, maybe later',
                              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
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
