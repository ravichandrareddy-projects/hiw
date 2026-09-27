import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/history_store.dart';
import '../../widgets/premium_glass_card.dart'; // 🆕
import '../../themes/hiw_theme.dart';

class AnimatedStatsCircle extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const AnimatedStatsCircle({
    super.key,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    final stats = HistoryStore().getStatsForDate(date);
    final protein = stats['protein'] ?? 0.0;
    final healthyPct = stats['healthyPercent'] ?? 0.0;
    final junkPct = stats['junkPercent'] ?? 0.0;

    // If no data, show empty state
    final hasData = protein > 0 || healthyPct > 0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          PremiumGlassCard(
            height: 200.h,
            width: 200.w,
            borderRadius: 100, // Make it circular
            padding: EdgeInsets.all(20.r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      // Healthy
                      PieChartSectionData(
                        value: hasData ? healthyPct : 100,
                        color: hasData
                            ? accent
                            : t.mutedColor.withValues(alpha: 0.25),
                        radius: 15,
                        showTitle: false,
                      ),
                      // Junk
                      if (hasData)
                        PieChartSectionData(
                          value: junkPct,
                          color: Colors.pinkAccent,
                          radius: 15,
                          showTitle: false,
                        ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeOutBack,
                ),

                // CENTER TEXT
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasData ? '${protein.toInt()}g' : '0g',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: t.inkColor,
                      ),
                    ),
                    Text(
                      'Protein',
                      style: TextStyle(fontSize: 12.sp, color: t.mutedColor),
                    ),
                    if (hasData)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          '${healthyPct.toInt()}% Healthy',
                          style: TextStyle(
                              fontSize: 10.sp, color: accent),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Tap for details',
            style: TextStyle(color: t.mutedColor, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
