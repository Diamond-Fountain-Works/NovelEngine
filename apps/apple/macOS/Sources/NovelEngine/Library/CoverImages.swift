import Foundation
import ImageIO
import UniformTypeIdentifiers

enum CoverImageError: LocalizedError {
    case unsupported
    var errorDescription: String? { "无法读取这张封面，请选择有效的图片文件。" }
}

enum CoverImages {
    static func fileExtension(at url: URL) throws -> String {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0, let identifier = CGImageSourceGetType(source),
              let type = UTType(identifier as String), type.conforms(to: .image), let ext = type.preferredFilenameExtension else { throw CoverImageError.unsupported }
        return ext
    }
    static func thumbnail(at url: URL) throws -> Data {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 640, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw CoverImageError.unsupported }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { throw CoverImageError.unsupported }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CoverImageError.unsupported }
        return data as Data
    }
}
