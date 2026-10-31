import Foundation
import Security
import Crypto
import Citadel

/// The app's SSH identity and saved passwords, in the Keychain
/// (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: never synced or backed up).
enum KeyStore {
    private static let service = "com.zzulanas.herdr.ssh"
    private static let keyAccount = "ed25519"

    enum KeyError: LocalizedError {
        case keychain(OSStatus)
        case badKey(String)
        var errorDescription: String? {
            switch self {
            case .keychain(let s): "Keychain error \(s)"
            case .badKey(let why): why
            }
        }
    }

    /// The signing key: a DEBUG override file, else the Keychain, else a new one (saved).
    static func signingKey() throws -> Curve25519.Signing.PrivateKey {
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment["HERDR_DEBUG_KEY_PATH"], !path.isEmpty {
            let text = try String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8)
            return try parseOpenSSH(text)
        }
        #endif
        if let raw = try read(account: keyAccount) {
            return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
        }
        let key = Curve25519.Signing.PrivateKey()
        try write(key.rawRepresentation, account: keyAccount)
        return key
    }

    /// OpenSSH one-line public key: `ssh-ed25519 AAAA… herdr-ios`.
    static func publicKeyLine() -> String {
        guard let key = try? signingKey() else { return "" }
        return publicKeyLine(for: key.publicKey)
    }

    static func publicKeyLine(for pub: Curve25519.Signing.PublicKey, comment: String = "herdr-ios") -> String {
        var blob = Data()
        func sshString(_ d: Data) {
            withUnsafeBytes(of: UInt32(d.count).bigEndian) { blob.append(contentsOf: $0) }
            blob.append(d)
        }
        sshString(Data("ssh-ed25519".utf8))
        sshString(pub.rawRepresentation)
        return "ssh-ed25519 \(blob.base64EncodedString()) \(comment)"
    }

    /// Replaces the app key with a pasted, unencrypted OpenSSH ed25519 private key.
    static func importPrivateKey(_ openSSHText: String) throws {
        let key = try parseOpenSSH(openSSHText)
        try write(key.rawRepresentation, account: keyAccount)
    }

    /// Generates a fresh key (the old one is gone for good).
    static func regenerateKey() throws {
        try write(Curve25519.Signing.PrivateKey().rawRepresentation, account: keyAccount)
    }

    private static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
            throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
        }
        do {
            return try Curve25519.Signing.PrivateKey(sshEd25519: trimmed + "\n")
        } catch {
            throw KeyError.badKey("Couldn't read that key: only unencrypted ed25519 keys work (\(error))")
        }
    }

    // MARK: Passwords

    static func password(for machine: UUID) -> String? {
        (try? read(account: "pw." + machine.uuidString)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    }

    static func setPassword(_ password: String?, for machine: UUID) {
        let account = "pw." + machine.uuidString
        if let password, !password.isEmpty {
            try? write(Data(password.utf8), account: account)
        } else {
            delete(account: account)
        }
    }

    // MARK: Host keys

    /// nil only when nothing is pinned; a Keychain failure throws so it is never taken for a first connection.
    static func hostKey(_ hostPort: String) throws -> String? {
        try read(account: "hostkey." + hostPort).flatMap { String(data: $0, encoding: .utf8) }
    }

    static func setHostKey(_ line: String?, for hostPort: String) throws {
        let account = "hostkey." + hostPort
        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
    }

    // MARK: Keychain

    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private static func read(account: String) throws -> Data? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
        return out as? Data
    }

    /// Update in place, add only when missing: a failed write never loses the existing item.
    private static func write(_ data: Data, account: String) throws {
        let attrs: [String: Any] = [kSecValueData as String: data,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var q = query(account)
            for (k, v) in attrs { q[k] = v }
            status = SecItemAdd(q as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
    }

    private static func delete(account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}
