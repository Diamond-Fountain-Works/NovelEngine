import Foundation

public struct TextStatistics: Equatable, Sendable {
    public let characters: Int
    public let paragraphs: Int
    public init(characters: Int, paragraphs: Int) { self.characters = characters; self.paragraphs = paragraphs }
    public init(_ text: String) {
        characters = text.filter { !$0.isWhitespace }.count
        paragraphs = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
}
