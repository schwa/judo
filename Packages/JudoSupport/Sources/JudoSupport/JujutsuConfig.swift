public struct JujutsuConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case templates
        case templateAliases = "template-aliases"
    }

    public var templates: [String: String] = [:]
    public var templateAliases: [String: String] = [:]
}
