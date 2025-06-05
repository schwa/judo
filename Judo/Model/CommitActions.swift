import Foundation
import Collections
import Everything

extension Repository {
    func undo() async throws {
        let jujutsu = Jujutsu(binaryPath: binaryPath)
        let data = try await jujutsu.run(subcommand: "undo", arguments: [], repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func abandon(commits: Collections.OrderedSet<ChangeID>) async throws {
        let jujutsu = Jujutsu(binaryPath: binaryPath)
        let arguments = commits.map(\.rawValue)
        let data = try await jujutsu.run(subcommand: "abandon", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func squash(commits: Collections.OrderedSet<ChangeID>, destination: ChangeID, description: String) async throws {
        let jujutsu = Jujutsu(binaryPath: binaryPath)
        let arguments = ["--from"] + commits.map(\.rawValue) + ["--into", destination.rawValue] + ["--message", description]
        let data = try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func describe(commits: Collections.OrderedSet<ChangeID>, description: String) async throws {
        let jujutsu = Jujutsu(binaryPath: binaryPath)
        let arguments = ["--message", description] + commits.map(\.rawValue)
        let data = try await jujutsu.run(subcommand: "describe", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func commitRecord(for: ChangeID) async throws -> CommitRecord {
        fatalError()
    }
}

