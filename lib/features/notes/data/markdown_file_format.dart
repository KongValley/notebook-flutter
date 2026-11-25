import 'dart:convert';

import 'package:file_selector/file_selector.dart';

const markdownFileTypes = [
  XTypeGroup(label: 'Markdown', extensions: ['md', 'markdown']),
];

String markdownFileName(String title) {
  final name = title.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  return '${name.isEmpty ? '未命名笔记' : name}.md';
}

String decodeMarkdownFile(List<int> bytes) {
  final bom =
      bytes.length >= 3 &&
      bytes[0] == 0xef &&
      bytes[1] == 0xbb &&
      bytes[2] == 0xbf;
  return '${bom ? '\uFEFF' : ''}${utf8.decode(bytes)}';
}
