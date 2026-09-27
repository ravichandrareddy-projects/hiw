// lib/widgets/rainbow_scan_overlay.dart
// Analyzing state: captured photo in a clean SQUARE card over a static
// rainbow-tinted backdrop, with the classic lightweight rotation spinner
// + status below. No per-frame painters — zero jank during recognition.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../themes/hiw_theme.dart';

class RainbowScanOverlay extends StatefulWidget {
  final String statusText;
  final ImageProvider? image;
  const RainbowScanOverlay({super.key, required this.statusText, this.image});

  @override
  State<RainbowScanOverlay> createState() => _RainbowScanOverlayState();
}

class _RainbowScanOverlayState extends State<RainbowScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);

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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    : Container(
                        color: Colors.white10,
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 64.sp,
                          color: Colors.white54,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 28.h),
            // ── Classic rotation spinner ──
            RotationTransition(
              turns: _spin,
              child: Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        t.accentColor.withValues(alpha: 0.25),
                    width: 4.w,
                  ),
                  gradient: SweepGradient(
                    colors: [
                      t.accentColor.withValues(alpha: 0.0),
                      t.accentColor,
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              widget.statusText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
