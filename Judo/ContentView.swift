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
                ChangeIDView(changeID: commit.change_id)
                Text(commit.author_name)
                    .foregroundStyle(.secondary)
                Text(commit.author_email)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(commit.description)
                    
            }


        }
    }
}

#Preview {
    ContentView()
}

@Observable
class Repository {
    var path: FSPath = "/Users/schwa/Projects/Ultraviolence"

    var binaryPath: FSPath = "/opt/homebrew/bin/jj"

    var commits: [CommitRecord] = []

    init() {
        Task {

            let temporaryConfig = JujutsuConfig(templateAliases: ["JudoCommitRecord": CommitRecord.template])
            // write to temp directory
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempConfigPath = tempDirectory.appending(path: "judo_jj_config.toml")
            print(tempConfigPath)

            let d = try TOMLEncoder().encode(temporaryConfig).write(toFile: tempConfigPath.path, atomically: true, encoding: .utf8)

            let arguments = ["log", "--no-graph", "-r", "all()", "--template", "JudoCommitRecord", "--config-file", tempConfigPath.path]
            print("jj \(arguments.joined(separator: " "))")
            do {
                print("Fetching...")



                let process = SimpleAsyncProcess(executableURL: binaryPath.url, arguments: arguments, currentDirectoryURL: path.url)
                let data = try await process.run()

                let header = "[\n".data(using: .utf8)!
                let footer = "\n]".data(using: .utf8)!
                let jsonData = header + data + footer
                let jsonString = String(data: jsonData, encoding: .utf8)!
//                print(jsonString)

                let decoder = JSONDecoder()
                decoder.allowsJSON5 = true



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

struct CommitRecord: Identifiable, Decodable {

    var id: String { commit_id }

    var change_id: ChangeID
    var commit_id: String
    var author_name: String
    var author_email: String
    var description: String
    var parents: [String]

    static let template = """
        "{\\n"
        ++ "\t'change_id': " ++ "'[" ++ change_id.shortest() ++ "]" ++ change_id ++ "'" ++ ",\\n"
        ++ "\t'commit_id': " ++ "'[" ++ commit_id.shortest() ++ "]" ++ commit_id ++ "'" ++ ",\\n"
        ++ "\t'author_name': " ++ author.name().escape_json() ++ ",\\n"
        ++ "\t'author_email': '" ++ concat(author.email().local(), "@", author.email().domain()) ++ "',\\n"
        ++ "\t'description': " ++ description.escape_json() ++ ",\\n"
        ++ "\t'parents': [" ++ parents.map(|c| "'" ++ c.commit_id() ++ "'").join("|") ++ "],\\n"
        ++ "},\\n"
        """
        .replacingOccurrences(of: "'", with: "\\\"")
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
