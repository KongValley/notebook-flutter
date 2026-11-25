import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

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
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(
          LogicalKeyboardKey.keyK,
          control: !isMac,
          meta: isMac,
        ): () =>
            showMonoCommandPalette(context),
        SingleActivator(
          LogicalKeyboardKey.backslash,
          control: !isMac,
          meta: isMac,
        ): controller.toggleSidebar,
        SingleActivator(
          LogicalKeyboardKey.keyN,
          control: !isMac,
          meta: isMac,
        ): () =>
            controller.createPage(),
        SingleActivator(
          LogicalKeyboardKey.keyL,
          control: !isMac,
          meta: isMac,
          shift: true,
        ): controller.toggleTheme,
        SingleActivator(
          LogicalKeyboardKey.keyO,
          control: !isMac,
          meta: isMac,
        ): () =>
            files.open(context),
        SingleActivator(
          LogicalKeyboardKey.keyS,
          control: !isMac,
          meta: isMac,
        ): () =>
            files.save(context),
        SingleActivator(
          LogicalKeyboardKey.keyS,
          control: !isMac,
          meta: isMac,
          shift: true,
        ): () =>
            files.save(context, saveAs: true),
      },
      child: Focus(
        autofocus: true,
        child: VirtualWindowFrame(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AmbientBackdrop(
              child: Column(
                children: [
                  const MonoTitlebar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FloatingSidebar(),
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
        ),
      ),
    );
  }
}
