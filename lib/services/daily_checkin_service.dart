// lib/services/daily_checkin_service.dart — Duplicate-proof local daily check-in reward service.
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/hw_wallet.dart';
import '../core/progression_engine.dart';

class DailyCheckInResult {
  final bool alreadyCheckedIn;
  final bool success;
  final int coinsEarned;
  final int xpEarned;
  final int streakDays;

  const DailyCheckInResult({
    required this.alreadyCheckedIn,
    required this.success,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.streakDays = 0,
  });
}

class DailyCheckInService {
  static final DailyCheckInService _instance = DailyCheckInService._internal();
  factory DailyCheckInService() => _instance;
  DailyCheckInService._internal();

  static const _lastCheckInDateKey = 'hiw_last_checkin_date';
  static const _checkInStreakKey = 'hiw_checkin_streak';

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<bool> hasCheckedInToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastCheckInDateKey);
    return lastDate == _todayKey();
  }

  Future<int> currentCheckInStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_checkInStreakKey) ?? 0;
  }

  /// Attempts to perform daily check-in. Duplicate calls on the same day are safely rejected.
  Future<DailyCheckInResult> performCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastDate = prefs.getString(_lastCheckInDateKey);

    if (lastDate == today) {
      final streak = prefs.getInt(_checkInStreakKey) ?? 1;
      return DailyCheckInResult(
        alreadyCheckedIn: true,
        success: false,
        streakDays: streak,
      );
    }

    // Determine streak continuity
    int streak = prefs.getInt(_checkInStreakKey) ?? 0;
    if (lastDate != null) {
      try {
        final last = DateFormat('yyyy-MM-dd').parse(lastDate);
        final difference = DateTime.now().difference(last).inDays;
        if (difference <= 1) {
          streak++;
        } else {
          streak = 1;
        }
      } catch (_) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    // Award rewards: +1 HW Coin, +20 XP
    const int coins = 1;
    const int xp = 20;

    await HWWallet().credit(coins, reason: 'Daily Check-in Reward (Day $streak)');
    await ProgressionEngine().awardXP(
      xp,
      title: 'Daily Check-in (Day $streak)',
      category: 'checkin',
    );

    await prefs.setString(_lastCheckInDateKey, today);
    await prefs.setInt(_checkInStreakKey, streak);

    return DailyCheckInResult(
      alreadyCheckedIn: false,
      success: true,
      coinsEarned: coins,
      xpEarned: xp,
      streakDays: streak,
    );
  }
}
