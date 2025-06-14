import Collections
import JudoSupport
import SwiftUI

struct RepositoryLogView: View {
    var log: RepositoryLog

    @Binding
    var selection: Set<ChangeID>

    @Environment(Repository.self)
    var repository

    @Environment(\.actionRunner)
    var actionRunner

    @State
    private var graph = Graph<ChangeID>(adjacency: [])

    @AppStorage("judo.debug-ui")
    var debugUI: Bool = false

    var body: some View {
        List(selection: $selection) {
            listContent
        }
        //        .scrollContentBackground(.hidden)
        //        .background(Color.black.opacity(0.1).border(Color.red).frame(width: 12 * CGFloat(graph.laneCount + 1)), alignment: .leading)
        //        .background(Color.white)
        //        .overlay(alignment: .bottomTrailing) {
        //            warningView
        //            .padding()
        //        }
    }

    @ViewBuilder
    var listContent: some View {
        ForEach(graph.rows) { row in
            Group {
                if let change = log.changes[row.node] {
                    HStack {
                        // Spacer().frame(width: CGFloat(graph.laneCount) * 12)
                        LanesView(laneCount: graph.laneCount, row: row)
                        ////                            .overlay(alignment: .leading) {
                        ////                                node(change: change, lane: row.activeLane)
                        ////                                .offset(x: Double(row.activeLane.id) * 12)
                        //                    }
                        VStack(alignment: .leading) {
                            ChangeRowView(change: change)
                            if debugUI {
                                Text("\(String(describing: row))").monospaced().font(.caption)
                                    .padding(2)
                                    .background(
                                        Color.black.colorEffect(ShaderLibrary.barberpole(.float(10), .float(0), .color(.orange.opacity(0.125)))),
                                        )
                            }
                        }
                    }
                    .environment(\.isRowSelected, selection.contains(row.node))
                    .tag(row.node)
                }
            }
        }
        .onMove { from, to in
            move(from: from, to: to)
        }
        .onChange(of: log.changes) {
            graph = log.makeGraph()
        }
    }

    @ViewBuilder
    var warningView: some View {
        Text("Warning: Timeline graph not 100% working yet.")
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding()
            .background(.yellow, in: Capsule())
    }

    //    @ViewBuilder
    //    func node(change: Change, lane: Int) -> some View {
    //        Group {
    //            if change.isHead == true {
    //                Text("@")
    //                    .foregroundStyle(.judoHeadColor)
    //            }
    //            else if change.isImmutable {
    //                Image(systemName: "diamond.fill")
    //                    .foregroundStyle(.judoLanesColor)
    //            } else {
    //                Image(systemName: "circle")
    //                    .foregroundStyle(.judoLanesColor)
    //            }
    //        }
    //        .padding(2)
    //        .background(Color.white, in: Circle())
    //        .frame(width: 12, height: 12)
    //        .border(Color.red)
    //    }

    func move(from: IndexSet, to: Int) {
        guard let actionRunner else {
            return
        }
        let from = from.map {
            log.changes.values[$0]
        }
        let to = log.changes.values[to]
        actionRunner.with(action: Action(name: "Rabase") {
            try await repository.rebase(from: from.map(\.changeID), to: to.changeID)
            try await repository.log(revset: log.revset ?? "")
        })
    }
}

// #Preview {
//    Image(systemName: "figure.run.circle.fill")
//        .font(.system(size: 300))
//        .colorEffect(ShaderLibrary.checkerboard(.float(10), .color(.blue)))
// }
//
// #Preview {
//    Image(systemName: "figure.run.circle.fill")
//        .font(.system(size: 300))
//        .colorEffect(ShaderLibrary.barberpole(.float(10), .float(0), .color(.orange)))
// }
