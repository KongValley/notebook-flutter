import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/window_bootstrap.dart';
import '../../core/mononote_shortcuts.dart';
import '../../core/widgets/frosted_glass_surface.dart';
import '../../core/widgets/shortcuts_dialog.dart';
import '../command_palette/widgets/command_palette_dialog.dart';
import '../editor/widgets/paper_editor_canvas.dart';
import '../inspector/widgets/outline_inspector_drawer.dart';
import '../notes/data/markdown_files.dart';
import '../notes/data/note_exports.dart';
import '../notes/state/workspace_controller.dart';
import '../sidebar/widgets/floating_sidebar.dart';
import 'widgets/mono_titlebar.dart';

/// Top-level desktop workspace shell for MonoNote.
class MonoShellPage extends ConsumerWidget {
  const MonoShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(workspaceProvider.notifier);
    final files = ref.read(markdownFilesProvider);
    final exports = ref.read(noteExportsProvider);
    final platform = Theme.of(context).platform;
    final compact = kIsWeb && MediaQuery.sizeOf(context).width < 760;

    return desktopWindowFrame(
      Scaffold(
        backgroundColor: Colors.transparent,
        drawer: compact
            ? const Drawer(
                width: 248,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: FloatingSidebar(inDrawer: true),
                  ),
                ),
              )
            : null,
        body: Builder(
          builder: (context) {
            void toggleSidebar() {
              if (compact) {
                Scaffold.of(context).openDrawer();
              } else {
                controller.toggleSidebar();
              }
            }

            final commands = <MonoShortcut, VoidCallback>{
              MonoShortcut.palette: () => showMonoCommandPalette(context),
              MonoShortcut.sidebar: toggleSidebar,
              MonoShortcut.newNote: () => controller.createPage(),
              MonoShortcut.theme: controller.toggleTheme,
              MonoShortcut.outline: controller.toggleInspector,
              MonoShortcut.previousTab: () => controller.cycleTab(-1),
              MonoShortcut.nextTab: () => controller.cycleTab(1),
              MonoShortcut.help: () => showMonoShortcuts(context),
              MonoShortcut.openMarkdown: () => files.open(context),
              MonoShortcut.saveMarkdown: () => files.save(context),
              MonoShortcut.saveMarkdownAs: () =>
                  files.save(context, saveAs: true),
              MonoShortcut.exportPng: () =>
                  exports.export(context, NoteExportFormat.png),
              MonoShortcut.exportPdf: () =>
                  exports.export(context, NoteExportFormat.pdf),
            };

            return CallbackShortcuts(
              bindings: {
                for (final command in commands.entries)
                  if (command.key.available)
                    command.key.activator(platform): command.value,
              },
              child: FocusScope(
                autofocus: true,
                child: AmbientBackdrop(
                  child: Column(
                    children: [
                      MonoTitlebar(
                        onOpenDrawer: compact ? toggleSidebar : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!compact) const FloatingSidebar(),
                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: const [
                                    Positioned.fill(child: PaperEditorCanvas()),
                                    OutlineInspectorDrawer(),
                                  ],
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
          },
        ),
      ),
    );
  }
}
