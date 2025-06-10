import Collections
import SwiftUI
import JudoSupport

struct MixedModeChangesDetailView: View {
    @Environment(Repository.self)
    var repository

    @State
    private var changeIndex: Int = 0

    var selectedChanges: [Change]

    var body: some View {
        VStack {
            Text("Change \(changeIndex + 1) of \(selectedChanges.count)")
            if let change = selectedChanges.first {
                MixedModeChangeDetailView(change: change)
            }
        }
    }
}
