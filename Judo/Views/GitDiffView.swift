import SwiftUI

struct GitDiffingView: View {
    let data: Data

    @State
    private var raw: Bool = false

    @State
    private var diff: Diff?

    var body: some View {
        Group {
            if raw == false, let diff {
//                GitDiffView(parsedDiff: diff)
                Color.red
            } else {
                let s = String(data: data, encoding: .utf8)!
                ScrollView {
                    Text(verbatim: s)
                        .monospaced()
                        .textSelection(.enabled)
                }
            }
        }
        .onChange(of: data, initial: true) {
            let s = String(data: data, encoding: .utf8)!
            diff = GitDiffParser.parse(diffText: s)
        }
        .toolbar {
            Toggle("Raw", isOn: $raw)
        }
    }
}

struct GitDiffView: View {
    var parsedDiff: Diff

    var body: some View {
        List {
            ForEach(Array(parsedDiff.files.indices), id: \.self) { fileIndex in
                let file = parsedDiff.files[fileIndex]

                Section {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(file.hunks.indices, id: \.self) { hunkIndex in
                            let hunk = file.hunks[hunkIndex]
                            Text(hunk.header)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)

                            ForEach(hunk.changes.indices, id: \.self) { changeIndex in
                                LineChangeView(change: hunk.changes[changeIndex])
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                header: {
                    Text("\(file.oldPath) → \(file.newPath)")
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
                //                footer: {
                //                    EmptyView()
                //                }
            }
        }
    }
}

struct LineChangeView: View {
    let change: LineChange

    var body: some View {
        HStack(spacing: 4) {
            Text(prefixSymbol)
                .frame(width: 20, alignment: .trailing)
                .foregroundColor(prefixColor)
            Text(change.content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .background(backgroundColor)
    }

    private var prefixSymbol: String {
        switch change.type {
        case .addition: return "+"
        case .deletion: return "-"
        case .unchanged: return " "
        }
    }

    private var prefixColor: Color {
        switch change.type {
        case .addition: return .green
        case .deletion: return .red
        case .unchanged: return .secondary
        }
    }

    private var backgroundColor: Color {
        switch change.type {
        case .addition: return Color.green.opacity(0.1)
        case .deletion: return Color.red.opacity(0.1)
        case .unchanged: return Color.clear
        }
    }
}
