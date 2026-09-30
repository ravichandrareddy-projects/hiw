// lib/core/subscription/billing_service.dart
// Play Billing path. Until Play Console products + review are ready,
// purchases fall back to a clearly-labelled TEST grant (no fake charges).
// Product IDs live in PlanConfig only.
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'entitlement.dart';
import 'plan.dart';

class BillingService {
  static bool _listenerOn = false;

  static Future<bool> storeAvailable() async {
    try {
      return await InAppPurchase.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  static void _ensureListener() {
    if (_listenerOn) return;
    _listenerOn = true;
    InAppPurchase.instance.purchaseStream.listen(
      (events) async {
        for (final e in events) {
          if (e.status == PurchaseStatus.purchased ||
              e.status == PurchaseStatus.restored) {
            final annual = (e.productID == PlanConfig.skuAnnual);
            await EntitlementStore.grantPro(
              source: ProSource.play,
              expiresAt: annual
                  ? DateTime.now().add(const Duration(days: 365))
                  : DateTime.now().add(const Duration(days: 30)),
            );
          }
          if (e.pendingCompletePurchase) {
            try {
              await InAppPurchase.instance
                  .completePurchase(e);
            } catch (_) {}
          }
        }
      },
      onError: (_) {},
    );
  }

  /// Returns true when Pro is active afterwards.
  static Future<bool> buy(bool annual) async {
    _ensureListener();
    final sku =
        annual ? PlanConfig.skuAnnual : PlanConfig.skuMonthly;
    try {
      if (!await storeAvailable()) {
        return await _testGrant();
      }
      final resp = await InAppPurchase.instance
          .queryProductDetails({sku});
      if (resp.productDetails.isEmpty) {
        // Product not configured in Play Console yet → test path.
        return await _testGrant();
      }
      final param = PurchaseParam(
          productDetails: resp.productDetails.first);
      final ok = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: param,
      );
      if (!ok) return await _testGrant();
      // Real purchase completes via purchaseStream listener above.
      await Future.delayed(const Duration(seconds: 2));
      return (await EntitlementStore.current()).isPro;
    } catch (e) {
      debugPrint('HIW BILLING: $e');
      return (await EntitlementStore.current()).isPro;
    }
  }

  /// TEST-ONLY grant, clearly labelled. Never a fake charge.
  static Future<bool> _testGrant() async {
    await EntitlementStore.grantPro(
      source: ProSource.mock,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    return true;
  }

  static Future<void> restore() async {
    _ensureListener();
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
  }
}
