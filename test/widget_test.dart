import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mononote/app/app.dart';
import 'package:mononote/core/theme/mononote_tokens.dart';
import 'package:mononote/core/widgets/mononote_logo_mark.dart';
import 'package:mononote/features/editor/widgets/paper_editor_canvas.dart';
import 'package:mononote/features/inspector/widgets/outline_inspector_drawer.dart';
import 'package:mononote/features/notes/data/markdown_files.dart';
import 'package:mononote/features/notes/data/note_exports.dart';
import 'package:mononote/features/notes/models/note_text.dart';
import 'package:mononote/features/notes/state/workspace_controller.dart';
import 'package:mononote/features/shell/widgets/mono_titlebar.dart';

void main() {
  Future<ProviderContainer> pumpMonoNote(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1240, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MonoNoteApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Finder inCanvas(String text) => find.descendant(
    of: find.byType(PaperEditorCanvas),
    matching: find.text(text),
  );

  Finder inTitlebar(Finder matching) =>
      find.descendant(of: find.byType(MonoTitlebar), matching: matching);

  Future<void> pressAltShift(
    WidgetTester tester,
    LogicalKeyboardKey key,
  ) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders MonoNote shell, frosted sidebar, tabs, and paper canvas',
    (tester) async {
      await pumpMonoNote(tester);

      expect(find.byType(MonoNoteLogoMark), findsOneWidget);
      expect(find.text('MonoNote 产品构想'), findsWidgets);
      expect(find.text('本地工作区'), findsOneWidget);
      expect(inCanvas('嵌套子页面卡片（点击卡片可跳转）'), findsOneWidget);
    },
  );

  testWidgets('navigates between pages via Craft-style subpage card and tabs', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);

    await tester.tap(inCanvas('块级交互与快捷键'));
    await tester.pumpAndSettle();

    final state = container.read(workspaceProvider);
    expect(state.activePageId, 'blocks');
    expect(state.openTabs, contains('blocks'));
    expect(inCanvas('核心桌面快捷键矩阵'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(MonoTitlebar),
        matching: find.text('毛玻璃与纸感规范'),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(workspaceProvider).activePageId, 'tokens');
    expect(inCanvas('Flutter 材质 Token 示例'), findsOneWidget);
  });

  testWidgets(
    'keeps tab widths steady without bottom underline bar on switch',
    (tester) async {
      await pumpMonoNote(tester);
      final vision = inTitlebar(find.byKey(const ValueKey('vision')));
      final tokens = inTitlebar(find.byKey(const ValueKey('tokens')));
      final visionBounds = tester.getRect(vision);
      final tokensBounds = tester.getRect(tokens);
      expect(
        inTitlebar(find.byType(AnimatedPositionedDirectional)),
        findsNothing,
      );
      expect(
        tester.getSemantics(vision).flagsCollection.isSelected,
        Tristate.isTrue,
      );

      await tester.tap(tokens);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.getRect(vision), visionBounds);
      expect(tester.getRect(tokens), tokensBounds);

      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(tokens).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(vision).flagsCollection.isSelected,
        Tristate.isFalse,
      );
    },
  );

  testWidgets('highlights tab close button on hover and closes tab on tap', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    final closeButton = inTitlebar(find.byKey(const ValueKey('tab-close-vision')));
    expect(closeButton, findsOneWidget);

    BoxDecoration closeDecoration() =>
        tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: closeButton,
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration! as BoxDecoration;

    expect(closeDecoration().color!.a, 0);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    await pointer.moveTo(tester.getCenter(closeButton));
    await tester.pumpAndSettle();

    expect(closeDecoration().color, MonoNoteThemeTokens.light.accentSoft);
    expect(
      tester.widget<Icon>(
        find.descendant(of: closeButton, matching: find.byType(Icon)),
      ).color,
      MonoNoteThemeTokens.light.accentPrimary,
    );
    expect(find.text('关闭标签'), findsOneWidget);

    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(container.read(workspaceProvider).openTabs, isNot(contains('vision')));
  });

  testWidgets('retargets an overflowing tab strip when selection changes', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    tester.view.physicalSize = const Size(920, 780);
    await tester.pumpAndSettle();
    final controller = container.read(workspaceProvider.notifier);
    final strip = inTitlebar(find.byType(SingleChildScrollView));
    final scroll = tester.widget<SingleChildScrollView>(strip).controller!;
    final search = inTitlebar(find.text('搜索或命令…'));
    final searchBounds = tester.getRect(search);

    const title = '一个必须横向滚动才能完整看见的很长的文档标签';
    controller.createPage(title: title);
    controller.createPage(title: title);
    final lastId = controller.createPage(title: title);
    final lastTab = inTitlebar(find.byKey(ValueKey(lastId)));
    await tester.pump();
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    expect(lastTab, findsOneWidget);
    expect(tester.getRect(search), searchBounds);

    controller.openPage('vision');
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);

    controller.openPage(lastId);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(lastTab).right,
      lessThanOrEqualTo(tester.getRect(strip).right + 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('swaps the breadcrumb and one scroll body during rapid changes', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    tester.view.physicalSize = const Size(1240, 640);
    await tester.pumpAndSettle();
    final controller = container.read(workspaceProvider.notifier);
    final body = find.descendant(
      of: find.byType(PaperEditorCanvas),
      matching: find.byType(ListView),
    );
    final visionBody = find.byKey(const PageStorageKey('document-vision'));
    final visionCrumb = find.byKey(const ValueKey('crumb-vision'));
    final crumbLeft = tester.getTopLeft(visionCrumb).dx;
    final visionScroll = tester.widget<ListView>(visionBody).controller!;
    final offset = visionScroll.position.maxScrollExtent.clamp(0.0, 80.0);
    expect(offset, greaterThan(0));
    visionScroll.jumpTo(offset);
    await tester.pump();

    await tester.tap(inTitlebar(find.byKey(const ValueKey('tokens'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(body, findsOneWidget);
    expect(visionBody, findsOneWidget);
    expect(find.byKey(const ValueKey('crumb-tokens')), findsNothing);

    controller.openPage('blocks');
    await tester.pump(const Duration(milliseconds: 75));
    final blocksCrumb = find.byKey(const ValueKey('crumb-blocks'));
    final blocksBody = find.byKey(const PageStorageKey('document-blocks'));
    expect(body, findsOneWidget);
    expect(blocksBody, findsOneWidget);
    expect(visionCrumb, findsNothing);
    expect(tester.getTopLeft(blocksCrumb).dx, crumbLeft);
    expect(tester.widget<ListView>(blocksBody).controller, isNot(visionScroll));

    await tester.pump(const Duration(milliseconds: 55));
    await tester.tap(inTitlebar(find.byKey(const ValueKey('vision'))));
    await tester.pumpAndSettle();
    expect(body, findsOneWidget);
    expect(tester.widget<ListView>(visionBody).controller!.offset, offset);
    expect(blocksCrumb, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles todo checkbox and inserts new block from slash menu', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('v-t3')),
        matching: find.bySemanticsLabel('待办状态'),
      ),
    );
    await tester.pumpAndSettle();

    final todoBlock = container
        .read(workspaceProvider)
        .activeDocument
        .blocks
        .firstWhere((b) => b.id == 'v-t3');
    expect(todoBlock.checked, isTrue);

    await tester.tap(find.text('+ 插入块 (/)'));
    await tester.pumpAndSettle();
    expect(find.text('插入块级元素'), findsOneWidget);

    await tester.tap(find.text('二级章节标题'));
    await tester.pumpAndSettle();

    expect(inCanvas('新增章节小标题'), findsOneWidget);
  });

  testWidgets(
    'toggles theme mode, sidebar, outline drawer, and command palette',
    (tester) async {
      final container = await pumpMonoNote(tester);

      await tester.tap(find.byIcon(LucideIcons.moon));
      await tester.pumpAndSettle();
      expect(container.read(workspaceProvider).themeMode, ThemeMode.dark);

      await tester.tap(find.byIcon(LucideIcons.alignLeft));
      await tester.pumpAndSettle();
      expect(container.read(workspaceProvider).isInspectorOpen, isTrue);
      expect(
        find.descendant(
          of: find.byType(OutlineInspectorDrawer),
          matching: find.text('文档大纲'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(LucideIcons.panelLeft));
      await tester.pumpAndSettle();
      expect(container.read(workspaceProvider).isSidebarOpen, isFalse);

      await tester.tap(find.text('搜索或命令…'));
      await tester.pumpAndSettle();
      expect(find.text('新建空白笔记页面'), findsOneWidget);

      await tester.tap(find.text('新建空白笔记页面'));
      await tester.pumpAndSettle();
      expect(container.read(workspaceProvider).activeDocument.title, '未命名笔记 1');
    },
  );

  testWidgets('formats selected text in place and keeps marks while typing', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    final controller = container.read(workspaceProvider.notifier);
    controller.openPage('tokens');
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byKey(const ValueKey('block-edit-t-p1')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '暖调纸感');
    final editing = tester.widget<TextField>(field).controller!;
    editing.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('format-bold')));
    await tester.pump();
    NoteText content() =>
        container.read(workspaceProvider).activeDocument.blocks.first.content;
    expect(content().runs, [
      (text: '暖调', marks: NoteMark.bold.mask),
      (text: '纸感', marks: 0),
    ]);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    editing.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '暖调的纸感',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(content().runs.first, (text: '暖调的', marks: NoteMark.bold.mask));
    expect(
      editing
          .buildTextSpan(context: tester.element(field), withComposing: false)
          .children!
          .first
          .style!
          .fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('drags a subpage card before a text block using its grip', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    final source = find.byKey(const ValueKey('block-grip-v-card-2'));
    final target = tester.getRect(find.byKey(const ValueKey('v-callout')));
    final gesture = await tester.startGesture(
      tester.getCenter(source),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, -25));
    await tester.pump();
    await gesture.moveTo(target.topCenter + const Offset(0, 8));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      container.read(workspaceProvider).activeDocument.blocks.first.id,
      'v-card-2',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs workspace and rich text shortcuts', (tester) async {
    final container = await pumpMonoNote(tester);

    await pressAltShift(tester, LogicalKeyboardKey.pageDown);
    expect(container.read(workspaceProvider).activePageId, 'tokens');
    await pressAltShift(tester, LogicalKeyboardKey.pageUp);
    expect(container.read(workspaceProvider).activePageId, 'vision');

    final field = find.descendant(
      of: find.byKey(const ValueKey('block-edit-v-callout')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '格式快捷键');
    tester.widget<TextField>(field).controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 2,
    );
    await pressAltShift(tester, LogicalKeyboardKey.keyX);
    await pressAltShift(tester, LogicalKeyboardKey.keyC);
    final content = container
        .read(workspaceProvider)
        .activeDocument
        .blocks
        .first
        .content;
    expect(content.hasMark(0, 2, NoteMark.strike), isTrue);
    expect(content.hasMark(0, 2, NoteMark.code), isTrue);

    await pressAltShift(tester, LogicalKeyboardKey.pageDown);
    expect(container.read(workspaceProvider).activePageId, 'tokens');
    await pressAltShift(tester, LogicalKeyboardKey.pageUp);
    expect(container.read(workspaceProvider).activePageId, 'vision');

    await pressAltShift(tester, LogicalKeyboardKey.keyH);
    expect(find.text('键盘快捷键'), findsOneWidget);
    expect(find.text('Alt+Shift+P'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('键盘快捷键'), findsNothing);
  });

  testWidgets('saves full length PNG and paginated PDF to selected files', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    final context = tester.element(find.byType(PaperEditorCanvas));
    final controller = container.read(workspaceProvider.notifier);
    final longBlock = List.generate(72, (index) => '第 $index 行').join('\n');
    controller.importMarkdown('完整笔记.md', '# 示例\n\n```text\n$longBlock\n```\n');
    final folder = Directory.systemTemp.createTempSync('mononote-export-test-');
    addTearDown(() => folder.deleteSync(recursive: true));
    final png = File('${folder.path}/完整笔记.png');
    final pdf = File('${folder.path}/完整笔记.pdf');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/file_selector');
    messenger.setMockMethodCallHandler(
      channel,
      (call) async =>
          call.arguments['suggestedName'].toString().endsWith('.png')
          ? png.path
          : pdf.path,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final exports = container.read(noteExportsProvider);
    await tester.runAsync(() async {
      await exports.export(context, NoteExportFormat.png);
      await exports.export(context, NoteExportFormat.pdf);
    });

    final pngBytes = png.readAsBytesSync();
    expect(pngBytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(ByteData.sublistView(pngBytes).getUint32(20), greaterThan(2000));
    final pdfText = latin1.decode(pdf.readAsBytesSync());
    expect(pdfText, startsWith('%PDF-'));
    expect(RegExp(r'/Type\s*/Page\b').allMatches(pdfText), hasLength(2));
  });

  testWidgets('opens Markdown, saves edits and protects external changes', (
    tester,
  ) async {
    final container = await pumpMonoNote(tester);
    final context = tester.element(find.byType(PaperEditorCanvas));
    final files = container.read(markdownFilesProvider);
    final folder = Directory.systemTemp.createTempSync('mononote-test-');
    addTearDown(() {
      final file = File('${folder.path}/本地笔记.md');
      final copy = File('${folder.path}/副本.md');
      if (file.existsSync()) file.deleteSync();
      if (copy.existsSync()) copy.deleteSync();
      folder.deleteSync();
    });
    final file = File('${folder.path}/本地笔记.md')
      ..writeAsStringSync('\uFEFF# 标题\r\n\r\n正文 **粗体**\r\n');
    final copy = File('${folder.path}/副本.md');
    const channel = MethodChannel('plugins.flutter.io/file_selector');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'openFile' => [file.path],
        'getSavePath' => copy.path,
        _ => null,
      },
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.runAsync(() => files.open(context));
    await tester.pumpAndSettle();
    expect(inCanvas('正文 粗体'), findsOneWidget);
    final controller = container.read(workspaceProvider.notifier);
    final openedId = container.read(workspaceProvider).activePageId;
    file.writeAsStringSync('\uFEFF# 标题\r\n\r\n外部更新的正文\r\n');
    await tester.runAsync(() => files.open(context));
    await tester.pumpAndSettle();
    expect(container.read(workspaceProvider).activePageId, openedId);
    expect(inCanvas('外部更新的正文'), findsOneWidget);
    final doc = container.read(workspaceProvider).activeDocument;
    controller.updateBlockContent(
      doc.id,
      doc.blocks.last.id,
      const NoteText.plain('修改后的正文'),
    );
    await tester.pump();
    expect(inCanvas('未保存'), findsOneWidget);
    await tester.runAsync(() => files.save(context));
    await tester.pumpAndSettle();
    expect(inCanvas('已保存'), findsOneWidget);
    expect(file.readAsBytesSync().take(3), [0xef, 0xbb, 0xbf]);
    expect(file.readAsStringSync(), '# 标题\r\n\r\n修改后的正文\r\n');

    file.writeAsStringSync('外部修改');
    await tester.runAsync(() => files.save(context));
    await tester.pumpAndSettle();
    expect(find.textContaining('磁盘文件已被修改'), findsOneWidget);
    expect(file.readAsStringSync(), '外部修改');
    await tester.runAsync(() => files.save(context, saveAs: true));
    await tester.pumpAndSettle();
    expect(copy.readAsStringSync(), '# 标题\r\n\r\n修改后的正文\r\n');
  });
}
