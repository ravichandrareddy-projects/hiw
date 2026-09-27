import 'dart:ui';
import 'package:flutter/material.dart';

/// Per-theme design tokens that `ThemeData` can't express:
/// flat paper card vs blurred glass card, ink/muted text, strokes, blur.
///
/// Usage: `HiwTheme.of(context).cardBackground`
/// Falls back to dark-glass tokens when a ThemeData has no extension attached.
class HiwTheme extends ThemeExtension<HiwTheme> {
  /// true → flat warm-paper card, no blur. false → blurred glass card.
  final bool isMinimal;
  final Color cardBackground;
  final Color cardStroke;
  final double cardRadius;
  final double blurSigma;
  final List<BoxShadow> cardShadow;
  final Color inkColor;
  final Color mutedColor;
  final Color accentColor;

  const HiwTheme({
    required this.isMinimal,
    required this.cardBackground,
    required this.cardStroke,
    required this.cardRadius,
    required this.blurSigma,
    required this.cardShadow,
    required this.inkColor,
    required this.mutedColor,
    required this.accentColor,
  });

  /// Warm-cream minimalist paper tokens (Plain theme).
  factory HiwTheme.minimal() => const HiwTheme(
        isMinimal: true,
        cardBackground: Colors.white,
        cardStroke: Color(0xFFE9E2D5),
        cardRadius: 20,
        blurSigma: 0,
        cardShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        inkColor: Color(0xFF211D16),
        mutedColor: Color(0xFF8A8171),
        accentColor: Color(0xFFE86A1D),
      );

  /// Blurred glass tokens for every non-Plain theme.
  factory HiwTheme.glass({
    required Color accent,
    Color ink = Colors.white,
    Color muted = Colors.white70,
  }) =>
      HiwTheme(
        isMinimal: false,
        cardBackground: Colors.white.withValues(alpha: 0.08),
        cardStroke: Colors.white.withValues(alpha: 0.2),
        cardRadius: 20,
        blurSigma: 18,
        cardShadow: const [],
        inkColor: ink,
        mutedColor: muted,
        accentColor: accent,
      );

  static HiwTheme of(BuildContext context) =>
      Theme.of(context).extension<HiwTheme>() ??
      HiwTheme.glass(accent: Theme.of(context).primaryColor);

  @override
  HiwTheme copyWith({
    bool? isMinimal,
    Color? cardBackground,
    Color? cardStroke,
    double? cardRadius,
    double? blurSigma,
    List<BoxShadow>? cardShadow,
    Color? inkColor,
    Color? mutedColor,
    Color? accentColor,
  }) {
    return HiwTheme(
      isMinimal: isMinimal ?? this.isMinimal,
      cardBackground: cardBackground ?? this.cardBackground,
      cardStroke: cardStroke ?? this.cardStroke,
      cardRadius: cardRadius ?? this.cardRadius,
      blurSigma: blurSigma ?? this.blurSigma,
      cardShadow: cardShadow ?? this.cardShadow,
      inkColor: inkColor ?? this.inkColor,
      mutedColor: mutedColor ?? this.mutedColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  HiwTheme lerp(ThemeExtension<HiwTheme>? other, double t) {
    if (other is! HiwTheme) return this;
    return HiwTheme(
      isMinimal: t < 0.5 ? isMinimal : other.isMinimal,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t)!,
      cardStroke: Color.lerp(cardStroke, other.cardStroke, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      inkColor: Color.lerp(inkColor, other.inkColor, t)!,
      mutedColor: Color.lerp(mutedColor, other.mutedColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
    );
  }
}
