import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../../notes/models/note_models.dart';
import '../../notes/models/note_text.dart';
import 'inline_block_editor.dart';

/// Renders a single document block with subtle hover drag/action affordances.
class NoteBlockItem extends StatefulWidget {
  const NoteBlockItem({
    super.key,
    required this.block,
    required this.onToggleTodo,
    required this.onOpenSubpage,
    required this.onDeleteBlock,
    required this.onChange,
    required this.onMove,
    this.inCardGrid = false,
  });

  final NoteBlock block;
  final VoidCallback onToggleTodo;
  final ValueChanged<String> onOpenSubpage;
  final VoidCallback onDeleteBlock;
  final ValueChanged<NoteText> onChange;
  final void Function(String sourceId, String targetId, {required bool after})
  onMove;
  final bool inCardGrid;

  @override
  State<NoteBlockItem> createState() => _NoteBlockItemState();
}

class _NoteBlockItemState extends State<NoteBlockItem> {
  bool _hovered = false;
  bool? _dropAfter;
  EdgeDraggingAutoScroller? _autoScroller;

  @override
  void dispose() {
    _autoScroller?.stopAutoScroll();
    super.dispose();
  }

  bool _isAfter(Offset offset) {
    final box = context.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(offset);
    return widget.inCardGrid
        ? local.dx >= box.size.width / 2
        : local.dy >= box.size.height / 2;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final block = widget.block;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != block.id,
      onMove: (details) {
        if (details.data == block.id) return;
        final after = _isAfter(details.offset);
        if (after != _dropAfter) setState(() => _dropAfter = after);
      },
      onLeave: (_) {
        if (_dropAfter != null) setState(() => _dropAfter = null);
      },
      onAcceptWithDetails: (details) {
        final after = _isAfter(details.offset);
        setState(() => _dropAfter = null);
        widget.onMove(details.data, block.id, after: after);
      },
      builder: (context, candidates, _) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGrip(t),
                Expanded(child: _buildContent(t)),
              ],
            ),
            if (_hovered)
              Positioned(
                top: 3,
                right: 2,
                child: Tooltip(
                  message: '移除此块',
                  child: InkWell(
                    onTap: widget.onDeleteBlock,
                    canRequestFocus: false,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: t.surfaceCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 13,
                        color: t.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            if (candidates.isNotEmpty && _dropAfter != null)
              Positioned(
                left: widget.inCardGrid && _dropAfter! ? null : 0,
                right: widget.inCardGrid && !_dropAfter! ? null : 0,
                top: !widget.inCardGrid && _dropAfter! ? null : 0,
                bottom: !widget.inCardGrid && !_dropAfter! ? null : 0,
                child: IgnorePointer(
                  child: SizedBox(
                    width: widget.inCardGrid ? 2 : null,
                    height: widget.inCardGrid ? null : 2,
                    child: ColoredBox(color: t.accentPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrip(MonoNoteThemeTokens tokens) {
    final block = widget.block;
    return Draggable<String>(
      key: ValueKey('block-grip-${block.id}'),
      data: block.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: 1,
      onDragStarted: () {
        FocusManager.instance.primaryFocus?.unfocus();
        _autoScroller = EdgeDraggingAutoScroller(
          Scrollable.of(context),
          velocityScalar: 8,
        );
      },
      onDragUpdate: (details) => _autoScroller?.startAutoScrollIfNecessary(
        Rect.fromCenter(center: details.globalPosition, width: 20, height: 64),
      ),
      onDragEnd: (_) {
        _autoScroller?.stopAutoScroll();
        _autoScroller = null;
      },
      feedback: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          margin: const EdgeInsets.only(left: 12, top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(tokens.pillRadius),
            border: Border.all(color: tokens.accentPrimary),
          ),
          child: Text(
            block.targetTitle ?? (block.text.isEmpty ? '空白块' : block.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MonoNoteTypography.micro(tokens),
          ),
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Tooltip(
          message: '拖拽排序',
          child: SizedBox(
            width: 22,
            height: 28,
            child: Icon(
              LucideIcons.gripVertical,
              size: 15,
              color: tokens.inkMuted.withValues(alpha: _hovered ? 1 : 0.38),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MonoNoteThemeTokens t) {
    final block = widget.block;
    Widget editor(TextStyle style, {bool rich = true}) => InlineBlockEditor(
      key: ValueKey('block-edit-${block.id}'),
      content: block.content,
      style: style,
      onChanged: widget.onChange,
      rich: rich,
    );
    final body = MonoNoteTypography.body(t);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 110),
      padding: const EdgeInsets.fromLTRB(4, 4, 24, 4),
      decoration: BoxDecoration(
        color: _hovered
            ? t.inkMuted.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(t.pillRadius),
      ),
      child: switch (block.type) {
        NoteBlockType.callout => _CalloutView(
          child: editor(body.copyWith(fontSize: 13.8)),
        ),
        NoteBlockType.heading2 => _Heading2View(
          child: editor(
            MonoNoteTypography.heading2(t).copyWith(
              fontSize: block.headingLevel == 1
                  ? 23
                  : block.headingLevel > 2
                  ? 15
                  : null,
            ),
          ),
        ),
        NoteBlockType.paragraph => editor(body),
        NoteBlockType.todo => _TodoView(
          checked: block.checked,
          onTap: widget.onToggleTodo,
          child: editor(
            body.copyWith(
              color: block.checked ? t.inkMuted : t.inkPrimary,
              decoration: block.checked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: t.inkMuted,
            ),
          ),
        ),
        NoteBlockType.code || NoteBlockType.markdown => _CodeBlockView(
          label: block.type == NoteBlockType.markdown
              ? 'Markdown 源文'
              : block.codeInfo,
          child: editor(MonoNoteTypography.code(t), rich: false),
        ),
        NoteBlockType.subpageCard => SubpageCardView(
          title: block.targetTitle ?? '子页面',
          excerpt: block.targetExcerpt ?? '',
          icon: block.targetIcon ?? NoteIconKind.file,
          onTap: () {
            final target = block.targetPageId;
            if (target != null) widget.onOpenSubpage(target);
          },
        ),
      },
    );
  }
}

class SubpageCardGrid extends StatelessWidget {
  const SubpageCardGrid({super.key, required this.cards});

  final List<Widget Function(bool)> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 420 && cards.length > 1;
        if (!twoColumns) {
          return Column(children: [for (final card in cards) card(false)]);
        }
        return Column(
          children: [
            for (var index = 0; index < cards.length; index += 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[index](true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: index + 1 < cards.length
                        ? cards[index + 1](true)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Interactive nested document card block with tactile hover elevation.
class SubpageCardView extends StatefulWidget {
  const SubpageCardView({
    super.key,
    required this.title,
    required this.excerpt,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String excerpt;
  final NoteIconKind icon;
  final VoidCallback onTap;

  @override
  State<SubpageCardView> createState() => _SubpageCardViewState();
}

class _SubpageCardViewState extends State<SubpageCardView> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovered ? -1.5 : 0, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered ? t.surfaceCardHover : t.surfaceCard,
            borderRadius: BorderRadius.circular(t.cardRadius),
            border: Border.all(
              color: _hovered ? t.borderStrong : t.borderSubtle,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: t.paperShadowColor,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: t.accentSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon.iconData,
                      size: 13,
                      color: t.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MonoNoteTypography.cardTitle(t),
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 13.5,
                    color: _hovered ? t.accentPrimary : t.inkMuted,
                  ),
                ],
              ),
              if (widget.excerpt.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MonoNoteTypography.cardExcerpt(t),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CalloutView extends StatelessWidget {
  const _CalloutView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: t.surfaceCard,
        borderRadius: BorderRadius.circular(t.cardRadius),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 20,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: t.accentPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 8),
            child: Icon(
              LucideIcons.sparkles,
              size: 14.5,
              color: t.accentPrimary,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Heading2View extends StatelessWidget {
  const _Heading2View({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 15,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: t.accentPrimary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TodoView extends StatelessWidget {
  const _TodoView({
    required this.child,
    required this.checked,
    required this.onTap,
  });

  final Widget child;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '待办状态',
            checked: checked,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.only(top: 3, right: 9, bottom: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: checked ? t.accentPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4.5),
                    border: Border.all(
                      color: checked ? t.accentPrimary : t.borderStrong,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: checked
                      ? const Icon(
                          LucideIcons.check,
                          size: 11,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CodeBlockView extends StatelessWidget {
  const _CodeBlockView({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.codeBg,
        borderRadius: BorderRadius.circular(t.cardRadius),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: MonoNoteTypography.micro(t)),
            const SizedBox(height: 4),
          ],
          child,
        ],
      ),
    );
  }
}
