// lib/screens/paywall_screen.dart — Pro plans, prices from PlanConfig only.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/subscription/billing_service.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../services/analytics_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';

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
      if (ok && _status != null && _status!.isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to HIW Pro 🎉')),
        );
        Navigator.of(context).pop(true);
      } else if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase did not complete.')),
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
          const SnackBar(content: Text('Pro is already active ✅')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await EntitlementStore.grantPro(
        source: ProSource.trial,
        expiresAt: DateTime.now()
            .add(Duration(days: PlanConfig.trialDays)),
      );
      await _refreshStatus();
      if (!mounted) return;
      AnalyticsService().log('trial_start');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Trial started — ${PlanConfig.trialDays} days of Pro 🎉')),
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
                ? 'Purchases restored ✅'
                : 'No Pro purchases found.')),
      );
      if (_status?.isPro ?? false) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'HIW Pro',
          style: TextStyle(
              color: t.inkColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.feature != null) ...[
                Text(
                  widget.feature!,
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 14.sp),
                ),
                SizedBox(height: 12.h),
              ],
              ...const [
                'Custom macro goals + fasting timer',
                'AI meal plans + 30/90/365-day trends',
                'Nutrient gaps + exportable reports',
                'Higher scan & chat limits',
                'Ad-free forever',
              ].map((f) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: t.accentColor, size: 20.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              color: t.inkColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _priceCard(
                        t, false, PlanConfig.monthlyLabel, 'per month'),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _priceCard(
                        t, true, PlanConfig.annualLabel, 'per year'),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  '${PlanConfig.trialDays}-day free trial • cancel anytime in Play Store',
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 12.sp),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: _busy ? null : _startTrial,
                  child: Text(
                    _busy
                        ? 'Working...'
                        : 'Start ${PlanConfig.trialDays}-Day Free Trial',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.inkColor,
                    side: BorderSide(color: t.cardStroke),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: _busy ? null : _buy,
                  child: Text(
                    _annual
                        ? 'Buy ${PlanConfig.annualLabel}'
                        : 'Buy ${PlanConfig.monthlyLabel}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(
                    'Restore purchases',
                    style: TextStyle(
                        color: t.mutedColor, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Center(
                child: Builder(builder: (_) {
                  final e = _status;
                  final label = e == null
                      ? 'Checking status...'
                      : e.isPro
                          ? 'Pro active (${e.source.name})'
                          : 'Free plan';
                  return Text(
                    label,
                    style: TextStyle(
                        color: t.mutedColor, fontSize: 12.sp),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceCard(
      HiwTheme t, bool annual, String price, String per) {
    final sel = _annual == annual;
    return GestureDetector(
      onTap: () => setState(() => _annual = annual),
      child: HiwCard(
        padding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        child: Container(
          decoration: sel
              ? BoxDecoration(
                  border: Border.all(
                      color: t.accentColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12.r),
                )
              : null,
          child: Column(
            children: [
              if (annual)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: t.accentColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(height: 6.h),
              Text(
                price,
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 17.sp,
                ),
              ),
              Text(
                per,
                style:
                    TextStyle(color: t.mutedColor, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
