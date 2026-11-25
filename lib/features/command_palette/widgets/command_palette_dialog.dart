import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/mononote_shortcuts.dart';
import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../../../core/widgets/frosted_glass_surface.dart';
import '../../../core/widgets/shortcuts_dialog.dart';
import '../../notes/data/markdown_files.dart';
import '../../notes/data/note_exports.dart';
import '../../notes/state/workspace_controller.dart';

/// Opens MonoNote's frosted global command palette (`Ctrl/Cmd + K`).
Future<void> showMonoCommandPalette(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.24),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      alignment: Alignment.topCenter,
      child: _CommandPaletteModal(workspaceContext: context),
    ),
  );
}

class _CommandItem {
  const _CommandItem({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onExecute,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onExecute;
}

class _CommandPaletteModal extends ConsumerStatefulWidget {
  const _CommandPaletteModal({required this.workspaceContext});

  final BuildContext workspaceContext;

  @override
  ConsumerState<_CommandPaletteModal> createState() =>
      _CommandPaletteModalState();
}

class _CommandPaletteModalState extends ConsumerState<_CommandPaletteModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final state = ref.watch(workspaceProvider);
    final controller = ref.read(workspaceProvider.notifier);
    final files = ref.read(markdownFilesProvider);
    final exports = ref.read(noteExportsProvider);
    final platform = Theme.of(context).platform;
    final workspaceContext = widget.workspaceContext;

    _CommandItem command(
      MonoShortcut shortcut,
      IconData icon,
      VoidCallback execute, {
      String? label,
    }) => _CommandItem(
      icon: icon,
      label: label ?? shortcut.label,
      hint: shortcut.keys(platform),
      onExecute: execute,
    );

    final commands = <_CommandItem>[
      command(
        MonoShortcut.help,
        LucideIcons.keyboard,
        () => showMonoShortcuts(workspaceContext),
      ),
      for (final doc in state.documents.values)
        _CommandItem(
          icon: doc.icon.iconData,
          label: '打开页面：${doc.title}',
          hint: doc.badge,
          onExecute: () => controller.openPage(doc.id),
        ),
      command(
        MonoShortcut.newNote,
        LucideIcons.plus,
        () => controller.createPage(),
        label: '新建空白笔记页面',
      ),
      command(
        MonoShortcut.openMarkdown,
        LucideIcons.folderOpen,
        () => files.open(workspaceContext),
      ),
      command(
        MonoShortcut.saveMarkdown,
        LucideIcons.save,
        () => files.save(workspaceContext),
      ),
      if (!kIsWeb)
        command(
          MonoShortcut.saveMarkdownAs,
          LucideIcons.fileDown,
          () => files.save(workspaceContext, saveAs: true),
        ),
      command(
        MonoShortcut.exportPng,
        LucideIcons.image,
        () => exports.export(workspaceContext, NoteExportFormat.png),
      ),
      command(
        MonoShortcut.exportPdf,
        LucideIcons.fileText,
        () => exports.export(workspaceContext, NoteExportFormat.pdf),
      ),
      command(
        MonoShortcut.theme,
        t.isDark ? LucideIcons.sun : LucideIcons.moon,
        controller.toggleTheme,
        label: t.isDark ? '切换到晨曦素笺（浅色纸感）' : '切换到松烟夜读（暗色墨韵）',
      ),
      command(
        MonoShortcut.sidebar,
        LucideIcons.panelLeft,
        controller.toggleSidebar,
        label: state.isSidebarOpen ? '折叠左侧浮动磨砂栏' : '展开左侧浮动磨砂栏',
      ),
      command(
        MonoShortcut.outline,
        LucideIcons.alignLeft,
        controller.toggleInspector,
        label: state.isInspectorOpen ? '隐藏右侧文档大纲' : '显示右侧文档大纲',
      ),
    ];

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? commands
        : commands.where((c) => c.label.toLowerCase().contains(q)).toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: FrostedGlassSurface(
        borderRadius: t.windowRadius,
        strong: true,
        border: Border.all(color: t.borderStrong),
        shadows: [
          BoxShadow(
            color: t.floatShadowColor,
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.borderSubtle)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 15, color: t.accentPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      style: MonoNoteTypography.body(t)
                          .copyWith(color: t.inkPrimary, height: 1.3),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '搜索页面、切换主题或执行命令…',
                        hintStyle: MonoNoteTypography.body(t)
                            .copyWith(color: t.inkMuted, height: 1.3),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t.inkMuted.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: t.borderSubtle),
                    ),
                    child: Text('ESC', style: MonoNoteTypography.micro(t)),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '没有匹配的页面或命令',
                        style: MonoNoteTypography.cardExcerpt(t),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(6),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _CommandRow(
                          item: item,
                          onTap: () {
                            Navigator.of(context).pop();
                            item.onExecute();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandRow extends StatefulWidget {
  const _CommandRow({required this.item, required this.onTap});

  final _CommandItem item;
  final VoidCallback onTap;

  @override
  State<_CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends State<_CommandRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? t.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(t.pillRadius),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 14,
                color: _hovered ? t.accentPrimary : t.inkSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MonoNoteTypography.navLabel(
                    t,
                  ).copyWith(color: _hovered ? t.accentPrimary : t.inkPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: t.inkMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: t.borderSubtle),
                ),
                child: Text(
                  widget.item.hint,
                  style: MonoNoteTypography.micro(t).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
