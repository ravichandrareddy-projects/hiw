// lib/auth/auth_welcome.dart — mandatory gate: Login or Register or Google.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../themes/hiw_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthWelcome extends StatefulWidget {
  final VoidCallback? onDone;
  const AuthWelcome({super.key, this.onDone});

  @override
  State<AuthWelcome> createState() => _AuthWelcomeState();
}

class _AuthWelcomeState extends State<AuthWelcome> {
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final user = await AuthService().signInWithGoogle();
      await AppState.setLoggedIn(true);
      await AppState.setEmail(user.email);
      final existing = await AppState.getUsername();
      if (existing == null || existing == 'User' || existing.isEmpty) {
        await AppState.setUsername(user.username);
      }
      if (!mounted) return;
      if (widget.onDone != null) {
        widget.onDone!();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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

              // 1. Google button
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
                    backgroundColor: t.cardBackground,
                  ),
                  onPressed: _busy ? null : _signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata_rounded,
                          size: 28.sp, color: t.inkColor),
                      SizedBox(width: 8.w),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // 2. Email / Mail Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(onDone: widget.onDone),
                    ),
                  ),
                  icon: const Icon(Icons.mail_outline_rounded, size: 20),
                  label: Text(
                    'Continue with Email',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Subtle Sign-up link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: t.mutedColor, fontSize: 13.5.sp),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(onDone: widget.onDone),
                        ),
                      ),
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: t.accentColor,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
