import JudoSupport
import SwiftUI

struct LanesView: View {
    var laneCount: Int
    var horizontalPadding: CGFloat = 4
    var laneWidth: CGFloat = 12
    //    var intersections: Intersections
    var row: Graph<ChangeID>.Row

    var body: some View {
        Canvas { context, size in
            let shhhColor = Color.secondary.opacity(0.15)

            func laneToX(_ lane: Int) -> CGFloat {
                (CGFloat(lane) + 0.5) * laneWidth + horizontalPadding
            }

            let minY = 0.0
            let midY = size.height / 2
            let maxY = size.height

            for lane in 0..<laneCount {
                let x = laneToX(lane)
                context.stroke(Path.wire(from: CGPoint(x: x, y: minY), to: CGPoint(x: x, y: maxY)), with: .color(shhhColor), lineWidth: 1)
            }

            for entrance in row.entrances {
                let sourceX = laneToX(entrance.source)
                let destinationX = laneToX(entrance.destination)
                context.stroke(Path.wire(from: CGPoint(x: sourceX, y: minY), to: CGPoint(x: destinationX, y: midY)), with: .color(.judoTimelineColor), lineWidth: 2)
            }

            for exit in row.exits {
                let sourceX = laneToX(exit.source)
                let destinationX = laneToX(exit.destination)
                context.stroke(Path.wire(from: CGPoint(x: sourceX, y: midY), to: CGPoint(x: destinationX, y: maxY)), with: .color(.judoTimelineColor), lineWidth: 2)
            }

            context.fill(Path(ellipseIn: CGRect(x: laneToX(row.currentLane) - 5, y: midY - 5, width: 10, height: 10)), with: .color(.judoTimelineNodeColor))
        }
        .background(Color.secondary.opacity(0.1))
        .frame(width: CGFloat(laneCount) * laneWidth + horizontalPadding * 2)
    }
}
