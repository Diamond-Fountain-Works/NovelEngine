# Novel Engine Project Formats 1 and 2

状态：已实现。作品格式版本与 App 版本独立。

```text
作品.novelengine/
  project.json
  documents/
    <lowercase-document-uuid>.txt
```

## 兼容规则

- 读取格式 1、2；未知版本拒绝读取。
- 纯章节 / 笔记作品继续写格式 1，保留旧客户端读取能力。
- 包含资料文档的作品写格式 2。旧客户端明确拒绝格式 2，不会只读取章节后丢弃资料。
- 添加资料不会重新生成作品或文档 UUID，不改写已有正文；读取本身不写回磁盘。

## 通用字段

| `project.json` 字段 | 合同 |
| --- | --- |
| schemaVersion | 整数 1 或 2 |
| projectId | 稳定 UUID |
| title | 作者原始字符串 |
| createdAt / updatedAt | ISO 8601 UTC，秒精度 |
| documents | 有序、非空数组，ID 不重复；顺序为作者的显示顺序 |
| documents[].id | 稳定 UUID |
| documents[].kind | 格式 1：`chapter`、`note`；格式 2 另支持 `character`、`event`、`world`、`setting` |
| documents[].title / synopsis | 作者原始字符串 |
| documents[].createdAt / updatedAt | ISO 8601 UTC，秒精度 |

## 格式 2 的资料字段

| 字段 | 合同 |
| --- | --- |
| parentID | 可选 UUID；同作品、同资料类型的上级文档；不能自引用或成环 |
| reference | 资料文档必填，章节 / 笔记不得携带 |
| reference.status | `undecided` 或 `confirmed`，由作者设置 |
| reference.code | 可选显示标识字符串；不是网络身份，也不决定事件先后 |
| reference.tags | 字符串数组 |
| reference.timeAnchor | 故事时间字符串；仅事件使用，支持相对时间 |
| reference.relatedIDs | 去重后的同作品目标文档 UUID 数组，不能指向自身 |
| reference.participantIDs | 事件参与人物 UUID；目标必须为顶级 `character` 文档 |
| reference.prerequisiteIDs | 事件前置 UUID；目标必须为 `event`，全链无环 |

非事件的 timeAnchor 为空字符串，participantIDs / prerequisiteIDs 为空数组。通用关联允许互相引用，不能用它冒充事件的有序前置约束。目标缺失、重复 UUID、父子关系非法、事件关系类型错误均拒绝整个读写操作。

## 正文与文件安全

正文路径由 UUID 计算，不接受 manifest 指定的绝对路径。文本保留 UTF-8 字节、换行、空格、Tab 与组合字符，不做 NFC 标准化；资料的栏目标题也是可编辑文本，不从模板覆盖已有正文。显式编辑的字节变化不能被 Swift 字符串的规范等价比较吞掉。

缺文件、无效 UTF-8、重复 ID、损坏关系和未知版本必须失败。Mac 文件适配拒绝符号链接和不认识的根目录条目；`.DS_Store` 不属于作品内容。

JSON 对象键顺序不构成业务含义，文档数组顺序构成显示顺序。当前格式没有签名、同步、删除或修订日志。SwiftUI FileDocument 与 UserDefaults 不属于跨平台文件合同。

实现：ProjectPackageCodec、NovelProject.validate。自动化：ProjectTests、ReferenceLibraryTests、NativeDocumentTests。
