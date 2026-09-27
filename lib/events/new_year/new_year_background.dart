import 'package:flutter/material.dart';
import 'fireworks_animation.dart';

class NewYearBackground extends StatelessWidget {
  final Widget child;
  const NewYearBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🎆 NEW YEAR NIGHT-SKY GRADIENT
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E), // Deep Space Blue
                Color(0xFF2D1B36), // Deep Purple
                Color(0xFF4A148C), // Royal Purple
              ],
            ),
          ),
        ),

        // 🎇 FULL-COLOR CELEBRATORY BACKGROUND
        Positioned.fill(
          child: Image.asset(
            'assets/new_year/new_year_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),

        // 🎇 ANIMATED FIREWORKS ON TOP
        const Positioned.fill(
          child: FireworksAnimation(),
        ),

        // APP CONTENT
        child,
      ],
    );
  }
}
