import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;

import '../state/workspace_controller.dart';
import 'markdown_codec.dart';
import 'markdown_file_format.dart';

Future<void> openMarkdown(WorkspaceController controller, XFile picked) async {
  final file = File(path.normalize(path.absolute(picked.path)));
  final existing = controller.documentForMarkdownPath(file.path);
  if (existing != null && existing.hasMarkdownChanges) {
    controller.openPage(existing.id);
    return;
  }
  controller.openMarkdown(file.path, await _readFile(file));
}

Future<String?> saveMarkdown(
  WorkspaceState Function() read,
  WorkspaceController controller, {
  required bool saveAs,
}) async {
  final active = read().activeDocument;
  var filePath = saveAs ? null : active.markdownSource?.path;
  if (filePath == null) {
    final location = await getSaveLocation(
      acceptedTypeGroups: markdownFileTypes,
      suggestedName: markdownFileName(active.title),
    );
    if (location == null) return null;
    filePath = path.normalize(path.absolute(location.path));
    if (path.extension(filePath).isEmpty) {
      final withExtension = File('$filePath.md');
      if (await withExtension.exists()) {
        throw const FormatException('同名 .md 文件已存在，请在保存对话框中选择该文件。');
      }
      filePath = withExtension.path;
    }
  }
  final existing = controller.documentForMarkdownPath(filePath);
  if (existing != null && existing.id != active.id) {
    throw const FormatException('目标文件已在另一个标签页打开。');
  }
  final doc = read().documents[active.id]!;
  final file = File(filePath);
  final backing = doc.markdownSource;
  final expectedSource = backing != null && path.equals(backing.path, filePath)
      ? backing.source
      : null;
  if (expectedSource == null || doc.hasMarkdownChanges) {
    final encoded = MarkdownCodec().encode(doc);
    await _writeFile(file, encoded, expectedSource: expectedSource);
    controller.markMarkdownSaved(doc, filePath, encoded);
  } else {
    await _verifySource(file, expectedSource);
  }
  return path.basename(filePath);
}

Future<String> _readFile(File file) async =>
    decodeMarkdownFile(await file.readAsBytes());

Future<void> _verifySource(File file, String expected) async {
  if (!await file.exists() || await _readFile(file) != expected) {
    throw const FormatException('磁盘文件已被修改或移走，请另存为 Markdown。');
  }
}

Future<void> _writeFile(
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
