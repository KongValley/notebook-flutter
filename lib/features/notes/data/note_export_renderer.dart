import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../models/note_models.dart';
import '../models/note_text.dart';
import '../presentation/note_mark_style.dart';

const _paperWidth = 720.0;
const _margin = 44.0;
const _contentWidth = _paperWidth - _margin * 2;
const _pageHeight = _paperWidth * 297 / 210;
const _pageContentHeight = _pageHeight - _margin * 2;
const _maxPngHeight = 8192;
const _tokens = MonoNoteThemeTokens.light;

Future<Uint8List> renderNotePng(NoteDocument document) async {
  final layout = _ExportLayout(document);
  try {
    final height = (layout.height + _margin * 2).ceil();
    if (height > _maxPngHeight) {
      throw const FormatException('笔记超出长图尺寸，请改用 PDF 分页导出。');
    }
    return await layout.render(
      start: 0,
      end: layout.height,
      height: height,
      scale: height * 2 <= _maxPngHeight ? 2 : 1,
    );
  } finally {
    layout.dispose();
  }
}

Future<Uint8List> renderNotePdf(NoteDocument document) async {
  final layout = _ExportLayout(document);
  try {
    final pdf = pw.Document(title: document.title);
    for (final (start, end) in layout.pages()) {
      final bytes = await layout.render(
        start: start,
        end: end,
        height: _pageHeight.ceil(),
        scale: 2,
      );
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(
            image,
            width: PdfPageFormat.a4.width,
            height: PdfPageFormat.a4.height,
          ),
        ),
      );
    }
    return await pdf.save();
  } finally {
    layout.dispose();
  }
}

class _ExportLayout {
  _ExportLayout(NoteDocument document) {
    _add(
      TextSpan(
        text: document.title,
        style: MonoNoteTypography.docTitle(_tokens).copyWith(fontSize: 32),
      ),
      gap: 12,
    );
    if (document.tags.isNotEmpty) {
      _add(
        TextSpan(
          text: document.tags.join('  '),
          style: MonoNoteTypography.micro(_tokens)
              .copyWith(color: _tokens.accentPrimary),
        ),
        gap: 12,
      );
    }
    _nextTop += 14;
    for (final block in document.blocks) {
      _addBlock(block);
    }
  }

  final _blocks = <_ExportBlock>[];
  double _nextTop = 0;

  double get height => _blocks.last.bottom;

  void _addBlock(NoteBlock block) {
    final body = MonoNoteTypography.body(_tokens);
    switch (block.type) {
      case NoteBlockType.paragraph:
        _add(_rich(block.content, body));
      case NoteBlockType.heading2:
        final size = switch (block.headingLevel) {
          1 => 23.0,
          2 => 19.0,
          _ => 16.0,
        };
        _nextTop += 6;
        _add(
          _rich(
            block.content,
            MonoNoteTypography.heading2(_tokens).copyWith(fontSize: size),
          ),
          accent: true,
        );
      case NoteBlockType.callout:
        _add(
          _rich(block.content, body),
          background: _tokens.surfaceCard,
          accent: true,
        );
      case NoteBlockType.todo:
        _add(
          _rich(
            block.content,
            block.checked
                ? body.copyWith(
                    color: _tokens.inkMuted,
                    decoration: TextDecoration.lineThrough,
                  )
                : body,
          ),
          checked: block.checked,
        );
      case NoteBlockType.code || NoteBlockType.markdown:
        final label = block.type == NoteBlockType.markdown
            ? 'Markdown 源文'
            : block.codeInfo;
        _add(
          TextSpan(
            children: [
              if (label.isNotEmpty)
                TextSpan(
                  text: '$label\n',
                  style: MonoNoteTypography.micro(_tokens),
                ),
              TextSpan(
                text: block.text,
                style: MonoNoteTypography.code(_tokens),
              ),
            ],
          ),
          background: _tokens.codeBg,
        );
      case NoteBlockType.subpageCard:
        _add(
          TextSpan(
            style: MonoNoteTypography.cardTitle(_tokens),
            text: block.targetTitle ?? '子页面',
            children: [
              if (block.targetExcerpt case final excerpt?
                  when excerpt.isNotEmpty)
                TextSpan(
                  text: '\n$excerpt',
                  style: MonoNoteTypography.cardExcerpt(_tokens),
                ),
            ],
          ),
          background: _tokens.surfaceCard,
          accent: true,
        );
    }
  }

  TextSpan _rich(NoteText content, TextStyle style) => TextSpan(
    style: style,
    children: [
      for (final run in content.segments)
        TextSpan(text: run.text, style: noteMarkStyle(run.marks, _tokens)),
    ],
  );

  void _add(
    TextSpan text, {
    double gap = 10,
    Color? background,
    bool accent = false,
    bool? checked,
  }) {
    final padding = background == null ? 0.0 : 12.0;
    final left = switch ((accent, checked)) {
      (_, final bool _) => 24.0,
      (true, _) => padding + 10,
      _ => padding,
    };
    final painter = TextPainter(text: text, textDirection: TextDirection.ltr)
      ..layout(maxWidth: _contentWidth - left - padding);
    final block = _ExportBlock(
      painter: painter,
      top: _nextTop,
      left: left,
      padding: padding,
      background: background,
      accent: accent,
      checked: checked,
    );
    _blocks.add(block);
    _nextTop = block.bottom + gap;
  }

  Iterable<(double, double)> pages() sync* {
    var start = 0.0;
    for (final block in _blocks) {
      if (block.bottom - start <= _pageContentHeight) continue;
      final blockHeight = block.bottom - block.top;
      final available = _pageContentHeight - (block.top - start);
      if (block.top > start &&
          (blockHeight <= _pageContentHeight || available < 72)) {
        yield (start, math.min(block.top, start + _pageContentHeight));
        start = block.top;
      }
      if (block.bottom - start <= _pageContentHeight) continue;

      var previous = block.top;
      for (final line in block.painter.computeLineMetrics().skip(1)) {
        final boundary =
            block.top + block.padding + line.baseline - line.ascent;
        if (boundary - start > _pageContentHeight) {
          yield (start, previous);
          start = previous;
        }
        previous = boundary;
      }
      if (block.bottom - start > _pageContentHeight) {
        yield (start, previous);
        start = previous;
      }
    }
    yield (start, height);
  }

  Future<Uint8List> render({
    required double start,
    required double end,
    required int height,
    required int scale,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale.toDouble());
    canvas.drawColor(_tokens.surfacePaper.withValues(alpha: 1), BlendMode.src);
    canvas.clipRect(
      Rect.fromLTWH(_margin, _margin, _contentWidth, end - start),
    );
    canvas.translate(_margin, _margin - start);
    for (final block in _blocks) {
      if (block.bottom <= start) continue;
      if (block.top >= end) break;
      block.paint(canvas);
    }

    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(
        _paperWidth.toInt() * scale,
        height * scale,
      );
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('无法编码导出图片。');
        return Uint8List.sublistView(data);
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  void dispose() {
    for (final block in _blocks) {
      block.painter.dispose();
    }
  }
}

class _ExportBlock {
  const _ExportBlock({
    required this.painter,
    required this.top,
    required this.left,
    required this.padding,
    required this.background,
    required this.accent,
    required this.checked,
  });

  final TextPainter painter;
  final double top;
  final double left;
  final double padding;
  final Color? background;
  final bool accent;
  final bool? checked;

  double get bottom => top + padding * 2 + painter.height;

  void paint(Canvas canvas) {
    final paint = Paint();
    if (background case final color?) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, top, _contentWidth, bottom),
          const Radius.circular(8),
        ),
        paint..color = color,
      );
    }
    if (accent) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(padding, top + padding + 5, 3, 15),
          const Radius.circular(1.5),
        ),
        paint..color = _tokens.accentPrimary,
      );
    }
    if (checked case final value?) {
      _paintCheckbox(canvas, paint, value);
    }
    painter.paint(canvas, Offset(left, top + padding));
  }

  void _paintCheckbox(Canvas canvas, Paint paint, bool value) {
    final y = top + 5;
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, y, 14, 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      box,
      paint
        ..color = value ? _tokens.accentPrimary : _tokens.inkMuted
        ..style = value ? PaintingStyle.fill : PaintingStyle.stroke,
    );
    if (!value) return;
    final tick = Path()
      ..moveTo(4, y + 7)
      ..lineTo(7, y + 10)
      ..lineTo(12, y + 4);
    canvas.drawPath(
      tick,
      paint
        ..color = _tokens.surfacePaper.withValues(alpha: 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }
}
