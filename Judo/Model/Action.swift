struct Action {
    let name: String

    let closure: () async throws -> Void
}

enum Status {
    case waiting
    case success(Action)
    case failure(Action, Error)
}

