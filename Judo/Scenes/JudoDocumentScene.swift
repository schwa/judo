import JudoSupport
import Subprocess
import SwiftUI
import System
import UniformTypeIdentifiers

struct JudoDocumentScene: Scene {
    @FocusedValue(Repository.self)
    private var repository: Repository?

    var body: some Scene {
        DocumentGroup(viewing: JudoDocument.self) { configuration in
            let path = FilePath(configuration.fileURL!.path)
            JudoDocumentView(path: path)
                .onOpenURL { url in
                    print("Opened URL: \(url)")
                }
                .onChange(of: repository?.path) {
                    print("REPO CHANGED: \(repository?.path)")
                }
                .onAppear {
                    print("JudoDocumentScene appeared")
                }
                .focusable()
        }
        .commands {
            CommandMenu("Repository") {
                Button("Reveal", systemImage: "stop.fill") {
                    print(repository)
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
            }
        }
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
    @SwiftUI.Environment(AppModel.self)
    private var appModel

    var path: FilePath

    @State
    private var repository: Repository?

    @State
    private var pathContainsGitRepository: Bool = false

    @State
    private var pathContainsJujutsuRepository: Bool = false

    var body: some View {
        Group {
            if !pathContainsGitRepository {
                ContentUnavailableView {
                    Text("Label")
                }
                description: {
                    Text("Description")
                }
                actions: {
                    Button("Create Repository") {
                        Task {
                            do {
                                try await RepositoryView.createGitRepository(at: path)
                                try await RepositoryView.createJujutsuRepository(at: path)
                            } catch {
                                logger?.error("Error: \(error)")
                            }
                        }
                    }
                }
            } else if !pathContainsJujutsuRepository {
                ContentUnavailableView {
                    Text("Label")
                }
                description: {
                    Text("Description")
                }
                actions: {
                    Button("Create Repository") {
                        Task {
                            do {
                                try await RepositoryView.createGitRepository(at: path)
                                try await RepositoryView.createJujutsuRepository(at: path)
                            } catch {
                                logger?.error("Error: \(error)")
                            }
                        }
                    }
                }
            } else {
                RepositoryView()
                    .environment(repository)
                    .onChange(of: path, initial: true) {
                        appModel.recentRepositories.append(path)
                    }
            }
        }
        .onChange(of: path, initial: true) {
            pathContainsGitRepository = RepositoryView.gitRepositoryExists(at: path)
            pathContainsJujutsuRepository = RepositoryView.jujutsuRepositoryExists(at: path)

            if pathContainsGitRepository && pathContainsJujutsuRepository {
                repository = Repository(appModel: appModel, path: path)
            }
        }
    }
}

extension RepositoryView {
    static func gitRepositoryExists(at path: FilePath) -> Bool {
        path.isDirectory && (path + ".git").isDirectory
    }

    static func jujutsuRepositoryExists(at path: FilePath) -> Bool {
        gitRepositoryExists(at: path) && path.isDirectory && (path + ".jj").isDirectory
    }

    static func createGitRepository(at path: FilePath) async throws {
        _ = try await run(.name("git"), useShell: true, arguments: ["init"], workingDirectory: path)
    }

    static func createJujutsuRepository(at path: FilePath) async throws {
        // TODO: #20 Use appModel.jujutsu here.
        _ = try await run(.name("jj"), useShell: true, arguments: ["git", "init", "colocate"], workingDirectory: path)
    }
}

extension FilePath {
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: string, isDirectory: &isDir)
        return exists && isDir.boolValue
    }
}
