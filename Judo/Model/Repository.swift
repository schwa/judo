import Collections
import Everything
import Foundation
import Observation
import TOMLKit

@Observable
class Repository {
    var appModel: AppModel
    var path: FSPath
    var binaryPath: FSPath {
        appModel.binaryPath
    }

    var canUndo: Bool {
        return true
    }

    init(appModel: AppModel, path: FSPath) {
        self.appModel = appModel
        self.path = path
    }

    func log(revset: String) async throws -> RepositoryLog {
        let temporaryConfig = JujutsuConfig(templateAliases: [
            CommitRecord.template.key: CommitRecord.template.content,
            Signature.template.key: Signature.template.content,
            ChangeID.template.key: ChangeID.template.content,
            CommitID.template.key: CommitID.template.content
        ])
        // let tempDirectory = FileManager.default.temporaryDirectory
        let tempDirectory = URL(fileURLWithPath: "/tmp")
        let tempConfigPath = tempDirectory.appending(path: "judo.toml")
//        print(tempConfigPath)
        try TOMLEncoder().encode(temporaryConfig).write(toFile: tempConfigPath.path, atomically: true, encoding: .utf8)

        var arguments = ["log", "--no-graph",
                         "--template", CommitRecord.template.name,
                         "--config-file", tempConfigPath.path
                         //                "--limit", "1"
        ]
        if !revset.isEmpty {
            arguments.append(contentsOf: ["-r", revset])
        }

//        print("jj \(arguments.joined(separator: " "))")
        let start = CFAbsoluteTimeGetCurrent()
//            print("Fetching...")
        let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: arguments, currentDirectoryURL: path.url)
        let data = try await process.run()

        let header = "[\n".data(using: .utf8)!
        let footer = "\n]".data(using: .utf8)!
        let jsonData = header + data + footer
        //            let jsonString = String(data: jsonData, encoding: .utf8)!
        //            print(jsonString)

        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.dateDecodingStrategy = .iso8601
        let commits = try decoder.decode([CommitRecord].self, from: jsonData)

        let end = CFAbsoluteTimeGetCurrent()
//            print("... fetched \(commits.count) (\(data.count) bytes) commits in \(end - start) seconds")
        let orderedCommits = OrderedDictionary(uniqueKeys: commits.map(\.id), values: commits)

        return RepositoryLog(repository: self, revset: revset, commits: orderedCommits)
    }

    var head: ChangeID? {
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

struct ChangeID: Hashable, Decodable {
    let rawValue: String

    // TODO: This is ephemeral and can change as repositories are updated.
    let shortest: String?

    init(rawValue: String, shortest: String? = nil) {
        self.rawValue = rawValue
        self.shortest = shortest
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    init(from decoder: any Decoder) throws {
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

    static let template = Template(name: "JUDO_CHANGE_ID", parameters: ["p"], content: """
        "'[" ++ p.shortest() ++ "]" ++ p ++ "'"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

// TODO: merge with ChangeID
struct CommitID: Hashable, Decodable {
    let rawValue: String

    // TODO: This is ephemeral and can change as repositories are updated.
    let shortest: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    init(from decoder: any Decoder) throws {
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

    static let template = Template(name: "JUDO_COMMIT_ID", parameters: ["p"], content: """
        "'[" ++ p.shortest() ++ "]" ++ p ++ "'"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

struct JujutsuConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case templates
        case templateAliases = "template-aliases"
    }

    var templates: [String: String] = [:]
    var templateAliases: [String: String] = [:]
}

// https://jj-vcs.github.io/jj/latest/templates/

struct Template {
    var name: String
    var parameters: [String] = []
    var content: String

    var key: String {
        name + (parameters.isEmpty ? "" : "(\(parameters.joined(separator: ",")))")
    }
}

struct Signature: Decodable {
    var name: String
    var email: String?
    var timestamp: Date

    // TODO: This can outout just "@" if email is empty
    static let template = Template(name: "JUDO_SIGNATURE", parameters: ["p"], content: """
        "{"
        ++ "'name': " ++ p.name().escape_json()
        ++ ", " ++ "'email': '" ++ p.email().local() ++ "@" ++ p.email().domain() ++ "'"
        ++ ", 'timestamp': '" ++ p.timestamp().format("%Y-%m-%dT%H:%M:%S%z") ++ "'"
        ++ "}"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

struct CommitRecord: Identifiable, Decodable {
    var id: ChangeID { change_id }

    var change_id: ChangeID
    var commit_id: CommitID
    var author: Signature
    var description: String
    var root: Bool
    var empty: Bool
    var immutable: Bool
    var git_head: Bool
    var conflict: Bool
    var parents: [ChangeID]
    var bookmarks: [String]

    // TODO: Make sure everything is escaped properly (esp. parents and bookmarks
    static let template = Template(name: "judo_commit_record", content: """
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
