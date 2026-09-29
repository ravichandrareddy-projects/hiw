// lib/screens/trends_screen.dart — Pro: 30/90/365-day trends from
// REAL stored data only (calories + log counts + streaks). No invented
// macros. Plus nutrient gaps (today vs targets) + export.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../core/history_store.dart';
import '../core/nutrition_store.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../services/analytics_service.dart';
import '../hive/history_hive_model.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';
import '../widgets/limit_sheet.dart';
import 'paywall_screen.dart';
import 'package:hive/hive.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _guardPro();
  }

  Future<void> _guardPro() async {
    if (await EntitlementStore.canUse(Feature.trends)) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showLimitSheet(
        context,
        title: 'Trends live in HIW Pro',
        usedLabel: 'Free stays generous — trends are Pro',
        resetLabel: 'anytime — upgrade when ready',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              const PaywallScreen(feature: 'Trends live in HIW Pro.'),
        ),
      );
    });
  }

  Map<DateTime, int> _dailyCalories(int days) {
    final box = Hive.box<HistoryHive>('historyBox');
    final now = DateTime.now();
    final map = <DateTime, int>{};
    for (var i = 0; i < days; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      map[d] = 0;
    }
    for (final h in box.values) {
      final d = DateTime(h.time.year, h.time.month, h.time.day);
      if (map.containsKey(d)) {
        map[d] = map[d]! + h.calories;
      }
    }
    return map;
  }

  Future<void> _export() async {
    if (!(await EntitlementStore.canUse(Feature.export))) {
      if (!mounted) return;
      await showLimitSheet(
        context,
        title: 'Export lives in HIW Pro',
        usedLabel: 'Free stays generous — reports are Pro',
        resetLabel: 'anytime — upgrade when ready',
      );
      return;
    }
    final store = HistoryStore();
    final buf = StringBuffer('date,food,meal,calories\n');
    for (final e in store.allEntries) {
      final f = e.food;
      buf.writeln(
          '${f.time.toIso8601String()},${f.name},${f.mealType.name},${f.calories}');
    }
    AnalyticsService().log('trends_export');
    await SharePlus.instance.share(
      ShareParams(text: 'HIW nutrition export\n$buf'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final data = _dailyCalories(_days);
    final keys = data.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (var i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[keys[i]]!.toDouble()));
    }
    final n = NutritionStore();
    final pTarget = n.proteinTargetG > 0 ? n.proteinTargetG : 60;
    double pToday = 0;
    for (final f in n.todayFoods) {
      pToday += f.protein;
    }
    final gapCal = n.dailyTargetCalories > 0
        ? n.dailyTargetCalories - n.totalCalories
        : 0;
    final gapPro = (pTarget - pToday).clamp(0.0, 9999.0);

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
          'Trends & Gaps',
          style: TextStyle(
              color: t.inkColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: t.inkColor),
            onPressed: _export,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [30, 90, 365]
                    .map((d) => GestureDetector(
                          onTap: () =>
                              setState(() => _days = d),
                          child: Container(
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h),
                            decoration: BoxDecoration(
                              color: _days == d
                                  ? t.accentColor
                                  : t.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(20.r),
                              border: Border.all(
                                  color: _days == d
                                      ? t.accentColor
                                      : t.cardStroke),
                            ),
                            child: Text(
                              '$d days',
                              style: TextStyle(
                                color: _days == d
                                    ? Colors.white
                                    : t.inkColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 12.h),
              HiwCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily calories (logged)',
                      style: TextStyle(
                        color: t.inkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 180.h,
                      child: spots.isEmpty
                          ? Center(
                              child: Text(
                                'No data yet — log meals to see trends.',
                                style: TextStyle(
                                    color: t.mutedColor),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: const FlGridData(
                                    show: false),
                                titlesData: const FlTitlesData(
                                    show: false),
                                borderData:
                                    FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: t.accentColor,
                                    barWidth: 2.5,
                                    dotData:
                                        const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: t.accentColor
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              HiwCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's gaps",
                      style: TextStyle(
                        color: t.inkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      gapCal > 0
                          ? '$gapCal kcal left today'
                          : 'Calorie target reached ✅',
                      style: TextStyle(
                          color: t.mutedColor,
                          fontSize: 13.sp),
                    ),
                    Text(
                      gapPro > 0
                          ? '${gapPro.toStringAsFixed(0)} g protein to go'
                          : 'Protein target reached ✅',
                      style: TextStyle(
                          color: t.mutedColor,
                          fontSize: 13.sp),
                    ),
                    Text(
                      'Macros history starts fresh — past protein data was never stored.',
                      style: TextStyle(
                          color: t.mutedColor,
                          fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
