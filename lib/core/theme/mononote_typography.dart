import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mononote_tokens.dart';

/// Cross-platform typography helpers tuned for CJK + Latin editorial reading.
class MonoNoteTypography {
  const MonoNoteTypography._();

  static const _webFont = 'Noto Sans SC';

  static Future<void> loadWebFonts() async {
    if (!kIsWeb) return;
    const directory = 'assets/fonts/noto-sans-sc';
    await (FontLoader(_webFont)
          ..addFont(rootBundle.load('$directory/NotoSansSC-Regular.otf'))
          ..addFont(rootBundle.load('$directory/NotoSansSC-Bold.otf')))
        .load();
  }

  static const List<String> uiFallback = <String>[
    if (kIsWeb) _webFont,
    'Segoe UI Variable',
    'Microsoft YaHei UI',
    'PingFang SC',
    'SF Pro Text',
    'Noto Sans SC',
    'sans-serif',
  ];

  static const List<String> editorialSerifFallback = <String>[
    'Noto Serif SC',
    'Source Han Serif SC',
    'Songti SC',
    'Georgia',
    'Microsoft YaHei UI',
    'serif',
  ];

  static const List<String> monoFallback = <String>[
    'JetBrains Mono',
    'Cascadia Code',
    'SF Mono',
    'Consolas',
    'monospace',
    if (kIsWeb) _webFont,
  ];

  static String get primaryUiFont {
    if (kIsWeb) return _webFont;
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'PingFang SC';
    }
    return 'Microsoft YaHei UI';
  }

  static ThemeData buildTheme(MonoNoteThemeTokens tokens) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      fontFamily: primaryUiFont,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.accentPrimary,
        brightness: tokens.brightness,
        primary: tokens.accentPrimary,
        surface: tokens.surfacePaper,
        onSurface: tokens.inkPrimary,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: tokens.inkPrimary,
        displayColor: tokens.inkPrimary,
        fontFamilyFallback: uiFallback,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.inkPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          fontSize: 11.5,
          color: tokens.surfacePaper,
          fontFamilyFallback: uiFallback,
        ),
      ),
    );
  }

  static TextStyle docTitle(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: kIsWeb ? _webFont : 'Georgia',
    fontFamilyFallback: editorialSerifFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.28,
    letterSpacing: -0.4,
    color: t.inkPrimary,
  );

  static TextStyle heading2(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.15,
    color: t.inkPrimary,
  );

  static TextStyle body(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.72,
    letterSpacing: 0.1,
    color: t.inkSecondary,
  );

  static TextStyle cardTitle(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: t.inkPrimary,
  );

  static TextStyle cardExcerpt(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 12.2,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: t.inkSecondary,
  );

  static TextStyle navLabel(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: t.inkSecondary,
  );

  static TextStyle micro(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: t.inkMuted,
  );

  static TextStyle code(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: 'Consolas',
    fontFamilyFallback: monoFallback,
    fontSize: 12.5,
    height: 1.58,
    color: t.inkSecondary,
  );
}
