// lib/services/analytics_service.dart
// Counts-only analytics, Firebase-ready but fully offline-safe.
// No google-services.json required: events are counted locally
// (SharedPreferences) until Firebase plugs in at the end.
// No PII, no food names, no chat text — counts only.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _i = AnalyticsService._internal();
  factory AnalyticsService() => _i;
  AnalyticsService._internal();

  static const _optOutKey = 'analytics_opt_out';

  /// Allowlist — counts only. Add new events here, never free-form.
  static const allowed = {
    'scan_success',
    'scan_quota_hit',
    'chat_sent',
    'chat_quota_hit',
    'paywall_open',
    'trial_start',
    'coupon_redeem',
    'fast_start',
    'mealplan_log',
    'trends_export',
  };

  Future<bool> isOptedOut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_optOutKey) ?? false;
  }

  Future<void> setOptOut(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optOutKey, v);
  }

  /// Local count + debug log. Firebase.logEvent plugs in here later
  /// (same call sites, zero UI churn).
  Future<void> log(String event) async {
    if (!allowed.contains(event)) return;
    if (await isOptedOut()) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final k = 'analytics_count_$event';
      await prefs.setInt(k, (prefs.getInt(k) ?? 0) + 1);
    } catch (_) {}
    debugPrint('HIW ANALYTICS: $event');
  }

  Future<int> count(String event) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('analytics_count_$event') ?? 0;
  }

  // TODO(firebase): when android/app/google-services.json lands:
  // 1. add firebase_core + firebase_analytics to pubspec,
  // 2. Firebase.initializeApp() in HIWBootApp._boot,
  // 3. mirror log() to FirebaseAnalytics.instance.logEvent(name: event).
}
