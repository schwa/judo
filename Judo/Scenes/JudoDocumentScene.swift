import JudoSupport
import SwiftUI
import System
import UniformTypeIdentifiers

struct JudoDocumentScene: Scene {
    @FocusedValue(Repository.self)
    private var repository

    var body: some Scene {
        DocumentGroup(viewing: JudoDocument.self) { configuration in
            let path = FilePath(configuration.fileURL!.path)
            JudoDocumentView(path: path)
        }
//        .commands {
//            CommandMenu("Changes") {
//                Button("Blah", systemImage: "stop.fill") {
//                    print(repository)
//                }
//                .keyboardShortcut("B", modifiers: [])
//            }
//        }
    }
}

// MARK: -

final class JudoDocument: ReferenceFileDocument {
    typealias Snapshot = ()

    static let readableContentTypes: [UTType] = [.directory]

    init(configuration _: ReadConfiguration) throws {
    }

    func snapshot(contentType _: UTType) throws {
        throw JudoError.generic("Cannot save scene.")
    }

    func fileWrapper(snapshot _: (), configuration _: WriteConfiguration) throws -> FileWrapper {
        throw JudoError.generic("Cannot save scene.")
    }
}

// MARK: -

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
