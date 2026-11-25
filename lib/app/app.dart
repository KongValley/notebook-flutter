import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/mononote_tokens.dart';
import '../core/theme/mononote_typography.dart';
import '../features/notes/state/workspace_controller.dart';
import '../features/shell/mono_shell_page.dart';

/// Root application widget configuring MonoNote's dual warm-paper themes.
class MonoNoteApp extends ConsumerWidget {
  const MonoNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      workspaceProvider.select((state) => state.themeMode),
    );

    return MaterialApp(
      title: 'MonoNote',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: MonoNoteTypography.buildTheme(MonoNoteThemeTokens.light),
      darkTheme: MonoNoteTypography.buildTheme(MonoNoteThemeTokens.dark),
      themeAnimationDuration: const Duration(milliseconds: 240),
      themeAnimationCurve: Curves.easeOutCubic,
      home: const MonoShellPage(),
    );
  }
}
