# MonoNote

MonoNote 是用 Flutter 构建的桌面块编辑器，采用暖色纸感画布、浮动侧栏和多标签页，支持打开和保存本地 Markdown。

## 网页体验

直接打开 [MonoNote 网页版](https://kongvalley.github.io/notebook-flutter/)。可以编辑示例笔记、拖动块排序，也可以通过画布右上角的文件菜单导入和下载 Markdown。文件在浏览器内处理，刷新前请下载需要保留的修改。

## Windows 下载

从 [GitHub Releases](https://github.com/KongValley/notebook-flutter/releases) 下载 Windows x64 ZIP。解压整个压缩包后，运行其中的 `mononote.exe`。

## 编辑笔记

- 在画布右上角打开「文件与导出」菜单，选择本地 `.md` 或 `.markdown` 文件，或将当前笔记导出为 PNG 长图和 A4 PDF。导出会包含完整笔记正文，PDF 按页以图片呈现。
- 从命令面板选择「查看快捷键」可查看当前平台的按键。Windows 上可用 `Alt+Shift+H` 打开快捷键列表、`Alt+Shift+G` 导出 PNG、`Alt+Shift+P` 导出 PDF。桌面版使用 `Ctrl+O` 打开 Markdown、`Ctrl+S` 保存、`Ctrl+Shift+S` 另存为，macOS 使用 `⌘` 代替 `Ctrl`。
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
