import 'package:flutter_test/flutter_test.dart';
import 'package:mononote/features/notes/data/markdown_codec.dart';
import 'package:mononote/features/notes/models/note_models.dart';
import 'package:mononote/features/notes/models/note_text.dart';

void main() {
  final codec = MarkdownCodec();

  test(
    'reads supported blocks and preserves raw Markdown when saving edits',
    () {
      const source = '''
---
title: 笔记
---

# 标题
正文 **粗体**、*斜体*、~~删除线~~和 `x < y`。

> 引用

- [x] 完成
- [ ] 待办

~~~dart title=test
<html>
~~~

| 名称 |
| --- |
| 表格 |

有 [链接][reference] 和 ![图片](photo.png)。

[reference]: https://example.com/path

第二个标题
----------
''';
      final blocks = codec.decode(source, 'page');
      expect(blocks.map((block) => block.type), [
        NoteBlockType.heading2,
        NoteBlockType.paragraph,
        NoteBlockType.callout,
        NoteBlockType.todo,
        NoteBlockType.todo,
        NoteBlockType.code,
        NoteBlockType.markdown,
        NoteBlockType.markdown,
        NoteBlockType.markdown,
        NoteBlockType.heading2,
      ]);
      expect(blocks.first.headingLevel, 1);
      expect(
        blocks[1].content.runs,
        contains((text: 'x < y', marks: NoteMark.code.mask)),
      );
      expect(blocks[3].checked, isTrue);
      expect(blocks[4].checked, isFalse);
      expect(blocks[5].codeInfo, 'dart title=test');
      expect(blocks[5].text, '<html>');
      expect(blocks.last.text, '第二个标题');
      final doc = seedMonoNoteDocuments()['vision']!.copyWith(
        blocks: blocks,
        markdownSource: MarkdownSource(
          path: 'note.md',
          source: source,
          savedBlocks: blocks,
        ),
      );
      expect(codec.encode(doc), source);
      final edited = doc.copyWith(
        blocks: [
          ...blocks.take(4),
          blocks[4].copyWith(checked: true),
          ...blocks.skip(5),
        ],
      );
      final output = codec.encode(edited);
      expect(output, startsWith('---\ntitle: 笔记\n---'));
      expect(output, contains('- [x] 完成\n- [x] 待办'));
      expect(output, contains('| 名称 |\n| --- |\n| 表格 |'));
      expect(output, contains('有 [链接][reference] 和 ![图片](photo.png)。'));
      expect(output, contains('[reference]: https://example.com/path'));
    },
  );

  test('round-trips adjacent marks, literal Markdown and multi-line tasks', () {
    final formatted = NoteText.fromRuns([
      (text: '标', marks: NoteMark.bold.mask),
      (text: '点! ', marks: NoteMark.italic.mask),
      (text: '*`', marks: NoteMark.code.mask | NoteMark.strike.mask),
      (text: ' & 文\n\n末尾 ', marks: 0),
    ]);
    final doc = seedMonoNoteDocuments()['vision']!.copyWith(
      blocks: [
        NoteBlock(
          id: 'first',
          type: NoteBlockType.paragraph,
          content: formatted,
        ),
        const NoteBlock(
          id: 'second',
          type: NoteBlockType.todo,
          text: '第一行\n第二行',
        ),
        const NoteBlock(id: 'third', type: NoteBlockType.code, text: '```\n代码'),
      ],
    );
    final reopened = codec.decode(codec.encode(doc), 'other-page');
    expect(reopened, hasLength(3));
    expect(reopened.first.content.sameAs(formatted), isTrue);
    expect(reopened[1].type, NoteBlockType.todo);
    expect(reopened[1].text, '第一行\n第二行');
    expect(reopened[2].text, '```\n代码');
  });

  test('closes an imported unterminated fence before adding another block', () {
    const source = '```dart\nfinal value = 1;\n';
    final blocks = codec.decode(source, 'page');
    final doc = seedMonoNoteDocuments()['vision']!.copyWith(
      blocks: [
        ...blocks,
        const NoteBlock(id: 'next', type: NoteBlockType.paragraph, text: '下一段'),
      ],
      markdownSource: MarkdownSource(
        path: 'note.md',
        source: source,
        savedBlocks: blocks,
      ),
    );
    final reopened = codec.decode(codec.encode(doc), 'other-page');
    expect(reopened.map((block) => block.type), [
      NoteBlockType.code,
      NoteBlockType.paragraph,
    ]);
    expect(reopened.last.text, '下一段');
  });
}
