// lib/screens/paywall_screen.dart — Reusable, transparent HIW Pro component.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../core/subscription/billing_service.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../services/analytics_service.dart';
import '../themes/hiw_theme.dart';
import '../themes/hiw_gold.dart';

class PaywallScreen extends StatefulWidget {
  final String? feature;
  const PaywallScreen({super.key, this.feature});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _annual = true;
  bool _busy = false;
  Entitlement? _status;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    AnalyticsService().log('paywall_open');
  }

  Future<void> _refreshStatus() async {
    final e = await EntitlementStore.verify();
    if (mounted) setState(() => _status = e);
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      final ok = await BillingService.buy(_annual);
      if (!mounted) return;
      await _refreshStatus();
      if (!mounted) return;
      if (ok && _status != null && _status!.isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to HIW Pro 🎉')),
        );
        Navigator.of(context).pop(true);
      } else if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase was not completed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startTrial() async {
    final cur = await EntitlementStore.current();
    if (cur.isPro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HIW Pro is already active ✅')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await EntitlementStore.grantPro(
        source: ProSource.trial,
        expiresAt: DateTime.now()
            .add(const Duration(days: PlanConfig.trialDays)),
      );
      await _refreshStatus();
      if (!mounted) return;
      AnalyticsService().log('trial_start');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('7-Day Free Trial activated! Welcome to Pro 🎉'),
        ),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await BillingService.restore();
      await Future.delayed(const Duration(seconds: 1));
      await _refreshStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((_status?.isPro ?? false)
              ? 'Purchases restored successfully ✅'
              : 'No active Pro subscriptions found.'),
        ),
      );
      if (_status?.isPro ?? false) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trialEndDate = DateFormat.yMMMd().format(
      DateTime.now().add(const Duration(days: PlanConfig.trialDays)),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HiwGold.proPill(label: 'HIW PRO', showCrown: true, fontSize: 11),
            SizedBox(width: 8.w),
            Text(
              'Membership',
              style: TextStyle(
                color: t.inkColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contextual Trigger Banner (if triggered from specific feature)
              if (widget.feature != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark ? HiwGold.cardBgDark : HiwGold.cardBgLight,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: HiwGold.borderLight, width: 1.2),
                    boxShadow: [HiwGold.subtleGlow(blur: 8, opacity: 0.2)],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: HiwGold.warmGold, size: 20.sp),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          widget.feature!,
                          style: TextStyle(
                            color: t.inkColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
              ],
              // Header intro
              Row(
                children: [
                  HiwGold.proPill(label: 'PREMIUM EXPERIENCE', showCrown: true, fontSize: 10),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Unlock HIW Pro',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Free plan stays forever. Upgrade only when you want deeper insights, AI meal planning, and higher limits.',
                style: TextStyle(
                  color: t.mutedColor,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),

              // Free vs Pro Comparison Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Free Plan Column
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: t.cardBackground,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: t.cardStroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Free Forever',
                            style: TextStyle(
                              color: t.mutedColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          _miniFeature(t, 'Core food & water log', isPro: false),
                          _miniFeature(t, '40 photo scans / mo', isPro: false),
                          _miniFeature(t, 'Unlimited text search', isPro: false),
                          _miniFeature(t, '20 barcode scans / mo', isPro: false),
                          _miniFeature(t, 'Basic avatar & habits', isPro: false),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Pro Column (Cool Champagne Gold)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isDark ? HiwGold.cardBgDark : HiwGold.cardBgLight,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: HiwGold.warmGold, width: 2.0.w),
                        boxShadow: [
                          HiwGold.haloGlow(blur: 14, opacity: 0.25),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              HiwGold.proPill(label: 'HIW PRO', showCrown: true, fontSize: 10),
                              const Spacer(),
                              Icon(Icons.workspace_premium_rounded, color: HiwGold.warmGold, size: 18.sp),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          _miniFeature(t, 'AI meal plans & fasting', isPro: true),
                          _miniFeature(t, '30/90/365-day trends', isPro: true),
                          _miniFeature(t, 'Nutrient gap analysis', isPro: true),
                          _miniFeature(t, 'Higher fair-use limits', isPro: true),
                          _miniFeature(t, 'Ad-free experience', isPro: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // Pricing Tiers
              Text(
                'Choose a plan',
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _priceCard(
                      t,
                      isDark: isDark,
                      annual: false,
                      price: PlanConfig.monthlyLabel,
                      per: 'per month',
                      tag: null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _priceCard(
                      t,
                      isDark: isDark,
                      annual: true,
                      price: PlanConfig.annualLabel,
                      per: 'per year (₹75/mo)',
                      tag: 'SAVE 37% • BEST VALUE',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Transparency Callout
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? HiwGold.cardBgDark : HiwGold.cardBgLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: HiwGold.borderLight.withValues(alpha: 0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded, color: HiwGold.warmGold, size: 18.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _annual
                            ? 'Includes ${PlanConfig.trialDays}-day free trial. If you activate today, billing begins on $trialEndDate. Cancel anytime with 1 tap.'
                            : 'Billed monthly at ${PlanConfig.monthlyLabel}. Cancel anytime in Google Play Store.',
                        style: TextStyle(
                          color: t.mutedColor,
                          fontSize: 12.sp,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Action Buttons with Gold Luxury Styling
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: HiwGold.buttonGradient,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    HiwGold.haloGlow(blur: 16, opacity: 0.45),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF2C1400),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: _busy ? null : (_annual ? _startTrial : _buy),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8.w),
                      Text(
                        _busy
                            ? 'Please wait...'
                            : (_annual
                                ? 'Start ${PlanConfig.trialDays}-Day Free Trial'
                                : 'Subscribe to Monthly (${PlanConfig.monthlyLabel})'),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2C1400),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 8.h),
              if (_annual)
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _buy,
                    child: Text(
                      'Or purchase annual plan directly (${PlanConfig.annualLabel})',
                      style: TextStyle(
                        color: t.mutedColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),

              Center(
                child: TextButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(
                    'Restore Purchases',
                    style: TextStyle(
                      color: HiwGold.deepGold,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 6.h),
              Center(
                child: Builder(builder: (_) {
                  final e = _status;
                  final label = e == null
                      ? 'Checking subscription...'
                      : e.isPro
                          ? 'Current Status: Pro Active (${e.source.name})'
                          : 'Current Status: Free Plan (Active Forever)';
                  return Text(
                    label,
                    style: TextStyle(
                      color: t.mutedColor,
                      fontSize: 11.5.sp,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniFeature(HiwTheme t, String text, {required bool isPro}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPro ? Icons.check_circle_rounded : Icons.check_rounded,
            color: isPro ? HiwGold.warmGold : t.mutedColor,
            size: 14.sp,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: t.inkColor,
                fontSize: 11.5.sp,
                height: 1.25,
                fontWeight: isPro ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(
    HiwTheme t, {
    required bool isDark,
    required bool annual,
    required String price,
    required String per,
    required String? tag,
  }) {
    final sel = _annual == annual;
    return GestureDetector(
      onTap: () => setState(() => _annual = annual),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: sel
              ? (isDark ? HiwGold.cardBgDark : HiwGold.cardBgLight)
              : t.cardBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: sel ? HiwGold.warmGold : t.cardStroke,
            width: sel ? 2.0 : 1.0,
          ),
          boxShadow: sel ? [HiwGold.subtleGlow(blur: 10, opacity: 0.25)] : null,
        ),
        child: Column(
          children: [
            if (tag != null)
              Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: HiwGold.badgeGradient,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: HiwGold.borderLight, width: 0.8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: const Color(0xFF3B1E00),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              SizedBox(height: 18.h),
            Text(
              price,
              style: TextStyle(
                color: sel ? HiwGold.deepGold : t.inkColor,
                fontWeight: FontWeight.w900,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              per,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.mutedColor, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }
}
