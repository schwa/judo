import JudoSupport
import SwiftUI
import System
import UniformTypeIdentifiers

struct ChangeRowView: View {
    @Environment(Repository.self)
    var repository

    @Environment(\.actionRunner)
    var actionRunner

    @State
    private var isTargeted: Bool = false

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
        .border(isTargeted ? Color.blue : Color.clear)
        .dropDestination(for: Bookmark.self, action: { items, _ in
            performBookmarkMove(bookmarks: items, change: change)
        }, isTargeted: { isTargeted in
            self.isTargeted = isTargeted
        })
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
                .font(.caption)
        } else {
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
            .font(.caption)
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
                .font(.caption)
        }
    }

    @ViewBuilder
    var timestampView: some View {
        if change.author.timestamp.timeIntervalSince1970 != 0 {
            Text(change.author.timestamp, style: .relative)
                .foregroundStyle(.judoTimestampColor)
                .fixedSize()
                .font(.caption)
        }
    }

    @ViewBuilder
    var gitHeadView: some View {
        if change.isGitHead {
            TagView("git_head()", systemImage: "star.fill")
                .backgroundStyle(.judoHeadColor)
                .font(.caption)
        }
    }

    @ViewBuilder
    var rootView: some View {
        if change.isRoot {
            TagView("root()", systemImage: "arrow.down.to.line")
                .backgroundStyle(.judoHeadColor)
                .font(.caption)
        }
    }

    @ViewBuilder
    var conflictView: some View {
        if change.isConflict {
            TagView("conflict()", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.judoConflictColor)
                .font(.caption)
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
                    TagView(bookmark, systemImage: "bookmark.fill")
                        .backgroundStyle(.judoBookmarkColor)
                        .draggable(Bookmark(repositoryPath: repository.path, source: change.changeID, bookmark: bookmark))
                }
            }
            .font(.caption)
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

        if let actionRunner {
            Button("Squash Change") {
                actionRunner.with(action: Action(name: "Squash Change") {
                    try await repository.squash(changes: [change.changeID])
                    try await repository.refresh()
                })
            }
            Button("Abandon Change") {
                actionRunner.with(action: Action(name: "Abandon Change") {
                    try await repository.abandon(changes: [change.changeID])
                    try await repository.refresh()
                })
            }
            Button("New Change") {
                actionRunner.with(action: Action(name: "New Change") {
                    try await repository.new(changes: [change.changeID])
                    try await repository.refresh()
                })
            }
        }
    }

    func performBookmarkMove(bookmarks: [Bookmark], change: Change) -> Bool {
        let action = PreviewableAction(name: "Hello") {
            let arguments = ["move"] + bookmarks.map(\.bookmark) + ["--to", change.changeID.description]
            _ = try await repository.jujutsu.run(subcommand: "bookmark", arguments: arguments, repository: repository)
            try await repository.refresh()
        }
        content: {
            // TODO: Add an allow backwards option
            Text("Move bookmark(s) \(bookmarks.map(\.bookmark).joined(separator: ", ")) to change \(change.changeID)")
                .padding()
        }

        actionRunner?.with(action: action)
        return false
    }
}

extension UTType {
    static let jujutsuBookmark = UTType(exportedAs: "io.schwa.judo.jj-bookmark")
}

struct Bookmark: Transferable, Codable {
    var repositoryPath: FilePath
    var source: ChangeID
    var bookmark: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .jujutsuBookmark)
    }
}
