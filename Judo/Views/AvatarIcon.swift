import SwiftUI
import Everything
import System
import JudoSupport

struct AvatarIcon: View {
    var email: String

    static let avatarCache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,  // 50 MB in RAM
        diskCapacity: 200 * 1024 * 1024,   // 200 MB on disk
        diskPath: (FilePath.temporaryDirectory + "AvatarCache").path
    )



    @State
    var image: Image?

    var body: some View {
        ZStack {
            image?.resizable()
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(maxHeight: 18)
        .onChange(of: email, initial: true) {
            guard !email.isEmpty else {
                image = nil
                return
            }
            let url = GravatarFetcher.gravatarURL(for: email)
            let request = URLRequest(url: url)
            if let cachedResponse = Self.avatarCache.cachedResponse(for: request) {
                if let nsImage = NSImage(data: cachedResponse.data) {
                    image = Image(nsImage: nsImage)
                    return
                }
            }
            Task {
                let config = URLSessionConfiguration.default
                config.urlCache = Self.avatarCache
                config.requestCachePolicy = .returnCacheDataElseLoad
                let session = URLSession(configuration: config)
                do {
                    let (data, response) = try await session.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw JudoError.generic("Invalid response for avatar fetch for \(email)")
                    }
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw JudoError.generic("Failed to fetch avatar for \(email): \(httpResponse.statusCode)")
                    }
                    if let nsImage = NSImage(data: data) {
                        image = Image(nsImage: nsImage)
                    }
                } catch {
                    logger?.log("Failed to fetch avatar for \(email): \(error)")
                }
            }
        }
    }
}
