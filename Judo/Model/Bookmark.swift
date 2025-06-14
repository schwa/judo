import UniformTypeIdentifiers
import CoreTransferable
import JudoSupport
import System

extension UTType {
    static let jujutsuBookmark = UTType(exportedAs: "io.schwa.judo.jj-bookmark")
}

struct Bookmark: Transferable, Codable {
    var repositoryPath: FilePath
    var source: ChangeID
    var bookmark: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .jujutsuBookmark)
    }
}
