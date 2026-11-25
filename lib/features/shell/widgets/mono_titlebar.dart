import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/window_bootstrap.dart';
import '../../../core/mononote_shortcuts.dart';
import '../../../core/theme/mononote_tokens.dart';
import '../../../core/theme/mononote_typography.dart';
import '../../../core/widgets/frosted_glass_surface.dart';
import '../../../core/widgets/mononote_logo_mark.dart';
import '../../command_palette/widgets/command_palette_dialog.dart';
import '../../notes/models/note_models.dart';
import '../../notes/state/workspace_controller.dart';

/// Unified 42px frosted glass titlebar with animated sliding document tabs,
/// centered search capsule, and platform-adaptive window controls.
class MonoTitlebar extends ConsumerWidget {
  const MonoTitlebar({super.key, this.onOpenDrawer});

  final VoidCallback? onOpenDrawer;
  bool get _isMac => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  bool get _isDesktopNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.monoTokens;
    final state = ref.watch(workspaceProvider);
    final controller = ref.read(workspaceProvider.notifier);
    final compact = onOpenDrawer != null;
    final platform = Theme.of(context).platform;
    final shortcutLabel = MonoShortcut.palette.keys(platform);
    final sidebarShortcut = MonoShortcut.sidebar.keys(platform);

    return SizedBox(
      height: 42,
      child: FrostedGlassSurface(
        borderRadius: 0,
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
        padding: EdgeInsets.only(
          left: _isMac ? 74 : 10,
          right: _isDesktopNative ? 0 : 8,
        ),
        child: Row(
          children: [
            if (!_isMac) ...[
              const MonoNoteLogoMark(size: 26),
              const SizedBox(width: 8),
            ],
            _TitlebarIconButton(
              icon: LucideIcons.panelLeft,
              tooltip: compact ? '打开工作空间' : '折叠/展开浮动侧栏 ($sidebarShortcut)',
              isActive: !compact && state.isSidebarOpen,
              onTap: onOpenDrawer ?? controller.toggleSidebar,
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 6,
              child: SizedBox.expand(
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    Positioned.fill(
                      child: desktopDragRegion(const SizedBox.expand()),
                    ),
                    _AnimatedTabsStrip(
                      openTabs: state.openTabs,
                      activePageId: state.activePageId,
                      documents: state.documents,
                      onSelectTab: controller.openPage,
                      onCloseTab: controller.closeTab,
                    ),
                  ],
                ),
              ),
            ),
            if (compact)
              _TitlebarIconButton(
                icon: LucideIcons.search,
                tooltip: '搜索或命令 ($shortcutLabel)',
                isActive: false,
                onTap: () => showMonoCommandPalette(context),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _SearchCapsule(
                  shortcutLabel: shortcutLabel,
                  onTap: () => showMonoCommandPalette(context),
                ),
              ),
              Expanded(
                flex: 4,
                child: desktopDragRegion(const SizedBox.expand()),
              ),
              _TitlebarIconButton(
                icon: LucideIcons.sparkles,
                tooltip: '显示/隐藏悬浮格式条',
                isActive: state.isFloatingToolbarVisible,
                onTap: controller.toggleFloatingToolbar,
              ),
            ],
            const SizedBox(width: 2),
            _TitlebarIconButton(
              icon: t.isDark ? LucideIcons.sun : LucideIcons.moon,
              tooltip: t.isDark ? '切换到晨曦素笺（浅色）' : '切换到松烟夜读（暗色）',
              isActive: false,
              onTap: controller.toggleTheme,
            ),
            const SizedBox(width: 2),
            _TitlebarIconButton(
              icon: LucideIcons.alignLeft,
              tooltip: '页面大纲与文档统计',
              isActive: state.isInspectorOpen,
              onTap: controller.toggleInspector,
            ),
            if (_isDesktopNative) ...[
              const SizedBox(width: 6),
              Container(width: 1, height: 18, color: t.borderSubtle),
              SizedBox(
                height: 42,
                child: DesktopWindowButtons(brightness: t.brightness),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const _tabMotionDuration = Duration(milliseconds: 200);
const _tabMotionCurve = Cubic(0.22, 1.0, 0.36, 1.0);
const _tabHeight = 28.0;
const _tabGap = 4.0;
const _tabPadding = 9.0;
const _tabIconSize = 13.0;
const _tabIconGap = 6.0;
const _tabCloseGap = 5.0;
const _tabCloseSize = 18.0;
const _tabMaxWidth = 200.0;

TextStyle _tabLabelStyle(MonoNoteThemeTokens tokens) =>
    MonoNoteTypography.navLabel(tokens).copyWith(fontSize: 12);

/// Horizontal scrollable tab strip with a sliding active indicator.
class _AnimatedTabsStrip extends StatefulWidget {
  const _AnimatedTabsStrip({
    required this.openTabs,
    required this.activePageId,
    required this.documents,
    required this.onSelectTab,
    required this.onCloseTab,
  });

  final List<String> openTabs;
  final String activePageId;
  final Map<String, NoteDocument> documents;
  final ValueChanged<String> onSelectTab;
  final ValueChanged<String> onCloseTab;

  @override
  State<_AnimatedTabsStrip> createState() => _AnimatedTabsStripState();
}

class _AnimatedTabsStripState extends State<_AnimatedTabsStrip>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _scrollAnimator;
  (String, Rect, double, double, Duration)? _revealLayout;
  double _scrollStart = 0;
  double _scrollEnd = 0;
  bool _animateNewTabs = false;

  @override
  void initState() {
    super.initState();
    _scrollAnimator = AnimationController(vsync: this)
      ..addListener(_onScrollTick);
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animateNewTabs = true;
  }

  @override
  void dispose() {
    _scrollAnimator.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollTick() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final eased = _tabMotionCurve.transform(_scrollAnimator.value);
    final next = lerpDouble(
      _scrollStart,
      _scrollEnd,
      eased,
    )!.clamp(position.minScrollExtent, position.maxScrollExtent);
    position.jumpTo(next);
  }

  void _revealActiveTab(Rect bounds, Duration duration) {
    final position = _scrollController.position;
    final pixels = position.pixels;
    final viewport = position.viewportDimension;
    const edgePad = 12.0;
    final target = switch (bounds) {
      _ when bounds.width > viewport => bounds.left - edgePad,
      _ when bounds.left < pixels => bounds.left - edgePad,
      _ when bounds.right > pixels + viewport =>
        bounds.right - viewport + edgePad,
      _ => pixels,
    }.clamp(position.minScrollExtent, position.maxScrollExtent);

    if (target == pixels || duration == Duration.zero) {
      _scrollAnimator.stop();
      if (target != pixels) {
        position.jumpTo(target);
      }
      return;
    }

    // Drive scroll with jumpTo via AnimationController instead of animateTo so
    // Scrollable's IgnorePointer never blocks rapid tab clicks mid-scroll.
    _scrollStart = pixels;
    _scrollEnd = target;
    _scrollAnimator.duration = duration;
    _scrollAnimator.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _tabMotionDuration;
    final labelStyle = DefaultTextStyle.of(context).style
        .merge(_tabLabelStyle(t));
    final measureStyle = MediaQuery.boldTextOf(context)
        ? labelStyle.merge(const TextStyle(fontWeight: FontWeight.bold))
        : labelStyle;
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    final tabs = <Widget>[];
    Rect? activeBounds;
    var left = 0.0;

    for (final tabId in widget.openTabs) {
      final doc = widget.documents[tabId];
      if (doc == null) continue;
      final labelWidth = TextPainter.computeWidth(
        text: TextSpan(text: doc.title, style: measureStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
        maxLines: 1,
      );
      final width =
          (labelWidth.ceilToDouble() +
                  2 * _tabPadding +
                  _tabIconSize +
                  _tabIconGap +
                  _tabCloseGap +
                  _tabCloseSize)
              .clamp(0.0, _tabMaxWidth);
      final isActive = tabId == widget.activePageId;
      if (isActive) {
        activeBounds = Rect.fromLTWH(left, 1, width, _tabHeight);
      }
      tabs.add(
        _TitlebarTab(
          key: ValueKey(tabId),
          doc: doc,
          width: width,
          motionDuration: duration,
          animateEntrance: _animateNewTabs && duration != Duration.zero,
          isActive: isActive,
          canClose: widget.openTabs.length > 1,
          onSelect: () => widget.onSelectTab(tabId),
          onClose: () => widget.onCloseTab(tabId),
        ),
      );
      left += width + _tabGap;
    }

    final bounds = activeBounds;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (bounds != null) {
          final layout = (
            widget.activePageId,
            bounds,
            constraints.maxWidth,
            left,
            duration,
          );
          if (layout != _revealLayout) {
            _revealLayout = layout;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _revealLayout == layout &&
                  _scrollController.hasClients) {
                _revealActiveTab(bounds, duration);
              }
            });
          }
        } else {
          _revealLayout = null;
        }

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _tabGap,
              children: tabs,
            ),
          ),
        );
      },
    );
  }
}

class _TitlebarIconButton extends StatefulWidget {
  const _TitlebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_TitlebarIconButton> createState() => _TitlebarIconButtonState();
}

class _TitlebarIconButtonState extends State<_TitlebarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final bg = widget.isActive || _hovered ? t.accentSoft : Colors.transparent;
    final fg = widget.isActive
        ? t.accentPrimary
        : (_hovered ? t.inkPrimary : t.inkSecondary);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 14.5, color: fg),
          ),
        ),
      ),
    );
  }
}

class _TitlebarTab extends StatefulWidget {
  const _TitlebarTab({
    super.key,
    required this.doc,
    required this.width,
    required this.motionDuration,
    required this.animateEntrance,
    required this.isActive,
    required this.canClose,
    required this.onSelect,
    required this.onClose,
  });

  final NoteDocument doc;
  final double width;
  final Duration motionDuration;
  final bool animateEntrance;
  final bool isActive;
  final bool canClose;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  State<_TitlebarTab> createState() => _TitlebarTabState();
}

class _TitlebarTabState extends State<_TitlebarTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    // Always keep the same base RGB when alpha is 0 so Color.lerp never passes
    // through muddy gray/black (Colors.transparent is 0x00000000).
    final tabBg = widget.isActive
        ? t.surfacePaper
        : (_hovered
              ? t.surfacePaper.withValues(alpha: 0.48)
              : t.surfacePaper.withValues(alpha: 0));
    final tabBorder = widget.isActive
        ? t.borderStrong.withValues(alpha: 0.55)
        : (_hovered
              ? t.borderSubtle.withValues(alpha: 0.45)
              : t.borderSubtle.withValues(alpha: 0));

    return Semantics(
      selected: widget.isActive,
      child: TweenAnimationBuilder<double>(
        duration: widget.motionDuration,
        curve: _tabMotionCurve,
        tween: Tween(begin: widget.animateEntrance ? 0.65 : 1, end: 1),
        builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onSelect,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: widget.width,
              height: _tabHeight,
              child: AnimatedContainer(
                duration: widget.motionDuration,
                curve: _tabMotionCurve,
                padding: const EdgeInsets.symmetric(horizontal: _tabPadding),
                decoration: BoxDecoration(
                  color: tabBg,
                  borderRadius: BorderRadius.circular(t.pillRadius),
                  border: Border.all(color: tabBorder),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isActive
                          ? t.paperShadowColor
                          : t.paperShadowColor.withValues(alpha: 0),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  duration: widget.motionDuration,
                  curve: _tabMotionCurve,
                  tween: Tween(end: widget.isActive ? 1 : 0),
                  builder: (context, selection, _) => Row(
                    children: [
                      Icon(
                        widget.doc.icon.iconData,
                        size: _tabIconSize,
                        color: Color.lerp(
                          t.inkSecondary,
                          t.accentPrimary,
                          selection,
                        ),
                      ),
                      const SizedBox(width: _tabIconGap),
                      Expanded(
                        child: Text(
                          widget.doc.title,
                          style: _tabLabelStyle(t).copyWith(
                            color: Color.lerp(
                              t.inkSecondary,
                              t.inkPrimary,
                              selection,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: _tabCloseGap),
                      SizedBox.square(
                        dimension: _tabCloseSize,
                        child: widget.canClose
                            ? _TabCloseButton(
                                key: ValueKey('tab-close-${widget.doc.id}'),
                                tabActiveOrHovered: widget.isActive || _hovered,
                                motionDuration: widget.motionDuration,
                                onClose: widget.onClose,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabCloseButton extends StatefulWidget {
  const _TabCloseButton({
    super.key,
    required this.tabActiveOrHovered,
    required this.motionDuration,
    required this.onClose,
  });

  final bool tabActiveOrHovered;
  final Duration motionDuration;
  final VoidCallback onClose;

  @override
  State<_TabCloseButton> createState() => _TabCloseButtonState();
}

class _TabCloseButtonState extends State<_TabCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final bg = _hovered ? t.accentSoft : t.accentSoft.withValues(alpha: 0);
    final fg = _hovered
        ? t.accentPrimary
        : t.inkSecondary.withValues(
            alpha: widget.tabActiveOrHovered ? 0.85 : 0.45,
          );

    return Tooltip(
      message: '关闭标签',
      child: Semantics(
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: widget.motionDuration,
              curve: _tabMotionCurve,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.x, size: 12, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchCapsule extends StatefulWidget {
  const _SearchCapsule({required this.shortcutLabel, required this.onTap});

  final String shortcutLabel;
  final VoidCallback onTap;

  @override
  State<_SearchCapsule> createState() => _SearchCapsuleState();
}

class _SearchCapsuleState extends State<_SearchCapsule> {
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
          height: 28,
          constraints: const BoxConstraints(minWidth: 148, maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: t.glassStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _hovered ? t.borderStrong : t.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.search,
                    size: 12.5,
                    color: _hovered ? t.inkPrimary : t.inkSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '搜索或命令…',
                    style: MonoNoteTypography.micro(t).copyWith(
                      fontSize: 12,
                      color: _hovered ? t.inkPrimary : t.inkSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: t.inkMuted.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: t.borderSubtle),
                ),
                child: Text(
                  widget.shortcutLabel,
                  style: MonoNoteTypography.micro(t).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
