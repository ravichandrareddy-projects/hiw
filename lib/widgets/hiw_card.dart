import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme_manager.dart';
import '../themes/hiw_theme.dart';

/// The one card widget for the whole app.
///
/// - Plain theme → flat warm-paper card (solid white, warm stroke,
///   soft shadow, zero blur).
/// - Every other theme → blurred glass card driven by [HiwTheme] tokens.
/// - Dev color overrides (DevThemeTools) still apply in glass mode.
class HiwCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;

  const HiwCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final tm = ThemeManager();
    final r = radius ?? t.cardRadius;

    Color bg = t.cardBackground;
    Color border = t.cardStroke;
    if (!t.isMinimal) {
      if (tm.cardColorOverride != null) {
        bg = tm.cardColorOverride!.withValues(alpha: tm.opacityOverride);
        border = tm.cardColorOverride!.withValues(alpha: 0.6);
      } else if (tm.opacityOverride != 0.2) {
        bg = bg.withValues(alpha: tm.opacityOverride);
      }
    }

    final content = Padding(
      padding: padding ?? EdgeInsets.all(16.r),
      child: child,
    );

    if (t.isMinimal) {
      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: border, width: 1),
          boxShadow: t.cardShadow,
        ),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: border, width: 1.w),
            boxShadow: t.cardShadow,
          ),
          child: content,
        ),
      ),
    );
  }
}
