import SwiftUI
import Collections

struct RevisionTimelineView: View {
    @State
    private var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    var log: RepositoryLog?

    var body: some View {

        let commits: [CommitRecord] = log.map { Array($0.commits.values) } ?? []

        List(commits, selection: $selection) { commit in
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

// MARK: -

struct RevisionTimelineViewNEW: View {
    @State
    private var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    var log: RepositoryLog?

    var body: some View {
        let commits: [CommitRecord] = log.map { Array($0.commits.values) } ?? []

        let rows = buildGraphRows(from: commits, allCommits: log?.commits ?? [:])
        let columnCount = rows.map { row -> Int in
            switch row {
            case let .commit(_, _, lanes):
                return lanes.count
            case .elision:
                return 0
            }
        }.max() ?? 0

        List(Array(rows.enumerated()), id: \.offset) { _, row in
            HStack {
                Group {
                    switch row {
                    case .commit:
                        LanesView(row: row, columnCount: columnCount)
                    //                        CommitGraphRowView(row: row, columnCount: columnCount)
                    case .elision:
                        Text("...")
                    }
                }
                .frame(width: 12 * CGFloat(columnCount))

                switch row {
                case let .commit(commit, _, _):
                    CommitRowView(commit: commit)
                case .elision:
                    Spacer()
                }
            }
        }
    }
}
