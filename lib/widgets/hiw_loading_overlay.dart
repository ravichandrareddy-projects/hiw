import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

class HIWLoadingOverlay extends StatefulWidget {
  final String statusText;

  const HIWLoadingOverlay({
    super.key,
    this.statusText = 'Analyzing with HIW AI...',
  });

  @override
  State<HIWLoadingOverlay> createState() => _HIWLoadingOverlayState();
}

class _HIWLoadingOverlayState extends State<HIWLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Rotating outer glowing ring
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 140.r,
                    height: 140.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00E676).withOpacity(0.3),
                        width: 3.w,
                      ),
                      gradient: SweepGradient(
                        colors: [
                          const Color(0xFF00E676).withOpacity(0.0),
                          const Color(0xFF00E676),
                          const Color(0xFF00B0FF),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pulsing HIW Cutlery Icon Container
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 90.r,
                    height: 90.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withOpacity(0.4),
                          blurRadius: 20.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF00E676),
                        width: 2.w,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 44.r,
                        color: const Color(0xFF00E676),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'HIW AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.statusText,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
