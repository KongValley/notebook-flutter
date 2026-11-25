# MonoNote

MonoNote 是用 Flutter 构建的桌面块编辑器，采用暖色纸感画布、浮动侧栏和多标签页，支持打开和保存本地 Markdown。

## Windows 下载

从 [GitHub Releases](https://github.com/KongValley/notebook-flutter/releases) 下载 Windows x64 ZIP。解压整个压缩包后，运行其中的 `mononote.exe`。

## 编辑笔记

- 在画布右上角打开「Markdown 文件」菜单，选择本地 `.md` 或 `.markdown` 文件。Windows 上也可以用 `Ctrl+O` 打开、`Ctrl+S` 保存、`Ctrl+Shift+S` 另存为，macOS 上使用 `⌘`。
- 点击文字块即可编辑。选中文字后，用块下方工具栏设置粗体、斜体、删除线或行内代码。待办状态通过方框切换。
- 拖动块左侧手柄，沿画布提示线调整顺序。保存 Markdown 时会写入当前块顺序。
- 表格、链接、图片等内容以可编辑的 Markdown 源文块保留。文件使用 UTF-8，修改后需要主动保存。若原文件已在应用外修改，可另存为新文件。

## 从源码构建

准备满足 `pubspec.yaml` 约束的 Flutter SDK 和 Windows 桌面构建工具，然后运行：

```sh
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

构建产物位于 `build/windows/x64/runner/Release/`。
