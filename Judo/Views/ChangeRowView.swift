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
                authorView

                diffStatView
                timestampView
            }
            descriptionView
        }
    }

    @ViewBuilder
    var diffStatView: some View {


        if change.totalAdded == 0 && change.totalRemoved == 0 && change.isEmpty {
            Text("empty")
                .padding(.vertical, 2)
                .padding(.leading, 4)
                .padding(.trailing, 2)
                .foregroundStyle(.white)
            //            .background(Color.red.mix(with: Color.green, by: 0.5), in: Capsule())
                .background(Color.orange, in: Capsule())
        }
        else {

            HStack(spacing: 0) {
                Text("+\(change.totalAdded, format: .number)")
                    .padding(.vertical, 2)
                    .padding(.leading, 4)
                    .padding(.trailing, 2)
                    .background(.green)
                    .fixedSize()
                Text("-\(change.totalRemoved, format: .number)")
                    .padding(.vertical, 2)
                    .padding(.leading, 2)
                    .padding(.trailing, 4)
                    .background(.red)
                    .fixedSize()
            }
            .monospaced()
            .foregroundStyle(.white)
            //        .font(.caption2)
            //        .background(.green)
            .clipShape(Capsule())
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
        IDView(change.changeID, variant: .changeID)
    }

    @ViewBuilder
    var commitIDView: some View {
        IDView(change.commitID, variant: .commitID)
    }

    @ViewBuilder
    var authorView: some View {
        if !change.author.name.isEmpty && !(change.author.email ?? "").isEmpty {
            ContactView(name: change.author.name, email: change.author.email)
        }
    }

    @ViewBuilder
    var timestampView: some View {
        if change.author.timestamp.timeIntervalSince1970 != 0 {
            Text(change.author.timestamp, style: .relative)
                .foregroundStyle(.judoTimestampColor)
                .fixedSize()
        }
    }

    @ViewBuilder
    var gitHeadView: some View {
        if change.isGitHead {
            TagView("git_head()")
                .backgroundStyle(.judoHeadColor)
        }
    }

    @ViewBuilder
    var rootView: some View {
        if change.isRoot {
            TagView("root()")
                .backgroundStyle(.judoHeadColor)
        }
    }

    @ViewBuilder
    var conflictView: some View {
        if change.isConflict {
            TagView("conflict()")
                .foregroundStyle(.judoConflictColor)
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
                        .backgroundStyle(.judoBookmarkColor)
                }
            }
        }
    }

    @ViewBuilder
    var descriptionView: some View {
        Group {
            if change.description.isEmpty {
                Text("(no description set)").italic().fixedSize().foregroundStyle(.secondary)
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

        CopyButton("Copy Change ID", value: change.changeID)
        CopyButton("Copy Description", value: change.description)
        Divider()

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

