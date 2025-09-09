import CoreTransferable
import System
import UniformTypeIdentifiers

public extension UTType {
    nonisolated static let jujutsuBookmark = UTType(exportedAs: "io.schwa.judo.jj-bookmark")
}

public struct Bookmark {
    public var repositoryPath: FilePath
    public var source: ChangeID
    public var bookmark: String
}

extension Bookmark: Sendable {
}

// TODO: This is needed because main actor isolation messes with synthesized Codable conformance & Transferable.
extension Bookmark: Codable {
    enum CodingKeys: String, CodingKey {
        case repositoryPath
        case source
        case bookmark
    }
    public nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.repositoryPath = try container.decode(FilePath.self, forKey: .repositoryPath)
        self.source = try container.decode(ChangeID.self, forKey: .source)
        self.bookmark = try container.decode(String.self, forKey: .bookmark)
    }
    public nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repositoryPath, forKey: .repositoryPath)
        try container.encode(source, forKey: .source)
        try container.encode(bookmark, forKey: .bookmark)
    }
}

 extension Bookmark: Transferable {
     public nonisolated static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .jujutsuBookmark)
        ProxyRepresentation { bookmark in
            bookmark.bookmark
        }
    }
}
