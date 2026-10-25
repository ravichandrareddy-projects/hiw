// lib/widgets/reminder_animated_badges.dart — Lightweight, isolated animations for reminder cards.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 💧 Animated Water Ripple/Wave Badge
class WaterRippleVisual extends StatefulWidget {
  final bool active;
  final Color color;
  const WaterRippleVisual({
    super.key,
    required this.active,
    this.color = const Color(0xFF0EA5E9),
  });

  @override
  State<WaterRippleVisual> createState() => _WaterRippleVisualState();
}

class _WaterRippleVisualState extends State<WaterRippleVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WaterRippleVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: widget.active ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WaterWavePainter(
                progress: widget.active ? _controller.value : 0.0,
                color: widget.color,
                isActive: widget.active,
              ),
              child: Center(
                child: Icon(
                  Icons.water_drop_rounded,
                  color: widget.active ? widget.color : widget.color.withValues(alpha: 0.4),
                  size: 22.sp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isActive;

  _WaterWavePainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final radius = (size.width / 2.2) * (0.6 + 0.4 * progress);
    final alpha = (1.0 - progress) * 0.4;
    paint.color = color.withValues(alpha: alpha);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isActive != isActive;
}

/// 🍽️ Animated Food Steam / Warmth Badge
class FoodSteamVisual extends StatefulWidget {
  final bool active;
  final Color color;
  const FoodSteamVisual({
    super.key,
    required this.active,
    this.color = const Color(0xFFF97316),
  });

  @override
  State<FoodSteamVisual> createState() => _FoodSteamVisualState();
}

class _FoodSteamVisualState extends State<FoodSteamVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FoodSteamVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: widget.active ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final shift = widget.active ? math.sin(_controller.value * math.pi) * 3 : 0.0;
            return Center(
              child: Transform.translate(
                offset: Offset(0, -shift),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: widget.active ? widget.color : widget.color.withValues(alpha: 0.4),
                  size: 22.sp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 🔥 Animated Streak Flame Badge
class StreakFlameVisual extends StatefulWidget {
  final bool active;
  final Color color;
  const StreakFlameVisual({
    super.key,
    required this.active,
    this.color = const Color(0xFFEF4444),
  });

  @override
  State<StreakFlameVisual> createState() => _StreakFlameVisualState();
}

class _StreakFlameVisualState extends State<StreakFlameVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StreakFlameVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: widget.active ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = widget.active ? 1.0 + (_controller.value * 0.15) : 1.0;
            return Center(
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: widget.active ? widget.color : widget.color.withValues(alpha: 0.4),
                  size: 22.sp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 🥗 Animated Nutrition Leaf Badge
class NutritionLeafVisual extends StatefulWidget {
  final bool active;
  final Color color;
  const NutritionLeafVisual({
    super.key,
    required this.active,
    this.color = const Color(0xFF10B981),
  });

  @override
  State<NutritionLeafVisual> createState() => _NutritionLeafVisualState();
}

class _NutritionLeafVisualState extends State<NutritionLeafVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NutritionLeafVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: widget.active ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final rotation = widget.active ? math.sin(_controller.value * math.pi) * 0.12 : 0.0;
            return Center(
              child: Transform.rotate(
                angle: rotation,
                child: Icon(
                  Icons.energy_savings_leaf_rounded,
                  color: widget.active ? widget.color : widget.color.withValues(alpha: 0.4),
                  size: 22.sp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
