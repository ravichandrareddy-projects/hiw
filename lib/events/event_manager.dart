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
      case 'greezy':
        return GreezyBackground(child: child);
      case 'customize':
        return CustomBackground(child: child);
      case 'christmas':
        return ChristmasBackground(child: child);
      case 'sankranti':
        return SankrantiBackground(child: child);
      default:
        return DefaultBackground(child: child);
    }
  }
}

/// Solid user-picked background for the Customize theme (no animation,
// no gradient — the palette test surface stays pure).
class CustomBackground extends StatelessWidget {
  final Widget child;
  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

/// Warm espresso backdrop with a faint gold glow up top (Greezy theme).
class GreezyBackground extends StatelessWidget {
  final Widget child;
  const GreezyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF241B12),
            Color(0xFF161210),
          ],
        ),
      ),
      child: child,
    );
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
      animation = const MorningWind(key: ValueKey('morning'));
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      baseColors = [const Color(0xFFFFF9C4), const Color(0xFFFFECB3)];
      animation = const AfternoonSun(key: ValueKey('afternoon'));
    } else if (hour >= 17 && hour < 20) {
      // Evening
      baseColors = [const Color(0xFFFF8A65), const Color(0xFFBF360C)];
      animation = const EveningSunset(key: ValueKey('evening'));
    } else {
      // Night
      baseColors = [const Color(0xFF0F172A), const Color(0xFF020617)];
      animation = const NightStars(key: ValueKey('night'));
    }

    // 🎨 APPLY OVERRIDES IF PRESENT
    // If user picks a background color, we use it for the gradient (slightly varying for depth)
    List<Color> finalColors = baseColors;
    if (tm.backgroundColorOverride != null) {
      final c = tm.backgroundColorOverride!;
      // Create a subtle gradient from the single chosen color
      final c2 = HSLColor.fromColor(c)
          .withLightness(
              (HSLColor.fromColor(c).lightness - 0.1).clamp(0.0, 1.0))
          .toColor();
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
