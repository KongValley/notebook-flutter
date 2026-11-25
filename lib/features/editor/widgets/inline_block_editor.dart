import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/mononote_shortcuts.dart';
import '../../../core/theme/mononote_tokens.dart';
import '../../notes/models/note_text.dart';
import '../../notes/presentation/note_mark_style.dart';

const _markActions = [
  (NoteMark.bold, LucideIcons.bold, MonoShortcut.bold),
  (NoteMark.italic, LucideIcons.italic, MonoShortcut.italic),
  (NoteMark.strike, LucideIcons.strikethrough, MonoShortcut.strike),
  (NoteMark.code, LucideIcons.code, MonoShortcut.code),
];

class InlineBlockEditor extends StatefulWidget {
  const InlineBlockEditor({
    super.key,
    required this.content,
    required this.style,
    required this.onChanged,
    this.rich = true,
  });

  final NoteText content;
  final TextStyle style;
  final ValueChanged<NoteText> onChanged;
  final bool rich;

  @override
  State<InlineBlockEditor> createState() => _InlineBlockEditorState();
}

class _InlineBlockEditorState extends State<InlineBlockEditor> {
  late final _BlockEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = _BlockEditingController(widget.content);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(InlineBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_controller.content.sameAs(widget.content)) {
      _controller.setContent(widget.content);
    }
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) _controller.typingMarks = null;
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggle(NoteMark mark) {
    if (!_focus.hasFocus ||
        !_controller.selection.isValid ||
        _controller.value.isComposingRangeValid &&
            !_controller.value.composing.isCollapsed) {
      return;
    }
    if (_controller.toggleMark(mark)) widget.onChanged(_controller.content);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      groupId: _controller,
      controller: _controller,
      focusNode: _focus,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: widget.style,
      onChanged: (_) => widget.onChanged(_controller.content),
      decoration: const InputDecoration.collapsed(hintText: '输入内容…'),
    );
    if (!widget.rich) return field;
    final platform = Theme.of(context).platform;
    return CallbackShortcuts(
      bindings: {
        for (final (mark, _, shortcut) in _markActions)
          shortcut.activator(platform): () => _toggle(mark),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          if (_focus.hasFocus)
            TextFieldTapRegion(
              groupId: _controller,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) => Align(
                  alignment: Alignment.centerLeft,
                  child: _FormatButtons(
                    controller: _controller,
                    onToggle: _toggle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormatButtons extends StatelessWidget {
  const _FormatButtons({required this.controller, required this.onToggle});

  final _BlockEditingController controller;
  final ValueChanged<NoteMark> onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.monoTokens;
    final platform = Theme.of(context).platform;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mark, icon, shortcut) in _markActions)
            Tooltip(
              message: '${shortcut.label} (${shortcut.keys(platform)})',
              child: Semantics(
                button: true,
                selected: controller.isMarked(mark),
                child: InkWell(
                  key: ValueKey('format-${mark.name}'),
                  canRequestFocus: false,
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => onToggle(mark),
                  child: Container(
                    width: 28,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.isMarked(mark)
                          ? tokens.accentSoft
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(icon, size: 15, color: tokens.inkPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockEditingController extends TextEditingController {
  _BlockEditingController(this.content) : super(text: content.text);

  NoteText content;
  int? typingMarks;

  void setContent(NoteText next) {
    content = next;
    typingMarks = null;
    if (text == next.text) {
      notifyListeners();
    } else {
      super.value = TextEditingValue(
        text: next.text,
        selection: TextSelection.collapsed(offset: next.text.length),
      );
    }
  }

  bool isMarked(NoteMark mark) {
    if (!selection.isValid) return false;
    if (selection.isCollapsed && typingMarks != null) {
      return typingMarks! & mark.mask != 0;
    }
    return content.hasMark(selection.start, selection.end, mark);
  }

  bool toggleMark(NoteMark mark) {
    if (selection.isCollapsed) {
      typingMarks =
          (typingMarks ?? content.marksAt(selection.start)) ^ mark.mask;
      notifyListeners();
      return false;
    }
    content = content.toggleMark(selection.start, selection.end, mark);
    notifyListeners();
    return true;
  }

  @override
  set value(TextEditingValue next) {
    final previous = super.value;
    if (next.text != previous.text) {
      final (start, end, newEnd) = _changedRange(previous, next);
      final inherited = start < end && content.text.isNotEmpty
          ? content.marksAt(start + 1)
          : content.marksAt(start);
      content = content.replace(
        start,
        end,
        next.text.substring(start, newEnd),
        typingMarks ?? inherited,
      );
    } else if (next.selection != previous.selection &&
        next.composing == previous.composing) {
      typingMarks = null;
    }
    super.value = next;
  }

  static (int, int, int) _changedRange(
    TextEditingValue previous,
    TextEditingValue next,
  ) {
    final before = previous.text;
    final after = next.text;
    final range =
        previous.isComposingRangeValid && !previous.composing.isCollapsed
        ? previous.composing
        : previous.selection;
    if (range.isValid && range.isNormalized) {
      final replacementEnd = after.length - (before.length - range.end);
      if (replacementEnd >= range.start &&
          after.startsWith(before.substring(0, range.start)) &&
          after.endsWith(before.substring(range.end))) {
        return (range.start, range.end, replacementEnd);
      }
    }
    var start = 0;
    var end = before.length;
    var newEnd = after.length;
    while (start < end &&
        start < newEnd &&
        before.codeUnitAt(start) == after.codeUnitAt(start)) {
      start++;
    }
    while (end > start &&
        newEnd > start &&
        before.codeUnitAt(end - 1) == after.codeUnitAt(newEnd - 1)) {
      end--;
      newEnd--;
    }
    if (start > 0 &&
        start < before.length &&
        (before.codeUnitAt(start) & 0xfc00) == 0xdc00) {
      start--;
    }
    if (end < before.length && (before.codeUnitAt(end) & 0xfc00) == 0xdc00) {
      end++;
      newEnd++;
    }
    return (start, end, newEnd);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (content.runs.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final composing = value.composing;
    final underlined =
        withComposing && value.isComposingRangeValid && !composing.isCollapsed;
    final spans = <TextSpan>[];
    final tokens = context.monoTokens;
    var offset = 0;
    for (final run in content.runs) {
      final runStyle = noteMarkStyle(run.marks, tokens);
      final next = offset + run.text.length;
      if (underlined && next > composing.start && offset < composing.end) {
        final start = (composing.start - offset).clamp(0, run.text.length);
        final end = (composing.end - offset).clamp(0, run.text.length);
        spans.addAll([
          TextSpan(text: run.text.substring(0, start), style: runStyle),
          TextSpan(
            text: run.text.substring(start, end),
            style: runStyle.copyWith(
              decoration: TextDecoration.combine([
                style?.decoration ?? TextDecoration.none,
                runStyle.decoration ?? TextDecoration.none,
                TextDecoration.underline,
              ]),
            ),
          ),
          TextSpan(text: run.text.substring(end), style: runStyle),
        ]);
      } else {
        spans.add(TextSpan(text: run.text, style: runStyle));
      }
      offset = next;
    }
    return TextSpan(style: style, children: spans);
  }
}
