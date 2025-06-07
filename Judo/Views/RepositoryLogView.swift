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
        VStack {
        let laneCount = rows.reduce(0) { max($0, $1.nextLanes.count) }
            List(selection: $selection) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if let change = log.changes[row.changeID] {
                        let lastRow = index > 0 ? rows[index - 1] : nil
                        HStack {
                            LanesView(change: change, row: row, lastRow: lastRow, laneCount: laneCount)
                            ChangeRowView(change: change)
                        }
                        .tag(row.id)
                    }
                }
                .onMove { from, to in
                    let from = from.map {
                        log.changes.values[$0]
                    }
                    let to = log.changes.values[to]
                    Task {
                        do {
                            try await repository.rebase(from: from.map(\.changeID), to: to.changeID)
                            //                        try await self.log?.refresh()
                            try await repository.log(revset: log.revset ?? "")
                        }
                        catch {
                            print("Error moving changes: \(error)")
                        }
                    }
                }
            }
            Text("Warning: Timeline graph not 100% working yet.")
                .foregroundStyle(.white)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(.yellow)

        }
        .onChange(of: log.changes) {
            rows = log.makeGraphRows()
        }
    }
}

