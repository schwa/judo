import JudoSupport
import SwiftUI

struct StatusView: View {
    @Binding
    var status: Status

    @State
    private var isPopoverPresented: Bool = false

    @State
    private var animateFailure: Bool = false

    var body: some View {
        Group {
            switch status {
            case .waiting:
                Text("Ready…")
                    .controlSize(.small)

            case .success(let action):
                Text("Success: \(action.name)")
                    .controlSize(.small)

            case .failure(let action, _):
                HStack {
                    Text("Failed: \(action.name)")
                    Toggle(isOn: $isPopoverPresented) {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .controlSize(.small)
            }
        }
        .scaleEffect(animateFailure ? 1.333 : 1.0)
        .onChange(of: status.action, initial: true) {
            if case .failure = status {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                    animateFailure = true
                }
                animateFailure = false
            }
        }
        .popover(isPresented: $isPopoverPresented) {
            statusPopover
        }
    }

    @ViewBuilder
    var statusPopover: some View {
        if case let .failure(_, error) = status {
            Form {
                switch error {
                case let error as SimpleAsyncProcess.Error:
                    LabeledContent("ExitCode", value: error.exitCode, format: .number)
                    LabeledContent("stderr") {
                        Text(error.stderr)
                            .monospaced()
                    }

                default:
                    Text("\(error.localizedDescription)")
                }
            }
            .padding()
        }
    }
}
