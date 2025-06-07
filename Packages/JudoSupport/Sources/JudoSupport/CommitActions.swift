import Foundation
import Collections
import Everything

public extension Repository {

    var jujutsu: Jujutsu {
        appModel.jujutsu
    }

    func new(changes: [Change] = []) async throws {
        let data = try await jujutsu.run(subcommand: "new", arguments: [], repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func undo() async throws {
        let data = try await jujutsu.run(subcommand: "undo", arguments: [], repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func abandon(changes: Collections.OrderedSet<ChangeID>) async throws {
        let arguments = changes.map(\.description)
        let data = try await jujutsu.run(subcommand: "abandon", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func squash(changes: Collections.OrderedSet<ChangeID>, destination: ChangeID, description: String) async throws {
        let arguments = ["--from", changes.map(\.description).joined(separator: " | "), "--into", destination.description] + ["--message", description]
        print(arguments)
        let data = try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func describe(changes: Collections.OrderedSet<ChangeID>, description: String) async throws {
        let arguments = ["--message", description] + changes.map(\.description)
        let data = try await jujutsu.run(subcommand: "describe", arguments: arguments, repository: self)
        print(String(data: data, encoding: .utf8) ?? "No output")
    }

    func rebase(from: [ChangeID], to: ChangeID) async throws {
        let arguments = ["--revisions"] + from.map(\.description)
         + ["--insert-after", to.description]
        print(arguments)
        let data = try await jujutsu.run(subcommand: "rebase", arguments: arguments, repository: self)
        print(">", String(data: data, encoding: .utf8) ?? "No output")
    }
}
