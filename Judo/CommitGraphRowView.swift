import Collections
import SwiftUI

struct CommitGraphRowView: View {
    let row: GraphRow
    let columnCount: Int

    var body: some View {
        Grid(alignment: .leading) {
            GridRow {
                ForEach(0..<columnCount, id: \.self) { index in
                    Text(symbol(at: index))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 12, alignment: .center)
                        .border(Color.red)
                }
            }
        }
    }

    private var lanes: [ChangeID?] {
        switch row {
        case .commit(_, _, let lanes),
             .elision(_, let lanes):
            return lanes
        }
    }

    private func symbol(at index: Int) -> String {
        switch row {
        case let .commit(commit, column, _):
            if index == column {
                return "•"
            }
            if lanes.indices.contains(index), lanes[index] != nil {
                return "|"
            }
            return ""

        case .elision:
            return lanes[index] != nil ? "|" : " "
        }
    }
}

enum GraphRow {
    case commit(commit: CommitRecord, column: Int, lanes: [ChangeID?])
    case elision(parents: [ChangeID], lanes: [ChangeID?])
}

func buildGraphRows(from sortedCommits: [CommitRecord], allCommits: OrderedDictionary<ChangeID, CommitRecord>) -> [GraphRow] {
    var rows: [GraphRow] = []
    var lanes: [ChangeID?] = []

    for commit in sortedCommits {
        // Determine column for this commit
        let column: Int
        if let idx = lanes.firstIndex(where: { $0 == commit.id }) {
            column = idx
        } else {
            // 🚫 Don't allow reuse if the commit is totally unrelated to current active commits
            let active = Set(lanes.compactMap(\.self))
            let conflicts = commit.parents.contains { active.contains($0) }

            if let reusable = lanes.firstIndex(of: nil), !conflicts {
                column = reusable
                lanes[column] = commit.id
            } else {
                column = lanes.count
                lanes.append(commit.id)
            }
        }

        // Emit row
        rows.append(.commit(commit: commit, column: column, lanes: lanes))

        // Clear this commit’s slot
        lanes[column] = nil

        for parent in commit.parents {
            if !lanes.contains(parent), allCommits[parent] != nil {
                if let empty = lanes.firstIndex(of: nil) {
                    lanes[empty] = parent
                } else {
                    lanes.append(parent)
                }
            }
        }
    }

    return rows
}

struct LanesView: View {
    static let laneWidth: CGFloat = 12

    let row: GraphRow
    let columnCount: Int

    var body: some View {
        Canvas { context, size in
            for index in 0..<columnCount {
                let hasNode: Bool
                switch row {
                case let .commit(_, column, _):
                    if index == column {
                        hasNode = true
                    } else if lanes.indices.contains(index), lanes[index] != nil {
                        hasNode = false
                    } else {
                        continue
                    }

                case .elision:
                    hasNode = false
                }

                let x = CGFloat(index) * Self.laneWidth + (Self.laneWidth / 2)
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height / 2))
                }
                context.stroke(path, with: .color(.orange), lineWidth: 2)

                if hasNode {
                    let path = Path { path in
                        path.addEllipse(in: CGRect(x: x - 4, y: size.height / 4 - 4, width: 8, height: 8))
                    }
                    context.fill(path, with: .color(.orange))
                }
            }
        }
        .frame(width: CGFloat(columnCount) * Self.laneWidth)
    }

    private var lanes: [ChangeID?] {
        switch row {
        case .commit(_, _, let lanes), .elision(_, let lanes):
            return lanes
        }
    }
}
