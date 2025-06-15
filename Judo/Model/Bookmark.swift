import CoreTransferable
import JudoSupport
import System
import UniformTypeIdentifiers

extension UTType {
    static let jujutsuBookmark = UTType(exportedAs: "io.schwa.judo.jj-bookmark")
}

struct Bookmark: Transferable, Codable {
    var repositoryPath: FilePath
    var source: ChangeID
    var bookmark: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .jujutsuBookmark)
        ProxyRepresentation { bookmark in
            bookmark.bookmark
        }
    }
}
