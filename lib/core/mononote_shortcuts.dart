import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum MonoShortcut {
  palette('搜索或命令', LogicalKeyboardKey.keyK, 'K', webAltShift: true),
  newNote('新建笔记', LogicalKeyboardKey.keyN, 'N', webAltShift: true),
  openMarkdown('打开 Markdown', LogicalKeyboardKey.keyO, 'O', webAltShift: true),
  saveMarkdown('保存 Markdown', LogicalKeyboardKey.keyS, 'S'),
  saveMarkdownAs('另存为 Markdown', LogicalKeyboardKey.keyS, 'S', shift: true),
  exportPng('导出 PNG 图片', LogicalKeyboardKey.keyG, 'G', alternative: true),
  exportPdf('导出 PDF', LogicalKeyboardKey.keyP, 'P', alternative: true),
  previousTab(
    '上一个笔记标签',
    LogicalKeyboardKey.pageUp,
    'Page Up',
    alternative: true,
  ),
  nextTab(
    '下一个笔记标签',
    LogicalKeyboardKey.pageDown,
    'Page Down',
    alternative: true,
  ),
  sidebar('展开或折叠侧栏', LogicalKeyboardKey.backslash, r'\'),
  outline('显示或隐藏大纲', LogicalKeyboardKey.keyD, 'D', alternative: true),
  theme('切换主题', LogicalKeyboardKey.keyL, 'L', shift: true),
  help('查看快捷键', LogicalKeyboardKey.keyH, 'H', alternative: true),
  bold('加粗', LogicalKeyboardKey.keyB, 'B'),
  italic('斜体', LogicalKeyboardKey.keyI, 'I'),
  strike('删除线', LogicalKeyboardKey.keyX, 'X', alternative: true),
  code('行内代码', LogicalKeyboardKey.keyC, 'C', alternative: true);

  const MonoShortcut(
    this.title,
    this.key,
    this.keyLabel, {
    this.shift = false,
    this.alternative = false,
    this.webAltShift = false,
  });

  final String title;
  final LogicalKeyboardKey key;
  final String keyLabel;
  final bool shift;
  final bool alternative;
  final bool webAltShift;

  bool get _usesAltShift => alternative || (kIsWeb && webAltShift);

  bool get available => !kIsWeb || this != saveMarkdownAs;

  String get label => switch (this) {
    openMarkdown when kIsWeb => '导入 Markdown',
    saveMarkdown when kIsWeb => '下载 Markdown',
    _ => title,
  };

  SingleActivator activator(TargetPlatform platform) {
    final mac = platform == TargetPlatform.macOS;
    return SingleActivator(
      key,
      control: !_usesAltShift && !mac,
      meta: !_usesAltShift && mac,
      alt: _usesAltShift,
      shift: _usesAltShift || shift,
      includeRepeats: false,
    );
  }

  String keys(TargetPlatform platform) {
    final mac = platform == TargetPlatform.macOS;
    if (mac) {
      final modifier = _usesAltShift ? '⌥' : '⌘';
      return '$modifier${_usesAltShift || shift ? '⇧' : ''}$keyLabel';
    }
    final modifier = _usesAltShift ? 'Alt' : 'Ctrl';
    return '$modifier+${_usesAltShift || shift ? 'Shift+' : ''}$keyLabel';
  }
}
