import JudoSupport
import SwiftUI

struct SignatureView: View {

    struct Options: OptionSet {
        let rawValue: Int

        static let showName = Options(rawValue: 1 << 0)
        static let showEmail = Options(rawValue: 1 << 1)
        static let showTimestamp = Options(rawValue: 1 << 2)
        static let showAvatar = Options(rawValue: 1 << 3)
        static let all: Options = [.showName, .showEmail, .showTimestamp, .showAvatar]
    }

    var signature: Signature
    var options: Options = Options.all

    var body: some View {
        HStack {
            if options.contains(.showAvatar), let email = signature.email {
                AvatarIcon(email: email)
                    .frame(maxHeight: 18)
            }
            VStack(alignment: .leading) {
                HStack {
                    if options.contains(.showName) {
                        Text(verbatim: signature.name)
                            .bold()
                    }
                    if options.contains(.showEmail), let email = signature.email {
                        Text(verbatim: email)
                            .foregroundStyle(.secondary)
                    }
                }
                if options.contains(.showTimestamp) {
                    Text(signature.timestamp, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .textSelection(.enabled)

//        Text("\(signature.name) (\(signature.timestamp, style: .relative))")
    }
}


struct SignatureMinimalView: View {
    var signature: Signature

    var body: some View {
        SignatureView(signature: signature, options: [.showName] )
    }
}

#Preview {
    VStack {
        SignatureView(signature: .example, options: [.all])
            .padding()
            .border(Color.red)

        SignatureView(signature: .example, options: [.showName, .showEmail])
            .padding()
            .border(Color.red)

        SignatureMinimalView(signature: .example)
            .padding()
            .border(Color.red)

        Spacer()
    }
}
