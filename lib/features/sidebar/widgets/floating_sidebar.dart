import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../../../core/widgets/frosted_glass_surface.dart';
import '../../notes/models/note_models.dart';
import '../../notes/state/workspace_controller.dart';

/// Collapsible floating frosted glass sidebar hosting quick links, hierarchical
/// workspace tree, tags, and local-first storage status.
class FloatingSidebar extends ConsumerWidget {
  const FloatingSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.monoTokens;
    final state = ref.watch(workspaceProvider);
    final controller = ref.read(workspaceProvider.notifier);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      width: state.isSidebarOpen ? 224 : 0,
      margin: EdgeInsets.only(right: state.isSidebarOpen ? 8 : 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: state.isSidebarOpen ? 1 : 0,
        child: IgnorePointer(
          ignoring: !state.isSidebarOpen,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 224,
            maxWidth: 224,
            child: FrostedGlassSurface(
              borderRadius: t.panelRadius,
              shadows: [
                BoxShadow(
                  color: t.paperShadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      children: [
                        const _SectionHeader(label: '快捷入口'),
                        const SizedBox(height: 4),
                        for (final doc in state.quickLinkDocuments)
                          _SidebarPageTile(
                            doc: doc,
                            isActive: doc.id == state.activePageId,
                            hasChildren: false,
                            isExpanded: false,
                            indentLevel: 0,
                            onTap: () => controller.openPage(doc.id),
                          ),
                        const SizedBox(height: 14),
                        _SectionHeader(
                          label: '工作空间',
                          trailing: Tooltip(
                            message: '新建笔记页面',
                            child: InkWell(
                              onTap: () => controller.createPage(),
                              borderRadius: BorderRadius.circular(5),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  LucideIcons.plus,
                                  size: 13,
                                  color: t.inkMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final root in state.rootTreeDocuments)
                          ..._buildTreeBranch(
                            doc: root,
                            state: state,
                            controller: controller,
                            indentLevel: 0,
                          ),
                        const SizedBox(height: 14),
                        const _SectionHeader(label: '标签集合'),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final tag in state.allTags)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.inkMuted.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: t.borderSubtle),
                                  ),
                                  child: Text(
                                    tag,
                                    style: MonoNoteTypography.micro(t)
                                        .copyWith(color: t.inkSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.borderSubtle)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: t.sage,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('本地工作区', style: MonoNoteTypography.micro(t)),
                          ],
                        ),
                        Text('v0.1', style: MonoNoteTypography.micro(t)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTreeBranch({
    required NoteDocument doc,
    required WorkspaceState state,
    required WorkspaceController controller,
    required int indentLevel,
  }) {
    final hasChildren = doc.childrenIds.isNotEmpty;
    final isExpanded = state.expandedTreeIds.contains(doc.id);
    final items = <Widget>[
      _SidebarPageTile(
        doc: doc,
        isActive: doc.id == state.activePageId,
        hasChildren: hasChildren,
        isExpanded: isExpanded,
        indentLevel: indentLevel,
        onTap: () => controller.openPage(doc.id),
        onToggleExpand: hasChildren
            ? () => controller.toggleTreeExpand(doc.id)
            : null,
      ),
    ];

    if (hasChildren && isExpanded) {
      for (final childId in doc.childrenIds) {
        final child = state.documents[childId];
        if (child != null) {
          items.addAll(
            _buildTreeBranch(
              doc: child,
              state: state,
              controller: controller,
              indentLevel: indentLevel + 1,
            ),
          );
        }
      }
    }
    return items;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: MonoNoteTypography.micro(t)
                .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SidebarPageTile extends StatefulWidget {
  const _SidebarPageTile({
    required this.doc,
    required this.isActive,
    required this.hasChildren,
    required this.isExpanded,
    required this.indentLevel,
    required this.onTap,
    this.onToggleExpand,
  });

  final NoteDocument doc;
  final bool isActive;
  final bool hasChildren;
  final bool isExpanded;
  final int indentLevel;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpand;

  @override
  State<_SidebarPageTile> createState() => _SidebarPageTileState();
}

class _SidebarPageTileState extends State<_SidebarPageTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final bgColor = widget.isActive
        ? t.accentSoft
        : (_hovered ? t.inkMuted.withValues(alpha: 0.10) : Colors.transparent);
    final fgColor = widget.isActive
        ? t.accentPrimary
        : (_hovered ? t.inkPrimary : t.inkSecondary);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.only(
            left: 8.0 + widget.indentLevel * 16.0,
            right: 8,
            top: 5.5,
            bottom: 5.5,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(t.pillRadius),
          ),
          child: Row(
            children: [
              if (widget.hasChildren)
                GestureDetector(
                  onTap: widget.onToggleExpand,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      widget.isExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 12,
                      color: fgColor.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              Icon(widget.doc.icon.iconData, size: 13.5, color: fgColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  widget.doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MonoNoteTypography.navLabel(t).copyWith(
                    color: fgColor,
                    fontSize: widget.indentLevel > 0 ? 12.2 : 12.8,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.doc.quickCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: t.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.doc.quickCount}',
                    style: MonoNoteTypography.micro(t).copyWith(
                      color: t.accentPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5,
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
