import SwiftUI
import UniformTypeIdentifiers

struct CopyButton <Label, Value>: View where Label: View, Value: Transferable & Sendable {
    var value: Value
    var label: Label

    init(value: Value, @ViewBuilder label: () -> Label) {
        self.value = value
        self.label = label()
    }

    var body: some View {
        Button {
            Task {
                try! await copy()
            }
        }
        label: {
            label
        }
    }

    func copy() async throws {
        let value = value
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        for type in value.exportedContentTypes() {
            print(UTType.plainText.identifier, type.identifier)
            let data = try await value.exported(as: type)
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(rawValue: type.identifier))
        }
        if value.exportedContentTypes().contains(.json) {
            let jsonData = try await value.exported(as: .json)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            pasteboard.setString(jsonString, forType: .string)
        }
    }
}

extension CopyButton where Label == SwiftUI.Label<Text, Image> {
    init(_ text: String, value: Value) {
        self.init(value: value) {
            SwiftUI.Label(text, systemImage: "doc.on.doc")
        }
    }

    init(value: Value) {
        self.init(value: value) {
            SwiftUI.Label("Copy", systemImage: "doc.on.doc")
        }
    }
}
