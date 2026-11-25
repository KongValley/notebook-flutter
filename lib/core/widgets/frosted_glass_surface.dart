import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/mononote_tokens.dart';

/// Reusable frosted glass container isolated with [RepaintBoundary] to keep
/// desktop frame rates smooth during scrolling and animations.
class FrostedGlassSurface extends StatelessWidget {
  const FrostedGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.strong = false,
    this.border,
    this.shadows,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final bool strong;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;
    final radius = BorderRadius.circular(borderRadius);
    final fillColor = strong ? t.glassStrong : t.glassChrome;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadows,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: t.blurSigma,
              sigmaY: t.blurSigma,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: radius,
                border: border ??
                    Border.all(
                      color: strong ? t.borderStrong : t.borderSubtle,
                      width: 1,
                    ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.08, 1.0],
                  colors: [
                    t.glassHighlight.withValues(alpha: t.isDark ? 0.08 : 0.42),
                    fillColor,
                    fillColor,
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Warm ambient backdrop with soft diffused orbs behind translucent chrome.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.monoTokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.ambientStart, t.ambientEnd],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  Positioned(
                    top: -70,
                    left: -50,
                    child: _SoftOrb(color: t.orbPrimary, size: 320),
                  ),
                  Positioned(
                    bottom: -60,
                    left: 80,
                    child: _SoftOrb(color: t.orbSecondary, size: 300),
                  ),
                  Positioned(
                    top: -80,
                    right: 90,
                    child: _SoftOrb(color: t.orbTertiary, size: 340),
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
