import SwiftUI
import Collections

struct RepositoryLogView: View {

    @Environment(Repository.self)
    var repository

    @State
    private var head: ChangeID?

    @Binding
    var selection: Set<ChangeID>

    @Binding
    var log: RepositoryLog

    var body: some View {
        let commits: [CommitRecord] = Array(log.commits.values)
        List(selection: $selection) {
            ForEach(commits) { commit in
                HStack {
                    if commit.immutable {
                        Image(systemName: "diamond.fill")
                    } else {
                        if commit.change_id == head {
                            Text("@")
                        } else {
                            Image(systemName: "circle")
                        }
                    }
                    CommitRowView(commit: commit)
                }
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

    }
}

// MARK: -

