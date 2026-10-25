// lib/themes/hiw_gold.dart — Unified luxury metallic champagne gold design system for HIW Pro.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HiwGold {
  // 🎨 Gold Color Palette
  static const Color champagneLight = Color(0xFFFFF7D6);
  static const Color shimmerLight = Color(0xFFFFF2A8);
  static const Color brightGold = Color(0xFFFFDF70);
  static const Color metallicGold = Color(0xFFFFD700);
  static const Color warmGold = Color(0xFFF59E0B);
  static const Color deepGold = Color(0xFFD97706);
  static const Color bronzeGold = Color(0xFFB45309);

  // Backgrounds & Surfaces
  static const Color cardBgLight = Color(0xFFFFFDF5);
  static const Color cardBgDark = Color(0xFF1E1705);
  static const Color borderLight = Color(0xFFF6C343);
  static const Color borderDark = Color(0xFF785108);

  // 🌈 Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [
      Color(0xFFFFFAEB),
      Color(0xFFFFD700),
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
    stops: [0.0, 0.35, 0.75, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldBorderGradient = LinearGradient(
    colors: [
      Color(0xFFFFF9DB),
      Color(0xFFFFD700),
      Color(0xFFF59E0B),
      Color(0xFFB45309),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFFFFE066),
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient badgeGradient = LinearGradient(
    colors: [
      Color(0xFFFFF3B0),
      Color(0xFFF59E0B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌟 Ambient Glow Shadows
  static BoxShadow haloGlow({
    double blur = 16,
    double spread = 1,
    double opacity = 0.45,
  }) {
    return BoxShadow(
      color: metallicGold.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: spread,
    );
  }

  static BoxShadow subtleGlow({
    double blur = 10,
    double opacity = 0.25,
  }) {
    return BoxShadow(
      color: warmGold.withValues(alpha: opacity),
      blurRadius: blur,
      offset: const Offset(0, 3),
    );
  }

  /// Luxury PRO pill badge
  static Widget proPill({
    String label = 'PRO',
    bool showCrown = true,
    double fontSize = 10,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: badgeGradient,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderLight, width: 1.w),
        boxShadow: [
          subtleGlow(blur: 6, opacity: 0.35),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCrown) ...[
            Text('👑', style: TextStyle(fontSize: (fontSize - 1).sp)),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF3B1E00),
              fontSize: fontSize.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Pro Member Banner / Pill for profile & header cards
  static Widget proMemberTag({double fontSize = 11}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFBEB),
            Color(0xFFFEF3C7),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: warmGold, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: warmGold.withValues(alpha: 0.25),
            blurRadius: 8.r,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👑', style: TextStyle(fontSize: fontSize.sp)),
          SizedBox(width: 5.w),
          Text(
            'PRO MEMBER',
            style: TextStyle(
              color: const Color(0xFF78350F),
              fontSize: fontSize.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
