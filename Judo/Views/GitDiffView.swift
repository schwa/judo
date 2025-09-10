import SwiftUI
import JudoSupport

struct GitDiffingView: View {
    let data: Data

    @State
    private var raw: Bool = false

    @State
    private var diff: Diff?

    var body: some View {
        Group {
            if raw == false, let diff {
                GitDiffView(parsedDiff: diff)
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
                FileChangeView(file: file)
            }
        }
    }
}

struct FileChangeView: View {
    var file: FileDiff

    var body: some View {
        VStack {
            FileChangeHeaderView(file: file)
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(file.hunks) { hunk in
                    Text(hunk.header)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)

                    var oldLineNumber = hunk.oldStart
                    var newLineNumber = hunk.newStart
                    
                    let changesWithLineNumbers = hunk.changes.enumerated().map { offset, change in
                        let id = "\(hunk.id)#\(offset)"
                        let lineNumbers = (old: oldLineNumber, new: newLineNumber)
                        
                        // Update line numbers based on change type
                        switch change.type {
                        case .addition:
                            newLineNumber += 1
                        case .deletion:
                            oldLineNumber += 1
                        case .unchanged:
                            oldLineNumber += 1
                            newLineNumber += 1
                        }
                        
                        return (id, lineNumbers, change)
                    }

                    ForEach(changesWithLineNumbers, id: \.0) { _, lineNumbers, change in
                        LineChangeView(oldLine: lineNumbers.old, newLine: lineNumbers.new, change: change)
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
}

struct FileChangeHeaderView: View {

    var file: FileDiff

    var body: some View {
        Text("\(file.oldPath) → \(file.newPath)")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.blue)
            .foregroundColor(.white)

    }
}

struct LineChangeView: View {
    let oldLine: Int
    let newLine: Int
    let change: LineChange

    var body: some View {
        HStack(spacing: 4) {
            Group {
                if change.type != .addition {
                    Text("\(oldLine)")
                }
                else {
                    Color.clear
                }
            }
            .frame(width: 40, alignment: .trailing)
            Divider()
            Group {
                if change.type != .deletion {
                    Text("\(newLine)")
                }
                else {
                    Color.clear
                }
            }
            .frame(width: 40, alignment: .trailing)
            Divider()
            Text(prefixSymbol)
                .frame(width: 20, alignment: .trailing)
                .foregroundColor(prefixColor)
            Text(change.content)
                .lineLimit(1)
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

extension Hunk: @retroactive Identifiable {
    public var id: String {
        "\(oldStart),\(oldCount)-\(newStart),\(newCount)"
    }
}
