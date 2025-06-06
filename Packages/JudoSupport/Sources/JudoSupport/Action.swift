public struct Action {
    public let name: String
    public let closure: () async throws -> Void

    public init(name: String, closure: @escaping () async throws -> Void) {
        self.name = name
        self.closure = closure
    }
}

public enum Status {
    case waiting
    case success(Action)
    case failure(Action, Error)
}

