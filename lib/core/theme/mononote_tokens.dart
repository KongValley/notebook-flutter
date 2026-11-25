import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Design tokens for MonoNote's "Warm Paper + Frosted Glass" aesthetic.
@immutable
class MonoNoteThemeTokens extends ThemeExtension<MonoNoteThemeTokens> {
  const MonoNoteThemeTokens({
    required this.brightness,
    required this.ambientStart,
    required this.ambientEnd,
    required this.orbPrimary,
    required this.orbSecondary,
    required this.orbTertiary,
    required this.surfacePaper,
    required this.surfaceCard,
    required this.surfaceCardHover,
    required this.glassChrome,
    required this.glassStrong,
    required this.glassHighlight,
    required this.borderSubtle,
    required this.borderStrong,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkMuted,
    required this.accentPrimary,
    required this.accentSoft,
    required this.sage,
    required this.sageSoft,
    required this.slate,
    required this.codeBg,
    required this.paperShadowColor,
    required this.floatShadowColor,
    this.blurSigma = 24.0,
    this.windowRadius = 14.0,
    this.panelRadius = 12.0,
    this.cardRadius = 10.0,
    this.pillRadius = 8.0,
  });

  final Brightness brightness;
  final Color ambientStart;
  final Color ambientEnd;
  final Color orbPrimary;
  final Color orbSecondary;
  final Color orbTertiary;
  final Color surfacePaper;
  final Color surfaceCard;
  final Color surfaceCardHover;
  final Color glassChrome;
  final Color glassStrong;
  final Color glassHighlight;
  final Color borderSubtle;
  final Color borderStrong;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkMuted;
  final Color accentPrimary;
  final Color accentSoft;
  final Color sage;
  final Color sageSoft;
  final Color slate;
  final Color codeBg;
  final Color paperShadowColor;
  final Color floatShadowColor;
  final double blurSigma;
  final double windowRadius;
  final double panelRadius;
  final double cardRadius;
  final double pillRadius;

  /// "晨曦素笺" — Warm Alabaster Paper & Frosted Cream Chrome.
  static const MonoNoteThemeTokens light = MonoNoteThemeTokens(
    brightness: Brightness.light,
    ambientStart: Color(0xFFEFE6D8),
    ambientEnd: Color(0xFFE2D9CB),
    orbPrimary: Color(0x5CD67E56),
    orbSecondary: Color(0x426E9E86),
    orbTertiary: Color(0x4CDAB882),
    surfacePaper: Color(0xF5FCFBF8),
    surfaceCard: Color(0xFFF5F1E9),
    surfaceCardHover: Color(0xFFEFE9DD),
    glassChrome: Color(0xA8F8F5EF),
    glassStrong: Color(0xCCFBF9F5),
    glassHighlight: Color(0xD1FFFFFF),
    borderSubtle: Color(0x173A3026),
    borderStrong: Color(0x293A3026),
    inkPrimary: Color(0xFF231F1B),
    inkSecondary: Color(0xFF655D55),
    inkMuted: Color(0xFF999086),
    accentPrimary: Color(0xFFC26D4A),
    accentSoft: Color(0x21C26D4A),
    sage: Color(0xFF4B7562),
    sageSoft: Color(0x214B7562),
    slate: Color(0xFF4F6882),
    codeBg: Color(0xFFEFE9DE),
    paperShadowColor: Color(0x0F282016),
    floatShadowColor: Color(0x26221A12),
  );

  /// "松烟夜读" — Warm Obsidian Ink & Smoked Glass Chrome.
  static const MonoNoteThemeTokens dark = MonoNoteThemeTokens(
    brightness: Brightness.dark,
    ambientStart: Color(0xFF161311),
    ambientEnd: Color(0xFF100E0C),
    orbPrimary: Color(0x3DD9845E),
    orbSecondary: Color(0x2E60947C),
    orbTertiary: Color(0x29A4865C),
    surfacePaper: Color(0xF51C1917),
    surfaceCard: Color(0xFF25221E),
    surfaceCardHover: Color(0xFF2C2823),
    glassChrome: Color(0xA8221E1B),
    glassStrong: Color(0xD627231F),
    glassHighlight: Color(0x17FFF5E8),
    borderSubtle: Color(0x17FFF5E8),
    borderStrong: Color(0x2EFFF5E8),
    inkPrimary: Color(0xFFEDE8E1),
    inkSecondary: Color(0xFFA69D92),
    inkMuted: Color(0xFF756D63),
    accentPrimary: Color(0xFFD98A68),
    accentSoft: Color(0x2ED98A68),
    sage: Color(0xFF78A890),
    sageSoft: Color(0x2978A890),
    slate: Color(0xFF83A0BE),
    codeBg: Color(0xFF141210),
    paperShadowColor: Color(0x47000000),
    floatShadowColor: Color(0x7A000000),
  );

  bool get isDark => brightness == Brightness.dark;

  @override
  MonoNoteThemeTokens copyWith({
    Brightness? brightness,
    Color? ambientStart,
    Color? ambientEnd,
    Color? orbPrimary,
    Color? orbSecondary,
    Color? orbTertiary,
    Color? surfacePaper,
    Color? surfaceCard,
    Color? surfaceCardHover,
    Color? glassChrome,
    Color? glassStrong,
    Color? glassHighlight,
    Color? borderSubtle,
    Color? borderStrong,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkMuted,
    Color? accentPrimary,
    Color? accentSoft,
    Color? sage,
    Color? sageSoft,
    Color? slate,
    Color? codeBg,
    Color? paperShadowColor,
    Color? floatShadowColor,
    double? blurSigma,
    double? windowRadius,
    double? panelRadius,
    double? cardRadius,
    double? pillRadius,
  }) {
    return MonoNoteThemeTokens(
      brightness: brightness ?? this.brightness,
      ambientStart: ambientStart ?? this.ambientStart,
      ambientEnd: ambientEnd ?? this.ambientEnd,
      orbPrimary: orbPrimary ?? this.orbPrimary,
      orbSecondary: orbSecondary ?? this.orbSecondary,
      orbTertiary: orbTertiary ?? this.orbTertiary,
      surfacePaper: surfacePaper ?? this.surfacePaper,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceCardHover: surfaceCardHover ?? this.surfaceCardHover,
      glassChrome: glassChrome ?? this.glassChrome,
      glassStrong: glassStrong ?? this.glassStrong,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSoft: accentSoft ?? this.accentSoft,
      sage: sage ?? this.sage,
      sageSoft: sageSoft ?? this.sageSoft,
      slate: slate ?? this.slate,
      codeBg: codeBg ?? this.codeBg,
      paperShadowColor: paperShadowColor ?? this.paperShadowColor,
      floatShadowColor: floatShadowColor ?? this.floatShadowColor,
      blurSigma: blurSigma ?? this.blurSigma,
      windowRadius: windowRadius ?? this.windowRadius,
      panelRadius: panelRadius ?? this.panelRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      pillRadius: pillRadius ?? this.pillRadius,
    );
  }

  @override
  MonoNoteThemeTokens lerp(
    covariant ThemeExtension<MonoNoteThemeTokens>? other,
    double t,
  ) {
    if (other is! MonoNoteThemeTokens) return this;
    return MonoNoteThemeTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      ambientStart: Color.lerp(ambientStart, other.ambientStart, t)!,
      ambientEnd: Color.lerp(ambientEnd, other.ambientEnd, t)!,
      orbPrimary: Color.lerp(orbPrimary, other.orbPrimary, t)!,
      orbSecondary: Color.lerp(orbSecondary, other.orbSecondary, t)!,
      orbTertiary: Color.lerp(orbTertiary, other.orbTertiary, t)!,
      surfacePaper: Color.lerp(surfacePaper, other.surfacePaper, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceCardHover: Color.lerp(
        surfaceCardHover,
        other.surfaceCardHover,
        t,
      )!,
      glassChrome: Color.lerp(glassChrome, other.glassChrome, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageSoft: Color.lerp(sageSoft, other.sageSoft, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      codeBg: Color.lerp(codeBg, other.codeBg, t)!,
      paperShadowColor: Color.lerp(
        paperShadowColor,
        other.paperShadowColor,
        t,
      )!,
      floatShadowColor: Color.lerp(
        floatShadowColor,
        other.floatShadowColor,
        t,
      )!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      windowRadius: lerpDouble(windowRadius, other.windowRadius, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      pillRadius: lerpDouble(pillRadius, other.pillRadius, t)!,
    );
  }
}

/// Convenient access to MonoNote design tokens from any widget [BuildContext].
extension MonoNoteTokensContext on BuildContext {
  MonoNoteThemeTokens get monoTokens =>
      Theme.of(this).extension<MonoNoteThemeTokens>() ??
      MonoNoteThemeTokens.light;
}
