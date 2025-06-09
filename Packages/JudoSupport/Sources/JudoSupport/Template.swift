// https://jj-vcs.github.io/jj/latest/templates/

public struct Template: Sendable {
    public var name: String
    public var parameters: [String]
    public var content: String

    public init(name: String, parameters: [String] = [], content: String) {
        self.name = name
        self.parameters = parameters
        self.content = content
    }

    public var key: String {
        name + (parameters.isEmpty ? "" : "(\(parameters.joined(separator: ",")))")
    }
}

