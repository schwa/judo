import SwiftUI
import JudoSupport

struct ChangesGraphView: View {

    @Binding
    var selection: Set<ChangeID>

    @Environment(Repository.self)
    var repository

    var body: some View {
        List(repository.currentLog.changes.values, selection: $selection) { change in
            IDView(change.changeID, variant: .changeID)
        }
    }
}

