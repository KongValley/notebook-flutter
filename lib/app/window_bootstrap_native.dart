import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Resolves the active desktop window, returning null in headless/test VMs.
Window? _currentDesktopWindow() {
  if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return null;
  }
  try {
    return WindowManager.instance.getCurrent();
  } on ArgumentError {
    return null;
  } catch (_) {
    return null;
  }
}

/// Configures the frameless unified titlebar and window bounds on startup.
Future<void> configureDesktopWindow() async {
  final window = _currentDesktopWindow();
  if (window == null) return;

  try {
    window.title = 'MonoNote';
    window.titleBarStyle = TitleBarStyle.hidden;
    window.isWindowControlButtonsVisible = Platform.isMacOS;
    window.minimumSize = const Size(760, 520).toNative();
    window.setSize(const Size(1240, 780).toNative(), false);
    window.show();
    window.focus();
  } catch (_) {
    // Gracefully continue if a platform backend does not support a property.
  }
}

/// Safely closes the active desktop window.
void _closeDesktopWindow() {
  final window = _currentDesktopWindow();
  if (window == null) return;
  try {
    if (Window.isCloseSupported()) {
      window.close();
    }
  } catch (_) {}
}

/// Safely minimizes or restores the active desktop window.
void _minimizeDesktopWindow() {
  final window = _currentDesktopWindow();
  if (window == null) return;
  try {
    if (window.isMinimized) {
      window.restore();
    } else {
      window.minimize();
    }
  } catch (_) {}
}

Widget desktopWindowFrame(Widget child) => VirtualWindowFrame(child: child);

Widget desktopDragRegion(Widget child) => DragToMoveArea(child: child);

class DesktopWindowButtons extends StatefulWidget {
  const DesktopWindowButtons({super.key, required this.brightness});

  final Brightness brightness;

  @override
  State<DesktopWindowButtons> createState() => _DesktopWindowButtonsState();
}

class _DesktopWindowButtonsState extends State<DesktopWindowButtons> {
  ListenerId? _listener;
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    final window = _currentDesktopWindow();
    if (window == null) return;
    _maximized = window.isMaximized;
    try {
      _listener = WindowManager.instance.addListener((event) {
        if (!mounted) return;
        switch (event) {
          case WindowMaximizedEvent():
          case WindowRestoredEvent():
          case WindowResizedEvent():
            final maximized = _currentDesktopWindow()?.isMaximized ?? false;
            if (maximized != _maximized) setState(() => _maximized = maximized);
          default:
            break;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_listener case final listener?) {
      try {
        WindowManager.instance.removeListener(listener);
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WindowCaptionButton.minimize(
          brightness: brightness,
          onPressed: _minimizeDesktopWindow,
        ),
        MaximizeButtonArea(
          child: _maximized
              ? WindowCaptionButton.unmaximize(
                  brightness: brightness,
                  onPressed: () => _currentDesktopWindow()?.unmaximize(),
                )
              : WindowCaptionButton.maximize(
                  brightness: brightness,
                  onPressed: () => _currentDesktopWindow()?.maximize(),
                ),
        ),
        WindowCaptionButton.close(
          brightness: brightness,
          onPressed: _closeDesktopWindow,
        ),
      ],
    );
  }
}
