import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/nutrition_store.dart';
import 'reminders_screen.dart';
import 'profile_edit_screen.dart';
import 'paywall_screen.dart';
import 'fasting_screen.dart';
import 'mealplan_screen.dart';
import 'trends_screen.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../core/subscription/coupon_service.dart';
import '../core/tester_gate.dart';
import '../services/analytics_service.dart';
import '../main.dart';
import '../events/event_manager.dart';
import '../core/theme_manager.dart';
import 'mood_support_screen.dart'; // 🆕 Mood support chatbot
import '../widgets/mood_check_overlay.dart'; // 🆕 Mood check overlay
import '../widgets/customize_theme_sheet.dart'; // 🆕 Customize palette
import '../themes/hiw_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'User';
  int _targetCalories = 2000;
  String? _testerCode;
  bool _isLoading = true;
  int _splashSeconds = 5; // TEMPORARY intro-timing test value

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final results = await Future.wait([
      AppState.getUsername(),
      AppState.getLastVerifiedCode(),
    ]);
    final splash = await AppState.getSplashSeconds();

    if (mounted) {
      setState(() {
        _username = (results[0] as String?) ?? 'User';
        _testerCode = results[1] as String?;
        _targetCalories = NutritionStore().dailyTargetCalories;
        _splashSeconds = splash;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: EventManager.wrapWithBackground(
            ThemeManager().currentThemeName,
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(24.0.r),
                      child: Column(
                        children: [
                          // 👤 AVATAR ICON
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.2),
                            child: Icon(Icons.person,
                                size: 50,
                                color: Theme.of(context).primaryColor),
                          ),
                          SizedBox(height: 16.h),

                          // 📛 USERNAME
                          Text(
                            _username,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Daily Goal: $_targetCalories kcal',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // 🧪 TESTER CODE BADGE
                          if (_testerCode != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color:
                                    Colors.blueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'Tester Code: $_testerCode',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                          // 🎨 FESTIVE VIBE SELECTOR
                          _buildTile(
                            context,
                            icon: Icons.palette,
                            color: Theme.of(context).primaryColor,
                            title: 'Festive Vibe',
                            subtitle:
                                ThemeManager().currentThemeName.toUpperCase(),
                            isDark: isDark,
                            onTap: () => _showThemePicker(context),
                          ),

                          SizedBox(height: 12.h),

                          // 🖌️ CUSTOMIZE COLORS (own palette, Plain untouched)
                          _buildTile(
                            context,
                            icon: Icons.color_lens_rounded,
                            color: Colors.purpleAccent,
                            title: 'Customize Colors',
                            subtitle: 'Build your own palette',
                            isDark: isDark,
                            onTap: () async {
                              await ThemeManager()
                                  .setThemeName('customize');
                              if (context.mounted) {
                                await showCustomizeSheet(context);
                                setState(() {});
                              }
                            },
                          ),

                          // ⏱️ INTRO TIMING (tester-only test setting 1-10s)
                          FutureBuilder<bool>(
                            future: TesterGate.isTesterMode(),
                            builder: (ctx, snap) {
                              if (snap.data != true) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  SizedBox(height: 12.h),
                                  _buildTile(
                                    context,
                                    icon: Icons.timer_outlined,
                                    color: Colors.tealAccent,
                                    title: 'Intro Timing (test)',
                                    subtitle:
                                        '$_splashSeconds s — tap to try 1-10 s',
                                    isDark: isDark,
                                    onTap: () =>
                                        _showIntroTiming(context),
                                  ),
                                ],
                              );
                            },
                          ),

                          SizedBox(height: 12.h),

                          // 🌱 HEALTH PROFILE TILE (onboarding values, editable)
                          _buildTile(
                            context,
                            icon: Icons.person_outline_rounded,
                            color: Colors.greenAccent,
                            title: 'My Health Profile',
                            subtitle:
                                'Goals, body, diet, daily targets',
                            isDark: isDark,
                            onTap: () async {
                              final changed =
                                  await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileEditScreen()),
                              );
                              if (changed == true) {
                                _loadUserData();
                              }
                            },
                          ),

                          SizedBox(height: 12.h),

                          // ⭐ HIW PRO TILE
                          _buildTile(
                            context,
                            icon: Icons.workspace_premium_rounded,
                            color: Colors.amberAccent,
                            title: 'HIW Pro',
                            subtitle: 'Plans, fasting, trends & more',
                            isDark: isDark,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PaywallScreen()),
                              );
                              _loadUserData();
                            },
                          ),

                          SizedBox(height: 12.h),

                          // 🎟️ REDEEM PRO CODE (coupons)
                          _buildTile(
                            context,
                            icon: Icons.confirmation_number_outlined,
                            color: Colors.pinkAccent,
                            title: 'Redeem Pro Code',
                            subtitle: 'Have a coupon? Unlock Pro',
                            isDark: isDark,
                            onTap: () => _showRedeemDialog(context),
                          ),

                          SizedBox(height: 12.h),

                          // ⏳ FASTING TILE (Pro)
                          _buildTile(
                            context,
                            icon: Icons.timer_outlined,
                            color: Colors.deepOrangeAccent,
                            title: 'Fasting Timer',
                            subtitle: 'Windows, rings & history',
                            isDark: isDark,
                            onTap: () =>
                                _openProFeature(context,
                                    Feature.fasting,
                                    const FastingScreen()),
                          ),

                          SizedBox(height: 12.h),

                          // 🍽️ MEAL PLANS TILE (Pro)
                          _buildTile(
                            context,
                            icon: Icons.restaurant_menu_rounded,
                            color: Colors.lightGreenAccent,
                            title: 'Meal Plans',
                            subtitle:
                                'Deterministic day plans from your targets',
                            isDark: isDark,
                            onTap: () =>
                                _openProFeature(context,
                                    Feature.mealPlans,
                                    const MealPlanScreen()),
                          ),

                          SizedBox(height: 12.h),

                          // 📈 TRENDS TILE (Pro)
                          _buildTile(
                            context,
                            icon: Icons.show_chart_rounded,
                            color: Colors.cyanAccent,
                            title: 'Trends & Gaps',
                            subtitle: '30/90/365 days + export',
                            isDark: isDark,
                            onTap: () =>
                                _openProFeature(context,
                                    Feature.trends,
                                    const TrendsScreen()),
                          ),

                          SizedBox(height: 12.h),

                          // 🔁 RESET PERSONALIZATION TILE
                          _buildTile(
                            context,
                            icon: Icons.restart_alt_rounded,
                            color: Colors.orangeAccent,
                            title: 'Reset Personalization',
                            subtitle:
                                'Restart the onboarding flow',
                            isDark: isDark,
                            onTap: () =>
                                _confirmReset(context),
                          ),

                          SizedBox(height: 12.h),

                          // 🔔 REMINDERS TILE
                          _buildTile(
                            context,
                            icon: Icons.notifications_active,
                            color: Colors.tealAccent,
                            title: 'Meal Reminders',
                            subtitle: 'Get notified before meal time',
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RemindersScreen()),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // 📊 ANALYTICS & PRIVACY TILE (counts-only, opt-out)
                          _buildTile(
                            context,
                            icon: Icons.privacy_tip_outlined,
                            color: Colors.grey,
                            title: 'Analytics & Privacy',
                            subtitle:
                                'Counts-only usage stats • Firebase plugs in later',
                            isDark: isDark,
                            onTap: () => _showPrivacyDialog(context),
                          ),

                          SizedBox(height: 12.h),

                          // 💙 TEST MOOD CHECK BUTTON (tester-only — audit §4)
                          FutureBuilder<bool>(
                            future: TesterGate.isTesterMode(),
                            builder: (ctx, snap) {
                              if (snap.data != true) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  _buildTile(
                                    context,
                                    icon: Icons.psychology,
                                    color: Colors.lightBlueAccent,
                                    title: 'Test Mood Check',
                                    subtitle:
                                        'Trigger mood check overlay (for testing)',
                                    isDark: isDark,
                                    onTap: () =>
                                        _showMoodCheckOverlay(context),
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                              );
                            },
                          ),

                          SizedBox(height: 32.h),

                          // 🚪 LOGOUT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.redAccent.withValues(alpha: 0.9),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                elevation: 4,
                                shadowColor:
                                    Colors.redAccent.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              onPressed: () => _handleLogout(context),
                              icon: const Icon(Icons.logout),
                              label: Text(
                                'LOGOUT',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24.h),
                          Text(
                            'HIW v0.0.03',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.3),
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 100.h), // 📏 SPACE FOR NAV
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(16.r),
      child: ListTile(
        leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.6),
              fontSize: 12.sp)),
      trailing: Icon(Icons.arrow_forward_ios,
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
          size: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      tileColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    ),
  );
  }

  // 🆕 Show mood check overlay for testing
  void _showMoodCheckOverlay(BuildContext context) {
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
                      "I'm not doing so great. Checking in from my profile.",
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
                      "I'm feeling really bad. I need some support right now.",
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

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final t = HiwTheme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            t.isMinimal ? Colors.white : const Color(0xFF1E293B),
        title: Text('Logout', style: TextStyle(color: t.inkColor)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: t.mutedColor)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: t.mutedColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.heavyImpact();
    await AppState.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppGate()),
      (_) => false,
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final t = HiwTheme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            t.isMinimal ? Colors.white : const Color(0xFF1E293B),
        title:
            Text('Reset Personalization', style: TextStyle(color: t.inkColor)),
        content: Text(
            'This restarts the onboarding flow so HIW can learn you again. Your food logs stay.',
            style: TextStyle(color: t.mutedColor)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: t.mutedColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
            child: const Text('Reset',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AppState.resetPersonalization();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppGate()),
      (_) => false,
    );
  }

  Future<void> _showPrivacyDialog(BuildContext context) async {
    final t = HiwTheme.of(context);
    var optedOut = await AnalyticsService().isOptedOut();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          backgroundColor:
              t.isMinimal ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r)),
          title:
              Text('Analytics & Privacy', style: TextStyle(color: t.inkColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HIW counts feature usage only (scans, chats, upgrades). No food names, no chat text, no PII. Firebase Analytics plugs in when google-services.json lands.',
                style: TextStyle(color: t.mutedColor, fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Text('Opt out',
                        style: TextStyle(color: t.inkColor)),
                  ),
                  Switch(
                    value: optedOut,
                    onChanged: (v) async {
                      await AnalyticsService().setOptOut(v);
                      setSheet(() => optedOut = v);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRedeemDialog(BuildContext context) async {
    final t = HiwTheme.of(context);
    final ctrl = TextEditingController();
    var busy = false;
    String? error;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          backgroundColor:
              t.isMinimal ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r)),
          title: Text('Redeem Pro Code',
              style: TextStyle(color: t.inkColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: t.inkColor),
                decoration: InputDecoration(
                  hintText: 'HIW-PRO-XXXX-XXX',
                  hintStyle: TextStyle(color: t.mutedColor),
                  errorText: error,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: t.cardStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        BorderSide(color: Theme.of(ctx).primaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: t.mutedColor)),
            ),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setSheet(() {
                        busy = true;
                        error = null;
                      });
                      final out =
                          await CouponService.redeem(ctrl.text);
                      if (!ctx.mounted) return;
                      if (out.result == CouponResult.ok) {
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          AnalyticsService().log('coupon_redeem');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(out.message)),
                          );
                          _loadUserData();
                        }
                      } else {
                        setSheet(() {
                          busy = false;
                          error = out.message;
                        });
                      }
                    },
              child: Text(busy ? 'Checking...' : 'Redeem'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _openProFeature(
      BuildContext context, Feature feature, Widget page) async {
    if (await EntitlementStore.canUse(feature)) {
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
            feature: 'This lives in HIW Pro. Free stays generous.'),
      ),
    );
    if (mounted) setState(() {});
  }

  void _showThemePicker(BuildContext context) {
    final t = HiwTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor:
          t.isMinimal ? Colors.white : const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Festive Vibe',
                  style: TextStyle(
                      color: t.inkColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 24.h),
              _themeOption(context, 'default', 'Default HIW'),
              _themeOption(context, 'plain', 'Plain Theme 🌿'),
              _themeOption(context, 'greezy', 'Greezy 🌾'),
              _themeOption(context, 'customize', 'Customize 🎨'),
              _themeOption(context, 'sankranti', 'Sankranti 🪁'),
              _themeOption(context, 'christmas', 'Christmas 🎄'),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  // ⏱️ TEMPORARY: intro timing tester (1-10s). Delete after finalizing.
  Future<void> _showIntroTiming(BuildContext context) async {
    final t = HiwTheme.of(context);
    int value = _splashSeconds;
    await showModalBottomSheet(
      context: context,
      backgroundColor: t.isMinimal ? Colors.white : const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Intro Timing (test)',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Restart the app to feel $value second${value == 1 ? '' : 's'}.',
                style: TextStyle(color: t.mutedColor, fontSize: 13.sp),
              ),
              Slider(
                value: value.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$value s',
                activeColor: Theme.of(ctx).primaryColor,
                onChanged: (v) => setSheet(() => value = v.round()),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AppState.setSplashSeconds(value);
                    if (mounted) setState(() => _splashSeconds = value);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, String key, String label) {
    final isSelected = ThemeManager().currentThemeName == key;
    final t = HiwTheme.of(context);
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : t.mutedColor)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
      onTap: () async {
        await ThemeManager().setThemeName(key);
        if (!context.mounted) return;
        Navigator.pop(context);
        // Jump straight into the palette editor for Customize.
        if (key == 'customize') await showCustomizeSheet(context);
        setState(() {}); // Refresh local UI
      },
    );
  }
}
