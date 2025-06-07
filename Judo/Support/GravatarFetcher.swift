import CommonCrypto
import Foundation

enum GravatarFetcher {
    static func gravatarURL(for email: String, size: Int = 80) -> URL {
        let emailHash = sha256Hash(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        return URL(string: "https://www.gravatar.com/avatar/\(emailHash)?s=\(size)&d=404")!
    }

    private static func sha256Hash(_ string: String) -> String {
        let data = string.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
