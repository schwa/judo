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

    public func log(revset: String) async throws {

        var arguments = ["--no-graph",
                         "--template", CommitRecord.template.name,
                         "--config-file", appModel.jujutsu.tempConfigPath.path
                         //                "--limit", "1"
        ]
        if !revset.isEmpty {
            arguments.append(contentsOf: ["-r", revset])
        }

//        print("jj \(arguments.joined(separator: " "))")
//        let start = CFAbsoluteTimeGetCurrent()
//            print("Fetching...")

        let data = try await appModel.jujutsu.run(subcommand: "log", arguments: arguments, repository: self)

        let header = "[\n".data(using: .utf8)!
        let footer = "\n]".data(using: .utf8)!
        let jsonData = header + data + footer
        //            let jsonString = String(data: jsonData, encoding: .utf8)!
        //            print(jsonString)

        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.dateDecodingStrategy = .iso8601
        let commits = try decoder.decode([CommitRecord].self, from: jsonData)

//        let end = CFAbsoluteTimeGetCurrent()
//            print("... fetched \(commits.count) (\(data.count) bytes) commits in \(end - start) seconds")
        let orderedCommits = OrderedDictionary(uniqueKeys: commits.map(\.id), values: commits)

        self.currentLog = RepositoryLog(revset: revset, commits: orderedCommits)
    }

    public var head: ChangeID? {
        do {
            let arguments = ["log", "--no-graph",
                             "-r", "@",
                             "--template", "change_id"
            ]

//            print("Fetching...")
            let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: arguments, currentDirectoryURL: path.url)
            let data = try process.runSync()
            guard let string = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return nil
            }

            return ChangeID(rawValue: string)
        } catch {
            print(error)
            return nil
        }
    }
}

public struct ChangeID: Hashable, Decodable {
    public let rawValue: String

    // TODO: This is ephemeral and can change as repositories are updated.
    public let shortest: String?

    public init(rawValue: String, shortest: String? = nil) {
        self.rawValue = rawValue
        self.shortest = shortest
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        let regex = #/^(\[(?<shortest>[a-z0-9]+)\])?(?<remaining>[a-z0-9]+)$/#
        guard let match = try regex.firstMatch(in: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ChangeID format")
        }

        let shortest = match.output.shortest
        let remaining = match.output.remaining

        self.shortest = shortest.map(String.init)
        self.rawValue = String(remaining)
    }

    public static let template = Template(name: "JUDO_CHANGE_ID", parameters: ["p"], content: """
        "'[" ++ p.shortest() ++ "]" ++ p ++ "'"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

// TODO: merge with ChangeID
public struct CommitID: Hashable, Decodable {
    public let rawValue: String

    // TODO: This is ephemeral and can change as repositories are updated.
    public let shortest: String

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        let regex = #/^\[(?<shortest>[a-z0-9]+)\]?(?<remaining>[a-z0-9]+)$/#
        guard let match = try regex.firstMatch(in: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ChangeID format")
        }

        let shortest = match.output.shortest
        let remaining = match.output.remaining

        self.shortest = String(shortest)
        self.rawValue = String(remaining)
    }

    public static let template = Template(name: "JUDO_COMMIT_ID", parameters: ["p"], content: """
        "'[" ++ p.shortest() ++ "]" ++ p ++ "'"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

public struct JujutsuConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case templates
        case templateAliases = "template-aliases"
    }

    public var templates: [String: String] = [:]
    public var templateAliases: [String: String] = [:]
}

// https://jj-vcs.github.io/jj/latest/templates/

public struct Template: Sendable {
    public var name: String
    public var parameters: [String] = []
    public var content: String

    public var key: String {
        name + (parameters.isEmpty ? "" : "(\(parameters.joined(separator: ",")))")
    }
}

public struct Signature: Decodable, Equatable {
    public var name: String
    public var email: String?
    public var timestamp: Date

    // TODO: This can outout just "@" if email is empty
    public static let template = Template(name: "JUDO_SIGNATURE", parameters: ["p"], content: """
        "{"
        ++ "'name': " ++ p.name().escape_json()
        ++ ", " ++ "'email': '" ++ p.email().local() ++ "@" ++ p.email().domain() ++ "'"
        ++ ", 'timestamp': '" ++ p.timestamp().format("%Y-%m-%dT%H:%M:%S%z") ++ "'"
        ++ "}"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

public struct CommitRecord: Identifiable, Decodable, Equatable {
    public var id: ChangeID { change_id }
    public var change_id: ChangeID
    public var commit_id: CommitID
    public var author: Signature
    public var description: String
    public var root: Bool
    public var empty: Bool
    public var immutable: Bool
    public var git_head: Bool
    public var conflict: Bool
    public var parents: [ChangeID]
    public var bookmarks: [String]

    // TODO: Make sure everything is escaped properly (esp. parents and bookmarks
    public static let template = Template(name: "judo_commit_record", content: """
        "{\\n"
        ++ "\t'change_id': " ++ JUDO_CHANGE_ID(change_id) ++ ",\\n"
        ++ "\t'commit_id': " ++ JUDO_COMMIT_ID(commit_id) ++ ",\\n"
        ++ "\t'author': " ++ JUDO_SIGNATURE(author) ++ ",\\n"
        ++ "\t'description': " ++ description.escape_json() ++ ",\\n"
        ++ "\t'root': " ++ root ++ ",\\n"
        ++ "\t'empty': " ++ empty ++ ",\\n"
        ++ "\t'git_head': " ++ git_head ++ ",\\n"
        ++ "\t'conflict': " ++ conflict ++ ",\\n"
        ++ "\t'immutable': " ++ immutable ++ ",\\n"
        ++ "\t'parents': [" ++ parents.map(|c| "'" ++ c.change_id() ++ "'").join(",") ++ "],\\n"
        ++ "\t'bookmarks': [" ++ bookmarks.map(|c| "'" ++ c ++ "'").join(",") ++ "],\\n"
        ++ "},\\n"
        """
                                    .replacingOccurrences(of: "'", with: "\\\"")
    )
}
