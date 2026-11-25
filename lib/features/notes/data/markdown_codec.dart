import 'package:markdown/markdown.dart' as md;

import '../models/note_models.dart';
import '../models/note_text.dart';

class MarkdownCodec {
  static final _heading = RegExp(r'^h([1-6])$');
  static final _task = RegExp(r'^ {0,3}([-+*]) +\[([ xX])\](?:[ \t]+(.*)|$)');
  static final _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
  static final _newline = RegExp(r'\r\n?|\n');
  static final _punctuation = RegExp(
    r'[!"#$%&'
    "'"
    r'()*+,\-./:;<=>?@\[\]\\^_`{|}~]',
  );
  static const _tags = {
    'strong': NoteMark.bold,
    'em': NoteMark.italic,
    'del': NoteMark.strike,
    'code': NoteMark.code,
  };

  List<NoteBlock> decode(String source, String pageId) {
    final (_, body) = _splitFrontMatter(_normalize(source));
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [_FormatTagSyntax(), _RawHtmlSyntax()],
      encodeHtml: false,
    );
    final lines = body.split('\n').map(md.Line.new).toList();
    final parser = _SourceParser(lines, document);
    parser.parseLines();
    final blocks = <NoteBlock>[];
    String nextId() => '$pageId-md-${blocks.length}';
    void addRaw(String raw) {
      if (raw.trim().isNotEmpty) {
        blocks.add(
          NoteBlock(id: nextId(), type: NoteBlockType.markdown, text: raw),
        );
      }
    }

    var cursor = 0;
    for (final part in parser.parts) {
      addRaw(_joinLines(lines.getRange(cursor, part.start)));
      final raw = _joinLines(lines.getRange(part.start, part.end));
      final node = part.node;
      final tag = node is md.Element ? node.tag : '';
      final headingLevel = _heading.firstMatch(tag);
      final children = node is md.Element
          ? node.children ?? <md.Node>[]
          : <md.Node>[];
      final quote =
          tag == 'blockquote' &&
          children.length == 1 &&
          children.first is md.Element &&
          (children.first as md.Element).tag == 'p';
      final sourceLines = raw.split('\n');
      final tasks = tag == 'ul'
          ? sourceLines.map(_task.firstMatch).toList()
          : const <RegExpMatch?>[];
      if (tasks.isNotEmpty && tasks.every((match) => match != null)) {
        final contents = [
          for (final match in tasks) _parseInline(document, match![3] ?? ''),
        ];
        if (contents.every((content) => content != null)) {
          for (var index = 0; index < tasks.length; index++) {
            blocks.add(
              NoteBlock(
                id: nextId(),
                type: NoteBlockType.todo,
                checked: tasks[index]![2] != ' ',
                content: contents[index],
                originalMarkdown: sourceLines[index],
              ),
            );
          }
        } else {
          addRaw(raw);
        }
      } else if (tag == 'pre' &&
          children.length == 1 &&
          children.first is md.Element) {
        final code = (children.first as md.Element).textContent;
        final fence = _fence.firstMatch(sourceLines.first);
        final marker = fence?[1];
        final closing = marker == null
            ? null
            : RegExp('^ {0,3}$marker${marker[0]}*[ \\t]*\$');
        blocks.add(
          NoteBlock(
            id: nextId(),
            type: NoteBlockType.code,
            text: code.endsWith('\n')
                ? code.substring(0, code.length - 1)
                : code,
            codeInfo: fence?[2]?.trim() ?? '',
            originalMarkdown:
                closing == null ||
                    (sourceLines.length > 1 &&
                        closing.hasMatch(sourceLines.last))
                ? raw
                : null,
          ),
        );
      } else if (tag == 'p' || headingLevel != null || quote) {
        final inlineNodes = quote
            ? (children.first as md.Element).children!
            : children;
        final content = _readInline(document, inlineNodes);
        if (content == null) {
          addRaw(raw);
        } else {
          blocks.add(
            NoteBlock(
              id: nextId(),
              type: quote
                  ? NoteBlockType.callout
                  : headingLevel != null
                  ? NoteBlockType.heading2
                  : NoteBlockType.paragraph,
              content: content,
              headingLevel: headingLevel == null
                  ? 2
                  : int.parse(headingLevel[1]!),
              originalMarkdown: raw,
            ),
          );
        }
      } else {
        addRaw(raw);
      }
      cursor = part.end;
    }
    addRaw(_joinLines(lines.skip(cursor)));
    return List.unmodifiable(blocks);
  }

  String encode(NoteDocument document) {
    final backing = document.markdownSource;
    if (backing != null && !document.hasMarkdownChanges) return backing.source;
    final (frontMatter, _) = _splitFrontMatter(
      _normalize(backing?.source ?? ''),
    );
    final body = StringBuffer();
    NoteBlockType? previousType;
    for (final block in document.blocks) {
      final markdown = _encodeBlock(block);
      if (markdown.isEmpty) continue;
      if (body.isNotEmpty) {
        body.write(
          previousType == NoteBlockType.todo && block.type == NoteBlockType.todo
              ? '\n'
              : '\n\n',
        );
      }
      body.write(markdown);
      previousType = block.type;
    }
    final content = [
      if (frontMatter.isNotEmpty) frontMatter,
      if (body.isNotEmpty) body.toString(),
    ].join('\n\n');
    final lineEnding = _newline.firstMatch(backing?.source ?? '')?[0] ?? '\n';
    final bom = backing?.source.startsWith('\uFEFF') == true ? '\uFEFF' : '';
    return '$bom${content.isEmpty ? '' : '$content\n'.replaceAll('\n', lineEnding)}';
  }

  static (String, String) _splitFrontMatter(String source) {
    final match = RegExp(
      r'^---[ \t]*\n[\s\S]*?^(?:---|\.\.\.)[ \t]*(?:\n|$)',
      multiLine: true,
    ).matchAsPrefix(source);
    return match == null
        ? ('', source)
        : (match[0]!.trimRight(), source.substring(match.end));
  }

  static String _normalize(String source) =>
      source.replaceFirst(RegExp(r'^\uFEFF'), '').replaceAll(_newline, '\n');

  static String _joinLines(Iterable<md.Line> lines) {
    final content = lines.map((line) => line.content).toList();
    while (content.isNotEmpty && content.last.trim().isEmpty) {
      content.removeLast();
    }
    return content.join('\n').replaceFirst(RegExp(r'^(?:[ \t]*\n)+'), '');
  }

  static NoteText? _parseInline(md.Document document, String source) =>
      _readInline(document, document.parseInline(source));

  static NoteText? _readInline(md.Document document, Iterable<md.Node> nodes) {
    final runs = <NoteRun>[];
    final openTags = <NoteMark>[];
    bool read(Iterable<md.Node> children, int marks) {
      for (final node in children) {
        if (node is md.UnparsedContent) {
          if (!read(document.parseInline(node.textContent), marks)) {
            return false;
          }
        } else if (node is md.Text) {
          final active = openTags.fold(
            marks,
            (value, mark) => value | mark.mask,
          );
          runs.add((text: node.textContent, marks: active));
        } else if (node is md.Element) {
          if (node.tag == 'br') {
            final active = openTags.fold(
              marks,
              (value, mark) => value | mark.mask,
            );
            runs.add((text: '\n', marks: active));
          } else if (node.tag == 'mono-format') {
            final mark = _tags[node.attributes['name']]!;
            if (node.attributes['close'] == 'true') {
              if (openTags.isEmpty || openTags.removeLast() != mark) {
                return false;
              }
            } else {
              openTags.add(mark);
            }
          } else {
            final mark = _tags[node.tag];
            if (mark == null || !read(node.children ?? [], marks | mark.mask)) {
              return false;
            }
          }
        }
      }
      return true;
    }

    return read(nodes, 0) && openTags.isEmpty ? NoteText.fromRuns(runs) : null;
  }

  static String _escape(String text) =>
      text.replaceAllMapped(_punctuation, (match) => '\\${match[0]}');

  static String _encodeInline(NoteText content, {required bool singleLine}) {
    final candidate = content.segments.map((run) {
      var text = _escape(run.text);
      if (run.marks & NoteMark.code.mask != 0) {
        final fence = _longerFence(run.text, '`', 1);
        final pad =
            run.text.startsWith('`') ||
            run.text.endsWith('`') ||
            (run.text.startsWith(' ') &&
                run.text.endsWith(' ') &&
                run.text.trim().isNotEmpty);
        text = pad ? '$fence ${run.text} $fence' : '$fence${run.text}$fence';
      }
      if (run.marks & NoteMark.bold.mask != 0) text = '**$text**';
      if (run.marks & NoteMark.italic.mask != 0) text = '*$text*';
      if (run.marks & NoteMark.strike.mask != 0) text = '~~$text~~';
      return text;
    }).join();
    final parser = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    if (candidate.trim() == candidate &&
        (!singleLine || !candidate.contains('\n')) &&
        !candidate.contains(RegExp(r'\n[ \t]*\n|\n[ \t]')) &&
        _parseInline(parser, candidate)?.sameAs(content) == true) {
      return candidate;
    }
    return content.segments.map((run) {
      var text = run.text.replaceAllMapped(
        RegExp(r'[\x09\x0A\x0D\x20-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]'),
        (match) => '&#${match[0]!.codeUnitAt(0)};',
      );
      for (final entry in _tags.entries) {
        if (run.marks & entry.value.mask != 0) {
          text = '<${entry.key}>$text</${entry.key}>';
        }
      }
      return text;
    }).join();
  }

  static String _longerFence(String text, String char, int minimum) {
    var length = minimum;
    for (final match in RegExp('$char+').allMatches(text)) {
      if (match[0]!.length >= length) length = match[0]!.length + 1;
    }
    return char * length;
  }

  static String _encodeBlock(NoteBlock block) {
    if (block.originalMarkdown case final original?) return original;
    if (block.type == NoteBlockType.markdown) return block.text;
    if (block.type == NoteBlockType.code) {
      final char = block.codeInfo.contains('`') ? '~' : '`';
      final fence = _longerFence(block.text, char, 3);
      return '$fence${block.codeInfo}\n${block.text}\n$fence';
    }
    if (block.type == NoteBlockType.subpageCard) {
      final text = [
        block.targetTitle,
        block.targetExcerpt,
      ].whereType<String>().join('\n');
      return _escape(text).split('\n').map((line) => '> $line').join('\n');
    }
    final inline = _encodeInline(
      block.content,
      singleLine:
          block.type == NoteBlockType.heading2 ||
          block.type == NoteBlockType.todo,
    );
    return switch (block.type) {
      NoteBlockType.heading2 => '${'#' * block.headingLevel} $inline',
      NoteBlockType.todo => '- [${block.checked ? 'x' : ' '}] $inline',
      NoteBlockType.callout =>
        inline.split('\n').map((line) => '> $line').join('\n'),
      _ => inline,
    };
  }
}

class _FormatTagSyntax extends md.InlineSyntax {
  _FormatTagSyntax() : super(r'<(/?)(strong|em|del|code)>', startCharacter: 60);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.empty('mono-format')
        ..attributes['name'] = match[2]!
        ..attributes['close'] = '${match[1]!.isNotEmpty}',
    );
    return true;
  }
}

class _RawHtmlSyntax extends md.InlineHtmlSyntax {
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('mono-raw'));
    return true;
  }
}

typedef _SourcePart = ({int start, int end, md.Node node});

class _SourceParser extends md.BlockParser {
  _SourceParser(super.lines, super.document) {
    final tracked = blockSyntaxes
        .map(
          (syntax) => switch (syntax) {
            md.EmptyBlockSyntax() ||
            md.LinkReferenceDefinitionSyntax() => syntax,
            md.ParagraphSyntax() => const _SourceParagraph(),
            md.SetextHeaderSyntax() => const _SourceHeading(),
            md.CodeBlockSyntax() => const _SourceCode(),
            _ => _SourceSyntax(syntax),
          },
        )
        .toList();
    blockSyntaxes.replaceRange(0, blockSyntaxes.length, tracked);
  }

  final parts = <_SourcePart>[];
  int position = 0;
  int? _pendingStart;

  @override
  void advance() {
    super.advance();
    position++;
  }

  @override
  void retreat() {
    super.retreat();
    position--;
  }

  @override
  void retreatBy(int count) {
    super.retreatBy(count);
    position -= count;
  }

  md.Node? record(md.Node? Function() parse) {
    final start = _pendingStart ?? position;
    final before = position;
    final node = parse();
    if (node != null) {
      parts.add((start: start, end: position, node: node));
      _pendingStart = null;
    } else if (before != position) {
      _pendingStart = start;
    }
    return node;
  }
}

mixin _TrackSource on md.BlockSyntax {
  @override
  md.Node? parse(md.BlockParser parser) =>
      (parser as _SourceParser).record(() => super.parse(parser));
}

class _SourceParagraph extends md.ParagraphSyntax with _TrackSource {
  const _SourceParagraph();
}

class _SourceHeading extends md.SetextHeaderSyntax with _TrackSource {
  const _SourceHeading();
}

class _SourceCode extends md.CodeBlockSyntax {
  const _SourceCode();

  @override
  md.Node parse(md.BlockParser parser) =>
      (parser as _SourceParser).record(() => super.parse(parser))!;
}

class _SourceSyntax extends md.BlockSyntax {
  const _SourceSyntax(this.delegate);

  final md.BlockSyntax delegate;

  @override
  RegExp get pattern => delegate.pattern;

  @override
  bool canParse(md.BlockParser parser) => delegate.canParse(parser);

  @override
  bool canEndBlock(md.BlockParser parser) => delegate.canEndBlock(parser);

  @override
  md.Node? parse(md.BlockParser parser) =>
      (parser as _SourceParser).record(() => delegate.parse(parser));
}
