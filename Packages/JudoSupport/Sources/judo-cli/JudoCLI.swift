import ArgumentParser
import Foundation
import System
import JudoSupport
#if os(macOS)
import AppKit
#endif

@main
struct JudoCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "judo-cli",
        abstract: "A command-line interface for Judo",
        subcommands: [Open.self, Show.self, Log.self]
    )
}

struct Open: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open a repository in Judo"
    )
    
    @Argument(help: "Path to the repository", completion: .directory)
    var path: String = "."
    
    @Option(name: .shortAndLong, help: "View mode (timeline, change, mixed)")
    var mode: ViewMode?
    
    @Option(name: .shortAndLong, help: "Change ID to select")
    var selection: String?
    
    enum ViewMode: String, ExpressibleByArgument {
        case timeline
        case change
        case mixed
        case log
        case show
        
        var urlValue: String {
            switch self {
            case .timeline, .log:
                return "timeline"
            case .change, .show:
                return "change"
            case .mixed:
                return "mixed"
            }
        }
    }
    
    @MainActor
    mutating func run() async throws {
        let repoPath = try resolveRepositoryPath(path)
        var components = URLComponents()
        components.scheme = "x-judo"
        components.path = repoPath.string
        
        var queryItems: [URLQueryItem] = []
        
        if let mode = mode {
            queryItems.append(URLQueryItem(name: "mode", value: mode.urlValue))
        }
        
        if let selection = selection {
            queryItems.append(URLQueryItem(name: "selection", value: selection))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw ValidationError("Failed to construct URL")
        }
        
        try await openURL(url)
    }
}

struct Show: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show a specific change in Judo"
    )
    
    @Argument(help: "Change ID to show")
    var changeID: String
    
    @Option(name: .shortAndLong, help: "Path to the repository", completion: .directory)
    var path: String = "."
    
    @MainActor
    mutating func run() async throws {
        let repoPath = try resolveRepositoryPath(path)
        var components = URLComponents()
        components.scheme = "x-judo"
        components.path = repoPath.string
        components.queryItems = [
            URLQueryItem(name: "mode", value: "change"),
            URLQueryItem(name: "selection", value: changeID)
        ]
        
        guard let url = components.url else {
            throw ValidationError("Failed to construct URL")
        }
        
        try await openURL(url)
    }
}

struct Log: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open repository log in Judo"
    )
    
    @Option(name: .shortAndLong, help: "Path to the repository", completion: .directory)
    var path: String = "."
    
    @Option(name: .shortAndLong, help: "Revset to display")
    var revset: String?
    
    @Option(name: .shortAndLong, help: "Number of commits to show")
    var limit: Int?
    
    @MainActor
    mutating func run() async throws {
        let repoPath = try resolveRepositoryPath(path)
        var components = URLComponents()
        components.scheme = "x-judo"
        components.path = repoPath.string
        
        var queryItems = [URLQueryItem(name: "mode", value: "timeline")]
        
        if let revset = revset {
            queryItems.append(URLQueryItem(name: "revset", value: revset))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw ValidationError("Failed to construct URL")
        }
        
        try await openURL(url)
    }
}

@MainActor
private func resolveRepositoryPath(_ path: String) throws -> FilePath {
    let filePath = FilePath(path)
    let absolutePath: FilePath
    
    if filePath.isAbsolute {
        absolutePath = filePath
    } else {
        let currentDirectory = FilePath(FileManager.default.currentDirectoryPath)
        absolutePath = currentDirectory.appending(filePath.components)
    }
    
    let jjPath = absolutePath.appending(".jj")
    guard FileManager.default.fileExists(atPath: jjPath.string) else {
        throw ValidationError("Not a jj repository: \(absolutePath.string)")
    }
    
    return absolutePath
}

@MainActor
private func openURL(_ url: URL) async throws {
    #if os(macOS)
    let workspace = NSWorkspace.shared
    guard workspace.open(url) else {
        throw ValidationError("Failed to open URL: \(url)")
    }
    #else
    throw ValidationError("URL opening is only supported on macOS")
    #endif
}

extension JudoCLI {
    struct ValidationError: Error, CustomStringConvertible {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
}