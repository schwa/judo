import SwiftUI
import JudoSupport

struct ChangeRowView: View {
    @Environment(Repository.self)
    var repository

    @Environment(\.actionHost)
    var actionHost

    var change: Change

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    HStack {
                        changeIDView
                        emailView
                        timestampView
                        bookmarksView
                        gitHeadView
                        rootView
                        conflictView
                    }
                    emptyView
                    descriptionView
                }
                Spacer()
                VStack {
                    commitIDView
                    parentCountView
                }
            }
        }
        .contextMenu {
            contextMenu
        }
    }

    @ViewBuilder
    var changeIDView: some View {
        IDView(change.changeID, style: .changeID)
    }

    @ViewBuilder
    var commitIDView: some View {
        IDView(change.commitID, style: .commitID)
    }

    @ViewBuilder
    var emailView: some View {
        if let email = change.author.email {
            Text(email).fixedSize()
        }
    }

    @ViewBuilder
    var timestampView: some View {
        Text(change.author.timestamp, style: .relative)
            .foregroundStyle(.cyan)
            .fixedSize()
    }

    @ViewBuilder
    var gitHeadView: some View {
        if change.isGitHead {
            Text("git_head()").italic()
                .foregroundStyle(.green)
                .fixedSize()
        }
    }

    @ViewBuilder
    var rootView: some View {
        if change.isRoot {
            Text("root()").italic()
                .foregroundStyle(.green)
                .fixedSize()
        }
    }

    @ViewBuilder
    var conflictView: some View {
        if change.isConflict {
            Text("conflict()").italic()
                .foregroundStyle(.red)
                .fixedSize()
        }
    }

    @ViewBuilder
    var emptyView: some View {
        if change.isEmpty && change.isRoot == false {
            Text("(empty)").italic()
                .foregroundStyle(.green)
                .fixedSize()
        }
    }

    @ViewBuilder
    var parentCountView: some View {
        VStack {
            Text("\(change.parents.count)")
            Text(change.parents.count == 1 ? "parent" : "parents")
                .font(.caption)
        }
        .fixedSize()
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    var bookmarksView: some View {
        if change.bookmarks.isEmpty == false {
            Text("\(change.bookmarks.joined(separator: ", "))")
                .foregroundStyle(.purple)
                .fixedSize()
        }
    }

    @ViewBuilder
    var descriptionView: some View {
        Group {
            if change.description.isEmpty && change.isRoot == false {
                Text("(no description set").italic().fixedSize()
            } else {
                let description = change.description.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(verbatim: description).lineLimit(1)
            }
        }
        .fixedSize()
        .font(.body)
    }

    @ViewBuilder
    var contextMenu: some View {
        if let actionHost {
            Button("Squash Change") {
                actionHost.with(action: Action(name: "Squash Change") {
                    try await repository.squash(changes: [change.changeID])
                    try await repository.refresh()
                })
            }
            Button("Abandon Change") {
                actionHost.with(action: Action(name: "Abandon Change") {
                    try await repository.abandon(changes: [change.changeID])
                    try await repository.refresh()
                })
            }
            Button("New Change") {
                actionHost.with(action: Action(name: "New Change") {
                    try await repository.new(changes: [change.changeID])
                    try await repository.refresh()
                })
            }
        }
    }
}
