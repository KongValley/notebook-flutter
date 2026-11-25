import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../../../core/widgets/frosted_glass_surface.dart';
import '../../notes/data/markdown_files.dart';
import '../../notes/data/note_exports.dart';
import '../../notes/models/note_models.dart';
import '../../notes/models/note_text.dart';
import '../../notes/state/workspace_controller.dart';
import 'block_widgets.dart';

/// Main warm paper editorial document canvas with a sequential page transition,
/// block composer, `/` slash menu, and optional frosted formatting toolbar.
class PaperEditorCanvas extends ConsumerStatefulWidget {
  const PaperEditorCanvas({super.key});

  @override
  ConsumerState<PaperEditorCanvas> createState() => _PaperEditorCanvasState();
}

class _PaperEditorCanvasState extends ConsumerState<PaperEditorCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _visibility;
  late final Animation<double> _opacity;
  late String _visiblePageId;
  bool _reduceMotion = false;
  bool _slashMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _visiblePageId = ref.read(workspaceProvider).activePageId;
    _visibility = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 215),
      reverseDuration: const Duration(milliseconds: 105),
    )..addStatusListener(_onVisibilityChanged);
    _opacity = _visibility.drive(CurveTween(curve: Curves.easeOutQuad));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion && !_visibility.isCompleted) {
      _showPage(ref.read(workspaceProvider).activePageId);
      _visibility.value = 1;
    }
  }

  @override
  void dispose() {
    _visibility.dispose();
    super.dispose();
  }

  void _showPage(String pageId) {
    if (_visiblePageId != pageId) {
      _visiblePageId = pageId;
      _slashMenuOpen = false;
    }
  }

  void _switchTo(String pageId) {
    if (_reduceMotion) {
      setState(() => _showPage(pageId));
    } else if (pageId == _visiblePageId) {
      _visibility.forward();
    } else if (_visibility.status != AnimationStatus.reverse) {
      _visibility.reverse();
    }
  }

  void _onVisibilityChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() => _showPage(ref.read(workspaceProvider).activePageId));
      _visibility.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final state = ref.watch(workspaceProvider);
    final controller = ref.read(workspaceProvider.notifier);
    final files = ref.read(markdownFilesProvider);
    final exports = ref.read(noteExportsProvider);
    ref.listen(
      workspaceProvider.select((state) => state.activePageId),
      (_, pageId) => _switchTo(pageId),
    );
    final doc = state.documents[_visiblePageId] ?? state.activeDocument;
    final isActive = doc.id == state.activePageId;

    return Container(
      decoration: BoxDecoration(
        color: t.surfacePaper,
        borderRadius: BorderRadius.circular(t.panelRadius),
        border: Border.all(color: t.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: t.paperShadowColor,
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.panelRadius),
        child: Stack(
          children: [
            Column(
              children: [
                _CanvasHeaderBar(
                  doc: doc,
                  opacity: _opacity,
                  onToggleSlashMenu: isActive
                      ? () => setState(() => _slashMenuOpen = !_slashMenuOpen)
                      : null,
                  onFileAction: isActive
                      ? (action) => switch (action) {
                          _FileAction.open => files.open(context),
                          _FileAction.save => files.save(context),
                          _FileAction.saveAs => files.save(
                            context,
                            saveAs: true,
                          ),
                          _FileAction.png => exports.export(
                            context,
                            NoteExportFormat.png,
                          ),
                          _FileAction.pdf => exports.export(
                            context,
                            NoteExportFormat.pdf,
                          ),
                        }
                      : null,
                ),
                Expanded(
                  child: ClipRect(
                    child: FadeTransition(
                      opacity: _opacity,
                      child: AnimatedBuilder(
                        animation: _opacity,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, 5 * (1 - _opacity.value)),
                          child: child,
                        ),
                        child: IgnorePointer(
                          ignoring: !isActive,
                          child: ExcludeFocus(
                            excluding: !isActive,
                            child: ExcludeSemantics(
                              excluding: !isActive,
                              child: _DocumentScrollBody(
                                key: ValueKey(doc.id),
                                doc: doc,
                                slashMenuOpen: _slashMenuOpen,
                                onSetSlashMenuOpen: (open) =>
                                    setState(() => _slashMenuOpen = open),
                                onInsertBlock: (type, {String? customText}) {
                                  controller.insertBlock(
                                    type,
                                    customText: customText,
                                  );
                                  setState(() => _slashMenuOpen = false);
                                },
                                onToggleTodo: (id) =>
                                    controller.toggleTodo(id, pageId: doc.id),
                                onOpenSubpage: controller.openPage,
                                onDeleteBlock: (id) =>
                                    controller.deleteBlock(id, pageId: doc.id),
                                onChangeBlock: (id, content) => controller
                                    .updateBlockContent(doc.id, id, content),
                                onMoveBlock:
                                    (source, target, {required after}) =>
                                        controller.moveBlock(
                                          doc.id,
                                          source,
                                          target,
                                          after: after,
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (state.isFloatingToolbarVisible)
              Positioned(
                top: 48,
                right: 22,
                child: IgnorePointer(
                  ignoring: !isActive,
                  child: ExcludeFocus(
                    excluding: !isActive,
                    child: _FloatingFormatToolbar(
                      onInsertHeading: () =>
                          controller.insertBlock(NoteBlockType.heading2),
                      onInsertTodo: () =>
                          controller.insertBlock(NoteBlockType.todo),
                      onInsertCallout: () =>
                          controller.insertBlock(NoteBlockType.callout),
                      onInsertCard: () =>
                          controller.insertBlock(NoteBlockType.subpageCard),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A document body with its own scroll controller and composer.
class _DocumentScrollBody extends StatefulWidget {
  const _DocumentScrollBody({
    super.key,
    required this.doc,
    required this.slashMenuOpen,
    required this.onSetSlashMenuOpen,
    required this.onInsertBlock,
    required this.onToggleTodo,
    required this.onOpenSubpage,
    required this.onDeleteBlock,
    required this.onChangeBlock,
    required this.onMoveBlock,
  });

  final NoteDocument doc;
  final bool slashMenuOpen;
  final ValueChanged<bool> onSetSlashMenuOpen;
  final void Function(NoteBlockType type, {String? customText}) onInsertBlock;
  final ValueChanged<String> onToggleTodo;
  final ValueChanged<String> onOpenSubpage;
  final ValueChanged<String> onDeleteBlock;
  final void Function(String, NoteText) onChangeBlock;
  final void Function(String, String, {required bool after}) onMoveBlock;

  @override
  State<_DocumentScrollBody> createState() => _DocumentScrollBodyState();
}

class _DocumentScrollBodyState extends State<_DocumentScrollBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _composerController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  void _insertAndScroll(NoteBlockType type, {String? customText}) {
    widget.onInsertBlock(type, customText: customText);
    _composerController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final horizontalPadding = kIsWeb && MediaQuery.sizeOf(context).width < 600
        ? 16.0
        : 32.0;

    return ListView(
      key: PageStorageKey<String>('document-${doc.id}'),
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        24,
        horizontalPadding,
        48,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DocumentHero(doc: doc),
                const SizedBox(height: 16),
                ..._buildGroupedBlocks(doc),
                const SizedBox(height: 14),
                if (widget.slashMenuOpen) ...[
                  _FrostedSlashMenu(onSelect: (type) => _insertAndScroll(type)),
                  const SizedBox(height: 8),
                ],
                _ComposerRow(
                  controller: _composerController,
                  slashOpen: widget.slashMenuOpen,
                  onToggleSlash: () =>
                      widget.onSetSlashMenuOpen(!widget.slashMenuOpen),
                  onChanged: (val) {
                    final shouldOpen = val.endsWith('/');
                    if (shouldOpen != widget.slashMenuOpen) {
                      widget.onSetSlashMenuOpen(shouldOpen);
                    }
                  },
                  onSubmitted: (val) {
                    final cleaned = val.replaceFirst(RegExp(r'/$'), '').trim();
                    if (cleaned.isNotEmpty) {
                      _insertAndScroll(
                        NoteBlockType.paragraph,
                        customText: cleaned,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedBlocks(NoteDocument doc) {
    final widgets = <Widget>[];
    final blocks = doc.blocks;
    var index = 0;

    while (index < blocks.length) {
      if (blocks[index].type == NoteBlockType.subpageCard) {
        final cardGroup = <NoteBlock>[];
        while (index < blocks.length &&
            blocks[index].type == NoteBlockType.subpageCard) {
          cardGroup.add(blocks[index]);
          index++;
        }
        widgets.add(
          Padding(
            key: ValueKey('cards-${cardGroup.first.id}'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SubpageCardGrid(
              cards: [
                for (final block in cardGroup)
                  (inGrid) => _buildBlock(block, inCardGrid: inGrid),
              ],
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      final block = blocks[index];
      widgets.add(_buildBlock(block));
      widgets.add(const SizedBox(height: 6));
      index++;
    }
    return widgets;
  }

  Widget _buildBlock(NoteBlock block, {bool inCardGrid = false}) =>
      NoteBlockItem(
        key: ValueKey(block.id),
        block: block,
        onToggleTodo: () => widget.onToggleTodo(block.id),
        onOpenSubpage: widget.onOpenSubpage,
        onDeleteBlock: () => widget.onDeleteBlock(block.id),
        onChange: (content) => widget.onChangeBlock(block.id, content),
        onMove: widget.onMoveBlock,
        inCardGrid: inCardGrid,
      );
}

enum _FileAction { open, save, saveAs, png, pdf }

class _CanvasHeaderBar extends StatelessWidget {
  const _CanvasHeaderBar({
    required this.doc,
    required this.opacity,
    required this.onToggleSlashMenu,
    required this.onFileAction,
  });

  final NoteDocument doc;
  final Animation<double> opacity;
  final VoidCallback? onToggleSlashMenu;
  final ValueChanged<_FileAction>? onFileAction;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final compact = kIsWeb && MediaQuery.sizeOf(context).width < 600;
    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (!compact) ...[
                  Text('工作空间', style: MonoNoteTypography.micro(t)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('/', style: MonoNoteTypography.micro(t)),
                  ),
                ],
                Flexible(
                  child: FadeTransition(
                    opacity: opacity,
                    child: Text(
                      doc.title,
                      key: ValueKey('crumb-${doc.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MonoNoteTypography.micro(t).copyWith(
                        color: t.inkSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              if (doc.markdownSource != null &&
                  (!kIsWeb || doc.hasMarkdownChanges)) ...[
                Tooltip(
                  message: doc.markdownSource!.path,
                  child: Text(
                    kIsWeb
                        ? '待导出'
                        : doc.hasMarkdownChanges
                        ? '未保存'
                        : '已保存',
                    style: MonoNoteTypography.micro(t).copyWith(
                      color: doc.hasMarkdownChanges ? t.accentPrimary : t.sage,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (!compact) ...[
                FadeTransition(
                  opacity: opacity,
                  child: Text(
                    '${doc.wordCount} 字',
                    style: MonoNoteTypography.micro(t),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              InkWell(
                onTap: onToggleSlashMenu,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Text(
                    compact ? '+ 插入块' : '+ 插入块 (/)',
                    style: MonoNoteTypography.micro(t).copyWith(
                      color: t.inkSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<_FileAction>(
                tooltip: '文件与导出',
                enabled: onFileAction != null,
                onSelected: onFileAction,
                padding: EdgeInsets.zero,
                icon: Icon(
                  LucideIcons.fileText,
                  size: 16,
                  color: t.inkSecondary,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _FileAction.open,
                    child: Text(kIsWeb ? '导入 Markdown…' : '打开本地 Markdown…'),
                  ),
                  PopupMenuItem(
                    value: _FileAction.save,
                    child: Text(kIsWeb ? '下载 Markdown' : '保存 Markdown'),
                  ),
                  if (!kIsWeb)
                    PopupMenuItem(
                      value: _FileAction.saveAs,
                      child: Text('另存为 Markdown…'),
                    ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _FileAction.png,
                    child: Text('导出 PNG 图片'),
                  ),
                  PopupMenuItem(value: _FileAction.pdf, child: Text('导出 PDF')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentHero extends StatelessWidget {
  const _DocumentHero({required this.doc});

  final NoteDocument doc;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: t.accentSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(doc.icon.iconData, size: 17, color: t.accentPrimary),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: t.sageSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                doc.badge,
                style: MonoNoteTypography.micro(t)
                    .copyWith(color: t.sage, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(doc.title, style: MonoNoteTypography.docTitle(t)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(doc.updatedLabel, style: MonoNoteTypography.micro(t)),
            Text('·', style: MonoNoteTypography.micro(t)),
            for (final tag in doc.tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tag,
                  style: MonoNoteTypography.micro(t).copyWith(
                    color: t.accentPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ComposerRow extends StatelessWidget {
  const _ComposerRow({
    required this.controller,
    required this.slashOpen,
    required this.onToggleSlash,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool slashOpen;
  final VoidCallback onToggleSlash;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.inkMuted.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(t.pillRadius),
        border: Border.all(
          color: slashOpen ? t.accentPrimary : t.borderStrong,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onToggleSlash,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: t.accentSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.plus, size: 13.5, color: t.accentPrimary),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: MonoNoteTypography.body(t)
                  .copyWith(color: t.inkPrimary, fontSize: 14, height: 1.4),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '继续输入文字回车成段，或键入 / 插入块级元素…',
                hintStyle: MonoNoteTypography.body(t)
                    .copyWith(color: t.inkMuted, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostedSlashMenu extends StatelessWidget {
  const _FrostedSlashMenu({required this.onSelect});

  final ValueChanged<NoteBlockType> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    const options = <(NoteBlockType, String, String, String)>[
      (NoteBlockType.heading2, 'H2', '二级章节标题', '#'),
      (NoteBlockType.todo, '✓', '待办任务清单', '[]'),
      (NoteBlockType.callout, '✦', '暖调高亮提示卡', '>'),
      (NoteBlockType.subpageCard, '↗', '嵌套子页面卡片', '[['),
      (NoteBlockType.code, '</>', '代码块片段', '```'),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 260,
        child: FrostedGlassSurface(
          borderRadius: 11,
          strong: true,
          border: Border.all(color: t.borderStrong),
          shadows: [
            BoxShadow(
              color: t.floatShadowColor,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 3, 8, 5),
                child: Text(
                  '插入块级元素',
                  style: MonoNoteTypography.micro(t)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              for (final opt in options)
                InkWell(
                  onTap: () => onSelect(opt.$1),
                  borderRadius: BorderRadius.circular(7),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: t.surfaceCard,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: t.borderSubtle),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            opt.$2,
                            style: MonoNoteTypography.micro(t).copyWith(
                              color: t.inkPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.$3,
                            style: MonoNoteTypography.navLabel(t)
                                .copyWith(color: t.inkPrimary, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: t.inkMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            opt.$4,
                            style: MonoNoteTypography.micro(t),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingFormatToolbar extends StatelessWidget {
  const _FloatingFormatToolbar({
    required this.onInsertHeading,
    required this.onInsertTodo,
    required this.onInsertCallout,
    required this.onInsertCard,
  });

  final VoidCallback onInsertHeading;
  final VoidCallback onInsertTodo;
  final VoidCallback onInsertCallout;
  final VoidCallback onInsertCard;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return FrostedGlassSurface(
      borderRadius: 999,
      strong: true,
      border: Border.all(color: t.borderStrong),
      shadows: [
        BoxShadow(
          color: t.floatShadowColor,
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarChip(label: 'H2', onTap: onInsertHeading),
          _ToolbarChip(label: '待办', onTap: onInsertTodo),
          _ToolbarChip(label: '提示卡', accent: true, onTap: onInsertCallout),
          _ToolbarChip(label: '子页面卡', onTap: onInsertCard),
        ],
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: MonoNoteTypography.micro(t).copyWith(
            color: accent ? t.accentPrimary : t.inkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
