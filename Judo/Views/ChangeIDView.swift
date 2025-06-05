import SwiftUI

extension Color {
    static let magenta = Color(nsColor: .magenta)
}

extension AttributedString {
    func modifying(_ modifier: (inout AttributedString) -> Void) -> AttributedString {
        var modified = self
        modifier(&modified)
        return modified
    }
}

extension ChangeID {
    var shortAttributedString: AttributedString {
        if let shortest {
            return AttributedString(shortest).modifying {
                $0.foregroundColor = Color.blue
            }
            + AttributedString(rawValue.trimmingPrefix(shortest).prefix(7))
        }
        else {
            return AttributedString(rawValue.prefix(8), attributes: .init([.foregroundColor: Color.secondary]))
        }
    }
}

extension CommitID {
    var shortAttributedString: AttributedString {
        return AttributedString(shortest) .modifying {
            $0.foregroundColor = Color.blue
        }

        + AttributedString(rawValue.trimmingPrefix(shortest).prefix(7))
    }
}


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
