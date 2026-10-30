#if os(macOS)
import Foundation

/// A `ByteTransport` over a local process, e.g. `ssh -T my-box '<herdrConnectCommand>'`.
/// macOS only (herdr-probe and tests).
public final class ProcessTransport: ByteTransport, @unchecked Sendable {
    public let executable: String
    public let arguments: [String]
    private let process = Process()
    private let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
    private let lock = NSLock()
    private var closed = false
    private var onClose: (@Sendable (Error?) -> Void)?

    public init(executable: String = "/usr/bin/ssh", arguments: [String]) {
        self.executable = executable; self.arguments = arguments
    }

    /// `ssh -T <host> <herdrConnectCommand>`.
    public static func ssh(_ host: String) -> ProcessTransport {
        ProcessTransport(arguments: ["-T", "-o", "BatchMode=yes", host, herdrConnectCommand])
    }

    public func start(onBytes: @escaping @Sendable (Data) -> Void,
                      onStderr: @escaping @Sendable (Data) -> Void,
                      onClose: @escaping @Sendable (Error?) -> Void) async throws {
        self.onClose = onClose
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardInput = stdin; process.standardOutput = stdout; process.standardError = stderr
        let readQueue = DispatchQueue(label: "herdr.process.read")
        stdout.fileHandleForReading.readabilityHandler = { [weak self] h in
            let d = h.availableData
            if d.isEmpty {
                h.readabilityHandler = nil
                readQueue.async { self?.finish(nil) }
            } else {
                readQueue.async { onBytes(d) }
            }
        }
        stderr.fileHandleForReading.readabilityHandler = { h in
            let d = h.availableData
            if d.isEmpty { h.readabilityHandler = nil } else { onStderr(d) }
        }
        process.terminationHandler = { [weak self] p in
            readQueue.asyncAfter(deadline: .now() + 0.2) {
                self?.finish(p.terminationStatus == 0 ? nil : HerdrError(code: -1, kind: "exit", message: "process exited \(p.terminationStatus)"))
            }
        }
        try process.run()
    }

    public func write(_ data: Data) async throws {
        guard lock.withLock({ !closed }) else { throw HerdrError.lost }
        try stdin.fileHandleForWriting.write(contentsOf: data)
    }

    public func close() {
        guard lock.withLock({ () -> Bool in defer { closed = true }; return !closed }) else { return }
        try? stdin.fileHandleForWriting.close()
        if process.isRunning { process.terminate() }
        onClose?(nil); onClose = nil
    }

    private func finish(_ err: Error?) {
        guard lock.withLock({ () -> Bool in defer { closed = true }; return !closed }) else { return }
        let cb = onClose; onClose = nil
        cb?(err)
    }
}
#endif
