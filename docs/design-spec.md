# MonoNote — Flutter 桌面端高颜值块级笔记工具设计规范

> **定位**：一款兼具「温润纸感（Warm Editorial Paper）」与「轻透磨砂（Translucent Frosted Glass）」美学的高颜值跨平台桌面块级笔记工作台。  
> **技术栈**：Flutter Desktop（优先适配 Windows 11，同时原生兼容 macOS 视觉规范与快捷键习惯）。

---

## 1. 核心美学哲学（Aesthetic Philosophy）

传统笔记应用往往陷入两种极端：要么过于厚重复古（缺少现代桌面系统质感），要么通体半透明炫技（导致长时间写作阅读视觉疲劳）。**MonoNote** 采用**「双层空间材质分离」**原则：

1. **导航与工具层 = 轻透暖调磨砂（Frosted Chrome Layer）**  
   一体化的无边框顶栏、可折叠浮动侧栏、`/` 斜杠菜单、文本悬浮工具岛、`Ctrl/Cmd + K` 命令面板均采用带有微弱暖色调的半透明毛玻璃材质。它如薄雾般悬浮于底层环境光之上，提供现代操作系统的空间景深与通透感。
2. **写作与阅读层 = 温润印刷纸张（Warm Paper Canvas）**  
   正文画布保持高不透明度的温润米白（晨曦素笺）或暖炭黑（松烟夜读），配以极低对比度的细边框与柔和阴影，杜绝纯白 `#FFFFFF` 刺眼与纯黑 `#000000` 过硬的反差，确保长文写作沉浸舒适。
3. **同心圆角与克制装饰（Concentric Geometry & Restraint）**  
   严格遵守外层圆角与内层圆角同心递减公式（`R_outer = R_inner + Padding`），用 `1px` 顶部内高光与微弱阴影代替粗重分割线，仅以**陶釉赤铜（Terracotta）**作为视觉焦点引导。

---

## 2. 信息架构与桌面端空间布局（Desktop Layout & Chrome）

```
┌─────────────────────────────────────────────────────────────────────────┐
│ [交通灯/Logo] [侧栏] [标签页: 📖 产品构想 ×] [🔍 搜索 / Ctrl+K] [主题] [— □ ×] │ 42px 一体化顶栏
├──┬───────────────────┬──────────────────────────────────────────────────┤
│  │ 浮动毛玻璃侧栏     │  温润纸感块级画布（Paper Canvas）               │
│  │ (240px, 可折叠)   │                                                  │
│  │                   │  面包屑: 工作空间 / 产品视觉构想     [字数][大纲] │
│8px│  • 今日随记       │  ┌────────────────────────────────────────────┐  │
│间│  • 灵感收件箱 (3)  │  │  # MonoNote 桌面端设计构想                 │  │
│距│  ───────────────  │  │  > 提示卡片 Callout                        │  │
│  │  ▾ 📖 产品构想     │  │  ┌──────────────────┐ ┌──────────────────┐ │  │
│  │    🎨 视觉规范     │  │  │ 嵌套子页面卡片 1  │ │ 嵌套子页面卡片 2  │ │  │
│  │    ⚡ 块级交互     │  │  └──────────────────┘ └──────────────────┘ │  │
│  │  ▸ 🪵 Flutter架构  │  │  [ ] 待办清单与可编辑块（输入 / 呼出菜单）  │  │
│  │                   │  └────────────────────────────────────────────┘  │
│  │  #标签 / 本地状态  │                      (按需右侧滑出: 260px 大纲)  │
└──┴───────────────────┴──────────────────────────────────────────────────┘
```

### 2.1 窗口与布局尺寸规范
| 区域 | 推荐尺寸（1280×800 基准） | 行为与交互规则 |
| :--- | :--- | :--- |
| **一体化顶栏 (Titlebar)** | 高度 `42px`（跨全宽） | 整条顶栏空白处均可拖拽移动窗口；内置紧凑文档标签页（最多显示 5 个，超出横向滚动）、居中磨砂搜索胶囊、主题/大纲开关。 |
| **浮动磨砂侧栏 (Floating Sidebar)** | 宽度 `240px`（允许拖拽调整 `200px–320px`） | 四周保留 `8px` 呼吸间距，`14px` 圆角；支持 `Ctrl/Cmd + \` 一键平滑折叠（`260ms` 阻尼缓动），折叠后画布自动居中扩展。 |
| **主纸感画布 (Paper Canvas)** | 弹性填充，正文栏最大宽度 `740px` | 左右最小安全留白 `32px`；支持拖拽窗口缩窄至 `640px` 时自动进入单栏纯净模式。 |
| **右侧大纲/双链抽屉 (Inspector)** | 宽度 `260px`（默认收起） | 点击右上角大纲图标后以半透明磨砂抽屉展开，展示页面目录锚点、双向引用与统计。 |

### 2.2 跨平台桌面适配策略（Windows 11 + macOS）
- **Windows 11**：
  - 采用无边框自定义窗口（`titleBarStyle: TitleBarStyle.hidden`），右上角绘制符合 Fluent Design 尺寸的 `46×42px` 最小化/最大化/关闭按钮（关闭按钮悬停呈现克制的 `#C42B1C` 警示红）。
  - 窗口底层支持接入 Windows 11 **Mica / Acrylic** 穿透，使顶栏与浮动侧栏隐约透出桌面壁纸色调。
  - 快捷键主修饰键映射为 `Ctrl`。
- **macOS**：
  - 保留原生左上方红黄绿交通灯（Traffic Lights），顶栏左侧预留 `76px` 安全区。
  - 底层调用 `NSVisualEffectView`（`.sidebar` / `.underWindowBackground` 材质）。
  - 快捷键主修饰键映射为 `Cmd (⌘)`。

---

## 3. 完整 Design Token 规范

### 3.1 色彩与毛玻璃材质系统（Color & Glass Tokens）

| Token 名称 | 晨曦素笺（Light Mode） | 松烟夜读（Dark Mode） | 用途说明 |
| :--- | :--- | :--- | :--- |
| `bgAmbient` | `#EFEBE3` → `#E7E2D8`（微渐变） | `#12100E` → `#171412` | 窗口底层背景，衬托磨砂玻璃层景深 |
| `surfacePaper` | `#FCFBF8`（98% 不透明） | `#1D1B19`（96% 不透明） | 核心写作画布与文档页卡片底色 |
| `surfaceCard` | `#F6F3EC` | `#25221F` | 嵌套子页面卡片、代码块、Callout 底色 |
| `glassChrome` | `rgba(247, 244, 238, 0.72)` | `rgba(33, 30, 27, 0.74)` | 浮动侧栏、顶栏、悬浮菜单毛玻璃基底 |
| `glassBlurSigma` | `22.0` (`saturate 1.35`) | `24.0` (`saturate 1.25`) | `ImageFilter.blur` 高斯模糊半径 |
| `glassHighlight` | `rgba(255, 255, 255, 0.72)` | `rgba(255, 245, 232, 0.08)` | 毛玻璃面板顶部 `1px` 模拟光线内高光 |
| `borderSubtle` | `rgba(55, 46, 36, 0.08)` | `rgba(255, 245, 232, 0.08)` | 画布、卡片与面板极细描边 |
| `borderStrong` | `rgba(55, 46, 36, 0.15)` | `rgba(255, 245, 232, 0.16)` | 激活输入框、聚焦胶囊边框 |
| `inkPrimary` | `#231F1B` | `#EDE8E1` | 标题、正文主文字（温润炭墨，非纯黑） |
| `inkSecondary` | `#696159` | `#A49B90` | 摘要、侧栏二级导航、面包屑 |
| `inkMuted` | `#9E958C` | `#6E665E` | 占位符、快捷键提示、时间戳 |
| `accentPrimary` | `#C26D4A`（陶釉赤铜） | `#D98A68` | 主激活态、光标、主要按钮、选中指示 |
| `accentSoft` | `rgba(194, 109, 74, 0.12)` | `rgba(217, 138, 104, 0.16)` | 侧栏当前选中胶囊、标签底色 |
| `semanticSage` | `#527966` | `#74A38C` | 完成状态、本地同步正常提示 |
| `semanticSlate` | `#526A84` | `#7F9BB8` | 双向链接、引用装饰、信息提示 |
| `semanticAmber` | `#B87D2B` | `#DAA24E` | 注意事项 Callout |

### 3.2 字体与排版层级（Typography Scale）

为体现纸张阅读的温润质感，建议支持**「人文混排模式（默认）」**与**「文艺衬线标题模式」**：
- **Windows Font Stack**：标题/正文 `'Segoe UI Variable', 'Microsoft YaHei UI', 'PingFang SC', sans-serif`；文艺标题可选 `'Noto Serif SC', 'Source Han Serif SC', Georgia, serif`；代码 `'JetBrains Mono', 'Cascadia Code', Consolas, monospace`。
- **macOS Font Stack**：`'.AppleSystemUIFont', 'PingFang SC', 'SF Pro Text', sans-serif`；衬线标题 `'Songti SC', 'New York', serif`。

| 层级 | 字号 | 字重 | 行高 | 字距 / 段间距 | 用途 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Doc Title (H0)` | `30px` | `700` | `1.28` | `-0.02em` / 下距 `12px` | 文档大标题 |
| `Heading 1` | `22px` | `650` | `1.35` | `-0.015em` / 上 `22px` 下 `8px` | 一级章节标题 |
| `Heading 2` | `17.5px` | `600` | `1.42` | `-0.01em` / 上 `16px` 下 `6px` | 二级小节标题 |
| `Body (Default)` | `15px` | `400` | `1.72` | `0.01em` / 块间距 `6px` | 正文段落、清单项 |
| `Card Excerpt` | `13px` | `400` | `1.55` | `0` | 嵌套子页面卡片摘要 |
| `UI Nav / Label` | `13px` | `500` | `1.4` | `0` | 侧栏节点、标签页、菜单项 |
| `Micro / Shortcut` | `11.5px` | `500` | `1.2` | `0.02em` | 快捷键徽章 `Ctrl+K`、状态字数 |

### 3.3 圆角、间距与阴影（Geometry & Elevation）
- **4px 基准空间栅格**：`4, 8, 12, 16, 20, 24, 32, 48`
- **同心圆角规范**：
  - 窗口圆角（非全屏）：`14px`
  - 浮动侧栏 / 主纸感画布：`12px`（外距窗口 `8px`）
  - 嵌套子页面卡片 / Callout 块：`10px`
  - 侧栏条目激活胶囊 / 按钮 / 菜单项：`8px`
  - 快捷键徽章 / Tag 胶囊：`6px`
- **纸感微阴影（Light Mode）**：
  - 画布基础投影：`0 2px 10px rgba(42, 34, 24, 0.04), 0 1px 2px rgba(42, 34, 24, 0.03)`
  - 悬浮菜单 / 斜杠面板：`0 14px 36px rgba(35, 28, 20, 0.12), 0 2px 8px rgba(35, 28, 20, 0.06)`

### 3.4 微动效曲线（Motion System）
- **标准空间缓动**：`Cubic(0.22, 1.0, 0.36, 1.0)`（轻柔入位、无生硬弹跳）
- **面板折叠/展开（Sidebar / Inspector）**：`260ms`
- **弹窗 / 斜杠菜单 / 命令面板**：`160ms`（伴随 `scale(0.97 -> 1.0)` + `opacity(0 -> 1)`）
- **文本悬浮工具岛**：`120ms`
- **块级交互高亮**：`90ms` 快速响应 hover 手柄与卡片抬升（`translateY(-1px)`）

---

## 4. 核心交互机制设计（Key Interactions）

1. **斜杠命令面板（`/` Slash Command）**  
   在任意空行或文本末尾输入 `/`（或点击块左侧 `+` 号），光标旁立即浮出毛玻璃命令菜单：支持键盘上下键选择、首字母/拼音首字母模糊过滤（如输入 `/todo`、`/card`、`/callout`）。
2. **Craft 式嵌套子页面卡片（Subpage Card Block）**  
   在文档内部创建的子页面，不仅同步出现在左侧树形目录中，还能在当前文档内以「精致小卡片」形式内嵌展示（含图标、标题、2 行摘要与子页面数量），点击即可平滑转场或新建顶栏标签页打开。
3. **局部悬浮格式化工具岛（Floating Selection Toolbar）**  
   鼠标选中文字后，仅在选区上方 `8px` 处浮现紧凑的磨砂胶囊工具条（加粗、斜体、荧光高亮、行内代码、转换块类型、链接笔记），未选中文字时完全隐身，保持画布绝对纯净。
4. **全局命令面板（`Ctrl/Cmd + K`）**  
   集成全文标题检索、最近文档、快捷新建以及环境控制（如直接输入「切换深色」、「折叠侧栏」），真正实现手不离键盘的桌面端效率。

---

## 5. Flutter 桌面端技术落地方案（Flutter Architecture）

### 5.1 推荐依赖包矩阵
| 能力域 | 推荐 Flutter 包 | 选型理由 |
| :--- | :--- | :--- |
| **无边框与窗口控制** | `window_manager` | 隐藏系统原生标题栏、实现自定义拖拽区域（`DragToMoveArea`）、窗口尺寸记忆与最大化状态同步 |
| **系统级毛玻璃/Mica** | `flutter_acrylic` | 支持 Windows 11 Mica / Acrylic、macOS `NSVisualEffectView` 背景材质穿透 |
| **块级富文档引擎** | `appflowy_editor`（或基于 `super_editor` 定制） | `appflowy_editor` 原生面向桌面端块级文档构建，支持树形 `Node` 文档模型、斜杠菜单插件、悬浮 Toolbar 与块拖拽 |
| **状态管理与依赖注入** | `flutter_riverpod` | 轻量、无上下文依赖，非常适合管理标签页栈、当前激活文档树与主题切换 |
| **本地优先数据库** | `drift` (SQLite + FTS5) | 本地关系表存储页面层级、标签与块快照，内置 FTS5 实现毫秒级 `Ctrl+K` 全文检索 |
| **快捷键与命令分发** | Flutter 原生 `Shortcuts` + `Actions` + `Intent` | 跨平台自动区分 `LogicalKeyboardKey` 的 `control`（Win）与 `meta`（macOS） |

### 5.2 Flutter 毛玻璃性能与主题工程实践
1. **严格限制 `BackdropFilter` 重绘范围**：  
   在 Flutter Desktop 中，大面积实时 `BackdropFilter` 叠加高帧率滚动可能造成 GPU 负载上升。应始终用 `ClipRRect` 包裹，并在外层添加 `RepaintBoundary`；仅对**顶栏、侧栏容器整体、弹窗层**应用一次 `ImageFilter.blur`，不要在列表的每一个 `ListTile` 上单独套用模糊滤镜。
2. **自定义 `ThemeExtension<MonoNoteThemeTokens>`**：  
   不要把纸张色与毛玻璃参数硬编码在 Widget 中，而是抽离为可插值（`lerp`）的 `ThemeExtension`，让Light（晨曦素笺）与 Dark（松烟夜读）切换时颜色平滑过渡。

### 5.3 推荐项目目录结构（`lib/`）
```text
lib/
├── app/
│   ├── app.dart                  # MaterialApp + ThemeExtension 注入 + 全局 Shortcuts
│   └── window_bootstrap.dart     # window_manager & flutter_acrylic 桌面初始化
├── core/
│   ├── theme/
│   │   ├── mononote_tokens.dart  # 色彩、毛玻璃、圆角、阴影 ThemeExtension 定义
│   │   └── mononote_typography.dart# 跨平台混排字体层级
│   └── shortcuts/
│       └── app_shortcuts.dart    # Win(Ctrl) / macOS(Cmd) 统一 Intent 映射
├── data/
│   ├── db/                       # Drift SQLite Schema & FTS5 全文索引
│   └── repositories/             # PageRepository, BlockRepository, Markdown 导入导出
└── features/
    ├── shell/                    # 无边框顶栏、多标签页、浮动侧栏布局容器
    ├── sidebar/                  # 磨砂树形页面导航、标签筛选、快速收件箱
    ├── editor/                   # 块级画布、斜杠菜单、嵌套子页面卡片块、悬浮工具条
    ├── inspector/                # 右侧滑出大纲与双向链接面板
    └── command_palette/          # Ctrl/Cmd+K 全局模糊搜索与命令弹窗
```
