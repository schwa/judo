public struct Revset {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ change: ChangeID) {
        self.rawValue = change.description
    }

    public init(all: [Self]) {
        self.rawValue = all.map(\.rawValue).joined(separator: " & ")
    }

    public init(all: [String]) {
        self.init(all: all.map { Self($0) })
    }

    public init(all: [ChangeID]) {
        self.init(all: all.map { Self($0) })
    }

    public init(description: String) {
        // TODO: #9 Escape
        self.rawValue = "description(\"\(description)\")"
    }

    public var string: String {
        rawValue
    }

    public var escaped: String {
        rawValue.escaped()
    }
}

extension Revset: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension Revset: Equatable {
}

extension Revset: Hashable {
}

extension Revset: Sendable {
}
