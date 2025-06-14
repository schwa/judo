import Collections
import os
import SwiftUI

let logger: Logger? = Logger()

extension Dictionary {
    init(_ orderedDictionary: OrderedDictionary<Key, Value>) {
        self.init(uniqueKeysWithValues: Array(orderedDictionary))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: String, paddedTo length: Int, pad: Character = " ") {
        let padCount = max(0, length - value.count)
        let padded = value + String(repeating: pad, count: padCount)
        appendLiteral(padded)
    }
}

extension Path {
    static func wire(from: CGPoint, to: CGPoint) -> Path {
        Path { path in
            path.move(to: from)

            let midY = (from.y + to.y) / 2

            // Control points for a smooth S curve
            path.addCurve(
                to: to,
                control1: CGPoint(x: from.x, y: midY),
                control2: CGPoint(x: to.x, y: midY)
            )
        }
    }
}

extension AttributedString {
    func modifying(_ modifier: (inout AttributedString) -> Void) -> AttributedString {
        var modified = self
        modifier(&modified)
        return modified
    }
}

extension EnvironmentValues {
    @Entry
    var isRowSelected: Bool = false
}

extension String {
    func quoted(smart: Bool = true) -> String {
        guard !containsTopLevelQuotes() else {
            return smart ? replacingStraightQuotesWithCurly() : self
        }

        return smart ? "“\(self)”" : "\"\(self)\""
    }

    private func containsTopLevelQuotes() -> Bool {
        hasPrefix("\"") && hasSuffix("\"") || hasPrefix("“") && hasSuffix("”")
    }

    private func replacingStraightQuotesWithCurly() -> String {
        var result = ""
        var insideQuote = false
        var i = startIndex

        while i < endIndex {
            let char = self[i]
            if char == "\"" {
                result.append(insideQuote ? "”" : "“")
                insideQuote.toggle()
            } else {
                result.append(char)
            }
            i = index(after: i)
        }

        return result
    }
}

extension Data {
    func wrapped(prefix: String, suffix: String) -> Data {
        let prefixData = prefix.data(using: .utf8) ?? Data()
        let suffixData = suffix.data(using: .utf8) ?? Data()
        return prefixData + self + suffixData
    }
}
