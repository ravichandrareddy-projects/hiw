//purchase screen
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../themes/hiw_theme.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: t.isMinimal ? null : const Color(0xFF020617),
      appBar: AppBar(
        title: Text('Shop', style: TextStyle(color: t.inkColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: t.inkColor),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                size: 80,
                color: accent,
              ),
              SizedBox(height: 24.h),
              Text(
                'THIS IS A HUGE UPDATE GATHERING IDEAS STAY!TUNES!😀😀',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: t.inkColor,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                height: 2.h,
                width: 60.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.3)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
