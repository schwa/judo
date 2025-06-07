import Collections
import SwiftUI
import JudoSupport

struct RepositoryLogViewNew: View {
    @Binding
    var selection: Set<ChangeID>

    var log: RepositoryLog

    @State
    var rows: [GraphRow] = []

    var body: some View {
        let laneCount = rows.reduce(0) { max($0, $1.nextLanes.count) }
        List(selection: $selection) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack {
                    LanesView(row: row, lastRow: index > 0 ? rows[index - 1] : nil, laneCount: laneCount)
                    CommitRowView(commit: row.commit)
                }
                .tag(row.id)
            }
        }
        .onChange(of: log.commits) {
            rows = log.makeGraphRows()
        }
    }
}

struct LanesView: View {
    var row: GraphRow
    var lastRow: GraphRow?
    var laneCount: Int
    var laneWidth: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let minY = 0.0
            let midY = size.height / 2
            let maxY = size.height
            let activeLaneX = (CGFloat(row.activeLane.id) + 0.5) * laneWidth

            func laneIDToX(_ laneID: LaneID) -> CGFloat {
                return (CGFloat(laneID.id) + 0.5) * laneWidth
            }

            let lanes = (lastRow?.nextLanes ?? [:]).sorted { $0.key.id < $1.key.id }.map { (laneIDToX($0.key), $0.value) }
            let nextLanes = row.nextLanes.sorted { $0.key.id < $1.key.id }.map { (laneIDToX($0.key), $0.value) }
            // Top half
            for (sourceX, currentChange) in lanes {
                let destinationX: CGFloat
                if currentChange == row.commit.change_id {
                    destinationX = laneIDToX(row.activeLane)
                }
                else {
                    destinationX = sourceX
                }
                context.stroke(Path.wire(from: CGPoint(x: sourceX, y: minY), to: CGPoint(x: destinationX, y: midY)), with: .color(.orange), lineWidth: 2)
            }
//            // Bottom half
            // Top half
            for (destinationX, nextChange) in nextLanes {
                let sourceX: CGFloat
                if nextChange == row.commit.change_id {
                    sourceX = laneIDToX(row.activeLane)
                }
                else {
                    sourceX = destinationX
                }
                context.stroke(Path.wire(from: CGPoint(x: sourceX, y: midY), to: CGPoint(x: destinationX, y: maxY)), with: .color(.purple), lineWidth: 2)
            }
//            for (change, destinationLane) in nextLanes.map({ ($1, $0.id) }) {
//            }
            context.fill(Path(ellipseIn: CGRect(x: activeLaneX - 4, y: midY - 4, width: 8, height: 8)), with: .color(.orange))
        }
        .frame(width: CGFloat(laneCount) * laneWidth)
    }
}


struct LaneID: Hashable {
    var id: Int
}

extension LaneID: CustomStringConvertible {
    var description: String {
        return "L\(id)"
    }
}

struct LaneSegment {
    var fromLane: LaneID
    var toLane: LaneID
}

struct GraphRow {
    let commit: CommitRecord
    let activeLane: LaneID
    let nextLanes: [LaneID: ChangeID]
}

extension RepositoryLog {
    func makeGraphRows() -> [GraphRow] {
        var nextLaneID = 0
        func makeLaneID() -> LaneID {
            defer {
                nextLaneID += 1
            }
            return LaneID(id: nextLaneID)
        }
        //

        var rows: [GraphRow] = []
        for (index, commit) in commits.values.enumerated() {
            let isAtEnd = index == commits.count - 1
            let lastRow = rows.last
            print("** \(commit.change_id.short(4)), [\(commit.parents.map { $0.short(4) })]")
            if let lastRow {
                var nextLanes = lastRow.nextLanes
                let activeLane = nextLanes
                    .sorted { $0.key.id < $1.key.id }
                    .first(where: { $0.value == commit.change_id })?.key ?? makeLaneID()
                if let first = commit.parents.first {
                    nextLanes[activeLane] = first
                    for parent in commit.parents.dropFirst() {
                        nextLanes[makeLaneID()] = parent
                    }
                }
                if isAtEnd {
                    nextLanes.removeAll()
                }
                let row = GraphRow(commit: commit, activeLane: activeLane, nextLanes: nextLanes)
                rows.append(row)
            }
            else {
                // First commit, create a new row
                let activeLane = makeLaneID()
                var nextLanes: [LaneID: ChangeID] = [:]
                // make next lanes - the first parent reuses laneID and the others get new ones
                if let first = commit.parents.first {
                    nextLanes[activeLane] = first
                    for parent in commit.parents.dropFirst() {
                        nextLanes[makeLaneID()] = parent
                    }
                }
                let row = GraphRow(commit: commit, activeLane: activeLane, nextLanes: nextLanes)
                rows.append(row)
            }
            print(">>", rows.last)
        }
        return rows
    }
}

extension GraphRow: CustomDebugStringConvertible {
    var debugDescription: String {

        return "GraphRow(commit: \(commit.change_id.short(4)), activeLane: \(activeLane), nextLanes: \(nextLanes))"

    }
}

// MARK: -

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: String, paddedTo length: Int, pad: Character = " ") {
        let padCount = max(0, length - value.count)
        let padded = value + String(repeating: pad, count: padCount)
        appendLiteral(padded)
    }
}

extension GraphRow: Identifiable {
    var id: ChangeID { commit.change_id }
}

extension Path {
    static func wire(from: CGPoint, to: CGPoint) -> Path {
        Path { path in
            path.move(to: from)

            let midY = (from.y + to.y) / 2

            // Control points for a smooth S curve
            path.addCurve(
                to: to,
                control1: CGPoint(x: from.x, y: midY),
                control2: CGPoint(x: to.x, y: midY)
            )
        }
    }
}
