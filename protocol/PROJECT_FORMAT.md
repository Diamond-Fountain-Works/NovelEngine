# Novel Engine Project Format 1

状态：已实现。此版本是作品格式版本，不是网络同步协议。

```text
作品.novelengine/
  project.json
  documents/
    <lowercase-document-uuid>.txt
```

`project.json` 字段：

| 字段 | 合同 |
| --- | --- |
| schemaVersion | 整数 1；其他版本拒绝读取 |
| projectId | UUID；打开、编辑和另存不重新生成 |
| title | 作者原始字符串 |
| createdAt / updatedAt | ISO 8601 UTC 字符串，秒精度 |
| documents | 有序、非空数组；顺序就是文档顺序 |
| documents[].id | 唯一 UUID |
| documents[].kind | `chapter` 或 `note` |
| documents[].title / synopsis | 原始字符串 |
| documents[].createdAt / updatedAt | ISO 8601 UTC 字符串，秒精度 |

正文从 document ID 计算路径，不接受远端或 manifest 提供的绝对路径。正文是 UTF-8，保留换行、空格、Tab、Unicode 原始编码，不做 NFC 标准化。缺文件、无效 UTF-8、重复 ID 和未知版本必须失败。Mac 文件适配拒绝符号链接和不认识的根目录条目；Finder 的 `.DS_Store` 不属于作品内容。

JSON 的对象键顺序不构成业务含义；documents 数组顺序构成业务含义。格式 1 没有签名和同步语义，也没有删除 / 修订记录。未来扩展需显式升级格式并增加兼容测试，不能静默改变字段含义。

实现：`ProjectPackageCodec`；测试：`ProjectTests`、`NativeDocumentTests`。SwiftUI FileDocument 及 UserDefaults 都不是跨平台合同。
