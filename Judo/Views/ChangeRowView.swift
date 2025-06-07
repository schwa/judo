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
                        IDView(change.changeID, style: .changeID)
                        if let email = change.author.email {
                            Text(email).fixedSize()
                        }
                        Text(change.author.timestamp, style: .relative)
                            .foregroundStyle(.cyan)
                            .fixedSize()
                        bookmarks
                        if change.isGitHead {
                            Text("git_head()").italic()
                                .foregroundStyle(.green)
                                .fixedSize()
                        }
                        if change.isRoot {
                            Text("root()").italic()
                                .foregroundStyle(.green)
                                .fixedSize()
                        }
                        if change.isConflict {
                            Text("conflict()").italic()
                                .foregroundStyle(.red)
                                .fixedSize()
                        }
                    }
                    if change.isEmpty && change.isRoot == false {
                        Text("(empty)").italic().foregroundStyle(.green)
                            .fixedSize()
                    }
                    description

                }
                Spacer()
                VStack {
                    IDView(change.commitID, style: .commitID)
                    parentCount
                }
            }
        }

        Spacer()
        .contextMenu {
            contextMenu
        }
    }

    @ViewBuilder
    var parentCount: some View {
        VStack {
            Text("\(change.parents.count)")
            Text(change.parents.count == 1 ? "parent" : "parents")
                .font(.caption)
        }
        .fixedSize()
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    var bookmarks: some View {
        if change.bookmarks.isEmpty == false {
            Text("\(change.bookmarks.joined(separator: ", "))")
                .foregroundStyle(.purple)
                .fixedSize()
        }
    }

    @ViewBuilder
    var description: some View {
        Group {
            if change.description.isEmpty && change.isRoot == false {
                Text("(no description set").italic().fixedSize()
            } else {
                let description = change.description.trimmingCharacters(in: .whitespacesAndNewlines)
                Text(verbatim: description).lineLimit(1)
            }
        }
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
