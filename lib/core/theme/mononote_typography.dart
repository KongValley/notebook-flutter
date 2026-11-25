import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mononote_tokens.dart';

/// Cross-platform typography helpers tuned for CJK + Latin editorial reading.
class MonoNoteTypography {
  const MonoNoteTypography._();

  static const _webFont = 'Noto Sans SC';

  static bool get _isAppleDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static Future<void> loadWebFonts() async {
    if (!kIsWeb) return;
    const directory = 'assets/fonts/noto-sans-sc';
    await (FontLoader(_webFont)
          ..addFont(rootBundle.load('$directory/NotoSansSC-Regular.otf'))
          ..addFont(rootBundle.load('$directory/NotoSansSC-Bold.otf')))
        .load();
  }

  static List<String> get uiFallback => <String>[
    if (kIsWeb) _webFont,
    if (_isWindows) ...const [
      'HarmonyOS Sans SC',
      'MiSans',
      'Source Han Sans SC',
      'Noto Sans SC',
      'Segoe UI Variable',
      'Segoe UI',
      'Microsoft YaHei UI',
    ] else if (_isAppleDesktop) ...const [
      'PingFang SC',
      'SF Pro Text',
      'Noto Sans SC',
    ] else ...const [
      'Noto Sans SC',
      'Source Han Sans SC',
      'Segoe UI',
      'Microsoft YaHei UI',
      'PingFang SC',
    ],
    'sans-serif',
  ];

  static List<String> get editorialSerifFallback => <String>[
    if (kIsWeb) _webFont,
    if (_isWindows) ...const [
      'LXGW WenKai',
      'LXGW WenKai GB',
      'Noto Serif SC',
      'Source Han Serif SC',
      'HarmonyOS Sans SC',
      'MiSans',
      'Source Han Sans SC',
      'Noto Sans SC',
      'Georgia',
      'Microsoft YaHei UI',
    ] else ...const [
      'Songti SC',
      'Noto Serif SC',
      'Source Han Serif SC',
      'Georgia',
      'PingFang SC',
    ],
    'serif',
  ];

  static List<String> get monoFallback => <String>[
    'JetBrains Mono',
    'JetBrainsMono NF',
    'Cascadia Mono',
    'Cascadia Code',
    'SF Mono',
    'Consolas',
    ...uiFallback,
    'monospace',
  ];

  static String get primaryUiFont {
    if (kIsWeb) return _webFont;
    if (_isAppleDesktop) return 'PingFang SC';
    if (_isWindows) return 'HarmonyOS Sans SC';
    return 'Noto Sans SC';
  }

  static String get primaryTitleFont {
    if (kIsWeb) return _webFont;
    if (_isAppleDesktop) return 'Songti SC';
    if (_isWindows) return 'LXGW WenKai';
    return 'Noto Serif SC';
  }

  static String get primaryMonoFont =>
      _isAppleDesktop ? 'SF Mono' : 'JetBrains Mono';

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
          fontFamily: primaryUiFont,
          fontSize: 12,
          color: tokens.surfacePaper,
          fontFamilyFallback: uiFallback,
        ),
      ),
    );
  }

  static TextStyle docTitle(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryTitleFont,
    fontFamilyFallback: editorialSerifFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.28,
    color: t.inkPrimary,
  );

  static TextStyle heading2(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: t.inkPrimary,
  );

  static TextStyle body(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.72,
    color: t.inkSecondary,
  );

  static TextStyle cardTitle(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: t.inkPrimary,
  );

  static TextStyle cardExcerpt(MonoNoteThemeTokens t) => TextStyle(
    fontFamily: primaryUiFont,
    fontFamilyFallback: uiFallback,
    fontSize: 13,
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
    fontFamily: primaryMonoFont,
    fontFamilyFallback: monoFallback,
    fontSize: 13,
    height: 1.55,
    color: t.inkSecondary,
  );
}
