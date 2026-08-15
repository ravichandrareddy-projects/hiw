import 'package:flutter/material.dart';
import '../core/theme_manager.dart'; // 🆕
import 'christmas/christmas_background.dart';
import 'sankranti/sankranti_background.dart';
import 'plain_background.dart';
import 'time_animations.dart';

class EventManager {
  static Widget wrapWithBackground(String theme, Widget child) {
    switch (theme) {
      case 'plain':
        return PlainBackground(child: child);
      case 'christmas':
        return ChristmasBackground(child: child);
      case 'sankranti':
        return SankrantiBackground(child: child);
      default:
        return DefaultBackground(child: child);
    }
  }
}

class DefaultBackground extends StatelessWidget {
  final Widget child;
  const DefaultBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final tm = ThemeManager(); // Singleton
    
    // 🎨 DEFINE BASE GRADIENTS
    List<Color> baseColors;
    Widget? animation;

    if (hour >= 5 && hour < 12) {
      // Morning
      baseColors = [const Color(0xFFB3E5FC), const Color(0xFFE1F5FE)];
      animation = MorningWind(key: const ValueKey('morning'));
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      baseColors = [const Color(0xFFFFF9C4), const Color(0xFFFFECB3)];
      animation = AfternoonSun(key: const ValueKey('afternoon'));
    } else if (hour >= 17 && hour < 20) {
      // Evening
      baseColors = [const Color(0xFFFF8A65), const Color(0xFFBF360C)];
      animation = EveningSunset(key: const ValueKey('evening'));
    } else {
      // Night
      baseColors = [const Color(0xFF0F172A), const Color(0xFF020617)];
      animation = NightStars(key: const ValueKey('night'));
    }

    // 🎨 APPLY OVERRIDES IF PRESENT
    // If user picks a background color, we use it for the gradient (slightly varying for depth)
    List<Color> finalColors = baseColors;
    if (tm.backgroundColorOverride != null) {
      final c = tm.backgroundColorOverride!;
      // Create a subtle gradient from the single chosen color
      final c2 = HSLColor.fromColor(c).withLightness((HSLColor.fromColor(c).lightness - 0.1).clamp(0.0, 1.0)).toColor();
      finalColors = [c, c2];
    }

    return AnimatedContainer(
      duration: const Duration(seconds: 1), // Faster response for dev tools
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: finalColors,
        ),
      ),
      child: Stack(
        children: [
          if (animation != null) 
            AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: animation,
            ),
          child,
        ],
      ),
    );
  }
}

