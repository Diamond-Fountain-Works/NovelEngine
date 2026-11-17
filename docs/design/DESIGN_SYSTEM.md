# Novel Engine Design System

目标版本：0.0.1。状态：候选设计，等待用户审图。

## 工作区

- 原生工作区由系统标题栏、固定资料导航、主编辑区及辅助编辑区组成；双主题统一使用 DFW 品牌语言。
- 0.0.1 不显示 AI 对话栏、模型选择、Token 消耗或 API Key 设置。
- 正文是主要空间。文档信息通过原生 Sheet 打开，专注模式隐藏导航与另一个编辑区。
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

- 左侧资料导航固定，不参与拆分、合并或区域类型切换。
- 窗口右上角直接排列左、右、上、下四个按钮，是唯一可见的分栏按钮组，不收进二级菜单。
- 首次点击创建辅助编辑区；之后方向按钮只改变同一个辅助区的位置，不继续生成嵌套区域。不在产品界面增加数量限制说明。
- 编辑区标题行仅放文档选择器，辅助区另有关闭按钮。主区没有关闭按钮；标题、正文和分隔条不再重复提供拆分或 Join。
- 每个编辑区独立选择章节、笔记、人物、事件、世界观或设定文档；选择不改变另一个编辑区，也不改变资料导航模块。
- 当前编辑区上沿用强调线标记。新辅助区获得正文焦点；移动现有辅助区保留文档与活动区。手动点击标题 / 搜索不能被正文焦点请求抢占。
- 关闭辅助区只改变视图，正文仍在作品里。布局撤销与文本撤销独立。恢复默认布局显示固定导航和主编辑区。
- 两区之间的分隔条支持拖动、方向键及双击均分；缩窗时限制有效比例，确保正文可操作。
- 摘要与统计由工具栏“文档信息”打开原生 Sheet；排版和专注通过编辑区标题右键访问。
- macOS 最小窗口为 760×520pt。横向分栏每区至少 240pt，纵向至少 180pt；不足时禁用该方向按钮。

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

- VS Code：此前实际检查编辑组；本轮按用户确认简化为固定导航和双区，方向按钮统一放在窗口顶部。旧截图只记录历史状态。
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
- `NativeWorkspace`：固定导航与双区根视图；`WorkspacePaneView`：通用区域；`EditorPaneView`：标题、正文与真实计数。
- `MacTextEditor`：NSTextView，系统原生选择、输入法和每编辑视图独立撤销栈；正文不添加装饰性背景。
- 四向按钮只位于 macOS Toolbar；编辑区标题只负责文档选择和辅助区关闭。`AreaDividerView` 负责拖动、双击和键盘调整。
- 系统设置窗口提供外观和正文排版；文档信息 Sheet 可关闭，设置不成为重复主导航。
- 原生截图单独留作 Candidate，不能沿用 HTML 截图当原生验收。

## 资料模块

- 固定导航使用左侧纵向模块栏：书稿、人物、事件、世界观、设定。图标配短标签，共用现有 DFW 双主题 Token。
- 书稿内部保留章节 / 笔记切换；其他模块使用可展开的同类型文档层级。普通列表行只有图标、标题和一行状态。
- 模块栏在短窗口中可滚动，目录不强迫窗口横向溢出。标题可截短，完整标题通过系统帮助可读。
- 资料正文继续使用同一编辑器。标题下只保留状态与“属性与关联”；字段及关系选择进入原生 Sheet，正文不接收属性输入。
- 资料属性只使用功能文案：标识、标签、故事时间、参与人物、前置事件、关联资料、上级文档、引用此文档、完成。状态为待定 / 已定案。
- 空状态为“暂无人物”等实际状态，新建只通过有效加号。模板只有可编辑栏目，无虚构人物和剧情。
- 事件编号、日期及标签不自动排序或改写正文；所有资料复用同一文档选择器、四向位置按钮和布局撤销。
