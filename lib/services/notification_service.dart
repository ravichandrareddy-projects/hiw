import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    debugPrint('--- NOTIFICATION SERVICE INIT START ---');
    
    // 🌍 TIMEZONE INITIALIZATION
    tz.initializeTimeZones();
    
    // Auto-detect timezone from system
    try {
      // Get UTC offset from system
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetHours = offset.inHours;
      
      debugPrint('System UTC offset: ${offset.inHours}h ${offset.inMinutes % 60}m');
      
      // Common Indian timezone
      if (offsetHours == 5 && offset.inMinutes % 60 == 30) {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        debugPrint('Timezone set to Asia/Kolkata');
      } else {
        // Use UTC for other timezones
        tz.setLocalLocation(tz.UTC);
        debugPrint('Timezone set to UTC');
      }
    } catch (e) {
      debugPrint('Error setting timezone: $e. Using UTC.');
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
    debugPrint('NotificationService Initialized ✅');
  }

  Future<void> requestPermissions() async {
    debugPrint('Explicitly Requesting Notification Permissions (v4)...');
    
    // 🔔 NORMAL NOTIFICATIONS
    final status = await Permission.notification.request();
    debugPrint('Notification Permission Status: $status');
    
    // ⏰ EXACT ALARMS (Android 12/13+)
    await checkExactAlarmPermission();
  }

  Future<void> scheduleMealNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // ✅ CORRECT APPROACH: Build TZDateTime properly
    final now = tz.TZDateTime.now(tz.local);
    
    // Create target time for today
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Subtract 15 minutes
    scheduledDate = scheduledDate.subtract(const Duration(minutes: 15));
    
    // If it's in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('🍽️ Scheduling Meal [$id]: $title');
    debugPrint('   Target time: $hour:$minute');
    debugPrint('   Notification at: ${scheduledDate.hour}:${scheduledDate.minute}');

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders_channel_v4',
          'Meal Reminders',
          channelDescription: 'Notifications for your scheduled meal times',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('✅ Meal notification scheduled');
  }

  Future<void> checkExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    debugPrint('Exact Alarm Status: $status');
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('Requesting Exact Alarm Permission...');
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> scheduleTestNotification() async {
    // ✅ CORRECT APPROACH: Use TZDateTime.now().add()
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    
    debugPrint('🧪 Scheduling Test Notification');
    debugPrint('   Current time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('   Scheduled for: $scheduledTime');
    
    await notificationsPlugin.zonedSchedule(
      999,
      '🧪 Test Notification',
      'If you see this, scheduling works!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_v5',
          'Test Notifications',
          channelDescription: 'Testing scheduled notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('✅ Test notification scheduled successfully');
  }

  Future<void> scheduleWaterReminders({
    required int startHour,
    required int startMinute,
  }) async {
    // Respect quiet hours: Only schedule between 07:00 and 21:30
    for (int i = 0; i < 14; i++) {
      int targetHour = (startHour + i) % 24;
      if (targetHour < 7 || targetHour > 21) continue; // Skip quiet hours
      
      final now = DateTime.now();
      DateTime targetDateTime = DateTime(now.year, now.month, now.day, targetHour, startMinute);

      if (targetDateTime.isBefore(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }

      await notificationsPlugin.zonedSchedule(
        200 + i,
        '💧 Time for a water break',
        'Hydration supports digestion & steady energy. Log a glass!',
        tz.TZDateTime.from(targetDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminders_channel',
            'Water Reminders',
            channelDescription: 'Hydration alerts with quiet hours respect',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    debugPrint('Scheduled daytime Water Reminders starting at $startHour:$startMinute (Local)');
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 20; i++) {
      await notificationsPlugin.cancel(200 + i);
    }
  }

  /// Evening streak protection nudge (ID 300, daily 21:00).
  Future<void> scheduleStreakNudge({int? currentStreak}) async {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (at.isBefore(now)) {
      at = at.add(const Duration(days: 1));
    }

    final body = (currentStreak != null && currentStreak > 0)
        ? 'Your $currentStreak-day HIW streak is waiting for you! Log today to keep it alive.'
        : 'Your HIW streak is waiting for you. Log your meals to build healthy consistency.';

    await notificationsPlugin.zonedSchedule(
      300,
      '🔥 Protect your streak',
      body,
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak Reminders',
          channelDescription: 'Evening streak protection nudge',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelStreakNudge() async {
    await notificationsPlugin.cancel(300);
  }

  /// Evening nutrition & macro progress checkpoint (ID 400, daily 18:30)
  Future<void> scheduleNutritionCheckpoint({int hour = 18, int minute = 30}) async {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) {
      at = at.add(const Duration(days: 1));
    }

    await notificationsPlugin.zonedSchedule(
      400,
      '🥗 Nutrition Checkpoint',
      "You're getting close to today's protein & calorie target! Check your daily balance.",
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nutrition_channel',
          'Nutrition Reminders',
          channelDescription: 'Daily macro and nutrient checkpoints',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNutritionCheckpoint() async {
    await notificationsPlugin.cancel(400);
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'immediate_notifications_channel',
      'Immediate Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }
}
