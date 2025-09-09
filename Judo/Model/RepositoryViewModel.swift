import Observation
import JudoSupport
import SwiftUI
import Collections

@Observable
class RepositoryViewModel {
    var repository: Repository
    var currentLog: RepositoryLog = RepositoryLog()

    init(repository: Repository) {
        self.repository = repository
    }
    
    func refreshLog() async throws {
        currentLog = try await repository.log(revset: currentLog.revset ?? "")
    }
    
    func log(revset: String) async throws {
        currentLog = try await repository.log(revset: revset)
    }
}

extension FocusedValues {
    @Entry
    var repositoryViewModel: RepositoryViewModel?
}

