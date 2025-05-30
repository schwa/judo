import Observation
import SwiftUI
import Everything

struct ContentView: View {

    @State
    var repository = Repository()

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    ContentView()
}

@Observable
class Repository {
    var path: FSPath = "/Users/schwa/Desktop/Judo"

    var binaryPath: FSPath = "/opt/homebrew/bin/jj"

    init() {
        Task {

            let template = """
            "{\\n"
            ++ "\t'commit_id': " ++ "'" ++ commit_id.shortest() ++ "|" ++ commit_id ++ "'" ++ ",\\n"
            ++ "\t'author.name': " ++ author.name().escape_json() ++ ",\\n"
            ++ "\t'author.email': '" ++ concat(author.email().local(), "@", author.email().domain()) ++ "',\\n"
            ++ "\t'description': " ++ description.escape_json() ++ ",\\n"
            ++ "\t'parents': " ++ parents.map(|c| c.commit_id()).join("|") ++ ",\\n"
            ++ "},\\n"
            """
            .replacingOccurrences(of: "'", with: "\\\"")


            let arguments = ["log", "--no-graph", "--reversed", "--template", template]
            do {
                let output = try Process.checkOutput(launchPath: binaryPath.path, arguments: arguments, currentDirectoryURL: path.url)

                print(try! output.standardOutput!.readString())
            }
            catch {
//                print("Error: \(error)")
            }
        }

    }
}

extension Process.Output {
    func readString() throws -> String {
        String(data: try read(), encoding: .utf8)!
    }
}
