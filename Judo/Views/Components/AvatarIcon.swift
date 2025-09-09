import Everything
import JudoSupport
import SwiftUI
import System

struct AvatarIcon: View {
    var email: String

    static let avatarCache = URLCache(
        memoryCapacity: 50 * 1_024 * 1_024,  // 50 MB in RAM
        diskCapacity: 200 * 1_024 * 1_024,   // 200 MB on disk
        diskPath: (FilePath.temporaryDirectory + "AvatarCache").path
    )

    @State
    private var image = Image(systemName: "person.crop.circle")

    var body: some View {
        ZStack {
            image.resizable()
        }
        .aspectRatio(1.0, contentMode: .fit)
        .onChange(of: email, initial: true) {
            guard !email.isEmpty else {
                image = Image(systemName: "person.crop.circle")
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

#Preview {
    AvatarIcon(email: "test1@example.com")
        .frame(width: 64, height: 64)
        .border(Color.red)
    AvatarIcon(email: "random@notarealdomain.com")
        .frame(width: 64, height: 64)
        .border(Color.red)
}
