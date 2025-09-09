import JudoSupport
import SwiftUI

struct DiffStatView: View {

    let change: Change

    init(change: Change) {
        self.change = change
    }

    var body: some View {
        if change.totalAdded == 0 && change.totalRemoved == 0 && change.isEmpty {
            Text("empty")
                .padding(.vertical, 2)
                .padding(.leading, 4)
                .padding(.trailing, 2)
                .foregroundStyle(.white)
            //            .background(Color.red.mix(with: Color.green, by: 0.5), in: Capsule())
                .background(Color.orange, in: Capsule())
                .font(.caption)
        } else {
            HStack(spacing: 0) {
                Text("+\(change.totalAdded, format: .number)")
                    .padding(.vertical, 2)
                    .padding(.leading, 4)
                    .padding(.trailing, 2)
                    .background(.green)
                    .fixedSize()
                Text("-\(change.totalRemoved, format: .number)")
                    .padding(.vertical, 2)
                    .padding(.leading, 2)
                    .padding(.trailing, 4)
                    .background(.red)
                    .fixedSize()
            }
            .monospaced()
            .foregroundStyle(.white)
            //        .font(.caption2)
            //        .background(.green)
            .clipShape(Capsule())
            .font(.caption)
        }
    }
}
