import Everything

public struct FullChangeRecord: Decodable, JutsuTemplateProviding {

    enum CodingKeys: String, CodingKey {
        case changeID = "change_id"
        case diff
    }

    public var changeID: ChangeID
    public var diff: TreeDiff

    public static let template = Template(name: "JUDO_FULL_CHANGE", content: """
        "{"
        ++ "'change_id':" ++ JUDO_ID(change_id) ++ ","
        ++ "'diff':" ++ JUDO_TREE_DIFF(self.diff())
        ++ "}"
    """
    .replacingOccurrences(of: "'", with: "\\\"")
    )
}

public struct TreeDiff: Decodable, JutsuTemplateProviding {
    public var files: [TreeDiffEntry]

    //         ++ "\t'bookmarks': [" ++ bookmarks.map(|c| "'" ++ c ++ "'").join(",") ++ "],\\n"

    public static let template = Template(name: "JUDO_TREE_DIFF", parameters: ["p"], content: """
        "{"
        ++ "'files': [" ++ p.files().map(|c| JUDO_TREE_DIFF_ENTRY(c)).join(",") ++ "]"
        ++ "}"
    """
        .replacingOccurrences(of: "'", with: "\\\"")
    )
}

public struct TreeDiffEntry: Decodable, JutsuTemplateProviding {
    public enum Status: String, Decodable {
        case modified
        case added
        case removed
        case copied
        case renamed
    }

    public var path: String
    public var status: Status
    public var source: TreeEntry
    public var target: TreeEntry

    public static let template = Template(name: "JUDO_TREE_DIFF_ENTRY", parameters: ["p"], content: """
        "{"
        ++ "'path':" ++ p.path().display().escape_json() ++ ","
        ++ "'status':" ++ p.status().escape_json() ++ ","
        ++ "'source':" ++ JUDO_TREE_ENTRY(p.source()) ++ ","
        ++ "'target':" ++ JUDO_TREE_ENTRY(p.target()) ++ ","
        ++ "}"
        """
        .replacingOccurrences(of: "'", with: "\\\"")
    )
}

public struct TreeEntry: Decodable, JutsuTemplateProviding {

    public enum FileType: String, Decodable {
        case file
        case symlink
        case tree
        case gitSubmodule = "git-submodule"
        case conflict
        case unknown = ""
    }


    public var path: String
    public var conflict: Bool
    public var fileType: FileType
    public var executable: Bool

    enum CodingKeys: String, CodingKey {
        case path
        case conflict
        case fileType = "file_type"
        case executable
    }

    public static let template = Template(name: "JUDO_TREE_ENTRY", parameters: ["p"], content: """
        "{"
        ++ "'path':" ++ p.path().display().escape_json() ++ ","
        ++ "'conflict':" ++ p.conflict() ++ ","
        ++ "'file_type':" ++ p.file_type().escape_json() ++ ","
        ++ "'executable':" ++ p.executable() ++ ","
        ++ "}"
        """
        .replacingOccurrences(of: "'", with: "\\\"")
    )
}

public extension Repository {
    func fullChange(change: ChangeID) async throws -> FullChangeRecord {
        do {
            let arguments = ["--no-graph", "-r", change.description]
            let changes: [FullChangeRecord] = try await fetch(subcommand: "log", arguments: arguments)
            return changes[0]
        }
        catch {
            logger?.error(error)
            throw error
        }
    }
}

