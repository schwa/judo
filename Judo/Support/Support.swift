import Collections
import SwiftUI

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
