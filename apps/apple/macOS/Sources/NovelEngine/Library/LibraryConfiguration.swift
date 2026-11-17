import Foundation

enum LibraryConfigurationError: LocalizedError {
    case qaRootRequired, unexpectedQAOverride
    var errorDescription: String? {
        switch self {
        case .qaRootRequired: "QA 构建缺少隔离作品目录，已停止启动。"
        case .unexpectedQAOverride: "作品目录配置无效，已停止启动。"
        }
    }
}

enum LibraryConfiguration {
    static func resolve(bundleID: String, qaRoot: String?, documents: URL) throws -> URL {
        let normal = documents.appendingPathComponent("Novel Engine", isDirectory: true).standardizedFileURL
        if bundleID.hasSuffix(".qa") {
            guard let qaRoot, qaRoot.hasPrefix("/") else { throw LibraryConfigurationError.qaRootRequired }
            let root = URL(fileURLWithPath: qaRoot, isDirectory: true).standardizedFileURL.resolvingSymlinksInPath()
            let production = normal.resolvingSymlinksInPath().path
            guard root.path != production, !root.path.hasPrefix(production + "/"), !production.hasPrefix(root.path + "/"), root.path != "/" else { throw LibraryConfigurationError.qaRootRequired }
            return root
        }
        guard qaRoot == nil else { throw LibraryConfigurationError.unexpectedQAOverride }
        return normal
    }
}
