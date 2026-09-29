// lib/core/subscription/coupon_service.dart
// Coupon redemption: bundled list today, server verify later.
// Grants 30-day Pro via EntitlementStore (source: coupon).
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'entitlement.dart';

enum CouponResult { ok, empty, invalid, alreadyRedeemed }

class CouponOutcome {
  final CouponResult result;
  final String message;
  const CouponOutcome(this.result, this.message);
}

class CouponService {
  static const assetPath = 'assets/pro_coupons.txt';
  static const _redeemedKey = 'pro_coupons_redeemed';
  static const grantDays = 30;

  static String normalize(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Pure helper (unit-testable, no assets/prefs).
  static CouponResult validate(
    String code,
    Set<String> valid,
    Set<String> redeemed,
  ) {
    final n = normalize(code);
    if (n.isEmpty) return CouponResult.empty;
    if (redeemed.contains(n)) return CouponResult.alreadyRedeemed;
    if (!valid.contains(n)) return CouponResult.invalid;
    return CouponResult.ok;
  }

  static Future<Set<String>> _bundled() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return raw
          .split(RegExp(r'[\r\n,;]+'))
          .map(normalize)
          .where((s) => s.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<Set<String>> _redeemed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_redeemedKey) ?? const [])
        .map(normalize)
        .toSet();
  }

  static Future<CouponOutcome> redeem(String code) async {
    final n = normalize(code);
    if (n.isEmpty) {
      return const CouponOutcome(
          CouponResult.empty, 'Enter a code first.');
    }
    final valid = await _bundled();
    final redeemed = await _redeemed();
    switch (validate(n, valid, redeemed)) {
      case CouponResult.empty:
        return const CouponOutcome(
            CouponResult.empty, 'Enter a code first.');
      case CouponResult.alreadyRedeemed:
        return const CouponOutcome(CouponResult.alreadyRedeemed,
            'This code was already used on this device.');
      case CouponResult.invalid:
        return const CouponOutcome(
            CouponResult.invalid, 'Invalid code. Check and try again.');
      case CouponResult.ok:
        await EntitlementStore.grantPro(
          source: ProSource.coupon,
          expiresAt:
              DateTime.now().add(const Duration(days: grantDays)),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            _redeemedKey, {...redeemed, n}.toList());
        return const CouponOutcome(CouponResult.ok,
            'Pro unlocked for 30 days 🎉');
    }
  }
}
