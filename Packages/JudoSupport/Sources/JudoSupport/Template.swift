// https://jj-vcs.github.io/jj/latest/templates/

public struct Template: Sendable {
    public var name: String
    public var parameters: [String] = []
    public var content: String

    public var key: String {
        name + (parameters.isEmpty ? "" : "(\(parameters.joined(separator: ",")))")
    }
}
