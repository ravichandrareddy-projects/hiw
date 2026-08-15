import 'package:flutter/material.dart';
import '../core/theme_manager.dart';

class PlainBackground extends StatelessWidget {
  final Widget child;
  const PlainBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager();
    final bgColor = tm.backgroundColorOverride ?? const Color(0xFFF7F9FC);

    return Container(
      color: bgColor,
      child: child,
    );
  }
}
