// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const LoginScreen({super.key, this.onDone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'user1@gmail.com');
  final _pass = TextEditingController(text: '1234');
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    if (!AuthService.validEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_pass.text.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await AuthService().login(email, _pass.text);
      await AppState.setLoggedIn(true);
      await AppState.setEmail(user.email);
      final existing = await AppState.getUsername();
      if (existing == null || existing == 'User') {
        await AppState.setUsername(user.username);
      }
      // Restore server-known calorie target when present (offline: skip).
      if (!mounted) return;
      if (widget.onDone != null) {
        widget.onDone!();
      } else {
        Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No internet. Check connection and retry.');
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.inkColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back.',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Log in to continue your journey.',
                style:
                    TextStyle(color: t.mutedColor, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style:
                      TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  style:
                      TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14.h),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: t.mutedColor,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13.sp,
                  ),
                ),
              ],
              SizedBox(height: 20.h),
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
                  onPressed: _busy ? null : _login,
                  child: _busy
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child:
                              const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(height: 12.h),
              Center(
                child: Text(
                  'Demo account: user1@gmail.com / 1234',
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
