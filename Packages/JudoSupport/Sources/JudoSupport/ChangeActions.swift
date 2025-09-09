import Collections
import Everything
import Foundation

public extension Repository {
    func new(jujutsu: Jujutsu, changes: [ChangeID] = []) async throws {
        try await runner.run(subcommand: "new", arguments: changes.map(\.description))
    }

    func undo(jujutsu: Jujutsu) async throws {
        try await runner.run(subcommand: "undo", arguments: [])
    }

    func abandon(jujutsu: Jujutsu, changes: [ChangeID]) async throws {
        let arguments = changes.map(\.description)
        try await runner.run(subcommand: "abandon", arguments: arguments)
    }

    func squash(jujutsu: Jujutsu, changes: [ChangeID]) async throws {
        let arguments = ["-r", changes.map(\.description).joined(separator: " | ")]
        try await runner.run(subcommand: "squash", arguments: arguments)
    }

    func squash(jujutsu: Jujutsu, changes: [ChangeID], destination: ChangeID, description: String) async throws {
        let arguments = ["--from", changes.map(\.description).joined(separator: " | "), "--into", destination.description] + ["--message", description]
        try await runner.run(subcommand: "squash", arguments: arguments)
    }

    func describe(jujutsu: Jujutsu, changes: [ChangeID], description: String) async throws {
        let arguments = ["--message", description] + changes.map(\.description)
        try await runner.run(subcommand: "describe", arguments: arguments)
    }

    func rebase(jujutsu: Jujutsu, from: [ChangeID], to: ChangeID) async throws {
        let arguments = ["--revisions"] + from.map(\.description)
            + ["--insert-after", to.description]
        try await runner.run(subcommand: "rebase", arguments: arguments)
    }
}
