import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'note_text.dart';

/// Semantic icon keys mapped cleanly to Lucide vector icons.
enum NoteIconKind {
  book,
  palette,
  bolt,
  layers,
  sun,
  inbox,
  file;

  IconData get iconData => switch (this) {
    NoteIconKind.book => LucideIcons.bookOpen,
    NoteIconKind.palette => LucideIcons.palette,
    NoteIconKind.bolt => LucideIcons.zap,
    NoteIconKind.layers => LucideIcons.layers,
    NoteIconKind.sun => LucideIcons.sun,
    NoteIconKind.inbox => LucideIcons.inbox,
    NoteIconKind.file => LucideIcons.fileText,
  };
}

/// Supported block types inside MonoNote's rich block document canvas.
enum NoteBlockType {
  paragraph,
  heading2,
  callout,
  todo,
  subpageCard,
  code,
  markdown,
}

/// Immutable representation of a single document block.
@immutable
class NoteBlock {
  const NoteBlock({
    required this.id,
    required this.type,
    String text = '',
    NoteText? content,
    this.checked = false,
    this.headingLevel = 2,
    this.codeInfo = '',
    this.originalMarkdown,
    this.targetPageId,
    this.targetTitle,
    this.targetExcerpt,
    this.targetIcon,
  }) : _contents = (text, content);

  final String id;
  final NoteBlockType type;
  final (String, NoteText?) _contents;
  String get text => _contents.$2?.text ?? _contents.$1;
  NoteText get content => _contents.$2 ?? NoteText.plain(_contents.$1);
  final bool checked;
  final int headingLevel;
  final String codeInfo;
  final String? originalMarkdown;
  final String? targetPageId;
  final String? targetTitle;
  final String? targetExcerpt;
  final NoteIconKind? targetIcon;

  NoteBlock copyWith({
    String? id,
    NoteBlockType? type,
    NoteText? content,
    bool? checked,
    String? targetPageId,
    String? targetTitle,
    String? targetExcerpt,
    NoteIconKind? targetIcon,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: _contents.$1,
      content: content ?? _contents.$2,
      checked: checked ?? this.checked,
      headingLevel: headingLevel,
      codeInfo: codeInfo,
      originalMarkdown: content == null && checked == null
          ? originalMarkdown
          : null,
      targetPageId: targetPageId ?? this.targetPageId,
      targetTitle: targetTitle ?? this.targetTitle,
      targetExcerpt: targetExcerpt ?? this.targetExcerpt,
      targetIcon: targetIcon ?? this.targetIcon,
    );
  }
}

@immutable
class MarkdownSource {
  const MarkdownSource({
    required this.path,
    required this.source,
    required this.savedBlocks,
  });

  final String path;
  final String source;
  final List<NoteBlock> savedBlocks;
}

/// Immutable representation of a hierarchical note page.
@immutable
class NoteDocument {
  const NoteDocument({
    required this.id,
    required this.title,
    required this.badge,
    required this.icon,
    required this.tags,
    required this.updatedLabel,
    required this.blocks,
    this.parentId,
    this.childrenIds = const [],
    this.isQuickLink = false,
    this.quickCount,
    this.markdownSource,
  });

  final String id;
  final String? parentId;
  final String title;
  final String badge;
  final NoteIconKind icon;
  final List<String> tags;
  final String updatedLabel;
  final List<NoteBlock> blocks;
  final List<String> childrenIds;
  final bool isQuickLink;
  final int? quickCount;
  final MarkdownSource? markdownSource;
  bool get hasMarkdownChanges =>
      markdownSource != null && !identical(markdownSource!.savedBlocks, blocks);

  /// Dynamically derives the heading outline from the document's H2 blocks.
  List<String> get outline {
    final headings = blocks
        .where(
          (b) => b.type == NoteBlockType.heading2 && b.text.trim().isNotEmpty,
        )
        .map((b) => b.text.trim())
        .toList();
    return headings.isEmpty ? [title] : headings;
  }

  /// Estimates character count for the document status strip.
  int get wordCount {
    var total = title.length;
    for (final block in blocks) {
      total += block.text.length + (block.targetTitle?.length ?? 0);
    }
    return total;
  }

  NoteDocument copyWith({
    String? id,
    String? parentId,
    String? title,
    String? badge,
    NoteIconKind? icon,
    List<String>? tags,
    String? updatedLabel,
    List<NoteBlock>? blocks,
    List<String>? childrenIds,
    bool? isQuickLink,
    int? quickCount,
    MarkdownSource? markdownSource,
  }) {
    return NoteDocument(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      badge: badge ?? this.badge,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      blocks: blocks ?? this.blocks,
      childrenIds: childrenIds ?? this.childrenIds,
      isQuickLink: isQuickLink ?? this.isQuickLink,
      quickCount: quickCount ?? this.quickCount,
      markdownSource: markdownSource ?? this.markdownSource,
    );
  }
}

/// Seeds MonoNote with high-aesthetic starter pages showcasing every block type.
Map<String, NoteDocument> seedMonoNoteDocuments() {
  return <String, NoteDocument>{
    'vision': const NoteDocument(
      id: 'vision',
      title: 'MonoNote 产品构想',
      badge: '核心设计文档',
      icon: NoteIconKind.book,
      tags: ['#桌面美学', '#Flutter'],
      updatedLabel: '更新于 刚刚',
      childrenIds: ['tokens', 'blocks'],
      blocks: [
        NoteBlock(
          id: 'v-callout',
          type: NoteBlockType.callout,
          text: '暖调纸感 × 轻透磨砂：让侧栏与顶栏如薄雾般轻盈退后，让文字与卡片在温润的米白纸张上自然浮现。',
        ),
        NoteBlock(
          id: 'v-h1',
          type: NoteBlockType.heading2,
          text: '嵌套子页面卡片（点击卡片可跳转）',
        ),
        NoteBlock(
          id: 'v-card-1',
          type: NoteBlockType.subpageCard,
          targetPageId: 'tokens',
          targetTitle: '毛玻璃与纸感规范',
          targetExcerpt: '晨曦米白与松烟炭墨 Token、Blur 24px 参数、同心圆角计算…',
          targetIcon: NoteIconKind.palette,
        ),
        NoteBlock(
          id: 'v-card-2',
          type: NoteBlockType.subpageCard,
          targetPageId: 'blocks',
          targetTitle: '块级交互与快捷键',
          targetExcerpt: '斜杠命令 /、悬浮文本工具岛、无边框窗口拖拽与键盘流…',
          targetIcon: NoteIconKind.bolt,
        ),
        NoteBlock(
          id: 'v-h2',
          type: NoteBlockType.heading2,
          text: '桌面端体验验收清单（可点击勾选）',
        ),
        NoteBlock(
          id: 'v-t1',
          type: NoteBlockType.todo,
          checked: true,
          text: '无边框一体化顶栏 + 跨平台 Win11/macOS 窗口控制',
        ),
        NoteBlock(
          id: 'v-t2',
          type: NoteBlockType.todo,
          checked: true,
          text: '可折叠磨砂浮动侧栏与全局搜索胶囊（Ctrl+K）',
        ),
        NoteBlock(
          id: 'v-t3',
          type: NoteBlockType.todo,
          checked: false,
          text: '扩展 Drift 本地数据库索引与 Markdown 双向导出',
        ),
      ],
    ),
    'tokens': const NoteDocument(
      id: 'tokens',
      parentId: 'vision',
      title: '毛玻璃与纸感规范',
      badge: 'Design Token',
      icon: NoteIconKind.palette,
      tags: ['#设计系统', '#色彩材质'],
      updatedLabel: '更新于 5 分钟前',
      blocks: [
        NoteBlock(
          id: 't-p1',
          type: NoteBlockType.paragraph,
          text: '纸张画布采用 #FCFBF8（光感护眼米白）与 #1C1917（松烟暖墨），彻底告别刺眼的纯白与冰冷的纯黑。',
        ),
        NoteBlock(
          id: 't-h1',
          type: NoteBlockType.heading2,
          text: 'Flutter 材质 Token 示例',
        ),
        NoteBlock(
          id: 't-code',
          type: NoteBlockType.code,
          text:
              '// MonoNoteThemeTokens (ThemeExtension)\n'
              'surfacePaper: Color(0xF5FCFBF8),\n'
              'glassChrome:  Color(0xA8F8F5EF), // blur sigma 24\n'
              'accentPrimary: Color(0xFFC26D4A), // 陶釉赤铜\n'
              'panelRadius:  12.0, // outer(20) - padding(8)',
        ),
        NoteBlock(
          id: 't-callout',
          type: NoteBlockType.callout,
          text: '高光描边细节：毛玻璃面板顶部附加 1px 半透明白色内高光，模拟真实玻璃斜切边缘的微弱反光。',
        ),
      ],
    ),
    'blocks': const NoteDocument(
      id: 'blocks',
      parentId: 'vision',
      title: '块级交互与快捷键',
      badge: '交互规范',
      icon: NoteIconKind.bolt,
      tags: ['#编辑器', '#效率流'],
      updatedLabel: '更新于 12 分钟前',
      blocks: [
        NoteBlock(
          id: 'b-p1',
          type: NoteBlockType.paragraph,
          text: '每个段落、待办或子页面都是独立可编辑的 BlockNode。你可以直接在下方输入框试着输入 / 或点击「+ 插入块」体验。',
        ),
        NoteBlock(id: 'b-h1', type: NoteBlockType.heading2, text: '核心桌面快捷键矩阵'),
        NoteBlock(
          id: 'b-t1',
          type: NoteBlockType.todo,
          checked: true,
          text: 'Ctrl / Cmd + K：呼出磨砂全局命令面板',
        ),
        NoteBlock(
          id: 'b-t2',
          type: NoteBlockType.todo,
          checked: true,
          text: 'Ctrl / Cmd + \\：平滑折叠或展开左侧浮动栏',
        ),
        NoteBlock(
          id: 'b-t3',
          type: NoteBlockType.todo,
          checked: false,
          text: 'Ctrl / Cmd + N：快速新建空白笔记页面',
        ),
      ],
    ),
    'flutter': const NoteDocument(
      id: 'flutter',
      title: 'Flutter 桌面架构',
      badge: '技术蓝图',
      icon: NoteIconKind.layers,
      tags: ['#Flutter', '#桌面端'],
      updatedLabel: '更新于 20 分钟前',
      blocks: [
        NoteBlock(
          id: 'f-callout',
          type: NoteBlockType.callout,
          text: '当前工程已集成 window_manager 0.6.0（无边框控制）、flutter_riverpod 3.5.0（状态管理）与 lucide_icons_flutter。',
        ),
        NoteBlock(id: 'f-h1', type: NoteBlockType.heading2, text: '性能与重绘控制原则'),
        NoteBlock(
          id: 'f-p1',
          type: NoteBlockType.paragraph,
          text: '对侧栏与顶栏容器整体使用一次 BackdropFilter 并包裹 RepaintBoundary，避免列表项逐条模糊导致桌面端高刷屏掉帧。',
        ),
      ],
    ),
    'daily': const NoteDocument(
      id: 'daily',
      title: '今日随记 · 11月25日',
      badge: 'Daily Note',
      icon: NoteIconKind.sun,
      tags: ['#每日记录'],
      updatedLabel: '今天 11:25',
      isQuickLink: true,
      blocks: [
        NoteBlock(id: 'd-h1', type: NoteBlockType.heading2, text: '今日记录'),
        NoteBlock(
          id: 'd-p1',
          type: NoteBlockType.paragraph,
          text: '确定 MonoNote 作为产品名称，结合暖调纸感与轻透磨砂材质，完成 Flutter 桌面端主框架落地。',
        ),
      ],
    ),
    'inbox': const NoteDocument(
      id: 'inbox',
      title: '灵感收件箱',
      badge: '待整理',
      icon: NoteIconKind.inbox,
      tags: ['#碎片收集'],
      updatedLabel: '今天 10:40',
      isQuickLink: true,
      quickCount: 3,
      blocks: [
        NoteBlock(id: 'i-h1', type: NoteBlockType.heading2, text: '待整理想法'),
        NoteBlock(
          id: 'i-t1',
          type: NoteBlockType.todo,
          checked: false,
          text: '为嵌套子页面卡片加入封面色条与拖拽排序支持',
        ),
        NoteBlock(
          id: 'i-t2',
          type: NoteBlockType.todo,
          checked: false,
          text: '增加本地 .md 文件夹双向监听与即时保存指示',
        ),
      ],
    ),
  };
}
