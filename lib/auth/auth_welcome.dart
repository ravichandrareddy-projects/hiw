// lib/auth/auth_welcome.dart — mandatory gate: Login or Register.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../themes/hiw_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthWelcome extends StatelessWidget {
  final VoidCallback? onDone;
  const AuthWelcome({super.key, this.onDone});

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                'HIW',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 64.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.w,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Health Is Wealth.',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Log in to sync your journey across devices.',
                style: TextStyle(color: t.mutedColor, fontSize: 14.sp),
              ),
              const Spacer(flex: 4),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            LoginScreen(onDone: onDone)),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.inkColor,
                    side: BorderSide(color: t.cardStroke),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            RegisterScreen(onDone: onDone)),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
