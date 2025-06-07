import SwiftUI

struct AuthorView: View {
    let name: String
    let email: String?

    @State
    var avatarImage: Image?

    var body: some View {
        HStack {
            avatarImage?.resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxHeight: 18)

            Text(name)
                .font(.headline)
            if let email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: email, initial: true) {
            if let email, !email.isEmpty {
                let url = GravatarFetcher.gravatarURL(for: email)
                Task {
                    let avatarCache = URLCache(
                        memoryCapacity: 50 * 1024 * 1024,  // 50 MB in RAM
                        diskCapacity: 200 * 1024 * 1024,   // 200 MB on disk
                        diskPath: "AvatarCache"
                    )

                    let config = URLSessionConfiguration.default
                    config.urlCache = avatarCache
                    config.requestCachePolicy = .returnCacheDataElseLoad

                    let session = URLSession(configuration: config)

                    let request = URLRequest(url: url)

                    do {
                        let (data, response) = try await session.data(for: request)

                        // Check HTTP status
                        guard let httpResponse = response as? HTTPURLResponse else {
//                            print("❌ Invalid response (not HTTP)")
                            return
                        }

//                        print("HTTP status: \(httpResponse.statusCode)")
//                        if let cacheControl = httpResponse.value(forHTTPHeaderField: "Cache-Control") {
//                            print("Cache-Control: \(cacheControl)")
//                        }
//                        if let age = httpResponse.value(forHTTPHeaderField: "Age") {
//                            print("Age header: \(age) seconds")
//                        }

                        // Handle status codes
                        guard (200...299).contains(httpResponse.statusCode) else {
//                            print("❌ HTTP error: \(httpResponse.statusCode)")
                            return
                        }

//                        // Check local cache
//                        if let cachedResponse = avatarCache.cachedResponse(for: request) {
//                            print("✅ Local cache hit")
//                        } else {
//                            print("❌ Local cache miss")
//                        }

                        // Create image
                        if let nsImage = NSImage(data: data) {
                            avatarImage = Image(nsImage: nsImage)
                        } else {
//                            print("❌ Failed to create image from data")
                        }

                    } catch {
//                        print("❌ Network error: \(error)")
                    }
                }
            }
            else {
                avatarImage = nil
            }
        }
    }
}
