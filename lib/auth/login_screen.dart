// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';
import 'register_screen.dart';

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

  Future<void> _completeAuth(AuthUser user) async {
    await AppState.setLoggedIn(true);
    await AppState.setEmail(user.email);
    final existing = await AppState.getUsername();
    if (existing == null || existing == 'User' || existing.isEmpty) {
      await AppState.setUsername(user.username);
    }
    if (!mounted) return;
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop(true);
    }
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
      await _completeAuth(user);
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await AuthService().signInWithGoogle();
      await _completeAuth(user);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google Sign-In failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showForgotPassword() async {
    final resetEmailCtrl = TextEditingController(text: _email.text.trim());
    final t = HiwTheme.of(context);
    String? resetError;
    bool resetBusy = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24.w,
              20.h,
              24.w,
              MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: t.cardStroke,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    color: t.inkColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter your email address and we will send you a secure link to reset your password.',
                  style: TextStyle(color: t.mutedColor, fontSize: 13.sp),
                ),
                SizedBox(height: 16.h),
                HiwCard(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                    decoration: InputDecoration(
                      hintText: 'Your registered email',
                      hintStyle: TextStyle(color: t.mutedColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                if (resetError != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    resetError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: resetBusy
                        ? null
                        : () async {
                            final target = resetEmailCtrl.text.trim();
                            if (!AuthService.validEmail(target)) {
                              setModalState(() =>
                                  resetError = 'Enter a valid email address.');
                              return;
                            }
                            setModalState(() {
                              resetBusy = true;
                              resetError = null;
                            });
                            try {
                              await AuthService().sendPasswordReset(target);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Password reset email sent. Check your inbox! 📬'),
                                ),
                              );
                            } on AuthException catch (e) {
                              setModalState(() => resetError = e.message);
                            } catch (_) {
                              setModalState(() => resetError =
                                  'Could not send reset link. Try again.');
                            } finally {
                              setModalState(() => resetBusy = false);
                            }
                          },
                    child: resetBusy
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                'Sign in to sync your nutrition and health journey.',
                style: TextStyle(color: t.mutedColor, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),

              // Email input
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Password input
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: t.mutedColor,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
              ),

              // Forgot password button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: t.accentColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (_error != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13.sp,
                  ),
                ),
              ],
              SizedBox(height: 14.h),

              // Sign in button
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
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(height: 20.h),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: t.cardStroke)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: t.mutedColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: t.cardStroke)),
                ],
              ),
              SizedBox(height: 20.h),

              // Google Sign-In button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.inkColor,
                    side: BorderSide(color: t.cardStroke),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
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
                          size: 26.sp, color: t.inkColor),
                      SizedBox(width: 8.w),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Register switch
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(onDone: widget.onDone),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: t.mutedColor, fontSize: 14.sp),
                      children: [
                        TextSpan(
                          text: 'Create Account',
                          style: TextStyle(
                            color: t.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Center(
                child: Text(
                  'Demo account: user1@gmail.com / 1234',
                  style: TextStyle(color: t.mutedColor, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
