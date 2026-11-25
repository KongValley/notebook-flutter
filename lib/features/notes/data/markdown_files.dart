import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/workspace_controller.dart';
import 'markdown_file_format.dart';
import 'markdown_file_native.dart'
    if (dart.library.js_interop) 'markdown_file_web.dart'
    as platform;

final markdownFilesProvider = Provider<MarkdownFiles>((ref) {
  return MarkdownFiles(
    () => ref.read(workspaceProvider),
    () => ref.read(workspaceProvider.notifier),
  );
});

class MarkdownFiles {
  MarkdownFiles(this._read, this._controller);

  final WorkspaceState Function() _read;
  final WorkspaceController Function() _controller;
  bool _busy = false;

  Future<void> open(BuildContext context) => _run(context, '打开失败', () async {
    final picked = await openFile(acceptedTypeGroups: markdownFileTypes);
    if (picked != null) await platform.openMarkdown(_controller(), picked);
  });

  Future<void> save(BuildContext context, {bool saveAs = false}) =>
      _run(context, kIsWeb ? '下载失败' : '保存失败', () async {
        final name = await platform.saveMarkdown(
          _read,
          _controller(),
          saveAs: saveAs,
        );
        if (name != null && context.mounted) {
          _message(context, '${kIsWeb ? '已发起下载' : '已保存'} · $name');
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

  static void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
