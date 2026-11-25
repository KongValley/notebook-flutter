import 'package:flutter/material.dart';

import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../models/note_text.dart';

TextStyle noteMarkStyle(int marks, MonoNoteThemeTokens tokens) {
  final code = marks & NoteMark.code.mask != 0;
  return TextStyle(
    fontWeight: marks & NoteMark.bold.mask != 0 ? FontWeight.w700 : null,
    fontStyle: marks & NoteMark.italic.mask != 0 ? FontStyle.italic : null,
    decoration: marks & NoteMark.strike.mask != 0
        ? TextDecoration.lineThrough
        : null,
    fontFamily: code ? MonoNoteTypography.primaryMonoFont : null,
    fontFamilyFallback: code ? MonoNoteTypography.monoFallback : null,
    backgroundColor: code ? tokens.codeBg : null,
  );
}
