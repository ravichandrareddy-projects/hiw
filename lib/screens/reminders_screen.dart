import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_state.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';
import 'notification_help_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final Map<String, TimeOfDay> _times = {
    'breakfast': const TimeOfDay(hour: 8, minute: 0),
    'lunch': const TimeOfDay(hour: 13, minute: 0),
    'dinner': const TimeOfDay(hour: 20, minute: 0),
    'snack': const TimeOfDay(hour: 17, minute: 0),
    'water': const TimeOfDay(hour: 6, minute: 0),
  };

  final Map<String, bool> _enabled = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'snack': false,
    'water': false,
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    NotificationService().requestPermissions();
    NotificationService().checkExactAlarmPermission(); // 🚨 New Check
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
    setState(() => _loading = false);
  }

  Future<void> _toggleReminder(String key, bool value) async {
    setState(() => _enabled[key] = value);
    await AppState.setReminderEnabled(key, value);
    if (value) {
      _schedule(key);
    } else {
      if (key == 'water') {
        NotificationService().cancelWaterReminders();
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
              surface: currentTheme.brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
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
    } else {
      NotificationService().scheduleMealNotification(
        id: _getId(key),
        title: '🍽️ Time for ${key.toUpperCase()}!',
        body: 'Your meal starts in 15 minutes. Stay healthy!',
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12.h),
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                    child: Text(
                      '💧 Hydration',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                  _reminderTile('water', 'Hourly Water Alert'),
                  SizedBox(height: 32.h),
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                    child: Text(
                      '🍽️ Meals',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                  _reminderTile('breakfast', 'Breakfast'),
                  SizedBox(height: 12.h),
                  _reminderTile('lunch', 'Lunch'),
                  SizedBox(height: 12.h),
                  _reminderTile('snack', 'Snack'),
                  SizedBox(height: 12.h),
                  _reminderTile('dinner', 'Dinner'),
                  SizedBox(height: 48.h),
                  Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        'Meal alerts arrive 15 mins before time.\nWater alerts repeat hourly for 16 instances.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        NotificationService().scheduleTestNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Test scheduled for 10 seconds from now! 🕒')),
                        );
                      },
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text('Test Scheduled Notification (10s)'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.orangeAccent.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationHelpScreen()),
                        );
                      },
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text('Notifications Not Working?'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.redAccent.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _reminderTile(String key, String label) {
    // Determine info text
    String info = '';
    if (key == 'water') {
      info = 'Starts daily at:';
    } else {
      info = 'Meal time:';
    }

    final time = _times[key] ?? const TimeOfDay(hour: 6, minute: 0);
    final dt = DateTime(2024, 1, 1, time.hour, time.minute);
    final timeLabel = DateFormat.jm().format(dt);

    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      info,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12.sp),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () => _pickTime(key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled[key] ?? false,
            activeThumbColor: Colors.tealAccent,
            onChanged: (v) => _toggleReminder(key, v),
          ),
        ],
      ),
    );
  }
}
