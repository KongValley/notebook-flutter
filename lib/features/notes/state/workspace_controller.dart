import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../data/markdown_codec.dart';
import '../models/note_models.dart';
import '../models/note_text.dart';

/// Immutable UI and document workspace state for MonoNote.
@immutable
class WorkspaceState {
  const WorkspaceState({
    required this.documents,
    required this.openTabs,
    required this.activePageId,
    required this.expandedTreeIds,
    this.isSidebarOpen = true,
    this.isInspectorOpen = false,
    this.isFloatingToolbarVisible = false,
    this.themeMode = ThemeMode.light,
    this.nextIdCounter = 1,
  });

  final Map<String, NoteDocument> documents;
  final List<String> openTabs;
  final String activePageId;
  final Set<String> expandedTreeIds;
  final bool isSidebarOpen;
  final bool isInspectorOpen;
  final bool isFloatingToolbarVisible;
  final ThemeMode themeMode;
  final int nextIdCounter;

  NoteDocument get activeDocument =>
      documents[activePageId] ?? documents.values.first;

  List<NoteDocument> get quickLinkDocuments =>
      documents.values.where((d) => d.isQuickLink).toList();

  List<NoteDocument> get rootTreeDocuments => documents.values
      .where((d) => !d.isQuickLink && d.parentId == null)
      .toList();

  List<String> get allTags {
    final seen = <String>{};
    for (final doc in documents.values) {
      seen.addAll(doc.tags);
    }
    return seen.toList();
  }

  WorkspaceState copyWith({
    Map<String, NoteDocument>? documents,
    List<String>? openTabs,
    String? activePageId,
    Set<String>? expandedTreeIds,
    bool? isSidebarOpen,
    bool? isInspectorOpen,
    bool? isFloatingToolbarVisible,
    ThemeMode? themeMode,
    int? nextIdCounter,
  }) {
    return WorkspaceState(
      documents: documents ?? this.documents,
      openTabs: openTabs ?? this.openTabs,
      activePageId: activePageId ?? this.activePageId,
      expandedTreeIds: expandedTreeIds ?? this.expandedTreeIds,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      isInspectorOpen: isInspectorOpen ?? this.isInspectorOpen,
      isFloatingToolbarVisible:
          isFloatingToolbarVisible ?? this.isFloatingToolbarVisible,
      themeMode: themeMode ?? this.themeMode,
      nextIdCounter: nextIdCounter ?? this.nextIdCounter,
    );
  }
}

/// Manages document tabs, hierarchical tree state, theme, and block edits.
class WorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return WorkspaceState(
      documents: seedMonoNoteDocuments(),
      openTabs: const ['vision', 'tokens'],
      activePageId: 'vision',
      expandedTreeIds: const {'vision'},
    );
  }

  void openPage(String pageId) {
    if (!state.documents.containsKey(pageId)) return;
    final tabs = List<String>.from(state.openTabs);
    if (!tabs.contains(pageId)) {
      if (tabs.length >= 5) {
        tabs.removeLast();
      }
      tabs.add(pageId);
    }
    state = state.copyWith(openTabs: tabs, activePageId: pageId);
  }

  void closeTab(String pageId) {
    if (state.openTabs.length <= 1) return;
    final tabs = state.openTabs.where((id) => id != pageId).toList();
    final nextActive = state.activePageId == pageId
        ? tabs.first
        : state.activePageId;
    state = state.copyWith(openTabs: tabs, activePageId: nextActive);
  }

  void cycleTab(int step) {
    final tabs = state.openTabs;
    if (tabs.length < 2) return;
    final current = tabs.indexOf(state.activePageId);
    openPage(tabs[(current + step) % tabs.length]);
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
  }

  void toggleInspector() {
    state = state.copyWith(isInspectorOpen: !state.isInspectorOpen);
  }

  void toggleFloatingToolbar() {
    state = state.copyWith(
      isFloatingToolbarVisible: !state.isFloatingToolbarVisible,
    );
  }

  void toggleTheme() {
    final next = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    state = state.copyWith(themeMode: next);
  }

  void toggleTreeExpand(String pageId) {
    final expanded = Set<String>.from(state.expandedTreeIds);
    if (!expanded.add(pageId)) {
      expanded.remove(pageId);
    }
    state = state.copyWith(expandedTreeIds: expanded);
  }

  void toggleTodo(String blockId, {String? pageId}) {
    final doc = state.documents[pageId ?? state.activePageId];
    if (doc == null) return;
    final updatedBlocks = doc.blocks
        .map(
          (b) => b.id == blockId && b.type == NoteBlockType.todo
              ? b.copyWith(checked: !b.checked)
              : b,
        )
        .toList();
    _replaceDocument(
      doc.copyWith(blocks: updatedBlocks, updatedLabel: '更新于 刚刚'),
    );
  }

  void updateBlockContent(String pageId, String blockId, NoteText content) {
    final doc = state.documents[pageId];
    if (doc == null) return;
    final index = doc.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0 || doc.blocks[index].content.sameAs(content)) return;
    final blocks = List<NoteBlock>.of(doc.blocks);
    blocks[index] = blocks[index].copyWith(content: content);
    _replaceDocument(doc.copyWith(blocks: blocks, updatedLabel: '更新于 刚刚'));
  }

  void moveBlock(
    String pageId,
    String blockId,
    String targetId, {
    required bool after,
  }) {
    final doc = state.documents[pageId];
    if (doc == null || blockId == targetId) return;
    final blocks = List<NoteBlock>.of(doc.blocks);
    final from = blocks.indexWhere((block) => block.id == blockId);
    final target = blocks.indexWhere((block) => block.id == targetId);
    if (from < 0 || target < 0) return;
    final to = target + (after ? 1 : 0) - (from < target ? 1 : 0);
    if (from == to) return;
    blocks.insert(to, blocks.removeAt(from));
    _replaceDocument(doc.copyWith(blocks: blocks, updatedLabel: '更新于 刚刚'));
  }

  NoteDocument? documentForMarkdownPath(String filePath) {
    for (final doc in state.documents.values) {
      final source = doc.markdownSource;
      if (source != null && path.equals(source.path, filePath)) return doc;
    }
    return null;
  }

  void openMarkdown(String filePath, String source) {
    final existing = documentForMarkdownPath(filePath);
    if (existing != null) {
      if (!existing.hasMarkdownChanges &&
          existing.markdownSource!.source != source) {
        final blocks = MarkdownCodec().decode(source, existing.id);
        _replaceDocument(
          existing.copyWith(
            blocks: blocks,
            updatedLabel: '从本地打开',
            markdownSource: MarkdownSource(
              path: filePath,
              source: source,
              savedBlocks: blocks,
            ),
          ),
        );
      }
      openPage(existing.id);
      return;
    }
    _addMarkdownDocument(filePath, source, '从本地打开');
  }

  void importMarkdown(String fileName, String source) =>
      _addMarkdownDocument(fileName, source, '从浏览器导入');

  void _addMarkdownDocument(String filePath, String source, String label) {
    final counter = state.nextIdCounter;
    final id = 'page-$counter';
    final blocks = MarkdownCodec().decode(source, id);
    final doc = NoteDocument(
      id: id,
      title: path.basenameWithoutExtension(filePath),
      badge: 'Markdown',
      icon: NoteIconKind.file,
      tags: const [],
      updatedLabel: label,
      blocks: blocks,
      markdownSource: MarkdownSource(
        path: filePath,
        source: source,
        savedBlocks: blocks,
      ),
    );
    _replaceDocument(doc, nextCounter: counter + 1);
    openPage(id);
  }

  void markMarkdownSaved(
    NoteDocument snapshot,
    String filePath,
    String source,
  ) {
    final current = state.documents[snapshot.id];
    if (current == null) return;
    _replaceDocument(
      current.copyWith(
        markdownSource: MarkdownSource(
          path: filePath,
          source: source,
          savedBlocks: snapshot.blocks,
        ),
      ),
    );
  }

  void insertBlock(
    NoteBlockType type, {
    String? customText,
    String? targetPageId,
  }) {
    final doc = state.activeDocument;
    final counter = state.nextIdCounter;
    final blockId = 'blk-$counter';

    final NoteBlock newBlock = switch (type) {
      NoteBlockType.paragraph => NoteBlock(
        id: blockId,
        type: NoteBlockType.paragraph,
        text: customText ?? '这是一段新添加的块级正文。',
      ),
      NoteBlockType.heading2 => NoteBlock(
        id: blockId,
        type: NoteBlockType.heading2,
        text: customText ?? '新增章节小标题',
      ),
      NoteBlockType.todo => NoteBlock(
        id: blockId,
        type: NoteBlockType.todo,
        checked: false,
        text: customText ?? '新建待办事项（点击可勾选）',
      ),
      NoteBlockType.callout => NoteBlock(
        id: blockId,
        type: NoteBlockType.callout,
        text: customText ?? '这是一张新插入的暖调提示卡片块。',
      ),
      NoteBlockType.code => NoteBlock(
        id: blockId,
        type: NoteBlockType.code,
        text: customText ?? '// MonoNote 代码片段\nfinal ready = true;',
      ),
      NoteBlockType.markdown => NoteBlock(
        id: blockId,
        type: NoteBlockType.markdown,
        text: customText ?? '',
      ),
      NoteBlockType.subpageCard => () {
        final target =
            state.documents[targetPageId ?? 'daily'] ??
            state.documents.values.first;
        return NoteBlock(
          id: blockId,
          type: NoteBlockType.subpageCard,
          targetPageId: target.id,
          targetTitle: target.title,
          targetExcerpt: '点击卡片即可直接在画布内完成层级跳转…',
          targetIcon: target.icon,
        );
      }(),
    };

    _replaceDocument(
      doc.copyWith(blocks: [...doc.blocks, newBlock], updatedLabel: '更新于 刚刚'),
      nextCounter: counter + 1,
    );
  }

  void updateDocumentTitle(String newTitle) {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    final doc = state.activeDocument;
    _replaceDocument(doc.copyWith(title: trimmed, updatedLabel: '更新于 刚刚'));
  }

  void deleteBlock(String blockId, {String? pageId}) {
    final doc = state.documents[pageId ?? state.activePageId];
    if (doc == null || !doc.blocks.any((block) => block.id == blockId)) return;
    final updatedBlocks = doc.blocks.where((b) => b.id != blockId).toList();
    _replaceDocument(
      doc.copyWith(blocks: updatedBlocks, updatedLabel: '更新于 刚刚'),
    );
  }

  /// Creates a new top-level or child page and opens it immediately.
  String createPage({String? parentId, String? title}) {
    final counter = state.nextIdCounter;
    final pageId = 'page-$counter';
    final docs = Map<String, NoteDocument>.from(state.documents);

    final newDoc = NoteDocument(
      id: pageId,
      parentId: parentId,
      title: title ?? '未命名笔记 $counter',
      badge: '新建文档',
      icon: NoteIconKind.file,
      tags: const ['#随记'],
      updatedLabel: '更新于 刚刚',
      blocks: [
        NoteBlock(
          id: 'blk-$counter-init',
          type: NoteBlockType.paragraph,
          text: '在这里开始记录你的想法，或在下方输入 / 插入更多块级元素。',
        ),
      ],
    );
    docs[pageId] = newDoc;

    final expanded = Set<String>.from(state.expandedTreeIds);
    if (parentId != null && docs.containsKey(parentId)) {
      final parent = docs[parentId]!;
      docs[parentId] = parent.copyWith(
        childrenIds: [...parent.childrenIds, pageId],
      );
      expanded.add(parentId);
    }

    final tabs = List<String>.from(state.openTabs);
    if (tabs.length >= 5) {
      tabs.removeLast();
    }
    tabs.add(pageId);

    state = state.copyWith(
      documents: docs,
      openTabs: tabs,
      activePageId: pageId,
      expandedTreeIds: expanded,
      nextIdCounter: counter + 1,
    );
    return pageId;
  }

  void _replaceDocument(NoteDocument updated, {int? nextCounter}) {
    final docs = Map<String, NoteDocument>.from(state.documents);
    docs[updated.id] = updated;
    state = state.copyWith(
      documents: docs,
      nextIdCounter: nextCounter ?? state.nextIdCounter,
    );
  }
}

final workspaceProvider = NotifierProvider<WorkspaceController, WorkspaceState>(
  WorkspaceController.new,
);
