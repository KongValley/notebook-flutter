import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Resolves the active desktop window, returning null in headless/test VMs.
Window? getCurrentDesktopWindow() {
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
  final window = getCurrentDesktopWindow();
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
void closeDesktopWindow() {
  final window = getCurrentDesktopWindow();
  if (window == null) return;
  try {
    if (Window.isCloseSupported()) {
      window.close();
    }
  } catch (_) {}
}

/// Safely minimizes or restores the active desktop window.
void minimizeDesktopWindow() {
  final window = getCurrentDesktopWindow();
  if (window == null) return;
  try {
    if (window.isMinimized) {
      window.restore();
    } else {
      window.minimize();
    }
  } catch (_) {}
}
