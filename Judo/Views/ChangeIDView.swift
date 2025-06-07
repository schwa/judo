import SwiftUI
import JudoSupport

extension Color {
    static let magenta = Color(nsColor: .magenta)
}

extension AttributedString {
    func modifying(_ modifier: (inout AttributedString) -> Void) -> AttributedString {
        var modified = self
        modifier(&modified)
        return modified
    }
}

