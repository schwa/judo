import SwiftUI
import JudoSupport

// TODO: Deprecate
// TODO: Rename to SignatureMinimalView
struct MiniSignatureView: View {
    var signature: Signature

    var body: some View {
        Text("\(signature.name) (\(signature.timestamp, style: .relative))")
            .textSelection(.enabled)
    }
}
