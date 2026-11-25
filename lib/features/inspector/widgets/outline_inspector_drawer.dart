import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../../../core/widgets/frosted_glass_surface.dart';
import '../../notes/state/workspace_controller.dart';

/// Slide-over frosted glass inspector showing dynamic document outline and
/// local workspace metadata.
class OutlineInspectorDrawer extends ConsumerWidget {
  const OutlineInspectorDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.monoTokens;
    final state = ref.watch(workspaceProvider);
    final controller = ref.read(workspaceProvider.notifier);
    final doc = state.activeDocument;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      top: 0,
      bottom: 0,
      right: state.isInspectorOpen ? 0 : -236,
      width: 220,
      child: IgnorePointer(
        ignoring: !state.isInspectorOpen,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: state.isInspectorOpen ? 1 : 0,
          child: FrostedGlassSurface(
            borderRadius: t.panelRadius,
            strong: true,
            border: Border.all(color: t.borderStrong),
            shadows: [
              BoxShadow(
                color: t.floatShadowColor,
                blurRadius: 28,
                offset: const Offset(-4, 8),
              ),
            ],
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '文档大纲',
                      style: MonoNoteTypography.micro(t).copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    InkWell(
                      onTap: controller.toggleInspector,
                      borderRadius: BorderRadius.circular(5),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          LucideIcons.x,
                          size: 13,
                          color: t.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: doc.outline.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final isFirst = index == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isFirst ? t.accentSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(
                              width: 2,
                              color: isFirst
                                  ? t.accentPrimary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          doc.outline[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MonoNoteTypography.cardExcerpt(t).copyWith(
                            color: isFirst ? t.accentPrimary : t.inkSecondary,
                            fontWeight:
                                isFirst ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.borderSubtle)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '关联子页：${doc.childrenIds.length} 篇文档',
                        style: MonoNoteTypography.micro(t),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '字符统计：${doc.wordCount} 字',
                        style: MonoNoteTypography.micro(t),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
