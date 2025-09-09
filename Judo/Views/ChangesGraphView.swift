import JudoSupport
import SwiftUI

struct ChangesGraphView: View {
    @Binding
    var selection: Set<ChangeID>

    @Environment(RepositoryViewModel.self)
    var repositoryViewModel

    var body: some View {
        List(repositoryViewModel.repository.currentLog.changes.values, selection: $selection) { change in
            IDView(change.changeID, variant: .changeID)
        }
    }
}
