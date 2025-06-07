import SwiftUI
import JudoSupport

struct ChangeRowView: View {
    @Environment(Repository.self)
    var repository

    var change: Change

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                IDView(change.changeID, style: .changeID)                    
                if let email = change.author.email {
                    Text(email)
                }
                Text(change.author.timestamp, style: .relative)
                    .foregroundStyle(.cyan)
                if change.bookmarks.isEmpty == false {
                    Text("\(change.bookmarks.joined(separator: ", "))")
                        .foregroundStyle(.purple)
                }
                if change.isGitHead {
                    Text("git_head()").italic()
                        .foregroundStyle(.green)
                }
                if change.isRoot {
                    Text("root()").italic()
                        .foregroundStyle(.green)
                }
                IDView(change.commitID, style: .commitID)
                if change.isConflict {
                    Text("conflict()").italic()
                        .foregroundStyle(.red)
                }
            }
            .font(.subheadline)
            if change.isEmpty && change.isRoot == false {
                Text("(empty)").italic().foregroundStyle(.green)
            }

            Group {
                if change.description.isEmpty && change.isRoot == false {
                    Text("(no description set").italic()
                } else {
                    let description = change.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    Text(verbatim: description).lineLimit(1)
                }
            }
            .font(.body)
        }
        Spacer()
        VStack {
            Text("\(change.parents.count)")
            Text(change.parents.count == 1 ? "parent" : "parents")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
