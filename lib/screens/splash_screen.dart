import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_state.dart';
import '../themes/hiw_theme.dart';

/// HIW liquid intro:
/// - H + W in dark green with a liquid highlight that flows down,
///   reverses up, and repeats until both letters stand filled.
/// - I in water blue drops from the top once the flow completes.
/// - Total time comes from Settings → Intro timing (1–10s, TEMPORARY).
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const leafGreen = Color(0xFF0B6B3A);
  static const waterBlue = Color(0xFF00B0FF);

  /// Number of down-up liquid passes before the letters settle.
  static const flowPasses = 5;

  AnimationController? _master;
  Timer? _timer;
  bool _done = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // TEMPORARY timing setting: load user-tested seconds, default 5.
    AppState.getSplashSeconds().then((s) {
      if (!mounted || _started) return;
      _start(Duration(seconds: s));
    });
    // Safety: never strand the user on the splash if prefs hang.
    Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _started) return;
      _start(const Duration(seconds: 5));
    });
  }

  void _start(Duration total) {
    _started = true;
    _master = AnimationController(vsync: this, duration: total)..forward();
    _timer = Timer(total, _finish);
    setState(() {});
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _master?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final master = _master;
    // Dark-green flow on light stages, bright leaf-green on dark ones
    // (Greezy/night) so the liquid stays readable everywhere.
    final isDarkStage =
        Theme.of(context).brightness == Brightness.dark;
    final flowGreen =
        isDarkStage ? const Color(0xFF2ECC71) : leafGreen;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish, // tap to skip
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: master == null
              ? Text(
                  'HIW',
                  style: TextStyle(
                    fontSize: 84.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.w,
                    color: t.inkColor,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _FlowLetter(
                          master: master,
                          letter: 'H',
                          base: flowGreen,
                        ),
                        // I falls into the CENTER between H and W.
                        _DropLetter(
                          master: master,
                          letter: 'I',
                          base: waterBlue,
                        ),
                        _FlowLetter(
                          master: master,
                          letter: 'W',
                          base: flowGreen,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: master,
                          curve:
                              const Interval(0.8, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: Text(
                        'HEALTH IS WEALTH',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4.w,
                          color: t.mutedColor,
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

/// A letter with liquid highlight flowing down then back up,
/// repeating [SplashScreen.flowPasses] times while H+W form together.
/// The I drops into the center BEFORE the flow completes, so all
/// three letters synchronize into H I W as one motion.
class _FlowLetter extends StatelessWidget {
  final Animation<double> master;
  final String letter;
  final Color base;

  const _FlowLetter({
    required this.master,
    required this.letter,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: master,
      builder: (context, _) {
        // 0→0.85: H+W flow passes (down → reverse up, repeated).
        // The I starts dropping at 0.45, mid-flow.
        final phase = (master.value / 0.85).clamp(0.0, 1.0);
        final cycles = phase * _SplashScreenState.flowPasses;
        final frac = cycles - cycles.floor();
        // Triangle wave: 0→1→0 per pass.
        final p = frac < 0.5 ? frac * 2 : (1 - frac) * 2;
        const band = 0.28;
        final stops = [
          (p - band).clamp(0.0, 1.0),
          p.clamp(0.0, 1.0),
          (p + band).clamp(0.0, 1.0),
        ];
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              base,
              _lighten(base),
              base,
            ],
            stops: stops,
          ).createShader(bounds),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 84.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.w,
              color: base,
              height: 1.0,
            ),
          ),
        );
      },
    );
  }

  Color _lighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0))
        .toColor();
  }
}

/// I drops from the top WHILE H+W are still completing (starts at 0.45),
/// lands in the exact center, and settles with them into H I W.
class _DropLetter extends StatelessWidget {
  final Animation<double> master;
  final String letter;
  final Color base;

  const _DropLetter({
    required this.master,
    required this.letter,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    final drop = Tween<Offset>(
      begin: const Offset(0, -2.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutBack),
      ),
    );
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.45, 0.55, curve: Curves.easeIn),
      ),
    );
    // Gentle settle wobble as all three letters land together.
    final wobble = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.8, 0.95, curve: Curves.easeOut),
      ),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: drop,
        child: AnimatedBuilder(
          animation: wobble,
          builder: (context, child) {
            final w = math.sin(wobble.value * math.pi) * 0.06;
            return Transform.translate(
              offset: Offset(0, -w * 20),
              child: child,
            );
          },
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 84.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.w,
              color: base,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
