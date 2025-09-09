import Everything
import SwiftUI

// TODO: Deprecate
struct ContactView: View {
    let name: String
    let email: String?

    var body: some View {
        ViewThatFits {
            HStack {
                if let email {
                    AvatarIcon(email: email)
                        .frame(maxHeight: 18)
                }
                Text(name)
                    .foregroundStyle(.judoContactColor)
                //                if let email {
                //                    Text(email)
                //                        .foregroundStyle(.secondary)
                //                        .foregroundStyle(.judoContactColor)
                //                }
            }

            Text(email ?? name).fixedSize()
                .foregroundStyle(.judoContactColor)
        }
        .contextMenu {
            if let email {
                CopyButton("Email", value: email)
            }
        }
    }
}
