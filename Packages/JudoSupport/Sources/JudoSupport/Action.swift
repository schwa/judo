import Foundation

public struct Action: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let closure: () async throws -> Void

    public init(name: String, closure: @escaping () async throws -> Void) {
        self.name = name
        self.closure = closure
    }

    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
}

public enum Status {
    case waiting
    case success(Action)
    case failure(Action, Error)
}

public extension Status {
    var action: Action? {
        switch self {
        case .waiting:
            return nil
        case .success(let action):
            return action
        case .failure(let action, _):
            return action
        }
    }
}

