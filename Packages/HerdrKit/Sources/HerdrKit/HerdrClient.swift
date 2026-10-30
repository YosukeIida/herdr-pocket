import Foundation

/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
/// JSON-RPC on channel 0, terminal and event streams on core-allocated channels.
///
/// Thread model: transport bytes are parsed on whatever thread the transport
/// calls back on (serially), under one lock. Writes go through a single serial
/// writer task. Stream and event callbacks are delivered on `callbackQueue`.
public final class HerdrClient: @unchecked Sendable {
    public let transport: ByteTransport
    /// Where stream/event/disconnect callbacks run. Set before `connect()`.
    public var callbackQueue: DispatchQueue = .main
    /// No bytes on any channel for this long = the connection is dead.
    public var livenessTimeout: TimeInterval = 45
    /// Called once on `callbackQueue` when the connection drops unexpectedly
    /// (not after `close()`).
    public var onDisconnect: ((HerdrError) -> Void)? {
        get { lock.withLock { _onDisconnect } }
        set { lock.withLock { _onDisconnect = newValue } }
    }
    private var _onDisconnect: ((HerdrError) -> Void)?

    public private(set) var hello: HelloInfo?
    /// Remote stderr so far (capped), for failure screens.
    public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }

    /// Methods the app calls; a core lacking one can't serve it.
    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.kill", "terminal.label", "terminal.attach",
                                         "terminal.keep", "doc.get", "doc.set", "events.subscribe", "machine.exec"]
    public static let minCoreVersion = "0.1.11"
    public static let generation: UInt64 = 1

    private enum Route { case terminal(TerminalStream), events(EventSubscription) }
    private enum Mode { case idle, plain, framed, closed }

    private let lock = NSLock()
    private var mode = Mode.idle
    private var plain = Data()
    private var helloCont: CheckedContinuation<JSONValue, Error>?
    private var decoder = FrameDecoder()
    private var nextID: UInt64 = 0
    private var pending: [UInt64: CheckedContinuation<JSONValue, Error>] = [:]
    private var cancelled: Set<UInt64> = []
    private var routes: [UInt32: Route] = [:]
    private var early: [UInt32: [Frame]] = [:]
    /// Channels we closed: drop their frames, swallow the CLOSE echo.
    private var closing: Set<UInt32> = []
    private var lastReceive = Date()
    private var stderrBuf = Data()
    private var closedByUs = false

    private let outbox: AsyncStream<Data>.Continuation
    private let outStream: AsyncStream<Data>
    private var writerTask: Task<Void, Never>?
    private var livenessTask: Task<Void, Never>?

    public init(transport: ByteTransport) {
        self.transport = transport
        (outStream, outbox) = AsyncStream<Data>.makeStream(bufferingPolicy: .unbounded)
    }

    deinit {
        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
    }

    public var isConnected: Bool { lock.withLock { mode == .framed } }

    // MARK: Connect

    /// Starts the transport, says hello in plain mode, then switches to frames.
    public func connect(helloTimeout: TimeInterval = 20) async throws -> HelloInfo {
        let started: Bool = lock.withLock {
            guard mode == .idle else { return false }
            mode = .plain; lastReceive = Date(); return true
        }
        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }

        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
            for await chunk in outStream {
                do { try await transport.write(chunk) } catch {
                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
                    return
                }
            }
        }

        try await transport.start(
            onBytes: { [weak self] in self?.receive($0) },
            onStderr: { [weak self] d in self?.lock.withLock {
                guard let self, self.stderrBuf.count < 16_384 else { return }
                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
            } },
            onClose: { [weak self] err in self?.transportClosed(err) })

        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
            let alreadyClosed: Bool = lock.withLock {
                if mode == .closed { return true }
                helloCont = cont; return false
            }
            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
                    defer { self.helloCont = nil }; return self.helloCont
                }) else { return }
                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
                                              hint: self.stderrText.trimmed.nilIfEmpty))
                self.close()
            }
        }
        do {
            let info = try Self.check(hello: reply)
            lock.withLock { hello = info }
            startLiveness()
            return info
        } catch {
            close()
            throw error
        }
    }

    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
    public static func check(hello reply: JSONValue) throws -> HelloInfo {
        if !reply["error"].isNull { throw rpcError(reply["error"]) }
        let r = reply["result"]
        let gen = r["generation"].uint64 ?? 0
        let version = r["version"].string ?? "0"
        if gen > generation {
            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
        }
        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
        }
        let methods = r["methods"].array?.compactMap(\.string) ?? []
        let missing = requiredMethods.filter { !methods.contains($0) }
        if !missing.isEmpty {
            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
        }
        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
                         version: version, methods: methods)
    }

    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }

    static func semver(_ v: String) -> [Int] {
        var s = v.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("hc ") { s.removeFirst(3) }
        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
        return (0..<3).map { $0 < parts.count ? parts[$0] : 0 }
    }

    /// Closes the connection. Pending calls fail with `lost`; streams get `onLost`.
    public func close() {
        lock.withLock { closedByUs = true }
        transport.close()
        fail(HerdrError(code: -1, kind: "closed", message: "Disconnected"))
    }

    // MARK: Calls

    /// One JSON-RPC call on channel 0. Errors are `HerdrError` (message, hint,
    /// kind). Cancelling the task sends `$/cancelRequest`.
    @discardableResult
    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
                              "params": params.isNull ? [:] : params]
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
                enum Outcome { case go, cancelled, closed }
                let outcome: Outcome = lock.withLock {
                    if cancelled.remove(id) != nil { return .cancelled }
                    if mode != .framed { return .closed }
                    pending[id] = cont; return .go
                }
                switch outcome {
                case .cancelled: cont.resume(throwing: CancellationError()); return
                case .closed: cont.resume(throwing: HerdrError.lost); return
                case .go: break
                }
                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
                }
            }
        } onCancel: {
            let wasPending = lock.withLock { () -> Bool in
                if pending[id] != nil { return true }
                cancelled.insert(id); return false
            }
            if wasPending {
                finish(id, .failure(CancellationError()))
                notify("$/cancelRequest", ["id": .number(Double(id))])
            }
        }
    }

    /// A notification (no id, no reply).
    public func notify(_ method: String, _ params: JSONValue = [:]) {
        let msg: JSONValue = ["jsonrpc": "2.0", "method": .string(method), "params": params]
        send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
    }

    private func finish(_ id: UInt64, _ result: Result<JSONValue, Error>) {
        guard let cont = lock.withLock({ pending.removeValue(forKey: id) }) else { return }
        cont.resume(with: result)
    }

    static func rpcError(_ e: JSONValue) -> HerdrError {
        HerdrError(code: e["code"].int ?? -32000, kind: e["data"]["kind"].string,
                   message: e["message"].string ?? "core call failed", hint: e["data"]["hint"].string)
    }

    // MARK: Typed helpers

    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
    /// exit or timeout is a result, not an error.
    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
        if let input { p["input"] = .string(input.base64EncodedString()) }
        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
        return ExecResult(code: r["code"].int,
                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
                          timedOut: r["timed_out"].bool ?? false)
    }

    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
        let r = try await call("doc.get", ["name": .string(name)])
        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
    }

    /// CAS write; throws kind "conflict" when `version` is stale. Returns the new version.
    public func docSet(_ name: String = "herdr-app", value: JSONValue, version: UInt64) async throws -> UInt64 {
        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
        return r["version"].uint64 ?? version + 1
    }

    public func listTerminals(all: Bool = false) async throws -> [TerminalRecord] {
        let r = try await call("terminal.list", ["all": .bool(all)])
        return (r["terminals"].array ?? []).map(TerminalRecord.init(raw:))
    }

    public func read(terminal: String, lines: Int = 200) async throws -> String {
        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
    }

    // MARK: Streams

    /// `terminal.attach`: opens a stream channel. Data that arrives before the
    /// reply (or before handlers are set) is kept and delivered in order.
    public func attach(terminal: String, cols: Int, rows: Int, history: Int = 2000,
                       display: JSONValue? = nil, observe: Bool = false) async throws -> TerminalStream {
        var p: JSONValue = ["terminal": .string(terminal), "cols": .number(Double(max(cols, 1))),
                            "rows": .number(Double(max(rows, 1))), "history": .number(Double(history)), "observe": .bool(observe)]
        if let display { p["display"] = display }
        let r = try await call("terminal.attach", p)
        guard let ch = r["channel"].uint64.map({ UInt32(clamping: $0) }), ch > 0 else {
            throw HerdrError(code: -32603, kind: "internal", message: "attach reply had no channel")
        }
        let stream = TerminalStream(channel: ch, record: TerminalRecord(raw: r["terminal"]))
        stream.sink = { [weak self] kind, payload in self?.streamSend(ch, kind, payload) }
        let queue = callbackQueue
        let backlog: [Frame]? = lock.withLock {
            guard mode == .framed else { return nil }
            routes[ch] = .terminal(stream)
            let frames = early.removeValue(forKey: ch) ?? []
            // Flush inside the lock so later frames queue behind these.
            for f in frames { route(f, to: .terminal(stream), queue: queue) }
            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
            return frames
        }
        if backlog == nil { queue.async { stream.deliver(.lost) } }
        return stream
    }

    /// `events.subscribe` with no filter (filtered subscriptions miss doc events).
    public func subscribe(coalesce: TimeInterval = 0.08) async throws -> EventSubscription {
        let r = try await call("events.subscribe", [:])
        guard let ch = r["channel"].uint64.map({ UInt32(clamping: $0) }), ch > 0 else {
            throw HerdrError(code: -32603, kind: "internal", message: "subscribe reply had no channel")
        }
        let sub = EventSubscription(channel: ch, snapshot: r, queue: callbackQueue, coalesce: coalesce)
        sub.closer = { [weak self] in self?.streamSend(ch, FrameKind.close, Data()) }
        let ok: Bool = lock.withLock {
            guard mode == .framed else { return false }
            routes[ch] = .events(sub)
            let frames = early.removeValue(forKey: ch) ?? []
            for f in frames { route(f, to: .events(sub), queue: callbackQueue) }
            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
            return true
        }
        guard ok else { throw HerdrError.lost }
        send(Frame.credit(ch, 1 << 20))
        return sub
    }

    private func streamSend(_ ch: UInt32, _ kind: UInt8, _ payload: Data) {
        if kind == FrameKind.close {
            let wasOpen: Bool = lock.withLock {
                guard routes.removeValue(forKey: ch) != nil else { return false }
                closing.insert(ch); return true
            }
            guard wasOpen else { return }
        } else if kind == FrameKind.data, payload.isEmpty {
            return
        }
        send(Frame(channel: ch, kind: kind, payload: payload))
    }

    private func send(_ f: Frame) {
        outbox.yield(f.encoded())
    }

    // MARK: Reading

    private func receive(_ bytes: Data) {
        var actions: [() -> Void] = []
        var protocolError: HerdrError?
        lock.withLock {
            lastReceive = Date()
            switch mode {
            case .idle, .closed:
                return
            case .plain:
                plain.append(bytes)
                guard let nl = plain.firstIndex(of: 0x0a) else { return }
                let line = plain[plain.startIndex..<nl]
                let rest = plain[plain.index(after: nl)...]
                let reply = (try? JSONValue.parse(Data(line))) ?? .null
                mode = .framed
                decoder.append(Data(rest))
                plain = Data()
                if let c = helloCont {
                    helloCont = nil
                    if reply.isNull {
                        actions.append { c.resume(throwing: HerdrError(kind: "parse_error", message: "The core's hello reply wasn't JSON")) }
                    } else {
                        actions.append { c.resume(returning: reply) }
                    }
                }
            case .framed:
                decoder.append(bytes)
            }
            do {
                while let f = try decoder.next() { handle(f, &actions) }
            } catch {
                protocolError = HerdrError(code: -32700, kind: "lost", message: "Lost the core", hint: "\(error)")
            }
        }
        for a in actions { a() }
        if let protocolError { fail(protocolError); transport.close() }
    }

    /// Called with the lock held.
    private func handle(_ f: Frame, _ actions: inout [() -> Void]) {
        if f.channel == 0 {
            guard f.kind == FrameKind.data, let msg = try? JSONValue.parse(f.payload),
                  let id = msg["id"].uint64 else { return }
            guard let cont = pending.removeValue(forKey: id) else {
                // A reply nobody waits for (cancelled or timed out). If it opened a
                // stream (attach, subscribe), close it so the core drops the viewer.
                if let ch = msg["result"]["channel"].uint64.flatMap({ UInt32(exactly: $0) }), ch > 0, routes[ch] == nil {
                    early.removeValue(forKey: ch)
                    closing.insert(ch)
                    send(Frame(channel: ch, kind: FrameKind.close, payload: Data()))
                }
                return
            }
            if msg["error"].isNull {
                let result = msg["result"]
                actions.append { cont.resume(returning: result) }
            } else {
                let err = Self.rpcError(msg["error"])
                actions.append { cont.resume(throwing: err) }
            }
            return
        }
        if closing.contains(f.channel) {
            if f.kind == FrameKind.close { closing.remove(f.channel) }
            return
        }
        guard let r = routes[f.channel] else {
            early[f.channel, default: []].append(f)
            return
        }
        if f.kind == FrameKind.close { routes.removeValue(forKey: f.channel) }
        route(f, to: r, queue: callbackQueue)
    }

    /// Called with the lock held.
    private func route(_ f: Frame, to r: Route, queue: DispatchQueue) {
        switch r {
        case .terminal(let s):
            switch f.kind {
            case FrameKind.data:
                let d = f.payload
                queue.async { s.deliver(.data(d)) }
            case FrameKind.close:
                let why = f.payload.isEmpty ? JSONValue.null : ((try? JSONValue.parse(f.payload)) ?? .null)
                queue.async { s.deliver(.close(why)) }
            default: break
            }
        case .events(let sub):
            switch f.kind {
            case FrameKind.data:
                sub.push(f.payload)
                send(Frame.credit(f.channel, f.payload.count))
            case FrameKind.close:
                sub.ended(lost: false)
            default: break
            }
        }
    }

    // MARK: Loss

    private func transportClosed(_ err: Error?) {
        let (hint, byUs): (String?, Bool) = lock.withLock {
            (String(decoding: stderrBuf, as: UTF8.self).trimmed.nilIfEmpty, closedByUs)
        }
        if byUs { return }
        fail(closedError(err, stderr: hint))
    }

    private func closedError(_ err: Error?, stderr: String? = nil) -> HerdrError {
        let stderr = stderr ?? stderrText.trimmed.nilIfEmpty
        if let stderr, stderr.contains("not installed") {
            return HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine", hint: stderr)
        }
        return HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: stderr ?? err.map { "\($0.localizedDescription)" })
    }

    /// Fails everything once: pending calls, hello, every stream.
    private func fail(_ error: HerdrError) {
        var conts: [CheckedContinuation<JSONValue, Error>] = []
        var helloC: CheckedContinuation<JSONValue, Error>?
        var lostRoutes: [Route] = []
        let first: Bool = lock.withLock {
            guard mode != .closed else { return false }
            mode = .closed
            conts = Array(pending.values); pending.removeAll()
            helloC = helloCont; helloCont = nil
            lostRoutes = Array(routes.values); routes.removeAll(); early.removeAll(); closing.removeAll()
            return true
        }
        guard first else { return }
        livenessTask?.cancel()
        outbox.finish()
        let lost = HerdrError(code: -1, kind: error.kind ?? "lost", message: error.message, hint: error.hint)
        helloC?.resume(throwing: lost)
        for c in conts { c.resume(throwing: lost) }
        let queue = callbackQueue
        for r in lostRoutes {
            switch r {
            case .terminal(let s): queue.async { s.deliver(.lost) }
            case .events(let sub): sub.ended(lost: true)
            }
        }
        let cb: ((HerdrError) -> Void)? = lock.withLock { closedByUs ? nil : _onDisconnect }
        if let cb { queue.async { cb(lost) } }
    }

    private func startLiveness() {
        livenessTask = Task.detached { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                let idle = self.lock.withLock { Date().timeIntervalSince(self.lastReceive) }
                if idle > self.livenessTimeout {
                    self.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core",
                                         hint: "no data for \(Int(idle)) s"))
                    self.transport.close()
                    return
                }
            }
        }
    }
}

/// What an events subscription delivered (coalesced).
public struct EventUpdate: Sendable {
    public var pushed: Pushed
    /// Every terminal the stream describes (live and finished), stream order.
    public var terminals: [TerminalRecord]
    public var seq: UInt64
}

/// An `events.subscribe` channel. Lines are applied off the main thread;
/// `onUpdate` gets coalesced results on the callback queue.
public final class EventSubscription: @unchecked Sendable {
    public let channel: UInt32
    /// The snapshot from the subscribe reply (all terminals, live and finished).
    public let snapshot: [TerminalRecord]
    public let snapshotSeq: UInt64
    public var onUpdate: ((EventUpdate) -> Void)? { didSet { queue.async { [weak self] in self?.flushIfReady() } } }
    /// The core closed the channel: subscribe again.
    public var onClose: (() -> Void)?
    /// The connection dropped.
    public var onLost: (() -> Void)?

    var closer: (() -> Void)?
    private let queue: DispatchQueue
    private let coalesce: TimeInterval
    private let lock = NSLock()
    private var lines: EventLines
    private var accumulated = Pushed()
    private var scheduled = false
    private var endedState: Bool?   // nil = open, false = closed by core, true = lost

    init(channel: UInt32, snapshot: JSONValue, queue: DispatchQueue, coalesce: TimeInterval) {
        self.channel = channel
        self.queue = queue
        self.coalesce = coalesce
        lines = EventLines(snapshot: snapshot)
        self.snapshot = lines.terminals.map(TerminalRecord.init(raw:))
        snapshotSeq = lines.seq
    }

    /// Current state of every terminal (thread-safe).
    public var terminals: [TerminalRecord] { lock.withLock { lines.terminals.map(TerminalRecord.init(raw:)) } }

    /// Stop the subscription (sends CLOSE).
    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }

    /// Lines received so far (heartbeats included).
    public var lineCount: Int { lock.withLock { linesSeen } }
    private var linesSeen = 0

    func push(_ bytes: Data) {
        let schedule: Bool = lock.withLock {
            let p = lines.push(bytes)
            linesSeen += p.lines
            accumulated.merge(p)
            guard !scheduled, p.terminals || !p.docs.isEmpty || p.missed else { return false }
            scheduled = true
            return true
        }
        if schedule { queue.asyncAfter(deadline: .now() + coalesce) { [weak self] in self?.flushIfReady() } }
    }

    func ended(lost: Bool) {
        lock.withLock { endedState = lost }
        queue.async { [weak self] in
            guard let self else { return }
            self.flushIfReady()
            if lost { self.onLost?() } else { self.onClose?() }
        }
    }

    /// On the callback queue.
    private func flushIfReady() {
        guard let onUpdate else { return }
        let update: EventUpdate? = lock.withLock {
            scheduled = false
            let p = accumulated
            guard p.terminals || !p.docs.isEmpty || p.missed else { return nil }
            accumulated = Pushed()
            return EventUpdate(pushed: p, terminals: lines.terminals.map(TerminalRecord.init(raw:)), seq: lines.seq)
        }
        if let update { onUpdate(update) }
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
