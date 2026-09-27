import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/nutrition_store.dart';
import 'reminders_screen.dart';
import '../services/notification_service.dart';
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
  bool _isVerified = false;
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
      AppState.isTesterVerified(),
    ]);
    final splash = await AppState.getSplashSeconds();

    if (mounted) {
      setState(() {
        _username = (results[0] as String?) ?? 'User';
        _testerCode = results[1] as String?;
        _isVerified = (results[2] as bool?) ?? false;
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

                          SizedBox(height: 12.h),

                          // ⏱️ INTRO TIMING (TEMPORARY test setting 1-10s)
                          _buildTile(
                            context,
                            icon: Icons.timer_outlined,
                            color: Colors.tealAccent,
                            title: 'Intro Timing (test)',
                            subtitle:
                                '$_splashSeconds s — tap to try 1-10 s',
                            isDark: isDark,
                            onTap: () => _showIntroTiming(context),
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

                          // 💙 TEST MOOD CHECK BUTTON
                          _buildTile(
                            context,
                            icon: Icons.psychology,
                            color: Colors.lightBlueAccent,
                            title: 'Test Mood Check',
                            subtitle:
                                'Trigger mood check overlay (for testing)',
                            isDark: isDark,
                            onTap: () => _showMoodCheckOverlay(context),
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
