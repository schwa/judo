import JudoSupport
import Foundation

extension Signature {
    static let example = Signature(name: "Jane Doe", email: "janedoe@example.com", timestamp: Date())
}

extension Change {
    static let example: Change = {
        return Change(
            changeID: ChangeID("deadbeef", shortest: "de"),
            commitID: CommitID("kkkkkkkk", shortest: "kk"),
            author: Signature(name: "Jane Doe", email: "jane@example.com", timestamp: Date().addingTimeInterval(-3600)),
            description: "Fix crash when opening settings on iOS 18.\n\n- Guard against nil user defaults\n- Add defensive check for feature flag\n- Update unit tests",
            isRoot: false,
            isEmpty: false,
            isImmutable: false,
            isGitHead: false,
            isConflict: false,
            parents: [ChangeID("zzzzzzzz", shortest: "zz")],
            bookmarks: ["v1.2.3", "release-candidate"],
            totalAdded: 42,
            totalRemoved: 7
        )
    }()
}

