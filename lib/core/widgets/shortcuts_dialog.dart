import 'package:flutter/material.dart';

import '../mononote_shortcuts.dart';

Future<void> showMonoShortcuts(BuildContext context) {
  final platform = Theme.of(context).platform;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('键盘快捷键'),
      scrollable: true,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final shortcut in MonoShortcut.values)
              if (shortcut.available)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text(shortcut.label)),
                      const SizedBox(width: 12),
                      Text(
                        shortcut.keys(platform),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
