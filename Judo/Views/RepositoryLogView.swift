import Collections
import JudoSupport
import SwiftUI

struct RepositoryLogView: View {
    var log: RepositoryLog

    @Binding
    var selection: Set<ChangeID>

    @Environment(Repository.self)
    var repository

    @Environment(\.actionRunner)
    var actionRunner

    @State
    private var graph = Graph<ChangeID>(adjacency: [])

    @AppStorage("judo.debug-ui")
    var debugUI: Bool = false

    var body: some View {
        List(selection: $selection) {
            ForEach(graph.rows) { row in
                if let change = log.changes[row.node] {
                    RepositoryLogRow(row: row, change: change, selected: selection.contains(row.node), laneCount: graph.laneCount)
                }
            }
            .onMove { from, to in
                move(from: from, to: to)
            }
            .onChange(of: log.changes) {
                graph = log.makeGraph()
            }
        }
    }

    @ViewBuilder
    var warningView: some View {
        Text("Warning: Timeline graph not 100% working yet.")
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding()
            .background(.yellow, in: Capsule())
    }

    //    @ViewBuilder
    //    func node(change: Change, lane: Int) -> some View {
    //        Group {
    //            if change.isHead == true {
    //                Text("@")
    //                    .foregroundStyle(.judoHeadColor)
    //            }
    //            else if change.isImmutable {
    //                Image(systemName: "diamond.fill")
    //                    .foregroundStyle(.judoLanesColor)
    //            } else {
    //                Image(systemName: "circle")
    //                    .foregroundStyle(.judoLanesColor)
    //            }
    //        }
    //        .padding(2)
    //        .background(Color.white, in: Circle())
    //        .frame(width: 12, height: 12)
    //        .border(Color.red)
    //    }

    func move(from: IndexSet, to: Int) {
        guard let actionRunner else {
            return
        }
        let from = from.map {
            log.changes.values[$0]
        }
        let to = log.changes.values[to]
        actionRunner.with(action: Action(name: "Rabase") {
            try await repository.rebase(from: from.map(\.changeID), to: to.changeID)
            try await repository.log(revset: log.revset ?? "")
        })
    }
}

// #Preview {
//    Image(systemName: "figure.run.circle.fill")
//        .font(.system(size: 300))
//        .colorEffect(ShaderLibrary.checkerboard(.float(10), .color(.blue)))
// }
//
// #Preview {
//    Image(systemName: "figure.run.circle.fill")
//        .font(.system(size: 300))
//        .colorEffect(ShaderLibrary.barberpole(.float(10), .float(0), .color(.orange)))
// }

struct RepositoryLogRow: View {
    let row: Graph<ChangeID>.Row
    let change: Change
    let selected: Bool
    let laneCount: Int

    @Environment(Repository.self)
    private var repository

    @Environment(\.actionRunner)
    private var actionRunner

    @State
    private var isTargeted: Bool = false

    @AppStorage("judo.debug-ui")
    var debugUI: Bool = false

    var body: some View {
        Group {
            HStack {
                LanesView(laneCount: laneCount, row: row)
                VStack(alignment: .leading) {
                    ChangeRowView(change: change, isBookmarkDropTarget: isTargeted)
                    if debugUI {
                        VStack(alignment: .leading) {
                            Text(String(describing: change))
                            Text(String(describing: row))
                        }
                        .monospaced().font(.caption)
                            .padding(2)
                            .debugBackground()
                    }
                }
            }
            .environment(\.isRowSelected, selected)
            .tag(row.node)
        }
        .border(isTargeted ? Color.blue : Color.clear)
        .dropDestination(for: Bookmark.self, action: { items, _ in
            performBookmarkMove(bookmarks: items, change: change)
        }, isTargeted: { isTargeted in
            self.isTargeted = isTargeted
        })
        // macOS 26 only - but can be used for better experience.
        //        .dropDestination(for: Bookmark.self) { items, session in
        //        }

    }

    // TODO: #23 Move
    func performBookmarkMove(bookmarks: [Bookmark], change: Change) -> Bool {
        let action = PreviewableAction(name: "Hello") {
            let arguments = ["move"] + bookmarks.map(\.bookmark) + ["--to", change.changeID.description]
            _ = try await repository.jujutsu.run(subcommand: "bookmark", arguments: arguments, repository: repository)
            try await repository.refresh()
        }
        content: {
            // TODO: #24 Hook up allow backwards which means PreviewableAction needs to become a "ConfigurableAction" and oh boy.
            Form {
                GroupBox("Move Bookmarks?") {
                    let bookmarks = bookmarks.map(\.bookmark).map { $0.quoted() }

                    Text("Move bookmark \(bookmarks.joined(separator: ", ")) to change `\(change.changeID.shortAttributedString(variant: .changeID))`?")
                        .padding()
                    Toggle("Allow backwards move", isOn: .constant(false))
                }
                .onAppear {
                    Task {
                        let result = try await repository.are(changes: [change.changeID], allAncestorsOf: bookmarks.map(\.source))
                        print("backwards?", result)
                    }
                }
            }
            .padding()
        }
        actionRunner?.with(action: action)
        return false
    }
}

extension View {
    func debugBackground() -> some View {
        self.background(
            Color.black.colorEffect(ShaderLibrary.barberpole(.float(10), .float(0), .color(.orange.opacity(0.125)))),
        )
    }
}
