import Collections
import Everything
import Foundation
import Observation
import System
import TOMLKit

@Observable
@MainActor
public class Repository {
    public var jujutsu: Jujutsu
    public var path: FilePath
    public var currentLog: RepositoryLog

    public var canUndo: Bool {
        true
    }

    public init(jujutsu: Jujutsu, path: FilePath) {
        self.jujutsu = jujutsu
        self.path = path
        self.currentLog = RepositoryLog()
    }

    public func refresh() async throws {
        try await log(revset: self.currentLog.revset ?? "")
    }

    public func log(revset: String) async throws {
        var arguments = ["--no-graph"]
        if !revset.isEmpty {
            arguments.append(contentsOf: ["-r", revset])
        }
        let changes: [Change] = try await fetch(subcommand: "log", arguments: arguments)

        // TODO: #18
        //        let bookmarks: [CommitRef] = try await fetch(subcommand: "bookmark", arguments: ["list"])
        self.currentLog = RepositoryLog(
            revset: revset,
            changes: OrderedDictionary(uniqueKeys: changes.map(\.id), values: changes),
            bookmarks: [:] // OrderedDictionary(uniqueKeys: bookmarks.map(\.name), values: bookmarks)
        )
    }

    public func fetch<T>(subcommand: String, arguments: [String]) async throws -> [T] where T: Decodable & JutsuTemplateProviding {
        let arguments = arguments + [
            "--template", T.template.name,
            "--config-file", jujutsu.tempConfigPath.path
        ]
        let data = try await jujutsu.run(subcommand: subcommand, arguments: arguments, repository: self)
        let header = "[\n".data(using: .utf8)!
        let footer = "\n]".data(using: .utf8)!
        let jsonData = header + data + footer
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([T].self, from: jsonData)
        } catch {
            logger?.error("Error decoding \(T.self): \(error)")
            logger?.error("Data: \(String(data: jsonData, encoding: .utf8) ?? "<invalid data>")")
            throw error
        }
    }
}

public protocol JutsuTemplateProviding {
    static var template: Template { get }
}

extension CommitRef: JutsuTemplateProviding {
}

extension Change: JutsuTemplateProviding {
}
