import Collections
import SwiftUI
import JudoSupport

struct RepositoryLogView: View {
    @Environment(Repository.self)
    var repository

    @Binding
    var selection: Set<ChangeID>

    var log: RepositoryLog

    @State
    var rows: [GraphRow] = []

    var body: some View {
        let laneCount = rows.reduce(0) { max($0, $1.nextLanes.count) }
        List(selection: $selection) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                let commit = log.commits[row.changeID]! // TODO: Bang!
                let lastRow = index > 0 ? rows[index - 1] : nil
                HStack {
                    LanesView(commit: commit, row: row, lastRow: lastRow, laneCount: laneCount)
                    CommitRowView(commit: commit)
                }
                .tag(row.id)
            }
            .onMove { from, to in
                let from = from.map {
                    log.commits.values[$0]
                }
                let to = log.commits.values[to]
                Task {
                    do {
                        try await repository.rebase(from: from.map(\.change_id), to: to.change_id)
//                        try await self.log?.refresh()
                        try await repository.log(revset: log.revset ?? "")
                    }
                    catch {
                        print("Error moving commits: \(error)")
                    }
                }
            }
        }
        .onChange(of: log.commits) {
            rows = log.makeGraphRows()
        }
    }
}

struct LanesView: View {
    var commit: CommitRecord
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
                if commit.isHead == true {
                    Text("@")
                        .foregroundStyle(.green)
                }
                else if commit.immutable {
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
        .frame(width: CGFloat(laneCount) * laneWidth)
    }

}

