import Foundation

public extension Repository {
    func are(jujutsu: Jujutsu, changes: [ChangeID], allAncestorsOf other: [ChangeID]) async throws -> Bool {
        let other = other.map { Revset.ancestors(of: $0) }
        let revset = Revset(all: other)
        return try await are(jujutsu: jujutsu, changes: changes, allMmembersOf: revset)
    }

    func are(jujutsu: Jujutsu, changes: [ChangeID], allMmembersOf revset: Revset) async throws -> Bool {
        let changes = changes.map(\.description).joined(separator: " | ")
        let data = try await runner.run(subcommand: "log", arguments: ["--no-graph", "--revisions", changes, "--template", "self.contained_in(\"\(revset.escaped)\") ++ \",\""], invalidatesCache: false)
            .wrapped(prefix: "[", suffix: "]")
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        let flags = try decoder.decode([Bool].self, from: data)
        return flags.allSatisfy(\.self)
    }
}

// TODO: #26 Experimental
public protocol RevsetConvertible {
    var revset: Revset { get }
}

extension Revset: RevsetConvertible {
    public var revset: Revset {
        self
    }
}

extension ChangeID: RevsetConvertible {
    public var revset: Revset {
        Revset(self.string)
    }
}

public extension Revset {
    static func ancestors(of other: some RevsetConvertible) -> Revset {
        Revset("::\(other.revset.string)")
    }
}
