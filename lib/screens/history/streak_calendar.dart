import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/history_store.dart';
import '../../widgets/premium_glass_card.dart';
import '../../themes/hiw_theme.dart';

class StreakCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const StreakCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday -
            1; // Mon=0

    return Column(
      children: [
        // 📅 MONTH HEADER BAR WITH CYBER BADGES
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _changeMonth(-1),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: t.isMinimal
                      ? accent.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                      color: t.isMinimal ? t.cardStroke : Colors.white10),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 14, color: accent),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
                border:
                    Border.all(color: accent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.1),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month,
                      size: 14, color: accent),
                  SizedBox(width: 8.w),
                  Text(
                    monthName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.sp,
                      letterSpacing: 1.1,
                      color: t.inkColor,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _changeMonth(1),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: t.isMinimal
                      ? accent.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                      color: t.isMinimal ? t.cardStroke : Colors.white10),
                ),
                child: Icon(Icons.arrow_forward_ios,
                    size: 14, color: accent),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // 🗓️ CYBER MATRIX GRID CARD
        PremiumGlassCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WEEKDAY LABELS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                    .map((day) {
                  return SizedBox(
                    width: 32.w,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                        letterSpacing: 0.5,
                        color: accent.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10.h),

              // DAYS MATRIX
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.82,
                ),
                itemCount: 42, // 6 weeks
                itemBuilder: (context, index) {
                  if (index < firstDayOffset ||
                      index >= firstDayOffset + daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final dayNum = index - firstDayOffset + 1;
                  final date =
                      DateTime(_currentMonth.year, _currentMonth.month, dayNum);

                  final isSelected =
                      DateUtils.isSameDay(date, widget.selectedDate);
                  final hasStreak = HistoryStore().hasStreak(date);
                  final entries = HistoryStore().getEntriesForDate(date);
                  final hasEntries = entries.isNotEmpty;

                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final isFuture = date.isAfter(today);

                  Color dayColor = t.inkColor;
                  if (hasEntries) {
                    final stats = HistoryStore().getStatsForDate(date);
                    final healthyPct = stats['healthyPercent'] ?? 0;
                    if (healthyPct >= 50) {
                      dayColor = Colors.greenAccent;
                    } else {
                      dayColor = Colors.orangeAccent;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      if (isFuture) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Day has not arrived yet! ⏳"),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      widget.onDateSelected(date);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasStreak)
                          Icon(Icons.local_fire_department,
                              color: Colors.orangeAccent, size: 14.r)
                        else
                          SizedBox(height: 14.h),
                        Container(
                          width: 32.w,
                          height: 32.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? accent
                                : (isFuture
                                    ? t.mutedColor.withValues(alpha: 0.08)
                                    : (hasEntries
                                        ? dayColor.withValues(alpha: 0.25)
                                        : (t.isMinimal
                                            ? Colors.black
                                                .withValues(alpha: 0.04)
                                            : Colors.white.withValues(
                                                alpha: 0.06)))),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : (hasEntries
                                      ? dayColor.withValues(alpha: 0.6)
                                      : (t.isMinimal
                                          ? t.cardStroke
                                          : Colors.white.withValues(
                                              alpha:
                                                  isFuture ? 0.04 : 0.15))),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: accent,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              if (hasEntries && !isSelected && !isFuture)
                                BoxShadow(
                                  color: dayColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : (isFuture
                                      ? t.mutedColor
                                      : t.inkColor),
                              fontWeight: isSelected || hasEntries
                                  ? FontWeight.w900
                                  : FontWeight.w500,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
