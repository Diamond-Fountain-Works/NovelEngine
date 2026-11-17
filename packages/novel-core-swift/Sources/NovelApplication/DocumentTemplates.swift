import NovelDomain

public enum DocumentTemplates {
    public static func body(for kind: WritingKind) -> String {
        let headings: [String]
        switch kind {
        case .chapter, .note: return ""
        case .character: headings = ["身份", "外貌与辨识特征", "性格与信念", "能力与限制", "人物关系", "知识与盲区", "声音与对白", "待补充"]
        case .event: headings = ["事件边界", "前置条件", "参与者与目标", "行动顺序", "各方认知", "结果", "后续事件", "待补充"]
        case .world: headings = ["基本情况", "组织与制度", "长期关系", "历史背景", "待补充"]
        case .setting: headings = ["用途", "规则与限制", "使用条件", "关联资料", "待补充"]
        }
        return headings.map { "## \($0)\n\n" }.joined()
    }
}
