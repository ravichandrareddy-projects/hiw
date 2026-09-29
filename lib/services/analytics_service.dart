// lib/services/analytics_service.dart
// Counts-only analytics, Firebase-mirrored when available.
// Works with NO google-services.json: Firebase init is guarded and
// local SharedPreferences counts always run. Opt-out blocks both.
// No PII, no food names, no chat text — counts only.
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _i = AnalyticsService._internal();
  factory AnalyticsService() => _i;
  AnalyticsService._internal();

  static const _optOutKey = 'analytics_opt_out';

  bool _firebaseReady = false;

  /// Guarded Firebase init. Safe without google-services.json
  /// (stays local-only). Called from HIWBootApp._boot.
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
    }
  }

  bool get firebaseReady => _firebaseReady;

  /// Allowlist — counts only. Add new events here, never free-form.
  static const allowed = {
    'scan_success',
    'scan_quota_hit',
    'barcode_success',
    'barcode_miss',
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

  /// Local count + debug log + Firebase mirror (when ready).
  /// Same call sites regardless of backend state — zero UI churn.
  Future<void> log(String event) async {
    if (!allowed.contains(event)) return;
    if (await isOptedOut()) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final k = 'analytics_count_$event';
      await prefs.setInt(k, (prefs.getInt(k) ?? 0) + 1);
    } catch (_) {}
    if (_firebaseReady) {
      try {
        await FirebaseAnalytics.instance.logEvent(name: event);
      } catch (_) {}
    }
    debugPrint('HIW ANALYTICS: $event');
  }

  Future<int> count(String event) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('analytics_count_$event') ?? 0;
  }
}
