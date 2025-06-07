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
                         "--template", Change.template.name,
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
        var changes = try decoder.decode([Change].self, from: jsonData)

        let head = head

        changes = changes.map {
            var change = $0
            change.isHead = head == change.changeID
            return change
        }


//        let end = CFAbsoluteTimeGetCurrent()
//            print("... fetched \(commits.count) (\(data.count) bytes) commits in \(end - start) seconds")
        let orderedChanges = OrderedDictionary(uniqueKeys: changes.map(\.id), values: changes)

        self.currentLog = RepositoryLog(revset: revset, changes: orderedChanges)
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

            return ChangeID(rawValue: string, shortest: nil)
        } catch {
            print(error)
            return nil
        }
    }
}
