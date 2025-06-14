import Everything
import SwiftUI

struct ContactView: View {
    let name: String
    let email: String?

    var body: some View {
        ViewThatFits {
            HStack {
                if let email {
                    AvatarIcon(email: email)
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
