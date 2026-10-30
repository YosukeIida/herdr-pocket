import Foundation

// CONTRACT FILE. Public signatures here are shared by the app's UI, store and
// mod host, which are written in parallel. Implement the bodies (here or in
// other files of HerdrKit); add API freely, but do not rename or remove these.

// MARK: Transport

/// Bytes to and from one `herdr-core connect` process: an SSH exec channel on
/// iOS, a local `ssh my-box ...` Process in herdr-probe.
public protocol ByteTransport: AnyObject, Sendable {
    /// Start the process/channel. `onBytes` gets stdout in order; `onClose`
    /// fires once when it ends (nil = clean EOF). `onStderr` is diagnostics.
    func start(onBytes: @escaping @Sendable (Data) -> Void,
               onStderr: @escaping @Sendable (Data) -> Void,
               onClose: @escaping @Sendable (Error?) -> Void) async throws
    func write(_ data: Data) async throws
    func close()
}

/// The command a transport runs on the box (SPEC.md §1).
public let herdrConnectCommand = #"sh -c 'p=$(command -v herdr-core) || p=$HOME/.local/bin/herdr-core; [ -x "$p" ] || { echo "herdr-core is not installed here" >&2; exit 127; }; exec "$p" connect'"#

// MARK: Errors

public struct HerdrError: Error, LocalizedError, Sendable, Equatable {
    public var code: Int
    public var kind: String?      // e.g. "not_found", "conflict", "lost"
    public var message: String
    public var hint: String?
    public init(code: Int = -32000, kind: String? = nil, message: String, hint: String? = nil) {
        self.code = code; self.kind = kind; self.message = message; self.hint = hint
    }
    public var errorDescription: String? { hint.map { "\(message) (\($0))" } ?? message }
    public static let lost = HerdrError(code: -1, kind: "lost", message: "Lost the core")
}

public struct HelloInfo: Sendable, Equatable {
    public var coreID: String
    public var coreName: String
    public var version: String
    public var methods: [String]
    public init(coreID: String, coreName: String, version: String, methods: [String]) {
        self.coreID = coreID; self.coreName = coreName; self.version = version; self.methods = methods
    }
}

public struct ExecResult: Sendable, Equatable {
    public var code: Int?        // nil when a signal ended it
    public var stdout: Data
    public var stderr: Data
    public var timedOut: Bool
    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool) {
        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut
    }
}

// MARK: Records

/// One terminal record (SPEC.md §5). Raw JSON kept; accessors on top.
public struct TerminalRecord: Identifiable, Equatable, Sendable {
    public var raw: JSONValue
    public init(raw: JSONValue) { self.raw = raw }
    public var id: String { address }
    public var address: String { raw["address"].string ?? "" }
    public var isLive: Bool { raw["state"].string == "live" }
    public var title: String { raw["title"].string ?? "" }
    public var cwd: String { raw["foreground"]["cwd"].string ?? raw["cwd"].string ?? "" }
    public var labels: [String: String] { raw["labels"].object?.compactMapValues { $0.string } ?? [:] }
    /// Status word from OSC 7501 ("working", "blocked", "done", "idle", "error", ...); nil = plain shell.
    public var statusWord: String? { raw["status"]["state"].string }
    public var statusApp: String? { raw["status"]["app"].string }
    public var parent: String? { raw["parent"].string }
    public var name: String? { raw["name"].string }
    public var turn: UInt64 { raw["turn"].uint64 ?? 0 }
    public var cols: Int { raw["cols"].int ?? 80 }
    public var rows: Int { raw["rows"].int ?? 24 }
    public var argv: [String] { (raw["foreground"]["argv"].array ?? raw["argv"].array ?? []).compactMap { $0.string } }
    public var spaceID: String? { labels["herdr.space"].flatMap { $0.isEmpty ? nil : $0 } }
    public var tabID: String? { labels["herdr.tab"].flatMap { $0.isEmpty ? nil : $0 } }
}

/// What the agents list shows (SPEC.md §5 Attention).
public enum Attention: Int, Comparable, Sendable {
    case none = 0, idle = 1, working = 2, done = 3, blocked = 4
    public static func < (a: Attention, b: Attention) -> Bool { a.rawValue < b.rawValue }
}

// MARK: Layout document

public struct PaneRef: Identifiable, Hashable, Sendable {
    public var id: String              // block node id
    public var terminal: String?       // content.terminal
    public var mod: String?            // content.mod
    public var modProps: JSONValue     // content.props
    public init(id: String, terminal: String?, mod: String?, modProps: JSONValue) {
        self.id = id; self.terminal = terminal; self.mod = mod; self.modProps = modProps
    }
}

public struct TabRef: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String            // raw; "" = auto
    public var panes: [PaneRef]        // pre-order DFS of root
    public init(id: String, name: String, panes: [PaneRef]) { self.id = id; self.name = name; self.panes = panes }
}

public struct SpaceRef: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String            // raw; "" = auto
    public var folder: String
    public var tabs: [TabRef]
    public init(id: String, name: String, folder: String, tabs: [TabRef]) {
        self.id = id; self.name = name; self.folder = folder; self.tabs = tabs
    }
}

/// The `herdr-app` doc, raw JSON preserved for writes (SPEC.md §5).
public struct LayoutDoc: Equatable, Sendable {
    public var value: JSONValue
    public var version: UInt64
    public init(value: JSONValue, version: UInt64) { self.value = value; self.version = version }
}

// MARK: Terminal stream

/// One attached terminal channel (SPEC.md §3). Callbacks are delivered on the
/// main queue, in order. Credit for each DATA payload is returned to the core
/// automatically after `onData` returns.
public final class TerminalStream: @unchecked Sendable {
    public let channel: UInt32
    /// The record from the attach reply.
    public let record: TerminalRecord
    public var onData: ((Data) -> Void)? { didSet { flushBacklog() } }
    /// Core ended the stream; payload is its JSON reason (or .null).
    public var onClose: ((JSONValue) -> Void)? { didSet { flushBacklog() } }
    /// Connection to the core dropped; reattach after reconnect.
    public var onLost: (() -> Void)? { didSet { flushBacklog() } }

    /// Set by HerdrClient; lets the stream talk back without a strong cycle.
    public var sink: ((_ kind: UInt8, _ payload: Data) -> Void)?

    public init(channel: UInt32, record: TerminalRecord) { self.channel = channel; self.record = record }

    public func write(_ bytes: Data) { guard !bytes.isEmpty else { return }; sink?(0, bytes) }
    public func resize(cols: Int, rows: Int) {
        guard cols > 0, rows > 0 else { return }
        var p = Data(); var c = UInt16(clamping: cols).littleEndian, r = UInt16(clamping: rows).littleEndian
        withUnsafeBytes(of: &c) { p.append(contentsOf: $0) }; withUnsafeBytes(of: &r) { p.append(contentsOf: $0) }
        sink?(3, p)
    }
    public func focus(_ on: Bool) { sink?(4, Data([on ? 1 : 0])) }
    /// Stop routing and send CLOSE.
    public func detach() { backlog.removeAll(); onData = nil; onClose = nil; onLost = nil; sink?(2, Data()); sink = nil }

    /// FACTS: display colors and pixel cell size (`{"fg","bg","cursor","cell":[w,h]}`).
    public func facts(_ display: JSONValue) { sink?(5, display.encoded()) }

    /// True once the core closed the stream or the connection dropped.
    public private(set) var ended = false

    // MARK: Delivery (HerdrClient calls `deliver` on the callback queue, in order).
    // Events that arrive before their handler is set wait in `backlog`, so data
    // from the first paint is never dropped, and credit is only returned for
    // bytes actually handed to `onData`.

    enum Event { case data(Data), close(JSONValue), lost }
    private var backlog: [Event] = []

    func deliver(_ e: Event) {
        backlog.append(e)
        flushBacklog()
    }

    private func flushBacklog() {
        while let e = backlog.first {
            switch e {
            case .data(let d):
                guard let h = onData else { return }
                backlog.removeFirst()
                h(d)
                sink?(1, withUnsafeBytes(of: UInt32(clamping: d.count).littleEndian) { Data($0) })
            case .close(let why):
                guard let h = onClose else { return }
                backlog.removeFirst(); ended = true; sink = nil
                h(why)
            case .lost:
                guard let h = onLost else { return }
                backlog.removeFirst(); ended = true; sink = nil
                h()
            }
        }
    }
}
