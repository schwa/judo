import SwiftUI
import JudoSupport

struct LanesView: View {
    var laneCount: Int
    var horizontalPadding: CGFloat = 4
    var laneWidth: CGFloat = 12
//    var intersections: Intersections
    var row: Graph<ChangeID>.Row

    var body: some View {
        Canvas { context, size in

            func laneToX(_ lane: Int) -> CGFloat {
                return CGFloat(lane) * 1.5 * laneWidth + horizontalPadding
            }

            let minY = 0.0
            let midY = size.height / 2
            let maxY = size.height
//            for entrance in intersections.entrances {
//                context.stroke(Path.wire(from: CGPoint(x: laneIDToX(entrance.source), y: minY), to: CGPoint(x: laneIDToX(entrance.destination), y: midY)), with: .color(.judoLanesColor), lineWidth: 2)
//            }
//            for exit in intersections.exits {
//                context.stroke(Path.wire(from: CGPoint(x: laneIDToX(exit.source), y: midY), to: CGPoint(x: laneIDToX(exit.destination), y: maxY)), with: .color(.judoLanesColor), lineWidth: 2)
//            }

            for lane in 0..<laneCount {
                let x = laneToX(lane)
                context.stroke(Path.wire(from: CGPoint(x: x, y: minY), to: CGPoint(x: x, y: maxY)), with: .color(.secondary), lineWidth: 1)
            }


        }
        .background(Color.secondary.opacity(0.2))
        .frame(width: CGFloat(laneCount) * laneWidth + horizontalPadding * 2)
    }
}
