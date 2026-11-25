import 'package:flutter/foundation.dart';

enum NoteMark {
  bold,
  italic,
  strike,
  code;

  int get mask => 1 << index;
}

typedef NoteRun = ({String text, int marks});

@immutable
class NoteText {
  const NoteText.plain(this.text) : runs = const [];

  factory NoteText.fromRuns(Iterable<NoteRun> runs) {
    final merged = <NoteRun>[];
    for (final run in runs) {
      if (run.text.isEmpty) continue;
      if (merged.isNotEmpty && merged.last.marks == run.marks) {
        final previous = merged.removeLast();
        merged.add((text: previous.text + run.text, marks: run.marks));
      } else {
        merged.add(run);
      }
    }
    final text = merged.map((run) => run.text).join();
    return merged.every((run) => run.marks == 0)
        ? NoteText.plain(text)
        : NoteText._(text, List.unmodifiable(merged));
  }

  const NoteText._(this.text, this.runs);

  final String text;
  final List<NoteRun> runs;

  Iterable<NoteRun> get segments =>
      runs.isEmpty ? [(text: text, marks: 0)] : runs;

  Iterable<NoteRun> _slice(int start, int end) sync* {
    var offset = 0;
    for (final run in segments) {
      final next = offset + run.text.length;
      if (offset >= end) break;
      if (next > start) {
        final from = (start - offset).clamp(0, run.text.length);
        final to = (end - offset).clamp(0, run.text.length);
        if (to > from) {
          yield (text: run.text.substring(from, to), marks: run.marks);
        }
      }
      offset = next;
    }
  }

  int marksAt(int offset) {
    if (text.isEmpty) return 0;
    final index = offset == 0 ? 0 : offset - 1;
    return _slice(index, index + 1).first.marks;
  }

  bool hasMark(int start, int end, NoteMark mark) => start == end
      ? marksAt(start) & mark.mask != 0
      : _slice(start, end).every((run) => run.marks & mark.mask != 0);

  NoteText toggleMark(int start, int end, NoteMark mark) {
    final remove = hasMark(start, end, mark);
    return NoteText.fromRuns([
      ..._slice(0, start),
      for (final run in _slice(start, end))
        (
          text: run.text,
          marks: remove ? run.marks & ~mark.mask : run.marks | mark.mask,
        ),
      ..._slice(end, text.length),
    ]);
  }

  NoteText replace(int start, int end, String replacement, int marks) {
    if (runs.isEmpty && marks == 0) {
      return NoteText.plain(text.replaceRange(start, end, replacement));
    }
    return NoteText.fromRuns([
      ..._slice(0, start),
      (text: replacement, marks: marks),
      ..._slice(end, text.length),
    ]);
  }

  bool sameAs(NoteText other) =>
      text == other.text && listEquals(runs, other.runs);
}
