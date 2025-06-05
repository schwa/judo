import SwiftUI
import Collections

struct RevisionTimelineView: View {
    @State
    private var repository = Repository(path: "/Users/schwa/Projects/Ultraviolence")

    @State
    private var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    @Binding
    var commits: OrderedDictionary<ChangeID, CommitRecord>

    var body: some View {
        List(commits.values, selection: $selection) { commit in
            HStack {
                if commit.immutable {
                    Image(systemName: "diamond.fill")
                } else {
                    if commit.change_id == head {
                        Text("@")
                    } else {
                        Image(systemName: "circle")
                    }
                }
                CommitRowView(commit: commit)
            }
        }
    }
}

struct RevisionTimelineViewNEW: View {
    @State
    private var repository = Repository(path: "/Users/schwa/Projects/Ultraviolence")

    @State
    private var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    @Binding
    var commits: OrderedDictionary<ChangeID, CommitRecord>

    var body: some View {
        let rows = buildGraphRows(from: Array(commits.values), allCommits: self.commits)
        let columnCount = rows.map { row -> Int in
            switch row {
            case let .commit(_, _, lanes):
                return lanes.count

            case let .elision(_, _):
                return 0
            }
        }.max() ?? 0

        List(Array(rows.enumerated()), id: \.offset) { _, row in
            HStack {
                Group {
                    switch row {
                    case let .commit(commit, _, lanes):
                        LanesView(row: row, columnCount: columnCount)
                    //                        CommitGraphRowView(row: row, columnCount: columnCount)
                    case let .elision(parents, lanes):
                        Text("...")
                    }
                }
                .frame(width: 12 * CGFloat(columnCount))

                switch row {
                case let .commit(commit, _, _):
                    CommitRowView(commit: commit)

                case let .elision(parents, _):
                    Spacer()
                }
            }
        }
    }
}
