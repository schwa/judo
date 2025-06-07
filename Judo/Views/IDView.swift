import SwiftUI
import JudoSupport

struct IDView: View {
    let id: JujutsuID
    let style: JujutsuID.Style

    init(_ id: JujutsuID, style: JujutsuID.Style) {
        self.id = id
        self.style = style
    }

    var body: some View {
        Text(id.shortAttributedString(style: style)).monospaced().textSelection(.enabled).fixedSize()
    }
}
