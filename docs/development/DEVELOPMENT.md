# 开发

## 工具链与入口

本机：Apple Silicon，Xcode 27.2，Swift 6.4.2。App 使用 SwiftPM，不依赖第三方包。最低编译目标 macOS 13；旧系统运行尚待对应机器验证。

```sh
make build       # 原生开发 App：build/Novel Engine.app
make run         # 构建并打开
make test        # 核心、AppKit 适配与原生文档测试
make check       # 文档链接、依赖边界和配置检查
make qa          # 构建、测试、静态检查
```

可在 Xcode 打开 `apps/apple/macOS/Package.swift`，选择 NovelEngine 产品。Codex Run 调用同一 `script/build_and_run.sh`。脚本支持 `--build`、`--build-qa`、`--debug`、`--logs`、`--telemetry`、`--verify`；不会强制终止可能含未保存正文的进程。

## 状态与文件位置

- App 状态与作品：WindowGroup / 托管作品库；默认存放于系统文稿目录，自动保存。
- 本机 UI 偏好：开发 Bundle 的 UserDefaults，只含主题、字体、布局与文档 ID。
- 构建、模块缓存：`build/`，不提交；不会安装到 Applications。
- 临时测试作品、截图、日志：开发者的 `~/Documents/Codex/` 可见任务目录，不提交仓库。
- 自动化磁盘测试只创建 UUID 命名的合成作品并在结束时删除，不读取私人小说。

## 新增代码

先确定模块责任。领域不得 import SwiftUI / AppKit / UIKit；平台适配不进入文件格式。中文输入要保留 marked text；不要在 View 刷新时重复赋值给正在组合输入的 NSTextView。

新增可见控件必须实际可用。新增文案只包含操作、状态与必要说明。设计截图保持 Candidate，人工确认前不称为批准基线。构建、单元测试、UI 实测分别记录。

## Git 边界

项目使用根目录自己的 `.git`。写操作前检查 `git rev-parse --show-toplevel` 必须为 NovelEngine 项目。公开上传前执行 `make check`；作品、日志、密钥和构建产物不进入仓库。任务完成后删除一次性测试缓存，保留必要日志及截图证据。

## 作品库与隔离 QA

正式开发 App 默认使用系统文稿目录下的 `Novel Engine`，新建后自动保存；不要通过测试写入该目录。

原生 UI QA：

```sh
./script/build_and_run.sh --build-qa "$HOME/Documents/Codex/NovelEngine-QA/Library"
```

产物为 `build/Novel Engine QA.app`，Bundle ID 为 `com.diamondfountain.novelengine.dev.qa`。路径只写入生成的 QA Info.plist，不进入正式配置。QA 缺少隔离路径时停止，不回退到正式库。所有 QA 数据必须是合成数据。测试结束后退出 QA App、记录结果并删除 QA 包和一次性数据，保留最新正式开发 App 与必要证据。

单元测试可用 `NOVELENGINE_TEST_ROOT` 指定可见测试目录；每项测试只创建并移除自己生成的 UUID 子目录。构建缓存位于 build，验收完成后清理重复测试缓存。
