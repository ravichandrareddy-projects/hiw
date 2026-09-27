import 'package:flutter/material.dart';
import 'falling_kites.dart';

class SankrantiBackground extends StatelessWidget {
  final Widget child;
  const SankrantiBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🌅 SANKRANTI CLEAN VIBRANT BACKGROUND
        Positioned.fill(
          child: Image.asset(
            'assets/sankranti/sankranti_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),

        // 🪁 LIGHTEST OVERLAY FOR CARD CONTRAST
        Container(
          color: Colors.white.withValues(alpha: 0.08),
        ),

        // 🪁 ANIMATED KITES (Subtle)
        const Positioned.fill(
          child: FallingKites(count: 3),
        ),

        // APP CONTENT
        child,
      ],
    );
  }
}
