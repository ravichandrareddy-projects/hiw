// lib/screens/fasting_screen.dart — Pro: fasting timer ring + history.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/fasting_engine.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../services/analytics_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';
import '../widgets/limit_sheet.dart';
import 'paywall_screen.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  DateTime? _start;
  int _lenMin = 16 * 60;
  List<String> _hist = [];
  late Timer _tick;
  DateTime _now = DateTime.now();
  int _picked = 2;

  @override
  void initState() {
    super.initState();
    _load();
    _guardPro();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() => _now = DateTime.now()) : null,
    );
  }

  Future<void> _guardPro() async {
    if (await EntitlementStore.canUse(Feature.fasting)) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showLimitSheet(
        context,
        title: 'Fasting lives in HIW Pro',
        usedLabel: 'Free stays generous — timer is Pro',
        resetLabel: 'anytime — upgrade when ready',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
              feature: 'Fasting timer lives in HIW Pro.'),
        ),
      );
    });
  }

  Future<void> _load() async {
    final s = await FastingEngine.activeStart();
    final l = await FastingEngine.activeLengthMin();
    final h = await FastingEngine.history();
    if (mounted) {
      setState(() {
        _start = s;
        _lenMin = l;
        _hist = h.reversed.toList();
      });
    }
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final active = _start != null;
    final prog = active
        ? FastingEngine.progress(_start!, _lenMin, _now)
        : 0.0;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Fasting Timer',
          style: TextStyle(
              color: t.inkColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Column(
            children: [
              SizedBox(height: 8.h),
              SizedBox(
                width: 230.w,
                height: 230.w,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: prog,
                      strokeWidth: 14.w,
                      backgroundColor: t.accentColor
                          .withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          t.accentColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            active
                                ? FastingEngine.remainingLabel(
                                    _start!, _lenMin, _now)
                                : FastPreset.list[_picked].label,
                            style: TextStyle(
                              color: t.inkColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 30.sp,
                            ),
                          ),
                          Text(
                            active ? 'remaining' : 'pick a window',
                            style: TextStyle(
                                color: t.mutedColor,
                                fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              if (!active) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  alignment: WrapAlignment.center,
                  children: FastPreset.list
                      .asMap()
                      .entries
                      .map((e) => GestureDetector(
                            onTap: () => setState(
                                () => _picked = e.key),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _picked == e.key
                                    ? t.accentColor
                                    : t.cardBackground,
                                borderRadius:
                                    BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: _picked == e.key
                                        ? t.accentColor
                                        : t.cardStroke),
                              ),
                              child: Text(
                                e.value.label,
                                style: TextStyle(
                                  color: _picked == e.key
                                      ? Colors.white
                                      : t.inkColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accentColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16.r),
                      ),
                    ),
                    onPressed: () async {
                      await FastingEngine.start(
                          FastPreset.list[_picked].fast);
                      AnalyticsService().log('fast_start');
                      _load();
                    },
                    child: const Text('Start Fast',
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.inkColor,
                          side: BorderSide(
                              color: t.cardStroke),
                          padding: EdgeInsets.symmetric(
                              vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () async {
                          await FastingEngine.end(
                              completed: false);
                          _load();
                        },
                        child: const Text('End Early'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () async {
                          final full =
                              await FastingEngine.end();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(full
                                      ? 'Fast complete! 🎉'
                                      : 'Fast logged.')));
                          _load();
                        },
                        child: const Text('Finish',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 18.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'History',
                  style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              if (_hist.isEmpty)
                Text(
                  'No fasts yet — start your first above.',
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 13.sp),
                ),
              ..._hist.take(20).map((h) {
                final p = h.split('>');
                final s = DateTime.fromMillisecondsSinceEpoch(
                    int.tryParse(p[0]) ?? 0);
                final done = p.length > 2 && p[2] == 'true';
                return HiwCard(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Icon(
                        done
                            ? Icons.verified_rounded
                            : Icons.history_rounded,
                        color: done
                            ? t.accentColor
                            : t.mutedColor,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          '${s.day}/${s.month}/${s.year}',
                          style: TextStyle(
                              color: t.inkColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        done ? 'Completed' : 'Ended early',
                        style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 12.sp),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
