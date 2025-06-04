import SwiftUI

struct CommitGraphRowView: View {
    let row: GraphRow

    var body: some View {
        Grid {
            GridRow {
                ForEach(0..<lanes.count, id: \.self) { index in
                    Text(symbol(at: index))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 12, alignment: .center)
                }
            }
        }
    }

    private var lanes: [ChangeID?] {
        switch row {
        case .commit(_, _, let lanes),
             .elision(_, let lanes):
            return lanes
        }
    }

    private func symbol(at index: Int) -> String {
        switch row {
        case let .commit(commit, column, _):
            if index == column {
                return "•"
            } else if lanes[index] != nil {
                return "|"
            } else {
                return " "
            }

        case .elision(_, _):
            return lanes[index] != nil ? "|" : " "
        }
    }
}

func partialTopologicalSort(commits: [ChangeID: CommitRecord]) -> [CommitRecord] {
    var visited = Set<ChangeID>()
    var result: [CommitRecord] = []
    func visit(_ id: ChangeID) {
        guard !visited.contains(id), let commit = commits[id] else { return }
        visited.insert(id)
        for parent in commit.parents {
            if commits[parent] != nil {
                visit(parent)
            }
        }
        result.append(commit)
    }
    for commit in commits.values {
        visit(commit.id)
    }
    return result.reversed()
}

enum GraphRow {
    case commit(commit: CommitRecord, column: Int, lanes: [ChangeID?])
    case elision(parents: [ChangeID], lanes: [ChangeID?])
}

func buildGraphRows(from sortedCommits: [CommitRecord], allCommits: [ChangeID: CommitRecord]) -> [GraphRow] {
    var rows: [GraphRow] = []
    var lanes: [ChangeID?] = []

    for commit in sortedCommits {
        // Find or assign column for this commit
        let column: Int
        if let idx = lanes.firstIndex(where: { $0 == commit.id }) {
            column = idx
        } else {
            column = lanes.count
            lanes.append(commit.id)
        }

        // Emit the commit row
        rows.append(.commit(commit: commit, column: column, lanes: lanes))

        // Replace the current commit with its parents (or remove if no parents)
        lanes[column] = nil // will be replaced or removed

        var phantomParents: [ChangeID] = []

        for parent in commit.parents {
            if allCommits[parent] != nil {
                // Parent is known: add to lanes if not already there
                if !lanes.contains(parent) {
                    if let emptySlot = lanes.firstIndex(of: nil) {
                        lanes[emptySlot] = parent
                    } else {
                        lanes.append(parent)
                    }
                }
            } else {
                // Parent is missing: phantom
                phantomParents.append(parent)
            }
        }

        // Emit elision row if there are phantom parents
        if !phantomParents.isEmpty {
            rows.append(.elision(parents: phantomParents, lanes: lanes))
        }

        // If the commit has no parents and isn’t referenced again, clean up
        if commit.parents.isEmpty || !lanes.contains(commit.id) {
            lanes[column] = nil
        }
    }

    return rows
}
