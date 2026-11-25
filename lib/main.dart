import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/window_bootstrap.dart';
import 'core/theme/mononote_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDesktopWindow();
  await MonoNoteTypography.loadWebFonts();

  runApp(const ProviderScope(child: MonoNoteApp()));
}
