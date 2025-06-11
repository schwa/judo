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
        HStack(spacing: 6) {
            switch status {
            case .waiting:
                Label("Ready", systemImage: "clock")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.secondary)
                    .padding(6)

            case .success(let action):
                Label(action.name, systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.green)
                    .padding(6)
                    .help("Success: \(action.name)")
            
            case .failure(let action, _):
                Button {
                    isPopoverPresented.toggle()
                } label: {
                    Label("\(action.name) failed ", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .scaleEffect(animateFailure ? 1.333 : 1.0)
                        .padding(6)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isPopoverPresented) {
                    statusPopover
                }
            }
        }
        .onChange(of: status.action, initial: true) {
            if case .failure = status {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                    animateFailure = true
                }
                animateFailure = false
            }
        }
    }

    @ViewBuilder
    var statusPopover: some View {
        if case let .failure(_, error) = status {
            Form {
                switch error {
//                case let error as SimpleAsyncProcess.Error:
//                    LabeledContent("ExitCode", value: error.exitCode, format: .number)
//                    LabeledContent("stderr") {
//                        Text(error.stderr)
//                            .monospaced()
//                    }
//
                default:
                    Text("\(error.localizedDescription)")
                }
            }
            .padding()
        }
    }
}

struct DummyError: LocalizedError {
    var errorDescription: String? { "Dummy failure" }
}

#Preview("StatusView – Waiting") {
    StatusView(status: .constant(.waiting))
        .padding()
}

#Preview("StatusView – Success") {
    StatusView(status: .constant(.success(.init(name: "Build", closure: {}))))
        .padding()
}

#Preview("StatusView – Failure") {
    StatusView(status: .constant(.failure(.init(name: "Run", closure: {}), DummyError())))
        .padding()
}
