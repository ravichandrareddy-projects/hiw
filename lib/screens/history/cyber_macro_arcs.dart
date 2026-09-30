import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/premium_glass_card.dart';
import '../../themes/hiw_theme.dart';

class CyberMacroArcs extends StatefulWidget {
  final double calories;
  final double calGoal;
  final double protein;
  final double proteinGoal;
  final double carbs;
  final double carbsGoal;
  final double fats;
  final double fatsGoal;
  final double healthyPercent;
  final VoidCallback? onTap;

  const CyberMacroArcs({
    super.key,
    required this.calories,
    this.calGoal = 2000.0,
    required this.protein,
    this.proteinGoal = 120.0,
    required this.carbs,
    this.carbsGoal = 250.0,
    required this.fats,
    this.fatsGoal = 65.0,
    required this.healthyPercent,
    this.onTap,
  });

  @override
  State<CyberMacroArcs> createState() => _CyberMacroArcsState();
}

class _CyberMacroArcsState extends State<CyberMacroArcs>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant CyberMacroArcs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calories != widget.calories ||
        oldWidget.protein != widget.protein ||
        oldWidget.healthyPercent != widget.healthyPercent) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    final trackColor = t.isMinimal
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.06);
    return GestureDetector(
      onTap: widget.onTap,
      child: PremiumGlassCard(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // 🛡️ HEADER BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: accent,
                              blurRadius: 6,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "MACRO COMMAND CENTER",
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: (widget.healthyPercent >= 50
                            ? Colors.greenAccent
                            : Colors.orangeAccent)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: (widget.healthyPercent >= 50
                              ? Colors.greenAccent
                              : Colors.orangeAccent)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    "${widget.healthyPercent.toInt()}% HEALTHY",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: widget.healthyPercent >= 50
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 🌀 ARC GAUGES CENTER PIECE
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, child) {
                return SizedBox(
                  width: 210.w,
                  height: 210.h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(210.w, 210.h),
                        painter: _CyberArcsPainter(
                          trackColor: trackColor,
                          calRatio: (widget.calories / widget.calGoal)
                                  .clamp(0.0, 1.0) *
                              _progressAnim.value,
                          protRatio: (widget.protein / widget.proteinGoal)
                                  .clamp(0.0, 1.0) *
                              _progressAnim.value,
                          carbsRatio: (widget.carbs / widget.carbsGoal)
                                  .clamp(0.0, 1.0) *
                              _progressAnim.value,
                          fatsRatio:
                              (widget.fats / widget.fatsGoal).clamp(0.0, 1.0) *
                                  _progressAnim.value,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${widget.calories.toInt()}",
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              color: t.inkColor,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color:
                                      accent.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "KCAL CONSUMED",
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: t.mutedColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: t.isMinimal
                                  ? Colors.black.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              "Goal: ${widget.calGoal.toInt()} kcal",
                              style: TextStyle(
                                  fontSize: 10.sp, color: accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 16.h),

            // 📊 MINI MACRO STATS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroPill(
                  label: "PROTEIN",
                  value: "${widget.protein.toInt()}g",
                  color: const Color(0xFF00E5FF),
                ),
                _buildMacroPill(
                  label: "CARBS",
                  value: "${widget.carbs.toInt()}g",
                  color: const Color(0xFFFFB300),
                ),
                _buildMacroPill(
                  label: "FATS",
                  value: "${widget.fats.toInt()}g",
                  color: const Color(0xFFFF4081),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: HiwTheme.of(context).inkColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberArcsPainter extends CustomPainter {
  final double calRatio;
  final double protRatio;
  final double carbsRatio;
  final double fatsRatio;
  final Color trackColor;

  _CyberArcsPainter({
    required this.calRatio,
    required this.protRatio,
    required this.carbsRatio,
    required this.fatsRatio,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Track 1: Outer Calorie Arc (Cyan/Emerald)
    _drawArcTrack(canvas, center,
        radius: 95.r,
        strokeWidth: 10.r,
        ratio: calRatio,
        colors: [const Color(0xFF00F5D4), const Color(0xFF00BBF9)]);

    // Track 2: Protein Arc (Neon Purple)
    _drawArcTrack(canvas, center,
        radius: 78.r,
        strokeWidth: 8.r,
        ratio: protRatio,
        colors: [const Color(0xFF7B2CBF), const Color(0xFF9D4EDD)]);

    // Track 3: Carbs Arc (Amber/Yellow)
    _drawArcTrack(canvas, center,
        radius: 63.r,
        strokeWidth: 7.r,
        ratio: carbsRatio,
        colors: [const Color(0xFFFFB703), const Color(0xFFFB8500)]);

    // Track 4: Fats Arc (Pink/Rose)
    _drawArcTrack(canvas, center,
        radius: 50.r,
        strokeWidth: 6.r,
        ratio: fatsRatio,
        colors: [const Color(0xFFFF007F), const Color(0xFFFF5400)]);
  }

  void _drawArcTrack(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double strokeWidth,
    required double ratio,
    required List<Color> colors,
  }) {
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (ratio <= 0) return;

    final sweepAngle = (2 * pi) * ratio;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        startAngle: 0,
        endAngle: 2 * pi,
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _CyberArcsPainter oldDelegate) {
    return oldDelegate.calRatio != calRatio ||
        oldDelegate.protRatio != protRatio ||
        oldDelegate.carbsRatio != carbsRatio ||
        oldDelegate.fatsRatio != fatsRatio ||
        oldDelegate.trackColor != trackColor;
  }
}
