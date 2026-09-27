import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/premium_glass_card.dart';
import '../themes/hiw_theme.dart';

/// Proactive mood check overlay with blur effect
/// Shows 3-4 times per day to check user's emotional state
class MoodCheckOverlay extends StatelessWidget {
  final VoidCallback onGood;
  final VoidCallback onNotGreat;
  final VoidCallback onStruggling;
  final VoidCallback onDismiss;

  const MoodCheckOverlay({
    super.key,
    required this.onGood,
    required this.onNotGreat,
    required this.onStruggling,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Centered mood check card
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.0.r),
              child: PremiumGlassCard(
                borderRadius: 24,
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close,
                            color: t.mutedColor, size: 20),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Emoji
                    Text(
                      '💙',
                      style: TextStyle(fontSize: 48.sp),
                    ),

                    SizedBox(height: 16.h),

                    // Question
                    Text(
                      'How are you feeling\nright now?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: t.inkColor,
                        height: 1.3.h,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      'Your wellbeing matters to us',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: t.mutedColor,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Response buttons
                    _MoodButton(
                      emoji: '😊',
                      label: "I'm Good",
                      color: Colors.green,
                      onTap: onGood,
                    ),

                    SizedBox(height: 12.h),

                    _MoodButton(
                      emoji: '😔',
                      label: "Not Great",
                      color: Colors.orange,
                      onTap: onNotGreat,
                    ),

                    SizedBox(height: 12.h),

                    _MoodButton(
                      emoji: '😔',
                      label: "Feeling Bad",
                      color: Colors.red,
                      onTap: onStruggling,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
