import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../../core/history_store.dart';
import '../../core/food_item.dart';
import '../../core/theme_manager.dart';
import '../../events/event_manager.dart';
import '../../widgets/premium_glass_card.dart'; // 🆕
import '../../themes/hiw_theme.dart';
import 'package:intl/intl.dart';

class DailyDetailScreen extends StatelessWidget {
  final DateTime date;

  const DailyDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final entries = HistoryStore().getEntriesForDate(date);
    final dateStr = DateFormat('MMMM d, yyyy').format(date);
    final dayStr = DateFormat('EEEE').format(date);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(
              'HIW',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: EventManager.wrapWithBackground(
        ThemeManager().currentThemeName,
        SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      dayStr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20),

              // LIST
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No meals logged for this day.',
                          style:
                              TextStyle(color: Theme.of(context).disabledColor),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.r),
                        physics: const BouncingScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _MealCard(entry.food);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final FoodItem food;
  const _MealCard(this.food);

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final timeStr = DateFormat('hh:mm a').format(food.time);

    // Logic for Status
    final isHeavy = food.calories > 500;
    final status = isHeavy ? "Heavy Meal" : "Healthy Choice";
    // We keep status text color distinct but fit the glass theme
    final statusColor =
        isHeavy ? Colors.orangeAccent : Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: PremiumGlassCard(
        borderRadius: 24,
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            // TOP ROW: Type + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PILL 1: MEAL TYPE
                PremiumGlassCard(
                  isInnerPill: true,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  borderRadius: 12,
                  child: Text(
                    food.mealType.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                // PILL 2: TIME
                PremiumGlassCard(
                  isInnerPill: true,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: t.mutedColor),
                      SizedBox(width: 4.w),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: t.inkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // MAIN INFO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    food.name,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: t.inkColor,
                      shadows: t.isMinimal
                          ? null
                          : [
                              Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4.r,
                                  offset: const Offset(0, 2))
                            ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // BOTTOM ROW: STATS (Pills like the image)
            Row(
              children: [
                // CALORIES PILL
                Expanded(
                  child: PremiumGlassCard(
                    isInnerPill: true,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        Text(
                          "Calories",
                          style:
                              TextStyle(fontSize: 11.sp, color: t.mutedColor),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "${food.calories}",
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: t.inkColor),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // STATUS PILL
                Expanded(
                  child: PremiumGlassCard(
                    isInnerPill: true,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    borderRadius: 16,
                    child: Column(
                      children: [
                        Text(
                          "Status",
                          style:
                              TextStyle(fontSize: 11.sp, color: t.mutedColor),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
