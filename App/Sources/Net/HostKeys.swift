import Foundation
import Crypto
import NIOCore
import NIOSSH

/// Trust-on-first-use host keys, pinned per host:port in UserDefaults.
enum HostKeys {
    private static let prefix = "hostkey."

    struct Mismatch: LocalizedError {
        var host: String
        var expected: String
        var got: String
        var errorDescription: String? {
            "\(host)'s host key changed (was \(expected), now \(got)). If the machine was reinstalled, tap Forget host key; otherwise someone may be intercepting the connection."
        }
    }

    /// The pinned key's fingerprint, for display.
    static func pinnedFingerprint(host: String, port: Int) -> String? {
        pinned(host: host, port: port).map(fingerprint)
    }

    static func pinned(host: String, port: Int) -> String? {
        UserDefaults.standard.string(forKey: prefix + "\(host):\(port)")
    }

    static func forget(host: String, port: Int) {
        UserDefaults.standard.removeObject(forKey: prefix + "\(host):\(port)")
    }

    static func pin(_ line: String, host: String, port: Int) {
        UserDefaults.standard.set(line, forKey: prefix + "\(host):\(port)")
    }

    /// `SHA256:<base64>` like ssh-keygen -l.
    static func fingerprint(_ openSSHLine: String) -> String {
        let parts = openSSHLine.split(separator: " ")
        guard parts.count >= 2, let blob = Data(base64Encoded: String(parts[1])) else { return openSSHLine }
        let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
        return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
    }

    /// Validator for Citadel: pins on first sight, fails on change.
    final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
        let host: String, port: Int
        init(host: String, port: Int) { self.host = host; self.port = port }

        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
            let line = String(openSSHPublicKey: hostKey)
            if let known = HostKeys.pinned(host: host, port: port) {
                if known == line {
                    validationCompletePromise.succeed(())
                } else {
                    validationCompletePromise.fail(Mismatch(host: host, expected: HostKeys.fingerprint(known),
                                                            got: HostKeys.fingerprint(line)))
                }
            } else {
                HostKeys.pin(line, host: host, port: port)
                validationCompletePromise.succeed(())
            }
        }
    }
}
