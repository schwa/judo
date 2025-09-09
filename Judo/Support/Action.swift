import Foundation
import SwiftUI

public protocol ActionProtocol: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var closure: () async throws -> Void { get }
}

extension ActionProtocol {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

protocol PreviewableActionProtocol: ActionProtocol {
    associatedtype Body: View
    var body: Body { get }
}

public struct Action: @MainActor ActionProtocol {
    public let id = UUID()
    public let name: String
    public let closure: () async throws -> Void

    public init(name: String, closure: @escaping () async throws -> Void) {
        self.name = name
        self.closure = closure
    }
}

public struct PreviewableAction <Content>: @MainActor PreviewableActionProtocol where Content: View {
    public let id = UUID()
    public let name: String
    public let closure: () async throws -> Void
    public let body: Content

    public init(name: String, closure: @escaping () async throws -> Void, @ViewBuilder content: () -> Content) {
        self.name = name
        self.closure = closure
        self.body = content()
    }
}

// MARK: -

public enum Status {
    case waiting
    case success(any ActionProtocol)
    case failure(any ActionProtocol, Error)
}

public extension Status {
    var actionID: UUID? {
        switch self {
        case .waiting:
            return nil

        case .success(let action):
            return action.id

        case .failure(let action, _):
            return action.id
        }
    }

    var action: (any ActionProtocol)? {
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
