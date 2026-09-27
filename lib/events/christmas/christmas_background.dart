import 'package:flutter/material.dart';
import 'falling_snow.dart';

class ChristmasBackground extends StatelessWidget {
  final Widget child;
  const ChristmasBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🌌 WINTER NIGHT GRADIENT
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B132B),
                Color(0xFF1C2541),
                Color(0xFF243B6B),
              ],
            ),
          ),
        ),

        // 🌲 TREES (DARKENED)
        Positioned.fill(
          child: Image.asset(
            'assets/christmas/trees.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            color: Colors.black.withValues(alpha: 0.35),
            colorBlendMode: BlendMode.darken,
          ),
        ),

        // ❄️ BACK SNOW (IGNORE TOUCH)
        const Positioned.fill(
          child: IgnorePointer(
            child: FallingSnow(flakes: 30),
          ),
        ),

        // APP CONTENT
        child,

        // ❄️ FRONT SNOW (IGNORE TOUCH — FIXES BUTTON)
        const Positioned.fill(
          child: IgnorePointer(
            child: FallingSnow(flakes: 25),
          ),
        ),
      ],
    );
  }
}
