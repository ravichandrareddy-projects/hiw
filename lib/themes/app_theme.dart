import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkBlueTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B1C2D),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12, color: Colors.white70),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    useMaterial3: true,
  );
}
