import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../state/workspace_controller.dart';
import 'markdown_codec.dart';

final markdownFilesProvider = Provider<MarkdownFiles>((ref) {
  return MarkdownFiles(
    () => ref.read(workspaceProvider),
    () => ref.read(workspaceProvider.notifier),
  );
});

class MarkdownFiles {
  MarkdownFiles(this._read, this._controller);

  static const _type = XTypeGroup(
    label: 'Markdown',
    extensions: ['md', 'markdown'],
  );

  final WorkspaceState Function() _read;
  final WorkspaceController Function() _controller;
  bool _busy = false;

  Future<void> open(BuildContext context) => _run(context, '打开失败', () async {
    final picked = await openFile(acceptedTypeGroups: [_type]);
    if (picked == null) return;
    final file = File(path.normalize(path.absolute(picked.path)));
    final existing = _controller().documentForMarkdownPath(file.path);
    if (existing != null && existing.hasMarkdownChanges) {
      _controller().openPage(existing.id);
      return;
    }
    _controller().openMarkdown(file.path, await _readFile(file));
  });

  Future<void> save(BuildContext context, {bool saveAs = false}) =>
      _run(context, '保存失败', () async {
        final active = _read().activeDocument;
        var filePath = saveAs ? null : active.markdownSource?.path;
        if (filePath == null) {
          final name = active.title
              .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
              .trim();
          final location = await getSaveLocation(
            acceptedTypeGroups: [_type],
            suggestedName: '${name.isEmpty ? '未命名笔记' : name}.md',
          );
          if (location == null) return;
          filePath = path.normalize(path.absolute(location.path));
          if (path.extension(filePath).isEmpty) {
            final withExtension = File('$filePath.md');
            if (await withExtension.exists()) {
              throw const FormatException('同名 .md 文件已存在，请在保存对话框中选择该文件。');
            }
            filePath = withExtension.path;
          }
        }
        final existing = _controller().documentForMarkdownPath(filePath);
        if (existing != null && existing.id != active.id) {
          throw const FormatException('目标文件已在另一个标签页打开。');
        }
        final doc = _read().documents[active.id]!;
        final file = File(filePath);
        final backing = doc.markdownSource;
        final expectedSource =
            backing != null && path.equals(backing.path, filePath)
            ? backing.source
            : null;
        if (expectedSource == null || doc.hasMarkdownChanges) {
          final encoded = MarkdownCodec().encode(doc);
          await _writeFile(file, encoded, expectedSource: expectedSource);
          _controller().markMarkdownSaved(doc, filePath, encoded);
        } else {
          await _verifySource(file, expectedSource);
        }
        if (context.mounted) {
          _message(context, '已保存 · ${path.basename(filePath)}');
        }
      });

  Future<void> _run(
    BuildContext context,
    String failure,
    Future<void> Function() action,
  ) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        final detail = error is FormatException
            ? error.message
            : error.toString();
        _message(context, '$failure · $detail');
      }
    } finally {
      _busy = false;
    }
  }

  static Future<String> _readFile(File file) async {
    final bytes = await file.readAsBytes();
    final bom =
        bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf;
    return '${bom ? '\uFEFF' : ''}${utf8.decode(bytes)}';
  }

  static Future<void> _verifySource(File file, String expected) async {
    if (!await file.exists() || await _readFile(file) != expected) {
      throw const FormatException('磁盘文件已被修改或移走，请另存为 Markdown。');
    }
  }

  static Future<void> _writeFile(
    File file,
    String source, {
    String? expectedSource,
  }) async {
    if (Platform.isMacOS) {
      if (expectedSource != null) await _verifySource(file, expectedSource);
      await file.writeAsString(source, flush: true);
      return;
    }
    final staging = await file.parent.createTemp('.mononote-');
    final temporary = File(path.join(staging.path, 'note.md'));
    try {
      await temporary.writeAsString(source, flush: true);
      if (expectedSource != null) await _verifySource(file, expectedSource);
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
      await staging.delete();
    }
  }

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
