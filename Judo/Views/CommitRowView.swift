import SwiftUI
import JudoSupport

struct CommitRowView: View {
    @Environment(Repository.self)
    var repository

    var commit: CommitRecord

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(commit.change_id.shortAttributedString(style: .changeID))
                if let email = commit.author.email {
                    Text(email)
                }
                Text(commit.author.timestamp, style: .relative)
                    .foregroundStyle(.cyan)
                if commit.bookmarks.isEmpty == false {
                    Text("\(commit.bookmarks.joined(separator: ", "))")
                        .foregroundStyle(.purple)
                }
                if commit.git_head {
                    Text("git_head()").italic()
                        .foregroundStyle(.green)
                }
                if commit.root {
                    Text("root()").italic()
                        .foregroundStyle(.green)
                }
                Text(commit.commit_id.shortAttributedString(style: .commitID))
                if commit.conflict {
                    Text("conflict()").italic()
                        .foregroundStyle(.red)
                }
            }
            .font(.subheadline)
            if commit.empty && commit.root == false {
                Text("(empty)").italic().foregroundStyle(.green)
            }

            Group {
                if commit.description.isEmpty && commit.root == false {
                    Text("(no description set").italic()
                } else {
                    let description = commit.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    Text(verbatim: description).lineLimit(1)
                }
            }
            .font(.body)
        }
        Spacer()
        VStack {
            Text("\(commit.parents.count)")
            Text(commit.parents.count == 1 ? "parent" : "parents")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}
