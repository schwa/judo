import Foundation
import JudoSupport

extension Repository {
    func are(changes: [ChangeID], allAncestorsOf other: [ChangeID]) async throws -> Bool {
        let other = other.map { Revset.ancestors(of: $0) }
        let revset = Revset(all: other)
        return try await are(changes: changes, allMmembersOf: revset)
    }

    func are(changes: [ChangeID], allMmembersOf revset: Revset) async throws -> Bool {
        let changes = changes.map(\.description).joined(separator: " | ")
        let data = try await jujutsu.run(subcommand: "log", arguments: ["--no-graph", "--revisions", changes, "--template", "self.contained_in(\"\(revset.escaped)\") ++ \",\""], repository: self)
            .wrapped(prefix: "[", suffix: "]")
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        let flags = try decoder.decode([Bool].self, from: data)
        return flags.allSatisfy(\.self)
    }
}

// TODO: Experimental
protocol RevsetConvertible {
    var revset: Revset { get }
}

extension Revset: RevsetConvertible {
    var revset: Revset {
        self
    }
}

extension ChangeID: RevsetConvertible {
    var revset: Revset {
        Revset(self.string)
    }
}

extension Revset {
    static func ancestors(of other: some RevsetConvertible) -> Revset {
        Revset("::\(other.revset.string)")
    }
}
