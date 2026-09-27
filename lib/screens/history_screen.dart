import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/history_store.dart';
import '../widgets/premium_glass_card.dart';
import '../themes/hiw_theme.dart';
import 'history/streak_calendar.dart';
import 'history/cyber_macro_arcs.dart';
import 'history/daily_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyDetailScreen(date: _selectedDate),
      ),
    );
  }

  int _calculateActiveStreak() {
    final store = HistoryStore();
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      if (store.hasStreak(checkDate)) {
        streak++;
      } else if (i > 0) {
        break; // Streak broken
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    final stats = HistoryStore().getStatsForDate(_selectedDate);
    final entries = HistoryStore().getEntriesForDate(_selectedDate);
    final activeStreak = _calculateActiveStreak();

    final calories = stats['calories'] ?? 0.0;
    final protein = stats['protein'] ?? 0.0;
    final healthyPct = stats['healthyPercent'] ?? 0.0;
    final carbs = protein * 1.5; // Estimated breakdown for visual gauge
    final fats = (calories * 0.25) / 9.0;

    final formattedSelectedDate =
        DateFormat('EEEE, MMM d').format(_selectedDate);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 48.h, 16.w, 140.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🛡️ CYBER COMMAND BANNER
          PremiumGlassCard(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security,
                            size: 14, color: accent),
                        SizedBox(width: 6.w),
                        Text(
                          "CYBER-HEALTH COMMAND HUB",
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: t.mutedColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      formattedSelectedDate,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: t.inkColor,
                      ),
                    ),
                  ],
                ),

                // 🔥 STREAK FLAME BADGE
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: Colors.orangeAccent, size: 18.r),
                      SizedBox(width: 4.w),
                      Text(
                        "$activeStreak STREAK",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.orangeAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 🌀 HERO CYBER MACRO GAUGES
          CyberMacroArcs(
            calories: calories,
            calGoal: 2000.0,
            protein: protein,
            proteinGoal: 120.0,
            carbs: carbs,
            carbsGoal: 220.0,
            fats: fats,
            fatsGoal: 65.0,
            healthyPercent: healthyPct,
            onTap: _navigateToDetails,
          ),

          SizedBox(height: 16.h),

          // 🗓️ CYBER MATRIX CALENDAR
          StreakCalendar(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
          ),

          SizedBox(height: 18.h),

          // 🍽️ LOGGED MEALS QUICK FEED FOR SELECTED DATE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MEAL ENTRIES (${entries.length})",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: accent,
                ),
              ),
              InkWell(
                onTap: _navigateToDetails,
                child: Text(
                  "View Detailed Logs ›",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: t.mutedColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          if (entries.isEmpty)
            PremiumGlassCard(
              padding: EdgeInsets.all(20.r),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.no_meals_outlined,
                        color: t.mutedColor, size: 36.r),
                    SizedBox(height: 8.h),
                    Text(
                      "No meals recorded for $formattedSelectedDate.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, color: t.mutedColor),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Scan food with HIW-T AI to keep your streak hot! 🔥",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11.sp, color: accent),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index].food;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: PremiumGlassCard(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            entry.calories > 500
                                ? Icons.lunch_dining
                                : Icons.restaurant,
                            color: accent,
                            size: 20.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.name,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: t.inkColor,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "${entry.mealType.name.toUpperCase()} • ${DateFormat('h:mm a').format(entry.time)}",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: t.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${entry.calories} kcal",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            if (entry.protein > 0)
                              Text(
                                "${entry.protein.toInt()}g protein",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: t.mutedColor,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
