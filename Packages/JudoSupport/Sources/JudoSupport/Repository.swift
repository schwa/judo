import Collections
import Everything
import Foundation
import Observation
import TOMLKit

@Observable
public class Repository {
    public var appModel: AppModel
    public var path: FSPath
    public var binaryPath: FSPath {
        appModel.binaryPath
    }
    public var currentLog: RepositoryLog

    public var canUndo: Bool {
        return true
    }

    public init(appModel: AppModel, path: FSPath) {
        self.appModel = appModel
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

        let bookmarks: [CommitRef] = try await fetch(subcommand: "bookmark", arguments: ["list"])
        self.currentLog = RepositoryLog(
            revset: revset,
            changes: OrderedDictionary(uniqueKeys: changes.map(\.id), values: changes),
            bookmarks: OrderedDictionary(uniqueKeys: bookmarks.map(\.name), values: bookmarks)
        )
    }

    public var head: ChangeID? {
        do {
            let arguments = [
                "log", "--no-graph",
                "-r", "@",
                "--template", "change_id"
            ]
            let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: arguments, currentDirectoryURL: path.url)
            let data = try process.runSync()
            guard let string = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return nil
            }
            return ChangeID(rawValue: string, shortest: nil)
        } catch {
            print(error)
            return nil
        }
    }

    public func fetch<T>(subcommand: String, arguments: [String]) async throws -> [T] where T: Decodable & JutsuTemplateProviding {
        let arguments = arguments + [
            "--template", T.template.name,
            "--config-file", appModel.jujutsu.tempConfigPath.path
        ]
        let data = try await appModel.jujutsu.run(subcommand: subcommand, arguments: arguments, repository: self)
        let header = "[\n".data(using: .utf8)!
        let footer = "\n]".data(using: .utf8)!
        let jsonData = header + data + footer
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([T].self, from: jsonData)
        }
        catch {
            print("Error decoding \(T.self): \(error)")
            print("Data: \(String(data: jsonData, encoding: .utf8) ?? "<invalid data>")")
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
