import Observation
import JudoSupport
import SwiftUI
import Collections
import System

@Observable
class RepositoryViewModel {
    var repository: Repository
    var jujutsu: Jujutsu
    var currentLog: RepositoryLog = RepositoryLog()

    init(jujutsu: Jujutsu, path: FilePath) {
        self.jujutsu = jujutsu
        self.repository = Repository(path: path)
    }
    
    func refreshLog() async throws {
        currentLog = try await repository.log(jujutsu: jujutsu, revset: currentLog.revset ?? "")
    }
    
    func log(revset: String) async throws {
        currentLog = try await repository.log(jujutsu: jujutsu, revset: revset)
    }
}

extension FocusedValues {
    @Entry
    var repositoryViewModel: RepositoryViewModel?
}

