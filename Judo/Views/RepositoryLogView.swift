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
    var rows: [GraphRow] = []

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
        let laneCount = rows.reduce(0) { max($0, $1.nextLanes.count) }
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
            Group {
                if let change = log.changes[row.changeID] {
                    let isLastRow = index > 0 ? rows[index - 1] : nil
                    HStack {
                        LanesView(change: change, row: row, lastRow: isLastRow, laneCount: laneCount)
                        ChangeRowView(change: change)
                    }
                    .environment(\.isRowSelected, selection.contains(row.changeID))
                    .tag(row.id)
                }
            }
//            .border(Color.red)
        }
        .onMove { from, to in
            move(from: from, to: to)
        }
        .onChange(of: log.changes) {
            rows = log.makeGraphRows()
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

