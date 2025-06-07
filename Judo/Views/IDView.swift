import SwiftUI
import JudoSupport

struct IDView: View {
    let id: JujutsuID
    let variant: JujutsuID.Variant

    @Environment(\.isRowSelected)
    private var isRowSelected: Bool

    init(_ id: JujutsuID, variant: JujutsuID.Variant) {
        self.id = id
        self.variant = variant
    }

    var body: some View {
        Text(id.shortAttributedString(variant: variant, style: isRowSelected ? .plain : .shortestHighlighted)).monospaced().textSelection(.enabled).fixedSize()

    }
}

