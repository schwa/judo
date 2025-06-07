import SwiftUI

public typealias ChangeID = ChangeIDOld_

public struct ChangeIDOld_: Hashable, Decodable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    // TODO: This is ephemeral and can change as repositories are updated.
    public let shortest: String?

    public init(rawValue: String, shortest: String? = nil) {
        self.rawValue = rawValue
        self.shortest = shortest
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        let regex = #/^(\[(?<shortest>[a-z0-9]+)\])?(?<remaining>[a-z0-9]+)$/#
        guard let match = try regex.firstMatch(in: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ChangeID format")
        }

        let shortest = match.output.shortest
        let remaining = match.output.remaining

        self.shortest = shortest.map(String.init)
        self.rawValue = String(remaining)
    }

    public func shortAttributedString(style: JujutsuID.Style) -> AttributedString {
        return AttributedString(short(4))
    }

    public func short(_ count: Int = 8) -> String {
        return String(rawValue.prefix(count))
    }

    public var description: String {
        return short(4)
    }

    public init(stringLiteral value: String) {
        rawValue = value
        shortest = nil
    }
}
