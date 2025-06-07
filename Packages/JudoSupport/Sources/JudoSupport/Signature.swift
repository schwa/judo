import Foundation

public struct Signature: Decodable, Equatable, Sendable {
    public var name: String
    public var email: String?
    public var timestamp: Date

    // TODO: This can outout just "@" if email is empty
    public static let template = Template(name: "JUDO_SIGNATURE", parameters: ["p"], content: """
        "{"
        ++ "'name': " ++ p.name().escape_json()
        ++ ", " ++ "'email': '" ++ p.email().local() ++ "@" ++ p.email().domain() ++ "'"
        ++ ", 'timestamp': '" ++ p.timestamp().format("%Y-%m-%dT%H:%M:%S%z") ++ "'"
        ++ "}"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}
