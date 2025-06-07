import SwiftUI
import JudoSupport

struct ChangeRowView: View {
    @Environment(Repository.self)
    var repository

    @Environment(\.actionHost)
    var actionHost

    var change: Change

    var body: some View {
        ViewThatFits {
            HStack(alignment: .firstTextBaseline) {
                primaryDataView
                Spacer()
                secondaryDataView
            }
            primaryDataView
        }
        .contextMenu {
            contextMenu
        }
    }

    @ViewBuilder
    var primaryDataView: some View {
        VStack(alignment: .leading) {
            HStack {
                changeIDView
                emailView
                timestampView
            }
            isEmptyView
            descriptionView
        }
    }

    @ViewBuilder
    var secondaryDataView: some View {
        HStack(alignment: .firstTextBaseline) {
            bookmarksView
            gitHeadView
            rootView
            conflictView
            VStack {
                commitIDView
                parentCountView
            }
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
            TagView("git_head()")
            .backgroundStyle(.green)
        }
    }

    @ViewBuilder
    var rootView: some View {
        if change.isRoot {
            TagView("root()")
            .backgroundStyle(.green)
        }
    }

    @ViewBuilder
    var conflictView: some View {
        if change.isConflict {
            TagView("conflict()")
            .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    var isEmptyView: some View {
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
            HStack {
                ForEach(change.bookmarks, id: \.self) { bookmark in
                    TagView(bookmark)
                        .backgroundStyle(.purple)
                }
            }
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

struct TagView <Content: View>: View {
    let content: Content

    @Environment(\.backgroundStyle)
    var backgroundStyle

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
        .fixedSize()
        .font(.caption)
        .foregroundStyle(.white)
        .backgroundStyle(.clear)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundStyle ?? AnyShapeStyle(.white), in: Capsule())
    }
}

extension TagView where Content == Text {
    init(_ text: String) {
        self.init { Text(text) }
    }
}
