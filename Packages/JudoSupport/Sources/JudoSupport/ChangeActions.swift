import Collections
import Everything
import Foundation

public extension Repository {
    func new(changes: [ChangeID] = []) async throws {
        try await jujutsu.run(subcommand: "new", arguments: changes.map(\.description), repository: self)
    }

    func undo() async throws {
        try await jujutsu.run(subcommand: "undo", arguments: [], repository: self)
    }

    func abandon(changes: [ChangeID]) async throws {
        let arguments = changes.map(\.description)
        try await jujutsu.run(subcommand: "abandon", arguments: arguments, repository: self)
    }

    func squash(changes: [ChangeID]) async throws {
        let arguments = ["-r", changes.map(\.description).joined(separator: " | ")]
        try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
    }

    func squash(changes: [ChangeID], destination: ChangeID, description: String) async throws {
        let arguments = ["--from", changes.map(\.description).joined(separator: " | "), "--into", destination.description] + ["--message", description]
        try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
    }

    func describe(changes: [ChangeID], description: String) async throws {
        let arguments = ["--message", description] + changes.map(\.description)
        try await jujutsu.run(subcommand: "describe", arguments: arguments, repository: self)
    }

    func rebase(from: [ChangeID], to: ChangeID) async throws {
        let arguments = ["--revisions"] + from.map(\.description)
            + ["--insert-after", to.description]
        try await jujutsu.run(subcommand: "rebase", arguments: arguments, repository: self)
    }
}
