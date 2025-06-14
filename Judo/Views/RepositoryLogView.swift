import Collections
import SwiftUI
import JudoSupport

struct RepositoryLogView: View {
    var log: RepositoryLog

    @Binding
    var selection: Set<ChangeID>

    @Environment(Repository.self)
    var repository

    @Environment(\.actionHost)
    var actionHost

    @State
    var graph: Graph = Graph<ChangeID>()

    var body: some View {
        List(selection: $selection) {
            listContent
        }
        //        .scrollContentBackground(.hidden)
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
                        LanesView(laneCount: graph.laneCount, row: row)
////                            .overlay(alignment: .leading) {
////                                node(change: change, lane: row.activeLane)
////                                .offset(x: Double(row.activeLane.id) * 12)
//                    }
                        VStack(alignment: .leading) {
                            ChangeRowView(change: change)
//                            Text("\(String(describing: row))").monospaced().font(.caption)
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
            print(log.changes.values.map { ($0.changeID, $0.parents) })
            graph = log.makeGraph()
            graph.prettyPrint()
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
        guard let actionHost else {
            return
        }
        let from = from.map {
            log.changes.values[$0]
        }
        let to = log.changes.values[to]
        actionHost.with(action: Action(name: "Rabase", closure: {
            try await repository.rebase(from: from.map(\.changeID), to: to.changeID)
            try await repository.log(revset: log.revset ?? "")
        }))
    }
}

