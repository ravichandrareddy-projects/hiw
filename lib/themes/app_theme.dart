import 'package:flutter/material.dart';
import 'hiw_theme.dart';

class AppTheme {
  // 🌅 MORNING THEME (05:00 - 11:59)
  static ThemeData morningTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFB3E5FC),
    primaryColor: const Color(0xFF0288D1),
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0288D1), brightness: Brightness.light),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFF37474F)),
      titleLarge: TextStyle(color: Color(0xFF01579B), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF01579B)),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(
        accent: const Color(0xFF0288D1),
        ink: const Color(0xFF263238),
        muted: const Color(0xFF37474F),
      )
    ],
    useMaterial3: true,
  );

  // ☀️ AFTERNOON THEME (12:00 - 16:59)
  static ThemeData afternoonTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF9C4), // Light Lemon/Cream
    primaryColor: const Color(0xFFFBC02D), // Soft Amber
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFBC02D), brightness: Brightness.light),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFF4E342E)),
      titleLarge: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFB71C1C)),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(
        accent: const Color(0xFFFBC02D),
        ink: const Color(0xFF3E2723),
        muted: const Color(0xFF4E342E),
      )
    ],
    useMaterial3: true,
  );

  // 🌇 EVENING THEME (17:00 - 19:59)
  static ThemeData eveningTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFFE64A19),
    primaryColor: const Color(0xFFFFCC80),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE64A19),
      brightness: Brightness.dark,
      secondary: const Color(0xFFFF7043),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Color(0xFFFFE0B2), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFFFE0B2)),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(accent: const Color(0xFFFFCC80))
    ],
    useMaterial3: true,
  );

  // 🌙 NIGHT THEME (20:00 - 04:59)
  static ThemeData nightTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: Colors.cyanAccent,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent, brightness: Brightness.dark),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Colors.cyanAccent),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(accent: Colors.cyanAccent)
    ],
    useMaterial3: true,
  );

  // 🎄 FESTIVE THEMES
  static ThemeData sankrantiTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF8E1),
    primaryColor: Colors.deepOrange,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.light),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2E1A08), fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFF4E342E)),
      titleLarge: TextStyle(color: Color(0xFFBF360C), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFBF360C)),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(
        accent: Colors.deepOrange,
        ink: const Color(0xFF2E1A08),
        muted: const Color(0xFF4E342E),
      )
    ],
    useMaterial3: true,
  );

  static ThemeData christmasTheme = ThemeData(    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B132B),
    primaryColor: Colors.redAccent,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(accent: Colors.redAccent)
    ],
    useMaterial3: true,
  );

  // ⚪ PLAIN THEME (warm-cream minimalist paper)
  static ThemeData plainTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFBF7EF),
    primaryColor: const Color(0xFFE86A1D), // warm orange accent
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE86A1D),
      brightness: Brightness.light,
      primary: const Color(0xFFE86A1D),
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF211D16), fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFF8A8171)),
      titleLarge: TextStyle(color: Color(0xFF211D16), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFE86A1D)),
    extensions: <ThemeExtension<dynamic>>[HiwTheme.minimal()],
    useMaterial3: true,
  );

  // 🌾 GREEZY THEME (dark warm espresso + muted gold, from reference palette)
  static ThemeData greezyTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF161210),
    primaryColor: const Color(0xFFC9A24B), // muted gold accent
    cardColor: const Color(0xFF2A211A),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFC9A24B),
      brightness: Brightness.dark,
      primary: const Color(0xFFC9A24B),
      surface: const Color(0xFF2A211A),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF5EFE4), fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFFB8A88F)),
      titleLarge: TextStyle(color: Color(0xFFF5EFE4), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFC9A24B)),
    extensions: <ThemeExtension<dynamic>>[
      HiwTheme.glass(
        accent: const Color(0xFFC9A24B),
        ink: const Color(0xFFF5EFE4),
        muted: const Color(0xFFB8A88F),
      ).copyWith(
        cardBackground: const Color(0xFF2A211A),
        cardStroke: const Color(0xFFC9A24B).withValues(alpha: 0.25),
      )
    ],
    useMaterial3: true,
  );

  /// Official DEFAULT HIW theme = Plain. Time-based themes remain
  /// available explicitly via 'auto'; all other names are variants.
  static ThemeData getTheme(String name) {
    if (name == 'plain' || name == 'default') return plainTheme;
    if (name == 'customize') return plainTheme;
    if (name == 'greezy') return greezyTheme;
    if (name == 'christmas') return christmasTheme;
    if (name == 'sankranti') return sankrantiTheme;

    // ⏳ Time-based variants (explicit 'auto' opt-in).
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return morningTheme;
    if (hour >= 12 && hour < 17) return afternoonTheme;
    if (hour >= 17 && hour < 20) return eveningTheme;
    return nightTheme;
  }
}
