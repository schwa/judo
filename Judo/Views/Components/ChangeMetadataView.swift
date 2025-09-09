import JudoSupport
import SwiftUI

struct ChangeMetadataMinimalView: View {
    let change: Change

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                IDView(change.changeID, variant: .changeID)
                Divider()
                IDView(change.commitID, variant: .commitID)
                Divider()
                SignatureMinimalView(signature: change.author)
            }
            .fixedSize(horizontal: false, vertical: true)
            Text(change.description.split(separator: "\n").first ?? "")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(change.description.isEmpty ? .secondary : .primary)
        }
    }
}

struct ChangeMetadataFullView: View {
    let change: Change

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                IDView(change.changeID, variant: .changeID)
                Divider()
                IDView(change.commitID, variant: .commitID)
                Divider()
                SignatureMinimalView(signature: change.author)
            }
            .fixedSize(horizontal: false, vertical: true)
            ChangeDescriptionView(change: change)
        }
    }
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

#Preview {
    VStack {
        ChangeMetadataMinimalView(change: .example)
            .padding()
            .border(Color.red)

        ChangeMetadataFullView(change: .example)
            .padding()
            .border(Color.red)

        Spacer()
    }
}
