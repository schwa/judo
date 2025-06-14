import Collections
import Everything
import Foundation

public extension Repository {
    var jujutsu: Jujutsu {
        appModel.jujutsu
    }

    func new(changes _: [ChangeID] = []) async throws {
        let data = try await jujutsu.run(subcommand: "new", arguments: [], repository: self)
        // TODO; Not basing it on changes
        logger?.info(String(data: data, encoding: .utf8) ?? "No output")
    }

    func undo() async throws {
        let data = try await jujutsu.run(subcommand: "undo", arguments: [], repository: self)
        logger?.info(String(data: data, encoding: .utf8) ?? "No output")
    }

    func abandon(changes: [ChangeID]) async throws {
        let arguments = changes.map(\.description)
        let data = try await jujutsu.run(subcommand: "abandon", arguments: arguments, repository: self)
        logger?.info(String(data: data, encoding: .utf8) ?? "No output")
    }

    func squash(changes: [ChangeID]) async throws {
        let arguments = ["-r", changes.map(\.description).joined(separator: " | ")
        ]
        logger?.info(arguments)
        let data = try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
        logger?.info(String(data: data, encoding: .utf8) ?? "No output")
    }

    func squash(changes: [ChangeID], destination: ChangeID, description: String) async throws {
        let arguments = ["--from", changes.map(\.description).joined(separator: " | "), "--into", destination.description] + ["--message", description]
        logger?.info(arguments)
        let data = try await jujutsu.run(subcommand: "squash", arguments: arguments, repository: self)
        logger?.info(String(data: data, encoding: .utf8) ?? "No output")
    }

    func describe(changes: [ChangeID], description: String) async throws {
        let arguments = ["--message", description] + changes.map(\.description)
        let data = try await jujutsu.run(subcommand: "describe", arguments: arguments, repository: self)
        logger?.info(String(data: data, encoding: .utf8) ?? "No output")
    }

    func rebase(from: [ChangeID], to: ChangeID) async throws {
        let arguments = ["--revisions"] + from.map(\.description)
            + ["--insert-after", to.description]
        logger?.info(arguments)
        let data = try await jujutsu.run(subcommand: "rebase", arguments: arguments, repository: self)
        logger?.info(">", String(data: data, encoding: .utf8) ?? "No output")
    }
}
