import SwiftUI

struct ChangeIDView: View {
    var changeID: ChangeID

    var body: some View {
        if let shortest = changeID.shortest {
            Text(shortest)
                .foregroundStyle(Color(nsColor: NSColor.magenta))
                + Text(changeID.rawValue.trimmingPrefix(shortest).prefix(7))
                .foregroundStyle(.secondary)
        } else {
            Text(changeID.rawValue.prefix(8))
                .foregroundStyle(.secondary)
        }
    }
}

struct CommitIDView: View {
    var commitID: CommitID

    var body: some View {
        Text(commitID.shortest)
            .foregroundStyle(.blue)
            + Text(commitID.rawValue.trimmingPrefix(commitID.shortest).prefix(7))
            .foregroundStyle(.secondary)
    }
}
