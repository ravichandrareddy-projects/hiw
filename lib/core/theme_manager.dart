import 'dart:async';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../themes/hiw_theme.dart';
import '../core/app_state.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  
  ThemeManager._internal() {
    _loadTheme();
    _startTicker();
  }

  // 1. EVENT THEME STATE (was ThemeNotifier)
  String _currentThemeName = 'default';
  String get currentThemeName => _currentThemeName;
  Timer? _ticker;

  // 2. DEV OVERRIDES STATE
  Color? _backgroundColorOverride;
  Color? _cardColorOverride;
  Color? _primaryColorOverride;
  double _opacityOverride = 0.2;

  // 2b. CUSTOMIZE THEME STATE (persisted via AppState)
  Color? _customBg;
  Color? _customCard;
  Color? _customPrimary;
  Color? _bottomNavBg;
  Color? _bottomNavSelection;

  // Plain defaults used when the user hasn't picked a custom color yet.
  static const Color _plainBg = Color(0xFFFBF7EF);
  static const Color _plainCard = Colors.white;
  static const Color _plainPrimary = Color(0xFFE86A1D);

  Color get customizeBg => _customBg ?? _plainBg;
  Color get customizeCard => _customCard ?? _plainCard;
  Color get customizePrimary => _customPrimary ?? _plainPrimary;
  Color? get bottomNavBg => _bottomNavBg;
  Color? get bottomNavSelection => _bottomNavSelection;

  // Getters
  Color? get backgroundColorOverride => _backgroundColorOverride;
  Color? get cardColorOverride => _cardColorOverride;
  Color? get primaryColorOverride => _primaryColorOverride;
  double get opacityOverride => _opacityOverride;

  // -------------------------
  // THEME DATA GENERATION
  // -------------------------
  ThemeData get currentThemeData {
    // 🎨 CUSTOMIZE theme: Plain base + user palette.
    if (_currentThemeName == 'customize') {
      final bg = customizeBg;
      final card = customizeCard;
      final primary = customizePrimary;
      // Auto ink: dark text on light bg, light text on dark bg.
      final darkBg = bg.computeLuminance() < 0.4;
      final ink = darkBg ? Colors.white : const Color(0xFF211D16);
      final muted = darkBg ? Colors.white70 : const Color(0xFF8A8171);
      return ThemeData(
        brightness: darkBg ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bg,
        primaryColor: primary,
        cardColor: card,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: darkBg ? Brightness.dark : Brightness.light,
          primary: primary,
          surface: card,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: muted),
          titleLarge: TextStyle(color: ink, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: primary),
        extensions: <ThemeExtension<dynamic>>[
          HiwTheme.minimal().copyWith(
            cardBackground: card,
            cardStroke: darkBg
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFE9E2D5),
            inkColor: ink,
            mutedColor: muted,
            accentColor: primary,
          ),
        ],
        useMaterial3: true,
      );
    }

    // Start with the base time-based theme
    ThemeData base = AppTheme.getTheme(_currentThemeName);

    // Apply overrides
    return base.copyWith(
      scaffoldBackgroundColor: _backgroundColorOverride ?? base.scaffoldBackgroundColor,
      primaryColor: _primaryColorOverride ?? base.primaryColor,
      // Note: cardColor in ThemeData isn't always used by custom widgets, but we set it for consistency
      cardColor: _cardColorOverride ?? base.cardColor,
    );
  }

  // -------------------------
  // EVENT THEME LOGIC
  // -------------------------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_currentThemeName == 'default') {
        notifyListeners(); // Trigger rebuild for time-based changes
      }
    });
  }

  Future<void> _loadTheme() async {
    _currentThemeName = await AppState.getTheme();
    final bg = await AppState.getCustomColor('bg');
    final card = await AppState.getCustomColor('card');
    final primary = await AppState.getCustomColor('primary');
    final bNavBg = await AppState.getCustomColor('bottomNavBg');
    final bNavSel = await AppState.getCustomColor('bottomNavSelection');
    if (bg != null) _customBg = Color(bg);
    if (card != null) _customCard = Color(card);
    if (primary != null) _customPrimary = Color(primary);
    if (bNavBg != null) _bottomNavBg = Color(bNavBg);
    if (bNavSel != null) _bottomNavSelection = Color(bNavSel);
    notifyListeners();
  }

  Future<void> setThemeName(String theme) async {
    _currentThemeName = theme;
    await AppState.setTheme(theme);
    notifyListeners();
  }

  // -------------------------
  // DEV TOOLS OVERRIDES
  // -------------------------
  void setBackgroundColor(Color color) {
    _backgroundColorOverride = color;
    notifyListeners();
  }

  void setCardColor(Color color) {
    _cardColorOverride = color;
    notifyListeners();
  }
  
  void setPrimaryColor(Color color) {
    _primaryColorOverride = color;
    notifyListeners();
  }

  void setOpacity(double value) {
    _opacityOverride = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void reset() {
    _backgroundColorOverride = null;
    _cardColorOverride = null;
    _primaryColorOverride = null;
    _opacityOverride = 0.2;
    notifyListeners();
  }

  // -------------------------
  // CUSTOMIZE THEME (persisted)
  // -------------------------
  Future<void> setCustomColor(String which, Color? color) async {
    switch (which) {
      case 'bg':
        _customBg = color;
        break;
      case 'card':
        _customCard = color;
        break;
      case 'primary':
        _customPrimary = color;
        break;
      case 'bottomNavBg':
        _bottomNavBg = color;
        break;
      case 'bottomNavSelection':
        _bottomNavSelection = color;
        break;
      default:
        return;
    }
    if (color == null) {
      await AppState.setCustomColor(which, -1);
    } else {
      await AppState.setCustomColor(which, color.toARGB32());
    }
    notifyListeners();
  }

  Future<void> resetBottomNavColors() async {
    _bottomNavBg = null;
    _bottomNavSelection = null;
    await AppState.setCustomColor('bottomNavBg', -1);
    await AppState.setCustomColor('bottomNavSelection', -1);
    notifyListeners();
  }

  Future<void> resetCustomColors() async {
    _customBg = null;
    _customCard = null;
    _customPrimary = null;
    _bottomNavBg = null;
    _bottomNavSelection = null;
    await AppState.clearCustomColors();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
