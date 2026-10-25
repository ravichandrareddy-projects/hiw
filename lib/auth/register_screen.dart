// lib/auth/register_screen.dart — direct registration without OTP.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const RegisterScreen({super.key, this.onDone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _completeAuth(AuthUser user) async {
    await AppState.setLoggedIn(true);
    await AppState.setEmail(user.email);
    final chosenName = _name.text.trim();
    if (chosenName.isNotEmpty) {
      await AppState.setUsername(chosenName);
    } else {
      await AppState.setUsername(user.username);
    }
    if (!mounted) return;
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    if (!AuthService.validEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    final perr = AuthService.passwordError(_pass.text);
    if (perr != null) {
      setState(() => _error = 'Password: $perr');
      return;
    }
    if (_pass.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await AuthService().register(
        email,
        _pass.text,
        username: _name.text.trim().isNotEmpty ? _name.text.trim() : null,
      );
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
                'Create account.',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Start your personalized nutrition & health journey.',
                style: TextStyle(color: t.mutedColor, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),

              // Name / Display name
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Your name or nickname',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Email
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Password
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _pass,
                  obscureText: _obscurePass,
                  style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Password (min 4 characters)',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: t.mutedColor,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Confirm Password
              HiwCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _confirm,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: t.inkColor, fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: TextStyle(color: t.mutedColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: t.mutedColor,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  onSubmitted: (_) => _register(),
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

              // Create Account CTA
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
                  onPressed: _busy ? null : _register,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
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

              // Google Sign-In
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

              // Already have account
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(onDone: widget.onDone),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: t.mutedColor, fontSize: 14.sp),
                      children: [
                        TextSpan(
                          text: 'Sign In',
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
            ],
          ),
        ),
      ),
    );
  }
}
