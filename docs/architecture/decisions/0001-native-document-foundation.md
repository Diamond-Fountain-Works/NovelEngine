# ADR 0001：原生文件型写作基础

状态：已实施。日期：2026-11-16。

## 决策

macOS 首个可编辑版本使用 SwiftUI DocumentGroup + FileDocument + NSTextView。作品为目录型 `.novelengine` 文件包；平台无关的 codec 放在 NovelStorage，系统文件协调留在 Mac App。

## 原因

当前需求是写作、章节 / 笔记和分栏。已有项目只有 HTML 原型，没有数据库和同步代码。系统文档 App 可直接提供新建、打开、保存、关闭时的未保存处理和多作品窗口；无需为首个编辑器增加数据库与网络服务。原文与元数据分开，也便于检查和未来跨平台读取。

## 约束与代价

- 没有承诺跨设备同步或数据库修订历史。
- 已保存作品可能由 Finder 或其他应用修改；读取异常必须报错，不能补空正文。
- 系统自动保存和崩溃恢复需要单独验证，不能由 codec 单元测试推断通过。
- 暂不提供不可恢复删除。未来修订、恢复及同步在独立 ADR 中确定。
- 先前 SQLite 是建议，没有实际数据库需要迁移。未来存储实现可以改变，但必须兼容格式 1 的作者内容。

Current entry and managed-saving ownership are documented in [the architecture](../ARCHITECTURE.md); this ADR retains the initial document-app decision.
