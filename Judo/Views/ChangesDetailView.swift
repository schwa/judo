import SwiftUI
import JudoSupport

struct ChangesDetailView: View {

    @State
    var currentIndex: Int = 0

    var changes: [Change]

    var body: some View {
        if changes.isEmpty {
            ContentUnavailableView("", systemImage: "gear", description: Text(""))
        }
        else {
            ChangeDetailView(change: changes[currentIndex])
                .id(changes[currentIndex].id)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button("Previous", systemImage: "chevron.up") {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                    }
                    ToolbarItem(placement: .navigation) {
                        Button("Next", systemImage: "chevron.down") {
                            currentIndex = min(currentIndex + 1, changes.count - 1)
                        }
                    }
                }
        }
    }
}

