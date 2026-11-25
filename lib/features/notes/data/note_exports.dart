import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../models/note_models.dart';
import '../state/workspace_controller.dart';
import 'markdown_file_format.dart';
import 'note_export_renderer.dart';

enum NoteExportFormat {
  png('PNG 图片', 'image/png', 'public.png'),
  pdf('PDF', 'application/pdf', 'com.adobe.pdf');

  const NoteExportFormat(this.label, this.mimeType, this.typeIdentifier);

  final String label;
  final String mimeType;
  final String typeIdentifier;

  XTypeGroup get fileType => XTypeGroup(
    label: label,
    extensions: [name],
    uniformTypeIdentifiers: [typeIdentifier],
  );

  Future<Uint8List> render(NoteDocument document) => switch (this) {
    png => renderNotePng(document),
    pdf => renderNotePdf(document),
  };
}

final noteExportsProvider = Provider<NoteExports>((ref) {
  return NoteExports(() => ref.read(workspaceProvider).activeDocument);
});

class NoteExports {
  NoteExports(this._readDocument);

  final NoteDocument Function() _readDocument;
  bool _busy = false;

  Future<void> export(BuildContext context, NoteExportFormat format) async {
    if (_busy) return;
    _busy = true;
    final document = _readDocument();
    final name = noteFileName(document.title, format.name);
    final messages = ScaffoldMessenger.of(context);

    void showStatus(String text, {bool working = false}) {
      if (!messages.mounted) return;
      messages
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            duration: working
                ? const Duration(minutes: 5)
                : const Duration(seconds: 4),
          ),
        );
    }

    try {
      var destination = name;
      if (!kIsWeb) {
        final location = await getSaveLocation(
          acceptedTypeGroups: [format.fileType],
          suggestedName: name,
        );
        if (location == null) return;
        destination = location.path;
        if (path.extension(destination).toLowerCase() != '.${format.name}') {
          throw FormatException('请使用 .${format.name} 文件扩展名。');
        }
      }
      showStatus('正在导出 ${format.label}…', working: true);
      final bytes = await format.render(document);
      await XFile.fromData(
        bytes,
        name: name,
        mimeType: format.mimeType,
      ).saveTo(destination);
      showStatus('${kIsWeb ? '已发起下载' : '已导出'} · ${path.basename(destination)}');
    } catch (error) {
      final detail = error is FormatException
          ? error.message
          : error.toString();
      showStatus('${format.label} 导出失败 · $detail');
    } finally {
      _busy = false;
    }
  }
}
