import Foundation
import Crypto
import NIOCore
import NIOSSH

/// Host keys pinned per host:port in the Keychain, after the person approves the first one.
enum HostKeys {
    struct Mismatch: LocalizedError {
        var host: String
        var expected: String
        var got: String
        var errorDescription: String? {
            "\(host)'s host key changed (was \(expected), now \(got)). If the machine was reinstalled, tap Forget host key; otherwise someone may be intercepting the connection."
        }
    }

    /// A host seen for the first time. Nothing is pinned and no credentials were sent yet.
    struct Unknown: LocalizedError, Equatable {
        var host: String
        var port: Int
        var line: String
        var fingerprint: String { HostKeys.fingerprint(line) }
        /// The command that prints this key's fingerprint on the machine itself.
        var checkCommand: String {
            let type = line.hasPrefix("ssh-ed25519") ? "ed25519" : line.hasPrefix("ecdsa-") ? "ecdsa" : "rsa"
            return "ssh-keygen -lf /etc/ssh/ssh_host_\(type)_key.pub"
        }
        var errorDescription: String? {
            "First connection to \(host). Compare its host key with the machine before trusting it."
        }
    }

    /// The pinned key's fingerprint, for display.
    static func pinnedFingerprint(host: String, port: Int) -> String? {
        (try? pinned(host: host, port: port))?.map(fingerprint)
    }

    static func pinned(host: String, port: Int) throws -> String? { try KeyStore.hostKey("\(host):\(port)") }

    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }

    static func pin(_ line: String, host: String, port: Int) throws {
        try KeyStore.setHostKey(line, for: "\(host):\(port)")
    }

    /// `SHA256:<base64>` like ssh-keygen -l.
    static func fingerprint(_ openSSHLine: String) -> String {
        let parts = openSSHLine.split(separator: " ")
        guard parts.count >= 2, let blob = Data(base64Encoded: String(parts[1])) else { return openSSHLine }
        let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
        return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
    }

    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
    /// so the app can show the fingerprint and pin it on approval.
    final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
        let host: String, port: Int
        init(host: String, port: Int) { self.host = host; self.port = port }

        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
            let line = String(openSSHPublicKey: hostKey)
            let known: String?
            do { known = try HostKeys.pinned(host: host, port: port) } catch {
                validationCompletePromise.fail(error); return
            }
            if let known {
                if known == line {
                    validationCompletePromise.succeed(())
                } else {
                    validationCompletePromise.fail(Mismatch(host: host, expected: HostKeys.fingerprint(known),
                                                            got: HostKeys.fingerprint(line)))
                }
            } else {
                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
            }
        }
    }
}
