import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/window_bootstrap.dart';
import '../../core/widgets/frosted_glass_surface.dart';
import '../command_palette/widgets/command_palette_dialog.dart';
import '../editor/widgets/paper_editor_canvas.dart';
import '../inspector/widgets/outline_inspector_drawer.dart';
import '../notes/data/markdown_files.dart';
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
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
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

            SingleActivator shortcut(
              LogicalKeyboardKey key, {
              bool shift = false,
            }) => SingleActivator(
              key,
              control: !isMac,
              meta: isMac,
              shift: shift,
            );

            return CallbackShortcuts(
              bindings: {
                shortcut(LogicalKeyboardKey.keyK): () =>
                    showMonoCommandPalette(context),
                shortcut(LogicalKeyboardKey.backslash): toggleSidebar,
                shortcut(LogicalKeyboardKey.keyN): () =>
                    controller.createPage(),
                shortcut(LogicalKeyboardKey.keyL, shift: true):
                    controller.toggleTheme,
                shortcut(LogicalKeyboardKey.keyO): () => files.open(context),
                shortcut(LogicalKeyboardKey.keyS): () => files.save(context),
                if (!kIsWeb)
                  shortcut(LogicalKeyboardKey.keyS, shift: true): () =>
                      files.save(context, saveAs: true),
              },
              child: Focus(
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
