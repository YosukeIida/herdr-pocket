import Foundation

/// What `scripts/pair.sh` puts in its QR code: everything a phone needs to reach `herdr-core connect`
/// on a box over SSH. The box made the key pair and authorized the public half for that command only,
/// so nothing goes back from the phone.
///
/// Text form: `herdr-pair:` + base64url(JSON `{"v":2,"h":host,"p":port,"u":user,"k":hostKeyBase64,"s":seedBase64}`),
/// short so the QR code fits a terminal: the host key is ed25519 (only its base64 travels) and the
/// phone's key is its 32-byte Ed25519 seed rather than an OpenSSH file.
public struct PairingOffer: Equatable, Sendable {
    public var host: String
    public var port: Int
    public var user: String
    /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
    public var hostKey: String
    /// The phone's Ed25519 private key seed (32 bytes).
    public var seed: Data

    public static let prefix = "herdr-pair:"

    public init(host: String, port: Int, user: String, hostKey: String, seed: Data) {
        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.seed = seed
    }

    public struct Invalid: LocalizedError, Equatable {
        public var reason: String
        public var errorDescription: String? { "Not a herdr pairing code: \(reason)." }
    }

    public static func decode(_ text: String) throws -> PairingOffer {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
        guard let data = base64url(String(s.dropFirst(prefix.count))), let v = try? JSONValue.parse(data) else {
            throw Invalid(reason: "the code is damaged")
        }
        guard v["v"].int == 2 else { throw Invalid(reason: "made by a different pair.sh") }
        guard let host = v["h"].string, !host.isEmpty, let user = v["u"].string, !user.isEmpty else {
            throw Invalid(reason: "no host or user")
        }
        let port = v["p"].int ?? 22
        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
        guard let k = v["k"].string, let blob = Data(base64Encoded: k), blob.count == 51 else { throw Invalid(reason: "no ed25519 host key") }
        guard let sb = v["s"].string, let seed = Data(base64Encoded: sb), seed.count == 32 else { throw Invalid(reason: "no key") }
        return PairingOffer(host: host, port: port, user: user, hostKey: "ssh-ed25519 " + k, seed: seed)
    }

    private static func base64url(_ s: String) -> Data? {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b += String(repeating: "=", count: (4 - b.count % 4) % 4)
        return Data(base64Encoded: b)
    }
}
