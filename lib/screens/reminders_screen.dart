// lib/screens/reminders_screen.dart — Dynamic visual reminder cards with centralized theme tokens.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../core/habit_engine.dart';
import '../services/notification_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/reminder_animated_badges.dart';
import 'notification_help_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final Map<String, TimeOfDay> _times = {
    'water': const TimeOfDay(hour: 7, minute: 0),
    'breakfast': const TimeOfDay(hour: 8, minute: 0),
    'lunch': const TimeOfDay(hour: 13, minute: 0),
    'snack': const TimeOfDay(hour: 17, minute: 0),
    'dinner': const TimeOfDay(hour: 20, minute: 0),
    'nutrition': const TimeOfDay(hour: 18, minute: 30),
    'streak': const TimeOfDay(hour: 21, minute: 0),
  };

  final Map<String, bool> _enabled = {
    'water': false,
    'breakfast': false,
    'lunch': false,
    'snack': false,
    'dinner': false,
    'nutrition': false,
    'streak': false,
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    NotificationService().requestPermissions();
    NotificationService().checkExactAlarmPermission();
  }

  Future<void> _loadSettings() async {
    for (String key in _times.keys) {
      final timeStr = await AppState.getReminderTime(key);
      if (timeStr != null) {
        final parts = timeStr.split(':');
        _times[key] = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      _enabled[key] = await AppState.isReminderEnabled(key);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleReminder(String key, bool value) async {
    setState(() => _enabled[key] = value);
    await AppState.setReminderEnabled(key, value);
    if (value) {
      _schedule(key);
    } else {
      if (key == 'water') {
        NotificationService().cancelWaterReminders();
      } else if (key == 'nutrition') {
        NotificationService().cancelNutritionCheckpoint();
      } else if (key == 'streak') {
        NotificationService().cancelStreakNudge();
      } else {
        NotificationService().cancelNotification(_getId(key));
      }
    }
  }

  int _getId(String key) {
    switch (key) {
      case 'breakfast':
        return 101;
      case 'lunch':
        return 102;
      case 'dinner':
        return 103;
      case 'snack':
        return 104;
      case 'streak':
        return 300;
      case 'nutrition':
        return 400;
      default:
        return 0;
    }
  }

  Future<void> _pickTime(String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[key]!,
      builder: (context, child) {
        final currentTheme = Theme.of(context);
        return Theme(
          data: currentTheme.copyWith(
            colorScheme: currentTheme.colorScheme.copyWith(
              surface: currentTheme.scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _times[key] = picked);
      await AppState.setReminderTime(key, '${picked.hour}:${picked.minute}');
      if (_enabled[key]!) {
        _schedule(key);
      }
    }
  }

  void _schedule(String key) {
    final time = _times[key]!;
    if (key == 'water') {
      NotificationService().scheduleWaterReminders(
        startHour: time.hour,
        startMinute: time.minute,
      );
    } else if (key == 'nutrition') {
      NotificationService().scheduleNutritionCheckpoint(
        hour: time.hour,
        minute: time.minute,
      );
    } else if (key == 'streak') {
      NotificationService().scheduleStreakNudge(
        currentStreak: HabitEngine().streakDays(),
      );
    } else {
      NotificationService().scheduleMealNotification(
        id: _getId(key),
        title: '🍽️ Time for ${key.toUpperCase()}!',
        body: '${key.toUpperCase()} starts in 15 minutes. Stay healthy!',
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reminders & Alerts',
          style: TextStyle(
            color: t.inkColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.inkColor, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                children: [
                  // 💧 HYDRATION SECTION
                  _sectionHeader(t, '💧 Hydration'),
                  _reminderTile(
                    t,
                    'water',
                    'Hourly Water Alert',
                    'Starts daytime at:',
                    WaterRippleVisual(
                      active: _enabled['water'] ?? false,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 🍽️ MEALS SECTION
                  _sectionHeader(t, '🍽️ Meals'),
                  _reminderTile(
                    t,
                    'breakfast',
                    'Breakfast Alert',
                    'Meal time:',
                    FoodSteamVisual(
                      active: _enabled['breakfast'] ?? false,
                      color: t.accentColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _reminderTile(
                    t,
                    'lunch',
                    'Lunch Alert',
                    'Meal time:',
                    FoodSteamVisual(
                      active: _enabled['lunch'] ?? false,
                      color: t.accentColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _reminderTile(
                    t,
                    'snack',
                    'Evening Snack',
                    'Meal time:',
                    FoodSteamVisual(
                      active: _enabled['snack'] ?? false,
                      color: t.accentColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _reminderTile(
                    t,
                    'dinner',
                    'Dinner Alert',
                    'Meal time:',
                    FoodSteamVisual(
                      active: _enabled['dinner'] ?? false,
                      color: t.accentColor,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 🥗 NUTRITION & HABITS SECTION
                  _sectionHeader(t, '🥗 Habits & Progression'),
                  _reminderTile(
                    t,
                    'nutrition',
                    'Nutrition Checkpoint',
                    'Checkpoint at:',
                    NutritionLeafVisual(
                      active: _enabled['nutrition'] ?? false,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _reminderTile(
                    t,
                    'streak',
                    'Streak Protection',
                    'Nudge time:',
                    StreakFlameVisual(
                      active: _enabled['streak'] ?? false,
                      color: const Color(0xFFEF4444),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Information note
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: t.cardBackground,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: t.cardStroke),
                    ),
                    child: Text(
                      'Quiet hours respected between 10:00 PM and 7:00 AM.\nMeal alerts arrive 15 minutes ahead to give you time to prepare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.mutedColor,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Diagnostics / Help
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          NotificationService().scheduleTestNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification scheduled for 10 seconds from now! 🕒'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_active_outlined, size: 15),
                        label: const Text('Test Notification (10s)'),
                        style: TextButton.styleFrom(
                          foregroundColor: t.mutedColor,
                          textStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationHelpScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.help_outline_rounded, size: 15),
                        label: const Text('Help & Permissions'),
                        style: TextButton.styleFrom(
                          foregroundColor: t.mutedColor,
                          textStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(HiwTheme t, String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: t.accentColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _reminderTile(
    HiwTheme t,
    String key,
    String label,
    String info,
    Widget visual,
  ) {
    final time = _times[key] ?? const TimeOfDay(hour: 7, minute: 0);
    final dt = DateTime(2026, 1, 1, time.hour, time.minute);
    final timeLabel = DateFormat.jm().format(dt);
    final isEnabled = _enabled[key] ?? false;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isEnabled ? t.accentColor.withValues(alpha: 0.35) : t.cardStroke,
        ),
      ),
      child: Row(
        children: [
          visual,
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Text(
                      info,
                      style: TextStyle(
                        color: t.mutedColor,
                        fontSize: 11.5.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () => _pickTime(key),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: t.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            color: t.accentColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            activeThumbColor: t.accentColor,
            onChanged: (v) => _toggleReminder(key, v),
          ),
        ],
      ),
    );
  }
}
