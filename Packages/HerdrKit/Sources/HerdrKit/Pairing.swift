import Foundation

/// What `scripts/pair.sh` puts in its QR code: everything a phone needs to reach `herdr-core connect`
/// on a box over SSH. The box made the key pair and authorized the public half for that command only,
/// so nothing goes back from the phone.
///
/// Text form: `herdr-pair:` + base64url(JSON `{"v":1,"host","port","user","hostKey","key"}`).
public struct PairingOffer: Equatable, Sendable {
    public var host: String
    public var port: Int
    public var user: String
    /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
    public var hostKey: String
    /// The phone's private key, unencrypted OpenSSH text.
    public var privateKey: String

    public static let prefix = "herdr-pair:"

    public init(host: String, port: Int, user: String, hostKey: String, privateKey: String) {
        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.privateKey = privateKey
    }

    public struct Invalid: LocalizedError, Equatable {
        public var reason: String
        public var errorDescription: String? { "Not a herdr pairing code: \(reason)." }
    }

    public static func decode(_ text: String) throws -> PairingOffer {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
        var b64 = String(s.dropFirst(prefix.count)).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
        guard let data = Data(base64Encoded: b64), let v = try? JSONValue.parse(data) else { throw Invalid(reason: "the code is damaged") }
        guard v["v"].int == 1 else { throw Invalid(reason: "made by a newer pair.sh") }
        guard let host = v["host"].string, !host.isEmpty, let user = v["user"].string, !user.isEmpty else {
            throw Invalid(reason: "no host or user")
        }
        let port = v["port"].int ?? 22
        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
        guard let hostKey = v["hostKey"].string, hostKey.hasPrefix("ssh-"), hostKey.split(separator: " ").count == 2 else {
            throw Invalid(reason: "no host key")
        }
        guard let key = v["key"].string, key.contains("BEGIN OPENSSH PRIVATE KEY") else { throw Invalid(reason: "no key") }
        return PairingOffer(host: host, port: port, user: user, hostKey: hostKey, privateKey: key)
    }
}
