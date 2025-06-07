import Foundation
import Collections
import Everything

public extension Repository {

    var jujutsu: Jujutsu {
        appModel.jujutsu
    }

    func new(selectedCommit: CommitRecord? = nil) async throws {
        let data = try await jujutsu.run(subcommand: "new", arguments: [], repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func undo() async throws {
        let data = try await jujutsu.run(subcommand: "undo", arguments: [], repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func abandon(commits: Collections.OrderedSet<ChangeID>) async throws {
        let arguments = commits.map(\.description)
        let data = try await jujutsu.run(subcommand: "abandon", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func squash(commits: Collections.OrderedSet<ChangeID>, destination: ChangeID, description: String) async throws {
        let arguments = ["--from", commits.map(\.description).joined(separator: " | "), "--into", destination.description] + ["--message", description]
        print(arguments)
        let data = try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func describe(commits: Collections.OrderedSet<ChangeID>, description: String) async throws {
        let arguments = ["--message", description] + commits.map(\.description)
        let data = try await jujutsu.run(subcommand: "describe", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func commitRecord(for: ChangeID) async throws -> CommitRecord {
        fatalError()
    }

    func rebase(from: [ChangeID], to: ChangeID) async throws {
        let arguments = ["--revisions"] + from.map(\.description)
         + ["--insert-after", to.description]
        print(arguments)
        let data = try await jujutsu.run(subcommand: "rebase", arguments: arguments, repository: self)
        print(">", String(data: data, encoding: .utf8) ?? "No output")
    }
}


//JJ: Enter a description for the combined commit.
//JJ: Description from the destination commit:
//Fake Commit B_2
//JJ: Description from source commit:
//Fake Commit B_3
//JJ: This commit contains the following changes:
//JJ: A file_2. txt
//JJ: A file_3. txt
//JJ:
//JJ: Lines starting with "JJ:" (like this one) will be removed.
