# Novel Engine Design System

目标版本：0.0.1。状态：候选设计，等待用户审图。

## 工作区

- 原生工作区由系统标题栏及可组合的书稿、正文、章节信息区域组成；双主题统一使用 DFW 品牌语言。
- 0.0.1 不显示 AI 对话栏、模型选择、Token 消耗或 API Key 设置。
- 正文是主要空间。章节信息可以收起，专注模式隐藏两侧面板。
- Mac 使用多栏工作区；iPad 和 Duo 展开状态按窗口宽度保留侧栏；手机默认只显示当前文档，侧栏通过按钮打开。
- 双主题共享布局、控件位置、字号规则与业务能力。

## 日间：Diamond Fountain Works

纸白编辑区、银蓝色侧栏、钴蓝选中状态与黑色文字。与夜间共享 Afterglow 品牌字和原始 DFW 星形；日间星形使用单色黑，夜间保留银白。钴蓝与青绿氛围仅用于窗口外部，不进入正文背景。

| Token | 颜色 |
| --- | --- |
| Canvas | `#EDF2FB` |
| Chrome | `#F8FAFF` |
| Editor | `#FFFFFF` |
| Sidebar | `#F0F4FC` |
| Rail | `#E8EFFC` |
| Text | `#07141D` |
| Secondary | `#465B73` |
| Placeholder | `#60738A` |
| Rule | `#D8E1EF` |
| Accent / Selection | `#0032D9` |
| Selection Text | `#F7FCFF` |
| Selection Metadata | `#D1DCF6` |

## 夜间：Diamond Fountain Works

依据 `diamond-fountain-works-design` skill 的 design-system.md。钴蓝作为导航与选中强调，青绿色用于少量交互，深色作为长文工作底色。模糊氛围限制在窗口外部及边缘，文字始终清晰。

| Token | 颜色 |
| --- | --- |
| Canvas | `#000E13` |
| Editor | `#081A22` |
| Sidebar | `#06131D` |
| Text | `#F2F7EF` |
| Secondary | `#B0C2D6` |
| Placeholder | `#8FA8BA` |
| Accent | `#0032D9` |
| Cyan | `#71FFDB` |
| Selection | `#143791` |

不将网站开场动画搬进写作界面。品牌标识可以使用 Afterglow Solid；正文不使用斜体展示字。

## 字体与资源

- 产品中文 UI：系统中文字体；Apple 原生实现优先系统字体与动态字号。
- 正文预览：宋体 / 系统衬线，支持切换为系统无衬线；正式端通过平台字体接口实现。
- DFW 英文品牌字：`DFW Afterglow Solid 1.001`，保留品牌资源；原生文档标题栏不重复叠放品牌字标。
- 预览英文界面：Nunito；中文使用系统回退。
- 星形复用 skill 的 `dfw-star.svg`，保持原始几何。没有使用固定 Diamond Fountain Works 文字标识替代 Novel Engine 品牌。
- 字体与对应 SIL OFL 许可证随预览保存在 `preview/assets/`。
- 预览功能图标采用 Heroicons 24px Outline，MIT 许可证保存在 `preview/assets/Heroicons-LICENSE.txt`；原生实现使用平台可访问图标。

## 工作区区域

- 书稿、正文、章节信息处于同一布局树。侧栏不是布局之外的固定面板，也能拆分、合并、关闭和切换类型。
- 窗口右上角直接排列左、右、上、下四个按钮，作用于当前活动区域；不收进母菜单。省略号只提供撤销布局、恢复默认布局。
- 所有区域共用一行标题：左侧类型选择器、内容标题、直接向右 / 向下按钮、更多操作和关闭。当前区域上沿用强调线标记。
- 全局按钮按当前区域 ID 操作；局部按钮和右键菜单传入所属区域 ID。点击正文不必先输入文字即可激活。
- 程序拆分后新区域获得键盘焦点；Join 后保留的源区域获得焦点。不能只改变强调线却把键盘留在旧区域。手动激活标题 / 搜索时不抢焦点到正文。
- 书稿列表打开文档时，使用最近活动的正文区；多个正文区可显示同一份文稿或不同文稿。
- Join 表示源区域向所选方向扩展，保留其类型与内容，关闭相邻目标视图。左侧书稿执行 Join Right 会保留书稿；右侧正文执行 Join Left 会保留正文。
- 分隔条右键根据鼠标位置选择相邻两个区域，第一层提供相应 Join 方向。四格上半段与下半段分别操作所在行。
- 只允许完整共边且结果可由布局树表达的矩形区域合并，不删除整个嵌套子树代替 Join。
- 拖动调整分隔条；方向键调整；双击均分。空间不足时禁用对应拆分方向。
- 关闭和合并不删除文稿。布局撤销与正文撤销独立；恢复默认布局为书稿加当前正文。专注模式保留全部区域状态。
- 原生 macOS 最小窗口为 760×520pt。历史 HTML 手机原型保留作参考，手机原生客户端尚未实施。

## 排版、输入和动画

- 正文字号默认 18px，约 1.9 倍行高；正文行宽默认 680px。窄窗口随有效宽度收缩。
- 中文正文支持多行与输入法组合输入。主题切换与面板切换保留当前编辑内容。
- 控件提供可读标签或 accessibility label；键盘焦点可见。窄窗口的主要图标按钮采用至少 44px 点击目标。
- 主题与面板过渡约 180ms。遵循 Reduce Motion，关闭非必要过渡。
- 预览仅显示当前真实计算的字数、章节数和编辑状态，不展示虚构同步成功。

## 预览边界

`preview/index.html` 是离线设计原型，不是 WebView 产品实现。主题、尺寸、章节、笔记、字数、分栏和排版控件可操作，输入及布局只保留在当前页面内存。没有数据库、账号、同步或 AI 请求。

预览代码按职责分为 `workspace-layout.js`（布局树）、`preview-documents.js`（文档内存模型）和 `preview-app.js`（控件与视图协调）。`tests/workspace-layout.test.cjs` 只验证设计原型的布局模型。

预览使用空白新文档，不填入用户小说或自动生成小说内容。预览截图保持候选状态，人工确认后再用于原生 UI 实施。

## 原生应用参考检查

2026-11-16 实际打开本机应用，只查看控件：

- VS Code：实际创建两个空白编辑组，确认拆分控件属于各自编辑组。Novel Engine 保留全局四向按钮，并在每组直接提供向右、向下拆分。
- Blender 5.2.3 LTS：Area Edge Options 第一层包含 Vertical Split、Horizontal Split、Join Right、Join Left、Swap Areas。当前借用紧凑单行 Join 菜单形式；未执行 Blender 的区域合并。
- Blender 源码进一步核对：Join 保留 source 区域并移除 target 区域；本项目不复刻 Blender 的完整区域引擎与部分边合并。
- 参考截图位于 `~/Documents/Codex/NovelEngine-架构与界面-2026-11-16/` 和 `~/Documents/Codex/NovelEngine-分栏与合并修正-2026-11-16/`。

## 参考

- [OpenFic 公开工作区截图](https://raw.githubusercontent.com/syrizelink/OpenFic/main/demo.png)
- [OpenFic Writing Sidebar](https://github.com/syrizelink/OpenFic/blob/main/frontend/src/features/writing/components/writing-sidebar.tsx)
- [VS Code 编辑组](https://code.visualstudio.com/docs/editing/getting-started/userinterface)
- [Blender 区域拆分与合并源码](https://github.com/blender/blender/blob/main/source/blender/editors/screen/screen_ops.cc)
- DFW skill：`~/.agents/skills/diamond-fountain-works-design/SKILL.md`

## 原生实现对应

- `NovelPalette`：双主题 Token；`NovelWordmark`：CoreText 注册的 Afterglow Solid 1.001 与同字体中的 DFW 星形。
- `NativeWorkspace`：统一区域根视图；`WorkspacePaneView`：通用区域；`EditorPaneView`：标题、正文与真实计数。
- `MacTextEditor`：NSTextView，系统原生选择、输入法和每编辑视图独立撤销栈；正文不添加装饰性背景。
- 四向按钮直接位于 macOS Toolbar；编辑组提供直接向右、向下按钮。`AreaDividerView` 负责原生右键坐标、菜单、拖动和键盘调整；可用相邻区域由 `NovelWorkspace` 计算。
- 系统设置窗口提供外观和正文排版；窗口内信息面板可关闭，设置不成为重复主导航。
- 原生截图单独留作 Candidate，不能沿用 HTML 截图当原生验收。
