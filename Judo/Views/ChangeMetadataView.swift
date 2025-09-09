import JudoSupport
import SwiftUI

struct ChangeMetadataMinimalView: View {
    let change: Change
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            IDView(change.changeID, variant: .changeID)
            Text(change.description.split(separator: "\n").first ?? "")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(change.description.isEmpty ? .secondary : .primary)
        }
    }
}

#Preview {
    ChangeMetadataMinimalView(change: Change.example)
}


extension Change {
    static let example: Change = {
        let exampleChangeID = ChangeID(rawValue: "abc123def")!
        let exampleCommitID = CommitID(rawValue: "fed321cba")!
        let exampleAuthor = Signature(name: "Jane Doe", email: "jane@example.com", timestamp: Date().addingTimeInterval(-3600))
        return Change(
            changeID: exampleChangeID,
            commitID: exampleCommitID,
            author: exampleAuthor,
            description: "Fix crash when opening settings on iOS 18.\n\n- Guard against nil user defaults\n- Add defensive check for feature flag\n- Update unit tests",
            isRoot: false,
            isEmpty: false,
            isImmutable: false,
            isGitHead: false,
            isConflict: false,
            parents: [ChangeID(rawValue: "parent123")!],
            bookmarks: ["v1.2.3", "release-candidate"],
            totalAdded: 42,
            totalRemoved: 7
        )
    }()
}

