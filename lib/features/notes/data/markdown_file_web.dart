import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../state/workspace_controller.dart';
import 'markdown_codec.dart';
import 'markdown_file_format.dart';

Future<void> openMarkdown(WorkspaceController controller, XFile picked) async {
  controller.importMarkdown(
    picked.name,
    decodeMarkdownFile(await picked.readAsBytes()),
  );
}

Future<String?> saveMarkdown(
  WorkspaceState Function() read,
  WorkspaceController controller, {
  required bool saveAs,
}) async {
  final doc = read().activeDocument;
  final name = doc.markdownSource?.path ?? markdownFileName(doc.title);
  final source = MarkdownCodec().encode(doc);
  await XFile.fromData(
    Uint8List.fromList(utf8.encode(source)),
    name: name,
    mimeType: 'text/markdown',
  ).saveTo(name);
  controller.markMarkdownSaved(doc, name, source);
  return name;
}
