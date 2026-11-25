import 'package:flutter/material.dart';

/// Displays the official MonoNote folded-vellum-paper app icon cleanly at
/// any UI size with high-quality filtering.
class MonoNoteLogoMark extends StatelessWidget {
  const MonoNoteLogoMark({
    super.key,
    this.size = 24,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MonoNote Logo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          'assets/logo/mononote_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        ),
      ),
    );
  }
}
