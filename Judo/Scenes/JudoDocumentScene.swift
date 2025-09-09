import AppKit
import JudoSupport
import Subprocess
import SwiftUI
import System
import UniformTypeIdentifiers

struct JudoDocumentScene: Scene {
    @FocusedValue(\.repositoryViewModel)
    private var repositoryViewModel: RepositoryViewModel?

    var body: some Scene {
        DocumentGroup(viewing: JudoDocument.self) { configuration in
            let path = FilePath(configuration.fileURL!.path)
            JudoDocumentView(path: path)
        }
        .commands {
            
            CommandGroup(after: .toolbar) {
                Divider()
                
                Menu("Repository Mode") {
                    Button("Timeline") {
                        repositoryViewModel?.mode = .timeline
                    }
                    .keyboardShortcut("1", modifiers: [.command])
                    .disabled(repositoryViewModel == nil)
                    
                    Button("Mixed") {
                        repositoryViewModel?.mode = .mixed
                    }
                    .keyboardShortcut("2", modifiers: [.command])
                    .disabled(repositoryViewModel == nil)
                    
                    Button("Change") {
                        repositoryViewModel?.mode = .change
                    }
                    .keyboardShortcut("3", modifiers: [.command])
                    .disabled(repositoryViewModel == nil)
                }
            }

            CommandMenu("Repository") {
                Button("Reveal in Finder") {
                    guard let repositoryViewModel else {
                        logger?.error("No repository focused")
                        return
                    }
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repositoryViewModel.repository.path.string)
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
                .disabled(repositoryViewModel == nil)
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
    private var repositoryViewModel: RepositoryViewModel?

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
                    .environment(repositoryViewModel)
                    .onChange(of: path, initial: true) {
                        appModel.recentRepositories.append(path)
                    }
            }
        }
        .onChange(of: path, initial: true) {
            pathContainsGitRepository = RepositoryView.gitRepositoryExists(at: path)
            pathContainsJujutsuRepository = RepositoryView.jujutsuRepositoryExists(at: path)

            if pathContainsGitRepository && pathContainsJujutsuRepository {
                repositoryViewModel = RepositoryViewModel(jujutsu: appModel.jujutsu, path: path)
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
