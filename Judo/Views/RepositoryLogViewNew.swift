import Collections
import SwiftUI

struct RepositoryLogViewNew: View {
    @Binding
    var selection: Set<ChangeID>

    var log: RepositoryLog

    @State
    var rows: [GraphRow] = []
    @State
    var maxLanes: Int = 0


    var body: some View {
        List(selection: $selection) {
            ForEach(rows) { row in
                rowView(row: row)
                .tag(row.id)
            }
        }
        .onChange(of: log.commits) {
            rows = log.makeGraphRows()
        }
        .onChange(of: rows) {
            maxLanes = rows.map { $0.lanes.count }.max() ?? 0
        }
    }


    @ViewBuilder
    func rowView(row: GraphRow) -> some View {
        HStack {
            LanesView(lanes: row.lanes, maxLanes: maxLanes)
            CommitRowView(commit: row.commit)
        }
    }
}

struct LanesView: View {
    var lanes: [Lane]
    var maxLanes: Int

    var body: some View {
        HStack {
            ForEach(0..<maxLanes, id: \.self) { index in
                Group {
                    let lane = lanes[safe: index] ?? .empty
                    switch lane {
                    case .empty:
                        Color.clear.frame(height: 12)
                    case .edge:
                        Color.orange.frame(width: 2, height: 12)
                    case .node:
                        Circle().fill(.orange)
                        .frame(height: 12)

                    }

                }
                .frame(width: 12)
            }
        }
    }
}

enum Lane: Equatable {
    case empty
    case edge(change: ChangeID, parents: [ChangeID])
    case node(change: ChangeID, parents: [ChangeID])
}

struct GraphRow: Identifiable, Equatable {
    var id: ChangeID {
        commit.change_id
    }
    var lanes: [Lane]
    var commit: CommitRecord
}

extension RepositoryLog {
    func makeGraphRows() -> [GraphRow] {
        var rows: [GraphRow] = []
        for commit in commits.values {
            let lastRow = rows.last
            var lanes = lastRow?.lanes ?? .init()
            lanes = lanes.map { lane in
                switch lane {
                case .empty:
                    return .empty
                case .edge(let commitID, let parents), .node(let commitID, let parents):
                    if parents.contains(commit.change_id) {
                        return .empty
                    }
                    else {
                        return .edge(change: commitID, parents: parents)
                    }
                }
            }
            if let index = lanes.firstIndex(where: { $0 == .empty }) {
                lanes[index] = .node(change: commit.change_id, parents: commit.parents)
            }
            else {
                lanes.append(.node(change: commit.change_id, parents: commit.parents))
            }
            let row = GraphRow(lanes: lanes, commit: commit)
            rows.append(row)
        }
        return rows
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
