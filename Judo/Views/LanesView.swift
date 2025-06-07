import SwiftUI
import JudoSupport

struct LanesView: View {
    var change: Change
    var row: GraphRow
    var lastRow: GraphRow?
    var laneCount: Int
    var hoziontalPadding: CGFloat = 4
    var laneWidth: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            func laneIDToX(_ laneID: LaneID) -> CGFloat {
                return hoziontalPadding + (CGFloat(laneID.id) + 0.5) * laneWidth
            }

            let minY = 0.0
            let midY = size.height / 2
            let maxY = size.height
            let activeLaneX = laneIDToX(row.activeLane)

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
                context.stroke(Path.wire(from: CGPoint(x: sourceX, y: minY), to: CGPoint(x: destinationX, y: midY)), with: .color(.black), lineWidth: 2)
            }
            // Bottom half
            for (destinationX, nextChange) in nextLanes {
                let sourceX: CGFloat
                if nextChange == row.changeID {
                    sourceX = laneIDToX(row.activeLane)
                }
                else {
                    sourceX = destinationX
                }
                context.stroke(Path.wire(from: CGPoint(x: sourceX, y: midY), to: CGPoint(x: destinationX, y: maxY)), with: .color(.black), lineWidth: 2)
            }

            if let icon = context.resolveSymbol(id: "icon") {
                context.draw(icon, at: CGPoint(x: activeLaneX, y: midY), anchor: .center)
            }
        }
        symbols: {
            Group {
                if change.isHead == true {
                    Text("@")
                        .foregroundStyle(.green)
                }
                else if change.isImmutable {
                    Image(systemName: "diamond.fill")
                        .foregroundStyle(.black)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.black)
                }
            }
            .padding(2)
            .background(Color.white, in: Circle())
            .tag("icon")
        }
        .frame(width: CGFloat(laneCount) * laneWidth + hoziontalPadding * 2)
    }

}

