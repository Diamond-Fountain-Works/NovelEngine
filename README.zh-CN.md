# Novel Engine

**面向长篇小说的原生写作工作台。**

[English](README.md) · [文档](docs/README.md) · [更新记录](CHANGELOG.md) · [参与开发](CONTRIBUTING.md)

[![macOS CI](https://github.com/Diamond-Fountain-Works/NovelEngine/actions/workflows/ci.yml/badge.svg)](https://github.com/Diamond-Fountain-Works/NovelEngine/actions/workflows/ci.yml)
![Version](https://img.shields.io/badge/version-0.0.1-blue)
![macOS](https://img.shields.io/badge/macOS-13%2B-black)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Novel Engine 用本地作品库管理小说。设置封面和作品资料，在双区编辑器中写作，内容自动保存到系统文稿目录。

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/workspace-dark.png">
  <img src="docs/assets/workspace-light.png" alt="Novel Engine 书稿列表与原生编辑器" width="1100">
</picture>

## 功能

- **作品库与主页。** 原始封面、作者与合作者署名、类型、标签、写作状态，以及不限字数的简介。
- **自动保存。** 默认存放于系统文稿目录的 `Novel Engine/作品/`；稳定作品 ID、完整快照、冲突检查和真实保存状态。

- **资料模块。** 纵向切换书稿、人物、事件、世界观与设定；支持总卡与子文档、待定 / 已定案状态、事件时间和文档关联。
- **章节与笔记。** 创建章节和笔记，编辑摘要，搜索标题，调整顺序，查看字符和段落统计。
- **双区编辑。** 左侧资料导航固定，辅助编辑区可放在主区的上下左右。两个编辑区独立选择文档，分隔条可调整；布局撤销与正文撤销独立。
- **原生文本编辑。** SwiftUI 界面与 AppKit 文本编辑器，支持输入法组合输入、选择、复制粘贴、撤销和重做。
- **作品导入与导出。** `.ne` 作品包包含 JSON、UTF-8 文档和原始封面；读取格式 1–3，继续导入旧 `.novelengine`，保留 ID 与原文。
- **双主题与排版。** Diamond Fountain Works 日间 / 夜间外观、字体和字号设置，以及保留原有布局的专注模式。

## 开始使用

需要 macOS 13 或更新版本，以及 Swift 6 工具链。当前开发与界面检查使用 Apple Silicon Mac。

```sh
git clone https://github.com/Diamond-Fountain-Works/NovelEngine.git
cd NovelEngine
make run
```

命令会构建并打开 `build/Novel Engine.app`。新建小说后自动保存，不需要逐次选择文件位置；需要传给别人时再导出 `.ne`。也可用 Xcode 打开 [`apps/apple/macOS/Package.swift`](apps/apple/macOS/Package.swift)，选择 `NovelEngine` 产品。

原生界面当前使用简体中文。v0.0.1 发布 macOS 源码；其他平台客户端与跨设备同步见[路线图](docs/roadmap/PHASES.md)。

## 工作区操作

| 操作 | 入口 |
| --- | --- |
| 创建或移动辅助区 | 窗口右上角四个方向按钮 |
| 切换本区文档 | 该区域标题处的文档选择器 |
| 关闭辅助区 | 辅助区标题右侧关闭按钮 |
| 文档信息与摘要 | 窗口工具栏的信息按钮 |
| 撤销布局 / 恢复默认布局 | 窗口工具栏的布局菜单 |
| 新建章节 / 笔记 | ⇧⌘N / ⌥⌘N |
| 新建小说 / 导入 | ⌘N / ⌘O |
| 立即保存 / 导出 ne | ⌘S / ⇧⌘S |
| 关闭窗口 / 设置 | ⌘W / ⌘, |

移动或关闭辅助区只改变视图，文稿仍然保留。方向按钮移动同一个辅助区。

## 开发

```sh
make build   # 构建 macOS 开发 App
make test    # 领域、布局、AppKit 与作品文件测试
make check   # 文档、模块边界与公开发布检查
make qa      # 构建、测试与检查
```

| 目录 | 职责 |
| --- | --- |
| `apps/apple/macOS` | App 入口、系统文档适配与 Bundle 配置 |
| `packages/novel-core-swift` | 领域、编辑用例、作品编解码与布局几何 |
| `packages/novel-ui-apple` | SwiftUI、设计 Token 与 AppKit 适配 |
| `protocol` | 平台无关作品格式 |
| `docs` | 产品、架构、设计、开发与 QA |
| `script` / `scripts` | 构建入口与工程检查 |

资料编辑见[资料模块](docs/product/REFERENCE_LIBRARY.md)。实现细节及验证范围见[架构](docs/architecture/ARCHITECTURE.md)、[作品格式](protocol/PROJECT_FORMAT.md)和[原生 QA](docs/qa/NATIVE_QA.md)。

## 许可证

[MIT](LICENSE) · © 2026 [Diamond Fountain Works](https://github.com/Diamond-Fountain-Works)。
字体和历史预览图标保留各自许可证，见[第三方声明](THIRD_PARTY_NOTICES.md)。
