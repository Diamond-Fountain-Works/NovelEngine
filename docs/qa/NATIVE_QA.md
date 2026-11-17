# 原生 QA

## 0.0.1 Build 15：资料模块与双区布局

日期：2026-11-17。开发 Bundle ID 不变；当前原生界面采用 [ADR 0003](../architecture/decisions/0003-fixed-library-paired-editors.md)。下面 Build 6 及更早记录是历史行为，不能作为当前交互规范。

| 检查 | 实际结果 |
| --- | --- |
| 构建与签名 | PASS；SwiftPM arm64 开发 App，0.0.1 Build 15，ad-hoc 签名 |
| 核心 XCTest | 52 PASS / 0 FAIL / 0 SKIP；含资料、格式 1 / 2、双区及历史布局几何 |
| AppKit / UI 会话 XCTest | 23 PASS / 0 FAIL / 0 SKIP；含 Unicode 输入、独立文档目标、旧偏好迁移与焦点 |
| 原生文件 XCTest | 5 PASS / 0 FAIL / 0 SKIP；含真实磁盘的资料 / 子文档往返 |
| 工程与公开检查 | PASS；文档链接、模块依赖、配置、源码及允许的二进制资源扫描 |
| 固定导航 | 原生 PASS；仅一份书稿 / 人物 / 事件 / 世界观 / 设定导航；没有局部分栏按钮或区域类型切换 |
| 四向位置 | 原生 PASS；上、下、左、右及重复右向点击始终保留同一主区和辅助区 ID、章节与人物选择 |
| 独立选择内容 | 原生 PASS；主区打开章节，辅助区打开人物，再切换事件并返回，其他区与导航模块保留 |
| 关闭及布局撤销 | 原生 PASS；关闭辅助区后主区铺满，撤销恢复原辅助区及其人物文档，作者正文保留 |
| 输入和信息 Sheet | 原生 PASS；章节输入中文、换行、连续空格与 Emoji；文本撤销 / 重做、摘要编辑、完成与保存 |
| 窗口和比例 | 原生 PASS；760pt 窄窗口的文档选择、资料属性及辅助区关闭可见；分隔条方向键由 50% 调至 55% 后恢复 |
| 保存与重启 | 原生 PASS；重新启动并打开合成作品，两区 ID、文档选择、正文、摘要和关联恢复；磁盘字节一致 |
| 旧资料兼容 | PASS；七份合成文档的 UUID、父子、资料属性、事件参与者及前置关系保留，只有明确输入的章节正文与摘要改变 |
| 双主题 | 原生日间 / 夜间已检查，之后恢复跟随系统；截图为 Candidate / REVIEW REQUIRED |

### 实施与失败记录

- Build 7–13 完成资料类型、空白栏目模板、人物子文档、状态与引用。原生验证标题 / 标签搜索保留祖先、循环事件前置禁用，以及旧格式 1 打开。
- Build 7 的属性 Popover 输入曾进入正文；随后改用原生 Sheet、取消待处理正文焦点请求并明确字段焦点。实际输入重测通过。
- 修复无改动属性提交触发已编辑状态；作者文本使用 UTF-8 相等性，NFD → NFC 显式输入及撤销 / 重做有 AppKit 测试。
- Build 14 的嵌套原生文档菜单发生 AX 操作超时；采样显示原生菜单正在等待事件，没有证据表明正文或文件被改写。取消菜单后，Build 15 改为按类型分组的直接文档列表浮层，实际两区选择已重测。
- Build 15 将导航从历史布局树分离，提供主区与可移动辅助区；`workspace.editors` / `library.browser` 为新本机偏好，旧 key 保留。布局只涉及视图，不修改作品格式。

### 证据与未运行范围

本地证据在 `~/Documents/Codex/NovelEngine-资料模块-2026-11-17/` 和 `~/Documents/Codex/NovelEngine-双区布局-2026-11-17/`。后者保存 Build 15 的构建 / 测试日志、逐方向 AX、正文撤销、关闭与布局撤销、重启、事件关联、双主题和窄窗口截图，以及正文 SHA-256 校验。

README 图片只使用空白工作区截图，移除系统标题栏并裁出工作区局部；不含作者小说、测试人物或私人目录。完整截图保留在本地，公开图片仍为候选。

- XCUITest：NOT RUN；自动化为 XCTest，原生实操为 Computer Use。
- 真实拼音候选窗口、旧 macOS 机器、异常终止恢复、其他平台客户端和跨端同步：NOT RUN。
- 分隔条拖动 / 双击由现有适配实现及键盘测试覆盖；本轮原生重测键盘比例，未另作鼠标拖动 / 双击验收。
- 没有自动安装到 Applications，没有导入私人 VG 内容，没有替换已发布 v0.0.1 Tag，也没有批准视觉基线。

---
# Native macOS QA

## 0.0.1 Build 6：统一区域与首次开源

日期：2026-11-17。环境：Apple Silicon、Swift 6.4.2、Xcode 27.2。

| 检查 | 实际结果 |
| --- | --- |
| 本地构建与签名 | PASS；0.0.1 Build 6 开发 Bundle，ad-hoc 签名 |
| XCTest | PASS：52 项，0 FAIL，0 SKIP；核心 33、UI 适配 / 会话 15、文件适配 4 |
| 统一区域 | 书稿、正文、章节信息使用同一布局；原生实查侧栏 Join Right、撤销、直接向下拆分侧栏、切换为章节信息 |
| 焦点故障 | 中间 Build 4 拆分后焦点仍在旧正文，已保留故障 AX / 截图。Build 5 修复，原生重测焦点进入新区域；Build 6 原生验证专注书稿区域后，焦点进入搜索框 |
| 文本撤销 | 原生实查：拆分和 Join 后，源编辑器的文本撤销 / 重做仍有效，两个共享视图同步显示原文 |
| 布局兼容 | 单元测试旧 pane 缺失类型时默认为正文、旧布局一次性迁移、已关闭侧栏不在重启时重建 |
| 文稿兼容 | 原生在 Build 5 打开 Build 4 合成作品，正文、区域类型和 pane ID 恢复；作品格式保持 1 |
| 多侧栏隐藏 | Build 6 单元测试确认一次隐藏多个同类区域只占一个布局撤销步骤 |
| 双主题 | 原生实查日间 / 夜间；最后恢复跟随系统 |
| 公开素材 | 两张空白工作区截图；README 图片裁去系统标题栏，并缩小为 1600px 宽；完整原始图保留本地 |
| Visual QA | Candidate / REVIEW REQUIRED；未自动批准视觉基线 |
| CI | 以 GitHub Actions 最新提交结果为准，不把本地测试作为 CI 结果 |

本地证据位于开发者 `~/Documents/Codex/NovelEngine-统一区域与开源发布-2026-11-17/`：`build6-qa.log`、`split-focus-before-fix.txt`、`split-focus-after-fix.txt`、`focus-and-undo-passed.txt`、`reopen-build4-project-in-build5.txt`、`build6-focus-sidebar.txt` 和 `build6-focus-sidebar.jpg`。初次新增焦点测试直接修改 NSView，随后被 SwiftUI 的既有 nil 属性覆盖，产生两条失败断言；已改为经 Representable 更新请求的真实调用路径，回归及完整测试通过，旧失败日志保留。

鼠标自动化对 SwiftUI 原生菜单曾超时，改用菜单键盘选择完成操作；该超时不当作 App 崩溃，也不当作点击成功。此处 UI 实查由 Computer Use 执行，XCTest 适配测试不称为 XCUITest。旧系统及其他平台尚未实际运行。

---

## 0.0.1 Build 3：直接拆分与相邻合并

日期：2026-11-16。使用本机构建的 SwiftUI / AppKit App 和合成作品，未使用作者稿件。

| 检查 | 实际结果 |
| --- | --- |
| `make qa` | PASS：42 项 XCTest，0 FAIL，0 SKIP；核心 28、UI 适配 / 会话 10、文件适配 4；13 份文档与模块检查通过 |
| 开发 Bundle | PASS：0.0.1 Build 3，`com.diamondfountain.novelengine.dev`；ad-hoc 签名校验通过 |
| 顶部四向按钮 | PASS：左、右、上、下逐个直接点击，创建方向正确；没有收进布局菜单 |
| 组内向下按钮 | PASS：右栏活动时点击左栏的向下按钮，只拆左栏；每组向右、向下均为直接按钮 |
| 焦点 | PASS：点击另一栏正文，不输入文字，活动组和侧栏文档类型立即切换，全局拆分作用于该组 |
| Join | PASS：四格上半段 Join Right 只关闭右上，左上扩展，下面两格保留；下半段 Join Left 保留右下并向左扩展；Build 3 再次执行上半段合并成功 |
| 拖动 / 键盘 / 均分 | PASS：左右分隔条从 50% 拖至 55.010%，Left 回到 50.010%，双击回到 50% |
| 关闭 / 撤销 | PASS：关闭一组后其他组与文档仍在；撤销 Join 恢复原 pane ID 与四格布局 |
| 专注 | PASS：保留当前笔记，退出后恢复原有三组；最终通过菜单鼠标点击执行退出，键盘自动化曾选中禁用拆分项，不能计为该路径通过 |
| 保存 / 重开 | PASS：Build 2 保存的两份文稿在 Build 3 打开，布局与文档引用恢复；最后磁盘字节与输入原文、换行、Emoji、末尾两个空格一致 |
| 窗口宽度 | PASS：macOS「窗口 → 移动与调整大小 → 左侧」检查 760pt 宽窗口，直接按钮和关闭按钮可见，正文换行；随后恢复原大小。初始边角拖动未改变尺寸，未计为通过 |
| 双主题 | 日间与夜间实查，随后恢复「跟随系统」；夜间截图来自相同 Join 逻辑的中间 Build 2，Build 3 夜间顶部按钮尚未另拍 |
| 视觉结论 | REVIEW REQUIRED；截图为 Candidate，未自动批准 |

### 修改文件

- `NovelWorkspace/WorkspaceLayout.swift`、`WorkspaceGeometry.swift`：显式拆分目标、完整共边的相邻 Join、跨父分支安全合并、关闭单组、布局撤销。
- `NovelUI/Workspace/WorkspaceSession.swift`、`NativeSplitNode.swift`、`JoinMenu.swift`、`WorkspaceToolbar.swift`：焦点路由、原生递归尺寸、专注保留视图、四个直接按钮与次要布局菜单。
- `NovelUI/Writing/EditorGroupHeader.swift`、`EditorPaneView.swift`、`ManuscriptSidebar.swift`：统一组标题、直接向右 / 向下、去掉第二行工具栏与侧栏 Join。
- `NovelUI/Platform/macOS/AreaDivider.swift`、`MacTextEditor.swift`：精确右键坐标、原生菜单与拖动、first responder 立即激活组。
- App Scene / Info.plist：紧凑系统工具栏、Build 3；作品格式和 Bundle ID 保持不变。
- 核心、会话、原生焦点及分隔条测试；README、需求、架构、设计、测试计划和阶段记录同步更新。

### 证据与范围

本地目录：`~/Documents/Codex/NovelEngine-分栏与合并修正-2026-11-16/`。

- `build3-qa.log`：统一构建、42 项测试与工程检查。
- `build3-direct-down.png`、`build3-local-down-inactive.png`：顶部与局部直接向下拆分。
- `build3-four-groups-join-menu.png`、`build3-layout-after-join.png`：完整共边的原生合并。
- `build3-narrow-window.png`、`build3-empty-workspace.png`：窄窗口与最终空白工作区。
- `build2-dark-two-documents.png`：中间版本夜间文稿；`vscode-real-editor-groups.png`：真实 VS Code 编辑组参考。
- `verification.json`：Bundle、合成正文与截图 SHA-256。

自动化为 XCTest 模型 / AppKit 适配测试，实际 UI 通过 Computer Use 操作，不称为 XCUITest。Join 只处理完整共边且可由布局树表达的区域，未实现 Blender 的部分边拖拽合并。历史 HTML 原型未随本轮重写。旧版 macOS、iOS / Android / Windows 原生与跨端同步未运行。

以下保留 Build 1 的历史验收记录。

---

日期：2026-11-16。版本：0.0.1 Build 1，开发 Bundle `com.diamondfountain.novelengine.dev`。环境：Apple Silicon、Xcode 27.2、Swift 6.4.2。本轮只使用合成作品。

## 自动化结果

| 检查 | 实际结果 |
| --- | --- |
| 核心领域、作品格式与布局 | 21 PASS / 0 FAIL / 0 SKIP |
| AppKit 文本与字体 | 5 PASS / 0 FAIL / 0 SKIP |
| 原生文件适配与真实磁盘往返 | 4 PASS / 0 FAIL / 0 SKIP |
| 原生开发 App 构建 | PASS，arm64，最低编译目标 macOS 13 |
| 本机代码签名验证 | PASS，ad-hoc 开发签名 |
| 统一 make qa 入口 | PASS；30 项 XCTest、0 FAIL、0 SKIP；13 份文档链接和模块边界检查通过 |

## 原生窗口实测

Computer Use 操作实际构建的 NovelEngine.app，不是 HTML，不是 XCUITest。

- 在 NSTextView 输入中文、多行、两个连续空格和表情；字数与段落数更新。
- Cmd+Z / Cmd+Shift+Z 撤销、重做后作品状态跟随正文变化。
- 右上角向右分栏，两个视图显示相同章节；快捷键新建独立笔记，在右栏编辑，项目统计为 1 章、25 字。
- 通过 NSSavePanel 保存 `Native-acceptance.novelengine`，退出旧进程，再从系统 Open 面板重新打开；章节、笔记与稳定 ID 保留。
- 目录中的 UTF-8 逐字节读取结果保留两个空格及原始换行；笔记独立保存。
- 原生右键第一层显示 Join Right / Join Left。菜单 AX 点击曾超时，改用键盘确认完成 Join Left，编辑区从两栏变为一栏，笔记仍为 6 字，项目总数仍为 25。
- 设置窗口可切换 DFW 夜间并返回编辑器，内容保留。测试后恢复“跟随系统”。
- 最后关闭合成作品，保留 0 字的空白原生编辑窗口供使用。

## 本轮修复

1. 编译：递归 SwiftUI 节点的 ViewBuilder 返回类型、CGFloat 推断已修复。
2. 撤销：最初 NSTextView 没有独立撤销栈；补充每视图 UndoManager。进一步发现撤销已改文字却未回写 Binding，增加 Undo / Redo 完成通知回写。保留原始失败日志；原有断言与新增重做断言现已通过。
3. 分栏宽度：真实双栏检查发现 NSTextView 没有随容器缩窄。使用窄范围 NSScrollView.tile 适配与宽度约束，添加 420px 容器测试；原生再次编辑右栏笔记成功。
4. 可访问性：去掉父级统一 identifier 对子控件的覆盖，正文、标题、分栏按钮保留明确标识。
5. 笔记标题的 Placeholder 使用“未命名笔记”。

## 状态边界

- 原生截图：Candidate / REVIEW REQUIRED，未由 AI 批准。
- XCUITest：NOT RUN；本轮是 XCTest 与 Computer Use 实操。
- 中文 marked text：AppKit 编程测试 PASS；真实拼音候选窗口组合输入 NOT RUN，实操中文为粘贴。
- 四个方向的布局模型 PASS；原生窗口实测了向右分栏与 Join Left，其他方向的鼠标操作未逐一重跑。
- 原生分隔条拖动 / 键盘比例、文档拖动排序、搜索与信息面板完整流程：已有实现，完整 UI 验收 NOT RUN。
- 自动保存异常退出恢复、旧 macOS 机器、跨端同步、iPhone / iPad / Android / Windows：NOT RUN。
- 没有安装到 Applications，没有读取真实小说、其他 App 数据、身份或密钥。

## 证据

本地路径：`~/Documents/Codex/NovelEngine-原生开发-2026-11-16/`。

- `text-editor-tests-first-failure.log`、`text-editor-tests-undo-binding-failure.log`、`undo-diagnostic.log`
- `text-editor-tests.log`、`native-document-tests.log`、`native-final-build.log`
- `before-editor-width-fix.png`、`native-split-light-candidate.png`、`native-join-light-candidate.png`、`native-dark-candidate.png`
- `native-edited-saved-AX.txt`、`native-save-before-width-fix-AX.txt`

QA 合成作品和重复测试缓存在完成后清理；保留以上检查证据与可运行开发 App。

## 产品名称修订

显示名统一为 **Novel Engine**，品牌字为 `NOVEL ENGINE`，构建包为 `build/Novel Engine.app`。Bundle ID、模块名、作品格式不变。重新构建和工程检查 PASS，实际启动后 App 菜单与可访问名称均显示 Novel Engine。历史检查中的旧包名保留作记录。
