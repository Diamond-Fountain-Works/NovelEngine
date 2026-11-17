# Novel Engine 0.0.1 设计预览检查

日期：2026-11-16。范围：本地 HTML 交互原型与架构文档。

## 结果

| 检查 | 结果 | 依据 |
| --- | --- | --- |
| 布局模型 | PASS | Node Test Runner：10 通过、0 失败、0 跳过 |
| JavaScript 语法 | PASS | 三个预览脚本通过 Node 语法检查 |
| 本地资源、ID 与文档链接 | PASS | 静态检查，字体和图标本地加载 |
| 日夜主题 | PASS | Safari 实际点击与截图；双主题使用 DFW 资源 |
| 四向新建分栏 | PASS | 四个方向逐个操作；检查分栏数与分隔条方向 |
| Join Left / Right | PASS | 两侧分别编辑不同章节，合并后两章仍在侧栏；最新菜单只显示方向图标及操作名 |
| Join Up / Down | PASS | 三栏嵌套布局中逐个执行；合并后两栏，撤销后恢复三栏 |
| 侧栏右键菜单 | PASS | 实际打开，包含可用的 Join 方向 |
| 分隔条缩放 | PASS | 键盘 50 → 55；鼠标拖动 55 → 62 |
| 同一文档多视图 | PASS | 在一个分栏输入 10 字、2 段，两个视图同时显示相同内容与计数 |
| 不同文档分栏 | PASS | 一侧 10 字，另一侧 5 字，项目统计保持 2 章、15 字 |
| 手机窄窗口 | PASS | 呈现一个编辑区；保留三栏及切换入口；回到 Mac 后恢复三栏和两个分隔条 |
| 文档、笔记与排版基础交互 | PASS | 新建章节、笔记空状态与创建、搜索、字体与字号、专注模式及浮层关闭已操作 |
| 人工视觉批准 | REVIEW REQUIRED | 截图均为 Candidate，尚无批准基线 |
| 原生 SwiftUI App 构建 | NOT RUN | 当前尚无 App Target |
| 原生客户端、数据库与跨端同步测试 | NOT RUN | 尚未实施 |
| 真机、中文输入法组合态与 Reduce Motion 运行检查 | NOT RUN | 中文验证为文本粘贴；Reduce Motion 当前仅有样式分支 |

浏览器操作使用 Computer Use 的原生 Safari 接口，不是 XCUITest。Mac / iPad / Duo / iPhone 按钮是预览窗口宽度切换，不代表对应真机验收。

## 已发现并修复

- 底部字数栏裁切：为编辑区设置正确的最小高度和滚动边界。
- 日间提示文字偏淡：提示文字对比度从约 2.82 调整为 4.92；选中章节元数据从约 3.78 调整为 5.04。
- 排版浮层与文档信息叠加：统一关闭其他临时浮层。
- 分隔条点击后没有键盘焦点：在拖动开始时显式聚焦，方向键缩放重测通过；原失败证据保留。
- 上下分栏留白占用过多：低高度采用紧凑工具栏与正文边距，保留滚动和底部状态。
- 窄窗口多栏过密：仅呈现当前分栏，保留完整布局并提供分栏切换。

## 预览代码职责

| 文件 | 职责 |
| --- | --- |
| `docs/design/preview/workspace-layout.js` | 布局树、分割方向、合并、比例与布局历史 |
| `docs/design/preview/preview-documents.js` | 预览文档内存模型；分栏共享引用 |
| `docs/design/preview/preview-app.js` | DOM 视图、事件、焦点、响应式布局与菜单 |
| `docs/design/preview/preview.css` | 双主题与基础工作区 |
| `docs/design/preview/workspace.css` | 分栏、分隔条、布局菜单和紧凑排版 |
| `docs/design/preview/tests/workspace-layout.test.cjs` | 原型布局模型回归测试 |

## 本地证据

路径：`~/Documents/Codex/NovelEngine-架构与界面-2026-11-16/`。

较早的分栏候选（保留对照）：

- `workspace-layout-light-candidate.png`
- `workspace-layout-dark-candidate.png`
- `workspace-join-menu-candidate.png`
- `phone-pane-switcher-candidate.png`

检查记录包括 `directional-ui-results.txt`、`vertical-join-ui-results.txt`、`shared-document-edit-AX.txt`、`separator-keyboard-before-fix-AX.txt`、`separator-keyboard-fixed-AX.txt`、`separator-drag-verified-AX.txt`、`phone-pane-switcher-AX.txt` 与 `workspace-final-join-AX.txt`。

`verification.json` 记录早期分栏版本；最新版本依据下方记录。截图仅留本地审图，不作为已批准基线。

## 本轮修订：直接分栏、Blender Join 与 DFW 日间

- 实际查看本机 VS Code 的直接 Split Editor 按钮与 Blender 5.2.3 LTS 的 Area Edge Options。Blender 第一层包含 Join Right / Join Left；只查看菜单，未修改 Blender 场景。
- 四个分栏图标直接放在右上角。四向分栏与对应 Join 已逐一点击，均从 1 栏变为 2 栏再合并回 1 栏。
- Join 菜单删除标题、解释、保留数量和底部提示；移除页面底部重复的预览说明，预览存储边界保留在 README。
- 用户最新决定：日间也采用 DFW。保留纸白正文，使用银蓝色侧栏、钴蓝选中状态、Afterglow Solid 1.001 与原始 DFW 星形。
- 日间正文、辅助文字、Placeholder、选中标题与元数据的静态对比度分别为 18.64、6.34、4.86、8.27、6.22。日间品牌字为 8.18。
- 最新配色在 Safari 检查：Mac 日间、Mac 夜间、手机日间，以及右向分栏和扁平 Join 菜单。窄窗口保留 2 栏布局树；回到 Mac 恢复双栏。截图仍待人工批准。
- 重跑布局测试：10 PASS、0 FAIL、0 SKIP。三个 JavaScript 语法、本地资源、HTML ID 与文档链接检查通过。DFW 字体和星形 SHA-256 与 skill 源文件一致。

本轮本地证据：

- `blender-join-left-right-reference.png`、`vscode-direct-split-reference.png`
- `inline-controls-ui-checks.json`：四向分栏与合并的浏览器检查
- `dfw-daylight-candidate.png`、`dfw-daylight-join-candidate.png`
- `dfw-night-direct-split-candidate.png`、`dfw-daylight-phone-candidate.png`
- `dfw-daylight-final-AX.txt`、`verification-dfw-daylight.json`：最新状态、检查结果与文件哈希
