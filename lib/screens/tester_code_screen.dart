import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../services/user_api.dart';
import '../themes/hiw_theme.dart';

class TesterCodeScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const TesterCodeScreen({super.key, required this.onVerified});

  @override
  State<TesterCodeScreen> createState() => _TesterCodeScreenState();
}

class _TesterCodeScreenState extends State<TesterCodeScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _validCodes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    // 🌍 Start waking up the backend immediately
    UserApi.healthCheck();

    try {
      final data = await rootBundle.loadString('assets/tester_codes.txt');
      setState(() {
        _validCodes = data
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading tester codes. Please contact admin.";
        _isLoading = false;
      });
    }
  }

  Future<void> _verify() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Local validity check
      if (!_validCodes.contains(code) &&
          !code.startsWith("DEV-") &&
          code != "HIW-DEV") {
        throw Exception("Invalid tester code. Access Denied.");
      }

      // 2. Instant pass for dev codes
      if (code.startsWith("DEV-") || code == "HIW-DEV") {
        await AppState.setTesterVerified(true);
        await AppState.setLastVerifiedCode(code);
        widget.onVerified();
        return;
      }

      // 3. Fetch user email for backend tracking
      final email = await AppState.getEmail() ?? "tester@hiw.app";

      // 4. Backend check with local fallback on network error/timeout
      try {
        await UserApi.verifyTesterCode(code, email);
      } catch (backendError) {
        final errStr = backendError.toString();
        // If it's already in use, throw
        if (errStr.contains("already in use")) {
          rethrow;
        }
        // If network issue/timeout/server offline, allow local pass since code is in _validCodes
        debugPrint(
            "Backend verify unreachable ($backendError). Proceeding with local verification.");
      }

      await AppState.setTesterVerified(true);
      await AppState.setLastVerifiedCode(code);
      widget.onVerified();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final fieldBorder =
        t.isMinimal ? t.cardStroke : Colors.white.withValues(alpha: 0.2);
    return Scaffold(
      backgroundColor: t.isMinimal ? null : const Color(0xFF0A0E21),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded,
                  size: 80, color: Colors.blueAccent),
              SizedBox(height: 24.h),
              Text(
                'TESTER ACCESS',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: t.inkColor,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Please enter your unique tester code to proceed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.mutedColor),
              ),
              SizedBox(height: 40.h),
              if (_isLoading)
                Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 16.h),
                    Text(
                      'Waking up backend server...\nThis may take 30-60 seconds on first run.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.mutedColor, fontSize: 12.sp),
                    ),
                  ],
                )
              else ...[
                TextField(
                  controller: _controller,
                  style: TextStyle(color: t.inkColor, fontSize: 18.sp),
                  decoration: InputDecoration(
                    hintText: 'Enter Code (e.g. HIW-XXXXX)',
                    hintStyle: TextStyle(color: t.mutedColor),
                    filled: true,
                    fillColor: t.isMinimal
                        ? Colors.black.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: fieldBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    errorText: _error,
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'VERIFY & ENTER',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
