import Collections
import SwiftUI

struct InspectorView: View {
    @Environment(Repository.self)
    var repository

    @State
    private var commitIndex: Int = 0

    var commits: OrderedDictionary<ChangeID, CommitRecord>

    var selectedCommits: [CommitRecord]

    var body: some View {
        VStack {
            Text("Commit \(commitIndex + 1) of \(selectedCommits.count)")
            if let commit = selectedCommits.first {
                CommitDetailView(commits: commits, commit: commit)
            }
        }
    }
}
