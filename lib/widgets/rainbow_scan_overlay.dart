// lib/widgets/rainbow_scan_overlay.dart
// Analyzing state: captured photo in a clean SQUARE card, wrapped in a
// SLOW-ROTATING rainbow ring with an orbiting glow spark, over slow
// rotating rainbow smoke. Recognition keeps running untouched — the
// rainbow is UI-only, driven by two lightweight animation controllers.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const List<Color> _kRainbow = [
  Color(0xFFEF5350),
  Color(0xFFFFB74D),
  Color(0xFFFFEE58),
  Color(0xFF66BB6A),
  Color(0xFF42A5F5),
  Color(0xFFAB47BC),
];

class RainbowScanOverlay extends StatefulWidget {
  final String statusText;
  final ImageProvider? image;
  final String? title;
  final String? categoryLabel;
  final Widget? customContent;

  const RainbowScanOverlay({
    super.key,
    required this.statusText,
    this.image,
    this.title,
    this.categoryLabel,
    this.customContent,
  });

  @override
  State<RainbowScanOverlay> createState() => _RainbowScanOverlayState();
}

class _RainbowScanOverlayState extends State<RainbowScanOverlay>
    with TickerProviderStateMixin {
  late AnimationController _ring;
  late AnimationController _smoke;

  @override
  void initState() {
    super.initState();
    // Rainbow ring + orbiting spark — one slow rotation.
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    // Rainbow smoke behind the card — even slower, reversed for drift.
    _smoke = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    _smoke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF141013),
            Color(0xFF1E2A4A),
            Color(0xFF3A1E4A),
            Color(0xFF4A2E1E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // ── Slow rainbow smoke (full screen, subdued) ──
          Positioned.fill(
            child: RotationTransition(
              turns: _smoke,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x2BEF5350),
                      Color(0x00FFFFFF),
                      Color(0x2BFFB74D),
                      Color(0x00FFFFFF),
                      Color(0x2BFFEE58),
                      Color(0x00FFFFFF),
                      Color(0x2B66BB6A),
                      Color(0x00FFFFFF),
                      Color(0x2B42A5F5),
                      Color(0x00FFFFFF),
                      Color(0x2BAB47BC),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Photo card + rotating rainbow ring + orbit spark ──
                SizedBox(
                  width: 344.w,
                  height: 344.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Slow conic rainbow ring hugging the card corners.
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _ring,
                          builder: (ctx, _) => CustomPaint(
                            painter: _RainbowRingPainter(
                              angle: _ring.value * 2 * math.pi,
                            ),
                          ),
                        ),
                      ),
                      // Orbiting glow spark on the ring.
                      Positioned.fill(
                        child: RotationTransition(
                          turns: _ring,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 10.w,
                              height: 10.w,
                              margin: EdgeInsets.only(bottom: 2.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: _kRainbow.first
                                        .withValues(alpha: 0.9),
                                    blurRadius: 14.r,
                                    spreadRadius: 3.r,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ── SQUARE photo card (sharp, untouched) ──
                      Container(
                        width: 300.w,
                        height: 300.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 30.r,
                              spreadRadius: 2.r,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26.r),
                          child: widget.image != null
                              ? Image(
                                  image: widget.image!,
                                  fit: BoxFit.cover,
                                )
                              : widget.customContent != null
                                  ? widget.customContent!
                                  : Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.16),
                                            Colors.white.withValues(alpha: 0.06),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(16.r),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.14),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.restaurant_menu_rounded,
                                              size: 46.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          Text(
                                            widget.title ?? 'Analyzing Food',
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 19.sp,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          if (widget.categoryLabel != null &&
                                              widget.categoryLabel!.isNotEmpty) ...[
                                            SizedBox(height: 10.h),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w, vertical: 5.h),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(14.r),
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Text(
                                                widget.categoryLabel!,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),
                // ── Slow rainbow conic spinner ──
                SizedBox(
                  width: 54.w,
                  height: 54.w,
                  child: RotationTransition(
                    turns: _ring,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 4.w,
                        ),
                        gradient: const SweepGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            ..._kRainbow,
                            Color(0xE6FFFFFF),
                          ],
                          stops: [0.0, 0.32, 0.46, 0.60, 0.74, 0.86, 0.96, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  widget.statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stroke rounded-rect painted with a slowly rotating conic rainbow.
/// One tiny layer, repaint listenable — negligible cost during recognition.
class _RainbowRingPainter extends CustomPainter {
  final double angle;
  _RainbowRingPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final hw = size.width / 2 - 4;
    final hh = size.height / 2 - 4;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: hw * 2,
        height: hh * 2,
      ),
      const Radius.circular(32),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = SweepGradient(
        colors: const [
          Color(0x00FFFFFF),
          ..._kRainbow,
          Color(0xDFFFFFFF),
        ],
        stops: const [0.0, 0.32, 0.46, 0.60, 0.74, 0.86, 0.96, 1.0],
        transform: GradientRotation(angle),
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RainbowRingPainter old) => old.angle != angle;
}
