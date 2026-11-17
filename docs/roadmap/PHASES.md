# 实施阶段

| 阶段 | 范围 | 当前状态 |
| --- | --- | --- |
| 设计 | DFW 双主题、分栏与 Join 的交互原型 | 可操作预览，截图待人工批准 |
| Native 1 | 核心模块、文件包、原生 macOS 编辑、章节 / 笔记与分栏 | Build 6 构建及 52 项 XCTest 通过；统一区域、焦点、Join 和文本撤销已实查，截图待人工复核 |
| Native 2 | 修订 / 恢复、导入导出与长文输入性能 | 待实施 |
| Apple Mobile | iPhone / Duo / iPad 原生 UI 和共享核心 | 待实施 |
| Sync | 账号 / 设备、持久 Outbox、冲突比较与安全同步 | 待设计与实施 |
| Other Native | Android 平板和 Windows 客户端 | 待实施 |

0.0.1 不接入 AI。后续阶段不在当前 UI 放置假入口。App、文件格式与未来同步协议分别管理版本。
