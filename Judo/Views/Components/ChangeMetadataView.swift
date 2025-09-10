import JudoSupport
import SwiftUI

struct ChangeMetadataMinimalView: View {
    let change: Change

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                IDView(change.changeID, variant: .changeID)
                Divider()
                IDView(change.commitID, variant: .commitID)
                Divider()
                SignatureMinimalView(signature: change.author)
            }
            .fixedSize(horizontal: false, vertical: true)
            Text(change.description.split(separator: "\n").first ?? "")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(change.description.isEmpty ? .secondary : .primary)
        }
    }
}

struct ChangeMetadataFullView: View {
    let change: Change

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                IDView(change.changeID, variant: .changeID)
                Divider()
                IDView(change.commitID, variant: .commitID)
                Divider()
                DiffStatView(change: change)
            }
            .fixedSize(horizontal: false, vertical: true)
            SignatureView(signature: change.author, options: .all)
            ChangeDescriptionView(change: change)
        }
    }
}


#Preview {
    VStack {
        ChangeMetadataMinimalView(change: .example)
            .padding()
            .border(Color.red)

        ChangeMetadataFullView(change: .example)
            .padding()
            .border(Color.red)

        Spacer()
    }
}
