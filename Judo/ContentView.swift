import Observation
import SwiftUI
import Everything
import TOMLKit

struct ContentView: View {

    @State
    var repository = Repository()

    var body: some View {
        //        TemplateDemoView()
        List(repository.commits, id: \.commit_id) { commit in
            HStack {
                if commit.immutable {
                    Image(systemName: "diamond.fill")
                }
                else {
                    Image(systemName: "circle")

                }

                VStack(alignment: .leading) {
                    HStack {
                        ChangeIDView(changeID: commit.change_id).monospaced()
                        if let email = commit.author.email {
                            Text(email)
                        }
                        Text(commit.author.timestamp, style: .relative)
                            .foregroundStyle(.cyan)
                        if commit.bookmarks.isEmpty == false {
                            Text("\(commit.bookmarks.joined(separator: ", "))")
                                .foregroundStyle(.purple)
                        }
                        if commit.root {
                            Text("root()").italic()
                                .foregroundStyle(.green)
                        }
                        Text(commit.commit_id)
                    }
                    if commit.empty && commit.root == false {
                        Text("(empty)").italic().foregroundStyle(.green)
                    }

                    if commit.description.isEmpty && commit.root == false  {
                        Text("(no description set").italic()
                    }
                    else {
                        Text(commit.description.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }

        }

    }
}

#Preview {
    ContentView()
}

@Observable
class Repository {
    //    var path: FSPath = "/Users/schwa/Projects/Ultraviolence"
    var path: FSPath = "/Users/schwa/Desktop/judo"

    var binaryPath: FSPath = "/opt/homebrew/bin/jj"

    var commits: [CommitRecord] = []

    init() {
        Task {

            let temporaryConfig = JujutsuConfig(templateAliases: [
                CommitRecord.template.key: CommitRecord.template.content,
                Signature.template.key: Signature.template.content,
            ])
            // write to temp directory
            //            let tempDirectory = FileManager.default.temporaryDirectory
            let tempDirectory = URL(fileURLWithPath: "/tmp")
            let tempConfigPath = tempDirectory.appending(path: "judo.toml")
            print(tempConfigPath)

            let d = try TOMLEncoder().encode(temporaryConfig).write(toFile: tempConfigPath.path, atomically: true, encoding: .utf8)

            let arguments = ["log", "--no-graph",
                             "-r", "all()",
                             "--template", CommitRecord.template.name,
                             "--config-file", tempConfigPath.path,
                             //                "--limit", "1"
            ]
            print("jj \(arguments.joined(separator: " "))")
            do {
                print("Fetching...")



                let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: arguments, currentDirectoryURL: path.url)
                let data = try await process.run()

                let header = "[\n".data(using: .utf8)!
                let footer = "\n]".data(using: .utf8)!
                let jsonData = header + data + footer
                let jsonString = String(data: jsonData, encoding: .utf8)!
                print(jsonString)

                let decoder = JSONDecoder()
                decoder.allowsJSON5 = true
                decoder.dateDecodingStrategy = .iso8601



                self.commits = try decoder.decode([CommitRecord].self, from: jsonData)
                print("Done")
                //                print(try! output.standardOutput!.readString())
            }
            catch {
                print("Error: \(error)")
            }
        }

    }
}

extension Process.Output {
    func readString() throws -> String {
        String(data: try read(), encoding: .utf8)!
    }
}

struct ChangeID: Hashable, Decodable {
    let rawValue: String
    let shortest: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        let regex = #/^\[(?<shortest>[a-z0-9]+)\]?(?<remaining>[a-z0-9]+)$/#
        guard let match = try regex.firstMatch(in: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ChangeID format")
        }

        let shortest = match.output.shortest
        let remaining = match.output.remaining

        self.shortest = String(shortest)
        self.rawValue = String(remaining)
    }
}

struct CommitID: Hashable {
    let rawValue: String
    let shortest: String
}

struct ChangeIDView: View {
    var changeID: ChangeID

    var body: some View {
        Text(changeID.rawValue)
    }
}

struct JujutsuConfig: Codable {

    enum CodingKeys: String, CodingKey {
        case templates
        case templateAliases = "template-aliases"
    }

    var templates: [String: String] = [:]
    var templateAliases: [String: String] = [:]
}

// https://jj-vcs.github.io/jj/latest/templates/

struct Template {
    var name: String
    var parameters: [String] = []
    var content: String

    var key: String {
        return name + (parameters.isEmpty ? "" : "(\(parameters.joined(separator: ",")))")
    }
}

struct Signature: Decodable {
    var name: String
    var email: String?
    var timestamp: Date

    static let template = Template(name: "JUDO_SIGNATURE", parameters: ["p"], content: """
        "{"
        ++ "'name': " ++ p.name().escape_json()
        ++ ", " ++ "'email': '" ++ p.email().local() ++ "@" ++ p.email().domain() ++ "'"
        ++ ", 'timestamp': '" ++ p.timestamp().format("%Y-%m-%dT%H:%M:%S%z")
        ++ "'}"
        """.replacingOccurrences(of: "'", with: "\\\"")
    )
}


struct CommitRecord: Identifiable, Decodable {

    var id: String { commit_id }

    var change_id: ChangeID
    var commit_id: String
    var author: Signature
    var description: String
    var root: Bool
    var empty: Bool
    var immutable: Bool
    var parents: [String]
    var bookmarks: [String]

    static let template = Template(name: "judo_commit_record", content: """
        "{\\n"
        ++ "\t'change_id': " ++ "'[" ++ change_id.shortest() ++ "]" ++ change_id ++ "'" ++ ",\\n"
        ++ "\t'commit_id': " ++ "'[" ++ commit_id.shortest() ++ "]" ++ commit_id ++ "'" ++ ",\\n"
        ++ "\t'author': " ++ JUDO_SIGNATURE(author) ++ ",\\n"
        ++ "\t'description': " ++ description.escape_json() ++ ",\\n"
        ++ "\t'root': " ++ root ++ ",\\n"
        ++ "\t'empty': " ++ empty ++ ",\\n"
        ++ "\t'immutable': " ++ immutable ++ ",\\n"
        ++ "\t'parents': [" ++ parents.map(|c| "'" ++ c.commit_id() ++ "'").join("|") ++ "],\\n"
        ++ "\t'bookmarks': [" ++ bookmarks.map(|c| "'" ++ c ++ "'").join("|") ++ "],\\n"
        ++ "},\\n"
        """
        .replacingOccurrences(of: "'", with: "\\\"")
    )
}

struct TemplateDemoView: View {
    @State
    var template: String = ""

    @State
    var revset: String = ""

    @State
    var output: String = ""

    var body: some View {
        VStack {
            TextField("Template", text: $template)
            TextField("Revset", text: $revset)
            Button("Run") {
                run()
            }
            ScrollView {
                Text(output).frame(maxWidth: .infinity).monospaced()
            }

        }
    }

    func run() {
        Task {

            var arguments: [String] = ["log"]

            if !revset.isEmpty {
                arguments.append(contentsOf: ["-r", revset])
            }
            if !template.isEmpty {
                arguments.append(contentsOf: ["--template", template])
            }

            let process = SimpleAsyncProcess(executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/jj"), arguments: arguments, currentDirectoryURL: URL(fileURLWithPath: "/Users/schwa/Projects/Ultraviolence"))
            do {
                let data = try await process.run()
                output = String(data: data, encoding: .utf8) ?? "Failed to decode output"
            } catch {
                output = "Error: \(error)"
            }
        }
    }
}
