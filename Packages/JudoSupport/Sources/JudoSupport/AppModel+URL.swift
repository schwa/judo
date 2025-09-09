import SwiftUI
import Foundation
import System

extension AppModel {
    func handle(_ url: URL) {
        print(url)
        guard url.scheme == "x-judo" else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        //        print(components.host)
        //        print(components.path)
        //        print(components.queryItems)

        //        print(repository)
        let path = FilePath(components.path)
        let openDocument = self.openDocument
        Task {
            try! await openDocument?(path.url)
        }
//        Task {
//            try! await Task.sleep(for: .seconds(1.0))
//            print("AFTER", currentRepository)
//        }
    }
}
