import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class ChristmasGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const ChristmasGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // 🔥 IMPORTANT: allow snow overflow
      children: [
        // ❄️ SNOW DUST (BEHIND GLASS)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SnowDustPainter(),
            ),
          ),
        ),

        // 🧊 GLASS CARD (CLIPPED)
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: child,
            ),
          ),
        ),

        // ❄️ SNOW CAP (TOP EDGE – OVERFLOW)
        Positioned(
          top: -6, // slight overflow like real snow
          left: 0,
          right: 0,
          height: 36.h,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SnowCapPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/* ================================
   ❄️ SNOW DUST INSIDE CARD
================================ */
class _SnowDustPainter extends CustomPainter {
  final Random _rnd = Random(99);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.22);

    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(
          _rnd.nextDouble() * size.width,
          _rnd.nextDouble() * size.height,
        ),
        _rnd.nextDouble() * 1.6 + 0.4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/* ================================
   ❄️ SNOW CAP ON TOP EDGE
================================ */
class _SnowCapPainter extends CustomPainter {
  final Random _rnd = Random(7);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.98);

    for (int i = 0; i < 32; i++) {
      canvas.drawCircle(
        Offset(
          _rnd.nextDouble() * size.width,
          _rnd.nextDouble() * size.height,
        ),
        _rnd.nextDouble() * 3.0 + 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
