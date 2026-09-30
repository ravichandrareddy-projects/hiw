import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schedules proactive mood checks 3-4 times per day
/// Triggers at optimal times: Morning, Afternoon, Evening, (Optional Night)
class MoodCheckScheduler {
  static final MoodCheckScheduler _instance = MoodCheckScheduler._internal();
  factory MoodCheckScheduler() => _instance;
  MoodCheckScheduler._internal();

  Timer? _timer;
  VoidCallback? _onMoodCheckTriggered;

  // Mood check time windows (hour of day)
  static const List<int> _checkHours = [
    9,  // Morning (9-10 AM)
    14, // Afternoon (2-3 PM)
    18, // Evening (6-7 PM)
    21, // Night (9-10 PM) - Optional
  ];

  /// Initialize the scheduler with callback
  void init([VoidCallback? onMoodCheckTriggered]) {
    _onMoodCheckTriggered = onMoodCheckTriggered;
    _startScheduler();
  }

  void _startScheduler() {
    // Check every minute if it's time for a mood check
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkIfTimeForMoodCheck();
    });
  }

  Future<void> _checkIfTimeForMoodCheck() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    // Get last mood check date
    final lastCheckDate = prefs.getString('last_mood_check_date') ?? '';
    final today = now.toIso8601String().split('T')[0];
    
    // Get today's completed checks
    final completedChecks = prefs.getStringList('today_mood_checks') ?? [];
    
    // Reset if new day
    if (lastCheckDate != today) {
      await prefs.setString('last_mood_check_date', today);
      await prefs.setStringList('today_mood_checks', []);
      completedChecks.clear();
    }
    
    // Check if current hour matches any check window
    final currentHour = now.hour;
    for (final checkHour in _checkHours) {
      // Check if we're in the time window (within 1 hour)
      if (currentHour == checkHour && !completedChecks.contains(checkHour.toString())) {
        // Trigger mood check
        _triggerMoodCheck(checkHour);
        break;
      }
    }
  }

  Future<void> _triggerMoodCheck(int checkHour) async {
    final prefs = await SharedPreferences.getInstance();
    final completedChecks = prefs.getStringList('today_mood_checks') ?? [];
    
    // Mark this hour as checked
    completedChecks.add(checkHour.toString());
    await prefs.setStringList('today_mood_checks', completedChecks);
    
    // Trigger callback if set
    debugPrint('🕐 Mood check triggered for hour: $checkHour');
    _onMoodCheckTriggered?.call();
  }

  /// Manually trigger a mood check (for testing)
  Future<void> triggerManualCheck() async {
    final now = DateTime.now();
    await _triggerMoodCheck(now.hour);
  }

  /// Check if it's time for a mood check right now
  Future<bool> shouldShowMoodCheck() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    final lastCheckDate = prefs.getString('last_mood_check_date') ?? '';
    final today = now.toIso8601String().split('T')[0];
    final completedChecks = prefs.getStringList('today_mood_checks') ?? [];
    
    // Reset if new day
    if (lastCheckDate != today) {
      return true; // Show first check of the day
    }
    
    // Check if current hour matches any unchecked window
    final currentHour = now.hour;
    for (final checkHour in _checkHours) {
      if (currentHour == checkHour && !completedChecks.contains(checkHour.toString())) {
        return true;
      }
    }
    
    return false;
  }

  void dispose() {
    _timer?.cancel();
  }
}
