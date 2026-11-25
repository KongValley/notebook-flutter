import 'package:flutter/widgets.dart';

Future<void> configureDesktopWindow() async {}

Widget desktopWindowFrame(Widget child) => child;

Widget desktopDragRegion(Widget child) => child;

class DesktopWindowButtons extends StatelessWidget {
  const DesktopWindowButtons({super.key, required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
