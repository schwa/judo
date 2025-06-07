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
                    CommitRowView(commit: log.commits[row.changeID]!)
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
                if currentChange == row.changeID {
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
                if nextChange == row.changeID {
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

