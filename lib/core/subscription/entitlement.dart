// lib/core/subscription/entitlement.dart
// Who is Pro: mock/coupon today, Play Billing + server verify later.
// Local-only = convenient, NOT tamper-proof (documented).
import 'package:shared_preferences/shared_preferences.dart';
import 'plan.dart';

enum ProSource { none, mock, coupon, trial, play, server }

class Entitlement {
  final Tier tier;
  final ProSource source;
  final DateTime? expiresAt;
  const Entitlement({
    required this.tier,
    required this.source,
    this.expiresAt,
  });

  bool get isPro {
    if (tier != Tier.pro) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }
}

class EntitlementStore {
  static const _tierKey = 'sub_tier';
  static const _sourceKey = 'sub_source';
  static const _expiryKey = 'sub_expiry_ms';

  static Future<Entitlement> current() async {
    final prefs = await SharedPreferences.getInstance();
    final tier =
        (prefs.getString(_tierKey) ?? 'free') == 'pro'
            ? Tier.pro
            : Tier.free;
    final source = ProSource.values.firstWhere(
      (e) => e.name == (prefs.getString(_sourceKey) ?? 'none'),
      orElse: () => ProSource.none,
    );
    final ms = prefs.getInt(_expiryKey);
    return Entitlement(
      tier: tier,
      source: source,
      expiresAt:
          ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  /// Server verification plugs in here (Supabase/Firebase later).
  /// Returns the local entitlement for now.
  static Future<Entitlement> verify() async => current();

  static Future<void> grantPro({
    required ProSource source,
    DateTime? expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tierKey, 'pro');
    await prefs.setString(_sourceKey, source.name);
    if (expiresAt == null) {
      await prefs.remove(_expiryKey);
    } else {
      await prefs.setInt(
          _expiryKey, expiresAt.millisecondsSinceEpoch);
    }
  }

  static Future<void> revokeToFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tierKey, 'free');
    await prefs.setString(_sourceKey, ProSource.none.name);
    await prefs.remove(_expiryKey);
  }

  /// Gate check used by every feature. Free list in PlanConfig.
  static Future<bool> canUse(Feature f) async {
    if ((await current()).isPro) return true;
    switch (f) {
      case Feature.photoScan:
      case Feature.barcodeScan:
      case Feature.chat:
      case Feature.comboPlate:
        return true; // quota-checked separately
      case Feature.customMacros:
      case Feature.fasting:
      case Feature.mealPlans:
      case Feature.trends:
      case Feature.gaps:
      case Feature.export:
        return false;
    }
  }
}
