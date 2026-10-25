import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../themes/hiw_theme.dart';

/// Clean Minimalist HIW Intro:
/// - 0.0s - 1.0s: App logo is in exact center (matching native launch size 90x90)
/// - 1.0s - 1.8s: Logo glides upward slowly and smoothly using easeInOutCubic (no jiggle/shake)
/// - 1.4s - 2.0s: H - I - W letters gently ease in directly under logo
/// - 1.9s - 2.4s: "HEALTH IS" fades in smoothly
/// - 2.3s - 3.7s: Tumbler slides: WEALTH ↑ -> WISDOM ↑ -> WELLNESS ↑ -> WIN 🏆
/// - 3.7s - 4.6s: WIN 🏆 rests settled in gold
/// - 4.6s - 5.0s: Clean, smooth fade exit into main app (zero side-slide lag)
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _master;
  late AnimationController _wordController;

  static const List<String> _wWords = ['Wealth', 'Wisdom', 'Wellness', 'WIN'];
  int _wordIndex = 0;
  Timer? _wordCycleTimer;
  Timer? _totalTimer;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    // 5.0-second smooth total timeline
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _wordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _master.forward();

    // Start cycling words at 2.3s so WIN settles by 3.6s
    Timer(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      _cycleNextWord();
    });

    // Auto finish at 5.0s
    _totalTimer = Timer(const Duration(milliseconds: 5000), _finish);
  }

  void _cycleNextWord() {
    if (!mounted || _done) return;

    if (_wordIndex < _wWords.length - 1) {
      _wordController.forward(from: 0.0).then((_) {
        _wordCycleTimer = Timer(const Duration(milliseconds: 220), () {
          if (!mounted || _done) return;
          setState(() {
            _wordIndex++;
          });
          _cycleNextWord();
        });
      });
    } else {
      // Final word: "WIN 🏆" settles cleanly and stays visible
      _wordController.forward(from: 0.0);
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _totalTimer?.cancel();
    _wordCycleTimer?.cancel();
    _master.dispose();
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // Palette harmonized with active theme
    final hColor = isDark ? const Color(0xFF00E676) : const Color(0xFF0B6B3A);
    final iColor = isDark ? const Color(0xFF00B0FF) : const Color(0xFF0288D1);
    final wColor = isDark ? const Color(0xFFFF9100) : const Color(0xFFE86A1D);
    final winGold = isDark ? const Color(0xFFFFD700) : const Color(0xFFD49B00);
    final mutedColor = t.mutedColor;

    // Timeline Intervals:
    // 1. Logo holds at center 0.0s - 1.0s (0.00 -> 0.20)
    //    Then glides upward slowly & smoothly 1.0s - 1.8s (0.20 -> 0.36)
    //    Using Curves.easeInOutCubic so it starts and stops like silk, no bounce/jiggle
    final logoMoveAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.20, 0.36, curve: Curves.easeInOutCubic),
    );

    // 2. Letters gently ease in below logo: 1.35s - 2.0s (0.27 -> 0.40)
    final lettersFadeAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.27, 0.38, curve: Curves.easeIn),
    );
    final lettersMoveAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.27, 0.40, curve: Curves.easeOutCubic),
    );

    // 3. Subtitle sentence entrance: 1.85s - 2.4s (0.37 -> 0.48)
    final subAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.37, 0.48, curve: Curves.easeOut),
    );

    // 4. Smooth, buttery fade out into the main screen: 4.65s - 5.0s (0.93 -> 1.00)
    final exitFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.93, 1.00, curve: Curves.easeIn),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish, // tap to skip immediately
      child: Scaffold(
        backgroundColor: bgColor,
        body: AnimatedBuilder(
          animation: exitFade,
          builder: (context, child) {
            return Opacity(
              opacity: (1.0 - exitFade.value).clamp(0.0, 1.0),
              child: child,
            );
          },
          child: Center(
            child: AnimatedBuilder(
              animation: logoMoveAnim,
              builder: (context, child) {
                // At 0.0 (first second), shiftY = 70.h putting the logo in dead center
                // As it progresses to 1.0, it glides up smoothly to its final position
                final shiftY = (1.0 - logoMoveAnim.value) * 70.h;
                return Transform.translate(
                  offset: Offset(0, shiftY),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 1. App Logo: 90x90 matching native launch image pixel-for-pixel ──
                  SizedBox(
                    width: 90.w,
                    height: 90.w,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // ── 2. Pure Typography H - I - W (Gently glides in below logo) ──
                  FadeTransition(
                    opacity: lettersFadeAnim,
                    child: AnimatedBuilder(
                      animation: lettersMoveAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, (1.0 - lettersMoveAnim.value) * 18.h),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          _buildCleanLetter('H', hColor),
                          SizedBox(width: 6.w),
                          _buildCleanLetter('I', iColor),
                          SizedBox(width: 6.w),
                          _buildCleanLetter('W', wColor),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // ── 3. Subtitle Row: HEALTH IS [TUMBLER] ──
                  FadeTransition(
                    opacity: subAnim,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'HEALTH',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5.w,
                            color: hColor,
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Text(
                          'IS',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5.w,
                            color: iColor,
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Tumbler: Clean rounded pill badge
                        Container(
                          height: 32.h,
                          constraints: BoxConstraints(minWidth: 105.w),
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: _wordIndex == _wWords.length - 1
                                  ? winGold.withValues(alpha: 0.7)
                                  : wColor.withValues(alpha: 0.25),
                              width: 1.4,
                            ),
                            boxShadow: _wordIndex == _wWords.length - 1
                                ? [
                                    BoxShadow(
                                      color: winGold.withValues(alpha: 0.25),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: ClipRect(
                            child: AnimatedBuilder(
                              animation: _wordController,
                              builder: (context, _) {
                                final isFinal =
                                    _wordIndex == _wWords.length - 1;
                                final currentWord = _wWords[_wordIndex];

                                double translateY = 0.0;
                                double opacity = 1.0;

                                if (isFinal) {
                                  // "WIN 🏆" settles cleanly in center and holds
                                  final val = Curves.easeOutCubic
                                      .transform(_wordController.value);
                                  translateY = (1.0 - val) * 12.h;
                                  opacity = _wordController.value.clamp(0.0, 1.0);
                                } else {
                                  final v = _wordController.value;
                                  if (v < 0.5) {
                                    final p = v / 0.5;
                                    translateY = (1.0 -
                                            Curves.easeOutCubic.transform(p)) *
                                        18.h;
                                    opacity = p;
                                  } else {
                                    final p = (v - 0.5) / 0.5;
                                    translateY =
                                        -Curves.easeInCubic.transform(p) * 18.h;
                                    opacity = 1.0 - p;
                                  }
                                }

                                return Transform.translate(
                                  offset: Offset(0, translateY),
                                  child: Opacity(
                                    opacity: opacity.clamp(0.0, 1.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currentWord.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.w,
                                            color: isFinal ? winGold : wColor,
                                          ),
                                        ),
                                        if (isFinal) ...[
                                          SizedBox(width: 4.w),
                                          Text(
                                            '🏆',
                                            style: TextStyle(fontSize: 13.sp),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 38.h),

                  // ── 4. Subtle tap prompt ──
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _master,
                      curve: const Interval(0.48, 0.65, curve: Curves.easeIn),
                    ),
                    child: Text(
                      'tap to enter',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5.w,
                        color: mutedColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanLetter(String letter, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 66.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 2.w,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
