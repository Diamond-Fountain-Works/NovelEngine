# Novel Engine Project Formats 1, 2 and 3

状态：已实现。作品格式版本与 App 版本独立。

```text
作品.ne/
  project.json
  documents/
    <lowercase-document-uuid>.txt
  assets/                            # 存在封面时
    <lowercase-cover-uuid>.<extension>
```

## 兼容规则

- 读取格式 1、2、3；未知版本拒绝读取。
- 新导出使用 `.ne`，导入也接受旧 `.novelengine`，扩展名不决定内部格式版本。
- 纯章节 / 笔记作品继续写格式 1，保留旧客户端读取能力。
- 带有作品级资料或封面时写格式 3；仅包含资料文档而无作品级资料时写格式 2。旧客户端明确拒绝格式 2，不会只读取章节后丢弃资料。
- 添加资料不会重新生成作品或文档 UUID，不改写已有正文；读取本身不写回磁盘。

## 通用字段

| `project.json` 字段 | 合同 |
| --- | --- |
| schemaVersion | 整数 1、2 或 3 |
| projectId | 稳定 UUID |
| title | 作者原始字符串 |
| createdAt / updatedAt | ISO 8601 UTC，秒精度 |
| documents | 有序、非空数组，ID 不重复；顺序为作者的显示顺序 |
| documents[].id | 稳定 UUID |
| documents[].kind | 格式 1：`chapter`、`note`；格式 2、3 另支持 `character`、`event`、`world`、`setting` |
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

## 格式 3 的作品资料

`details` 在格式 3 必填，格式 1、2 不携带。旧作品读取为无作者、无封面、无简介的资料，不自动生成这些内容。

| 字段 | 合同 |
| --- | --- |
| author | 作者 / 笔名，原始字符串 |
| contributors | 有稳定 UUID 的署名与分工；每项包含 id、name、role，不是账号或协作权限 |
| genre / tags | 作者填写的类型与标签文本 |
| synopsis | 不设应用字数上限的作品简介，原始 UTF-8 字符串 |
| status | planning、writing、completed |
| cover | 可选封面清单；id、fileExtension、originalFilename、byteCount、sha256 |

封面路径由 UUID 和校验后的扩展名生成，不采用原始文件名拼接路径。原图字节保存于 assets；显示用缩略图不覆盖原图。导入 / 导出校验原文件 SHA-256 和长度，缺失或损坏时失败。作品级简介与各文档的 synopsis 相互独立。

## 正文与文件安全

正文路径由 UUID 计算，不接受 manifest 指定的绝对路径。文本保留 UTF-8 字节、换行、空格、Tab 与组合字符，不做 NFC 标准化；资料的栏目标题也是可编辑文本，不从模板覆盖已有正文。显式编辑的字节变化不能被 Swift 字符串的规范等价比较吞掉。

缺文件、无效 UTF-8、重复 ID、损坏关系和未知版本必须失败。当前导入 / 导出拒绝符号链接、未声明的正文与不认识的根目录条目；`.DS_Store` 不属于作品内容。

JSON 对象键顺序不构成业务含义，文档数组顺序构成显示顺序。当前格式没有签名、同步、删除或修订日志。SwiftUI FileDocument 与 UserDefaults 不属于跨平台文件合同。

实现：ProjectPackageCodec、NovelProject.validate。自动化：ProjectTests、ReferenceLibraryTests、NativeDocumentTests。

## 托管作品库

App 默认使用系统文稿目录中的 `Novel Engine/作品/<project-uuid>/`，不要求用户逐次选择保存位置。`head.json` 指向一份完整校验的 revisions 快照；当前与上一份快照保留。assets 为作品独立原图目录。发布前先写完整快照，再原子替换 head；残缺且尚未发布的快照不能替换当前作品。

本机 head、修订目录及锁文件不属于 `.ne` 导出合同。导出只包含以上标准作品布局；导入不改写来源文件。跨进程锁与修订摘要检测本地冲突，冲突时保留未保存的编辑供导出。它们不是跨设备同步协议。
