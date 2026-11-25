import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mononote/core/theme/mononote_tokens.dart';
import 'package:mononote/core/theme/mononote_typography.dart';
import 'package:mononote/features/notes/models/note_text.dart';
import 'package:mononote/features/notes/presentation/note_mark_style.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('uses crisp Windows font stack and integer pixel sizes', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const tokens = MonoNoteThemeTokens.light;

    expect(MonoNoteTypography.primaryUiFont, 'HarmonyOS Sans SC');
    expect(MonoNoteTypography.primaryTitleFont, 'LXGW WenKai');
    expect(MonoNoteTypography.primaryMonoFont, 'JetBrains Mono');

    expect(
      MonoNoteTypography.uiFallback,
      containsAllInOrder([
        'HarmonyOS Sans SC',
        'MiSans',
        'Source Han Sans SC',
        'Noto Sans SC',
        'Segoe UI Variable',
        'Segoe UI',
        'Microsoft YaHei UI',
      ]),
    );
    expect(
      MonoNoteTypography.monoFallback,
      containsAllInOrder([
        'JetBrains Mono',
        'JetBrainsMono NF',
        'Cascadia Mono',
        'Cascadia Code',
        'Consolas',
        'HarmonyOS Sans SC',
        'monospace',
      ]),
    );

    final styles = [
      MonoNoteTypography.docTitle(tokens),
      MonoNoteTypography.heading2(tokens),
      MonoNoteTypography.body(tokens),
      MonoNoteTypography.cardTitle(tokens),
      MonoNoteTypography.cardExcerpt(tokens),
      MonoNoteTypography.navLabel(tokens),
      MonoNoteTypography.micro(tokens),
      MonoNoteTypography.code(tokens),
    ];
    for (final style in styles) {
      expect(style.fontSize! % 1, 0);
    }

    final inlineCode = noteMarkStyle(NoteMark.code.mask, tokens);
    expect(inlineCode.fontFamily, 'JetBrains Mono');
    expect(inlineCode.fontFamilyFallback, contains('Cascadia Mono'));

    final plain = noteMarkStyle(NoteMark.bold.mask, tokens);
    expect(plain.fontFamily, isNull);
    expect(plain.fontFamilyFallback, isNull);
  });

  test('preserves macOS font preferences', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    expect(MonoNoteTypography.primaryUiFont, 'PingFang SC');
    expect(MonoNoteTypography.primaryTitleFont, 'Songti SC');
    expect(MonoNoteTypography.primaryMonoFont, 'SF Mono');
  });
}
