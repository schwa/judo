import Collections
import SwiftUI
import JudoSupport

struct InspectorView: View {
    @Environment(Repository.self)
    var repository

    @State
    private var changeIndex: Int = 0

    var changes: OrderedDictionary<ChangeID, Change>

    var selectedChanges: [Change]

    var body: some View {
        VStack {
            Text("Change \(changeIndex + 1) of \(selectedChanges.count)")
            if let change = selectedChanges.first {
                ChangeDetailView(changes: changes, change: change)
            }
        }
    }
}
