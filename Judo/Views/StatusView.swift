import SwiftUI

struct StatusView: View {
    @Binding
    var status: Status

    @State
    var isErrorPresented: Bool = false

    var body: some View {
        Group {
            switch status {
            case .waiting:
                Text("Ready…")
                .controlSize(.small)
            case .success(let action):
                Text("Success: \(action.name)")
                .controlSize(.small)
            case .failure(let action, let error):
                HStack {
                    Text("Failed: \(action.name)")
                    Toggle(isOn: $isErrorPresented) {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.red)
//                        Image(systemName: "exclamationmark.triangle.fill")
//                            .foregroundColor(.yellow)
                    }
                }
                .controlSize(.small)
                .popover(isPresented: $isErrorPresented) {
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
    }
}
