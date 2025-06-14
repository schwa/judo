import SwiftUI
import CoreTransferable

public typealias ChangeID = JujutsuID
public typealias CommitID = JujutsuID

public struct JujutsuID {
    internal let rawValue: String

    // TODO: This is ephemeral and can change as repositories are updated.
    public let shortestPrefixCount: Int?

    public init?(rawValue: String) {
        self.rawValue = rawValue
        self.shortestPrefixCount = nil
    }

    public init(rawValue: String, shortest: String?) {
        self.rawValue = rawValue
        // Assert shortest is part of rawValue if it exists
        if let shortest = shortest {
            precondition(rawValue.hasPrefix(shortest), "Shortest prefix must be a prefix of the raw value")
        }
        self.shortestPrefixCount = shortest?.count
    }
}

extension JujutsuID: Sendable {
}

extension JujutsuID: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension JujutsuID: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        // Match the format: [shortest]remaining
        let regex = #/^((?<shortest>[a-z0-9]+)\|)?(?<full>[a-z0-9]+)$/#
        guard let match = try regex.firstMatch(in: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid id format")
        }
        let shortest = match.output.shortest
        let full = match.output.full
        self.init(rawValue: String(full), shortest: shortest.map(String.init))
    }

    public static let template = Template(name: "JUDO_ID", parameters: ["p"], content: """
        "'" ++ p.shortest() ++ "|" ++ p ++ "'"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}

extension JujutsuID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        rawValue = value
        shortestPrefixCount = nil
    }
}

public extension JujutsuID {
    enum Variant {
        case changeID
        case commitID
    }

    enum Style {
        case plain
        case shortestHighlighted
    }

    func shortAttributedString(variant: Variant, style: Style = .shortestHighlighted) -> AttributedString {

        switch (variant, style, shortestPrefixCount) {
        case (.changeID, .shortestHighlighted, .some):
            return AttributedString(shortest()).modifying {
                $0.foregroundColor = Color.judoShortChangeIDColor
            }
            + AttributedString(rawValue.trimmingPrefix(shortest()).prefix(8 - shortest().count))
        case (.commitID, .shortestHighlighted, .some):
            return AttributedString(shortest()).modifying {
                $0.foregroundColor = Color.judoShortCommitIDColor
            }
            + AttributedString(rawValue.trimmingPrefix(shortest()).prefix(8 - shortest().count))
        default:
            return AttributedString(short())

        }
    }
}

extension JujutsuID: CustomStringConvertible {
    public var description: String {
        return short(4)
    }
}

extension JujutsuID: CustomDebugStringConvertible {
    public var debugDescription: String {
        return rawValue
    }
}

public extension JujutsuID {
    func short(_ count: Int = 8) -> String {
        return String(rawValue.prefix(count))
    }

    func shortest() -> String{
        if let shortestPrefixCount {
            return String(rawValue.prefix(shortestPrefixCount))
        }
        return rawValue
    }
}

// MARK: -

private extension AttributedString {
    func modifying(_ modifier: (inout AttributedString) -> Void) -> AttributedString {
        var modified = self
        modifier(&modified)
        return modified
    }
}

extension JujutsuID: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.rawValue)

    }
}
