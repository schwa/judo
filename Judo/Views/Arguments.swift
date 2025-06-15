import Foundation
import JudoSupport

// TODO: Experimental

struct Arguments {
    var strings: [String]
}

extension Arguments: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: String...) {
        self.strings = elements
    }
}

extension Arguments {
    static func + (lhs: Arguments, rhs: Arguments) -> Arguments {
        Arguments(strings: lhs.strings + rhs.strings)
    }
    static func + (lhs: Arguments, rhs: some ArgumentsConvertible) -> Arguments {
        Arguments(strings: lhs.strings + rhs.arguments.strings )
    }
}

protocol ArgumentsConvertible {
    var arguments: Arguments { get }
}

extension Revset: ArgumentsConvertible {
    var arguments: Arguments {
        Arguments(strings: [self.rawValue])
    }
}

extension ChangeID: ArgumentsConvertible {
    var arguments: Arguments {
        Arguments(strings: [description]) // TODO: RAWVALUE
    }
}

extension Array: ArgumentsConvertible where Element: ArgumentsConvertible {
    var arguments: Arguments {
        Arguments(strings: self.map(\.arguments).flatMap(\.strings))
    }
}

extension Jujutsu {
    func run<T>(subcommand: String, arguments: Arguments, repository: Repository) async throws -> [T] where T: Decodable {
        let arguments = arguments.strings
        let data = try await run(subcommand: subcommand, arguments: arguments, repository: repository)
            .wrapped(prefix: "[", suffix: "]")
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        return try decoder.decode([T].self, from: data)
    }
}
