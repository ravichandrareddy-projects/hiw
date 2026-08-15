//glass card
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme_manager.dart'; // 🆕

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    // final isDark = Theme.of(context).brightness == Brightness.dark; // unused
    final primaryColor = Theme.of(context).primaryColor;
    final tm = ThemeManager(); // Singleton
    
    // 🎨 DYNAMIC GLASS STYLE BASED ON TIME
    Color glassColor;
    double blur = 10;
    Color borderColor;
    List<BoxShadow> shadows = [];
    bool showSnow = false;

    // 🎄 FESTIVE & THEME OVERRIDES (TOP PRIORITY)
    if (tm.currentThemeName == 'plain' || primaryColor == const Color(0xFF10B981)) {
      // Plain Theme Style - Clean solid light cards with crisp border & shadow
      glassColor = Colors.white;
      blur = 0; // Crisp non-blurred background
      borderColor = const Color(0xFFE5E7EB);
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10.r,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (primaryColor == Colors.redAccent) {
      // Christmas Theme Style - Deeper Night Vibe
      glassColor = Colors.black.withOpacity(0.4);
      blur = 20;
      borderColor = Colors.white.withOpacity(0.3); // Increased visibility
      showSnow = false;
    } else if (primaryColor == Colors.deepOrange) {
      // Sankranti Theme Style
      glassColor = Colors.white.withOpacity(0.15);
      blur = 15;
      borderColor = Colors.orange.withOpacity(0.5); // Increased visibility
    } else {
      // ⏳ DYNAMIC DEFAULT THEME (BASED ON TIME)
      if (hour >= 5 && hour < 12) {
        // 🌅 Morning: White frosted glass, high blur
        glassColor = Colors.white.withOpacity(0.12);
        blur = 15;
        borderColor = Colors.white.withOpacity(0.4);
      } else if (hour >= 12 && hour < 17) {
        // ☀️ Afternoon: Warm white glass, medium blur
        glassColor = Colors.white.withOpacity(0.15);
        blur = 10;
        borderColor = Colors.black12.withOpacity(0.2);
      } else if (hour >= 17 && hour < 20) {
        // 🌇 Evening: Amber-tinted glass with sunset glow
        glassColor = const Color(0xFFE64A19).withOpacity(0.15);
        blur = 15;
        borderColor = const Color(0xFFFFCC80).withOpacity(0.4);
        shadows = [
          BoxShadow(
            color: const Color(0xFFE64A19).withOpacity(0.2),
            blurRadius: 15.r,
            spreadRadius: 2.r,
          ),
        ];
      } else {
        // 🌙 Night: Dark glass with subtle neon glow
        glassColor = Colors.black.withOpacity(0.4);
        blur = 20;
        borderColor = primaryColor.withOpacity(0.4); // Visible border
        shadows = [
           BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 12.r, spreadRadius: 1.r),
        ];
      }
    }

    // 🛠️ APPLY DEV OVERRIDES (Force Border Visibility)
    // If user set a custom card color, use it as tint
    if (tm.cardColorOverride != null) {
       glassColor = tm.cardColorOverride!.withOpacity(tm.opacityOverride);
       borderColor = tm.cardColorOverride!.withOpacity(0.6); // Strong border based on choice
    } else if (tm.opacityOverride != 0.2) {
       // Only opacity changed
       glassColor = glassColor.withOpacity(tm.opacityOverride);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: 1.w,
            ),
            boxShadow: shadows,
          ),
          child: Stack(
            children: [
              Padding(
                padding: padding ?? EdgeInsets.all(16.r),
                child: child,
              ),
              if (showSnow)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    painter: _CardSnowPainter(),
                    size: const Size(double.infinity, 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSnowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, 8);
    
    // Wave pattern for "stuck snow"
    for (double i = size.width; i >= 0; i -= 8) {
      path.lineTo(i, 4 + (i % 16 < 8 ? 4 : 0));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
