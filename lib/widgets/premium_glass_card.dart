import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../themes/hiw_theme.dart';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool isInnerPill; // 🆕 Toggle for the "pill/button" look inside
  final Color? color; // 🆕 Optional custom background color

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.isInnerPill = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);

    // 📄 PLAIN THEME: flat warm-paper card, no blur, no glow.
    if (t.isMinimal && color == null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding ?? EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: t.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: t.cardStroke, width: 1),
          boxShadow: t.cardShadow,
        ),
        child: child,
      );
    }

    // Glass + Greezy: card bg/stroke from theme tokens
    // (warm brown + gold hairline in Greezy, neutral glass elsewhere).
    final bg = color ??
        (isInnerPill
            ? Colors.black.withValues(alpha: 0.3)
            : t.cardBackground);
    final stroke = isInnerPill
        ? Colors.white.withValues(alpha: 0.6)
        : t.cardStroke;
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              // 🎨 BACKGROUND (theme token: warm brown in Greezy)
              color: bg,

              borderRadius: BorderRadius.circular(borderRadius),

              // 💎 BORDER (theme token: gold hairline in Greezy)
              border: Border.all(
                color: stroke,
                width: isInnerPill ? 1.5 : 1.0,
              ),

              // 🔦 SHADOWS & GLOWS
              boxShadow: [
                if (!isInnerPill)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20.r,
                    spreadRadius: 0,
                  ),

                // ✨ INNER GLOW SIMULATION (Top-Left Highlight)
                if (isInnerPill)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    offset: const Offset(-2, -2),
                    blurRadius: 4.r,
                    blurStyle: BlurStyle
                        .inner, // CRITICAL: Makes it look like glass bevel
                  ),
                if (isInnerPill)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(3, 3),
                    blurRadius: 6.r,
                    blurStyle: BlurStyle.inner, // CRITICAL: Depth
                  ),
              ],

              // 🌈 GRADIENT OVERLAY (Subtle reflection)
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isInnerPill ? 0.15 : 0.1),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: isInnerPill ? 0.05 : 0.02),
                ],
                stops: const [0.0, 0.4, 0.6, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
