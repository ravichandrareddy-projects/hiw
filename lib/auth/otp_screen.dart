// lib/auth/otp_screen.dart — 6-box code entry (mock: 123456).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../core/auth_service.dart';
import '../themes/hiw_theme.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onDone;
  const OtpScreen({super.key, required this.email, this.onDone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_ctrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user =
          await AuthService().verifyOtp(widget.email, _ctrl.text);
      await AppState.setLoggedIn(true);
      await AppState.setEmail(user.email);
      await AppState.setUsername(user.username);
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check your email.',
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Code sent to ${widget.email}',
                style:
                    TextStyle(color: t.mutedColor, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.inkColor,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8.w,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: TextStyle(color: t.mutedColor),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: t.cardStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                        color: t.accentColor, width: 2),
                  ),
                ),
                onSubmitted: (_) => _verify(),
              ),
              SizedBox(height: 6.h),
              Center(
                child: Text(
                  'Demo code: 123456',
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 12.sp),
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
              const Spacer(),
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
                  onPressed: _busy ? null : _verify,
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
                          'Verify',
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
