import SwiftUI
import UniformTypeIdentifiers
import System
import JudoSupport

struct JudoDocumentScene: Scene {
    var body: some Scene {
        DocumentGroup(viewing: JudoDocument.self) { configuration in
            let path = FilePath(configuration.fileURL!.path)
            JudoDocumentView(path: path)
        }
    }
}

final class JudoDocument: ReferenceFileDocument {
    typealias Snapshot = ()

    static let readableContentTypes: [UTType] = [.directory]

    init(configuration: ReadConfiguration) throws {
    }
    
    func snapshot(contentType: UTType) throws -> () {
        throw JudoError.generic("Cannot save scene.")
    }
    
    func fileWrapper(snapshot: (), configuration: WriteConfiguration) throws -> FileWrapper {
        throw JudoError.generic("Cannot save scene.")
    }
}

struct JudoDocumentView: View {

    @Environment(AppModel.self)
    private var appModel

    var path: FilePath

    var body: some View {
        let repository = Repository(appModel: appModel, path: path)
        RepositoryView()
            .environment(repository)
            .onChange(of: path, initial: true) {
                appModel.recentRepositories.append(path)
            }
    }
}

