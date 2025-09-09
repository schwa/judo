import SwiftUI
import System
import JudoSupport

struct DebugSettingsView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Environment") {
                    DebugEnviromentView()
                }
                NavigationLink("Pasteboard") {
                    PasteboardView()
                }
                //                NavigationLink("Paths") {
                //                    DebugPathView()
                //                }
            }
        } detail: {

        }



    }
}

struct DebugEnviromentView: View {
    @State
    var environmentVariables: [(key: String, value: String)] = []

    enum Source: Hashable {
        case process
        case shell
    }

    @State
    var source: Source = .process

    var body: some View {
        VStack {
            Picker("Source", selection: $source) {
                Text("Process").tag(Source.process)
                Text("Shell").tag(Source.shell)
            }
            .pickerStyle(.segmented)
            List {
                ForEach(environmentVariables, id: \.key) { key, value in
                    LabeledContent(key, value: value)
                }
            }
        }
        .onChange(of: source, initial: true) {
            switch source {
            case .process:
                environmentVariables = ProcessInfo.processInfo.environment
                    .sorted { $0.key < $1.key }
                    .map { ($0.key, $0.value) }
            case .shell:

                Task {
                    let result = try! await run(.path(FilePath("env")), useShell: true)
                    guard let output = result.standardOutput else {
                        return
                    }
                    let pattern = #/^(?<key>.+)=(?<value>.+)$/#

                    environmentVariables = output.lines.compactMap { line in
                        guard let match = line.wholeMatch(of: pattern) else {
                            return nil
                        }
                        let key = String(match.key)
                        let value = String(match.value)
                        return (key, value)
                    }
                    .sorted { $0.key < $1.key }
                }
            }
        }

    }
}

extension String {
    var lines: [String] {
        self.split(whereSeparator: \.isNewline).map { String($0) }
    }
}

struct PasteboardView: View {

    @State
    private var pasteboardChangeCount: Int?

    @State
    private var pasteboardItems: [NSPasteboardItem]?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
            Group {
                if let pasteboardChangeCount, let pasteboardItems {
                    Text("\(pasteboardChangeCount)")

                    List {
                        ForEach(Array(pasteboardItems.enumerated()), id: \.offset) { index, item in
                            Section("\(index)") {
                                LabeledContent("Types") {
                                    Text("\(item.types.map(\.rawValue).joined(separator: ", "))")
                                }
                                if let string = item.string(forType: .string) {
                                    LabeledContent("String") {
                                        Text(string)
                                    }
                                }
                                if let url = item.string(forType: .fileURL) {
                                    LabeledContent("URL") {
                                        Text("\(url)")
                                    }
                                }
                            }

                        }
                    }
                }
            }
            .onChange(of: timeline.date, initial: true) {
                let pasteboard = NSPasteboard.general
                if pasteboard.changeCount != pasteboardChangeCount {
                    pasteboardChangeCount = NSPasteboard.general.changeCount
                    pasteboardItems = NSPasteboard.general.pasteboardItems
                }
            }
        }
    }
}


//struct DebugPathView: View {
//
//    @State
//    var paths: [String] = []
//
//    init() {
//    }
//
//    var body: some View {
//        List(Array(paths.enumerated()), id: \.offset) { offset, path in
//            Text(path)
//        }
//        .task {
//            let result = try! await run(.path(FilePath("")), arguments: ["printenv PATH"])
//            paths = result.standardOutput?.lines ?? ["oops?"]
//        }
//    }
//}
