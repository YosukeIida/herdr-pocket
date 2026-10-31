import Foundation
import HerdrKit
import Citadel
import Crypto
import NIOCore
import NIOSSH

/// `ByteTransport` over an SSH exec channel (no PTY) running
/// `herdrConnectCommand`, via Citadel.
final class CitadelTransport: ByteTransport, @unchecked Sendable {
    enum Auth {
        case key(Curve25519.Signing.PrivateKey)
        case password(String)
    }

    let host: String, port: Int, user: String
    private let auth: Auth
    private let lock = NSLock()
    private var client: SSHClient?
    private var writer: TTYStdinWriter?
    private var task: Task<Void, Never>?
    private var closed = false
    private var onClose: (@Sendable (Error?) -> Void)?

    init(host: String, port: Int, user: String, auth: Auth) {
        self.host = host; self.port = port; self.user = user; self.auth = auth
    }

    func start(onBytes: @escaping @Sendable (Data) -> Void,
               onStderr: @escaping @Sendable (Data) -> Void,
               onClose: @escaping @Sendable (Error?) -> Void) async throws {
        let method: SSHAuthenticationMethod = switch auth {
        case .key(let k): .ed25519(username: user, privateKey: k)
        case .password(let p): .passwordBased(username: user, password: p)
        }
        let client: SSHClient
        do {
            client = try await SSHClient.connect(
                host: host, port: port, authenticationMethod: method,
                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
                reconnect: .never, connectTimeout: .seconds(12))
        } catch {
            throw Self.friendly(error, host: host, user: user)
        }
        let isClosed: Bool = lock.withLock {
            self.client = client; self.onClose = onClose; return closed
        }
        if isClosed { try? await client.close(); throw HerdrError(code: -1, kind: "closed", message: "Disconnected") }

        // The exec channel lives in this task; `start` returns once stdin is writable.
        try await withCheckedThrowingContinuation { (ready: CheckedContinuation<Void, Error>) in
            let readyOnce = Once(ready)
            let t = Task.detached { [weak self] in
                var failure: Error?
                do {
                    try await client.withExec(herdrConnectCommand) { inbound, outbound in
                        self?.lock.withLock { self?.writer = outbound }
                        readyOnce.resume(.success(()))
                        for try await out in inbound {
                            switch out {
                            case .stdout(let b): onBytes(Data(b.readableBytesView))
                            case .stderr(let b): onStderr(Data(b.readableBytesView))
                            }
                        }
                    }
                } catch let e as SSHClient.CommandFailed where e.exitCode == 127 {
                    failure = HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine",
                                         hint: "install herdr-core in ~/.local/bin")
                } catch is CancellationError {
                } catch {
                    failure = error
                }
                readyOnce.resume(.failure(failure ?? HerdrError.lost))
                self?.finish(failure)
            }
            lock.withLock { task = t }
        }
    }

    func write(_ data: Data) async throws {
        guard let w = lock.withLock({ closed ? nil : writer }) else { throw HerdrError.lost }
        try await w.write(ByteBuffer(bytes: data))
    }

    func close() {
        let (t, c, cb): (Task<Void, Never>?, SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
            guard !closed else { return (nil, nil, nil) }
            closed = true
            defer { onClose = nil; writer = nil }
            return (task, client, onClose)
        }
        t?.cancel()
        if let c { Task.detached { try? await c.close() } }
        cb?(nil)
    }

    private func finish(_ err: Error?) {
        let (c, cb): (SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
            guard !closed else { return (nil, nil) }
            closed = true
            defer { onClose = nil; writer = nil }
            return (client, onClose)
        }
        if let c { Task.detached { try? await c.close() } }
        cb?(err)
    }

    /// SSH failures in words a person can act on.
    static func friendly(_ error: Error, host: String, user: String) -> Error {
        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return error }
        if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
            return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
                              hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
        }
        let text = String(describing: error)
        if text.contains("connectTimeout") || text.contains("timeout") || text.contains("Timeout") {
            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "is Tailscale connected?")
        }
        if text.contains("connectionRefused") || text.contains("Connection refused") {
            return HerdrError(code: -1, kind: "unreachable", message: "\(host) refused the SSH connection", hint: "is sshd running on port 22?")
        }
        if text.contains("NIOConnectionError") || text.contains("unreachable") || text.contains("resolve") {
            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "check the address and your network")
        }
        return HerdrError(code: -1, kind: "ssh", message: "SSH to \(host) failed", hint: text)
    }
}

/// Resumes a continuation at most once.
private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var cont: CheckedContinuation<Void, Error>?
    init(_ c: CheckedContinuation<Void, Error>) { cont = c }
    func resume(_ r: Result<Void, Error>) {
        let c: CheckedContinuation<Void, Error>? = lock.withLock { defer { cont = nil }; return cont }
        c?.resume(with: r)
    }
}
