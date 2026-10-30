import Foundation

/// A `doc` event: the named layout document changed (machine = nil: this core).
public struct DocChange: Equatable, Sendable {
    public var name: String
    public var machine: String?
    public var version: UInt64?
}

/// One applied `event` line, for callers that react to specific kinds
/// (`restarted` -> reattach, `size` -> RESIZE, ...).
public struct TerminalEvent: Equatable, Sendable {
    public var type: String
    public var terminal: String
    public var data: JSONValue
}

/// What one push changed.
public struct Pushed: Equatable, Sendable {
    /// Docs to read again. `missed` also implies every doc.
    public var docs: [DocChange] = []
    /// A `missed` line replaced the whole snapshot: re-read every doc.
    public var missed = false
    /// The terminal list changed.
    public var terminals = false
    /// Addresses whose record changed (or vanished).
    public var changed: Set<String> = []
    /// Applied terminal events in order.
    public var events: [TerminalEvent] = []
    /// Any line arrived (heartbeats included): proof of life.
    public var lines = 0

    public init() {}

    public mutating func merge(_ o: Pushed) {
        docs += o.docs; missed = missed || o.missed; terminals = terminals || o.terminals
        changed.formUnion(o.changed); events += o.events; lines += o.lines
    }
}

/// The events channel's state: an exact port of herdr-app `hc.rs` `EventLines`
/// (SPEC.md §4). Pure value type: feed it DATA payloads, read `terminals`.
public struct EventLines: Sendable {
    private var pending: [UInt8] = []
    /// The last event applied; older ones were in the snapshot.
    public private(set) var seq: UInt64
    /// Every terminal the stream describes, in its order (finished ones too).
    public private(set) var terminals: [JSONValue]

    /// From `events.subscribe`'s reply: its `seq` and `terminals`.
    public init(snapshot: JSONValue) {
        terminals = snapshot["terminals"].array ?? []
        seq = snapshot["seq"].uint64 ?? 0
    }

    /// Live records, in stream order.
    public var live: [TerminalRecord] {
        terminals.filter { $0["state"].string == "live" }.map(TerminalRecord.init(raw:))
    }

    public mutating func push(_ bytes: Data) -> Pushed {
        var pushed = Pushed()
        var start = 0
        pending.append(contentsOf: bytes)
        var lines: [JSONValue] = []
        for i in pending.indices where pending[i] == UInt8(ascii: "\n") {
            let slice = pending[start..<i]
            start = i + 1
            guard !slice.isEmpty, let v = try? JSONValue.parse(Data(slice)) else { continue }
            lines.append(v)
        }
        if start > 0 { pending.removeSubrange(0..<start) }
        for line in lines {
            pushed.lines += 1
            let p = line["params"]
            switch line["method"].string {
            case "missed":
                terminals = p["terminals"].array ?? []
                seq = p["seq"].uint64 ?? seq
                pushed.missed = true
                pushed.terminals = true
                pushed.changed.formUnion(terminals.compactMap { $0["address"].string })
            case "event":
                if let s = p["seq"].uint64, s <= seq { continue }
                seq = p["seq"].uint64 ?? seq
                if p["type"].string == "doc" {
                    pushed.docs.append(DocChange(name: p["data"]["name"].string ?? "herdr-app",
                                                 machine: p["machine"].string,
                                                 version: p["data"]["version"].uint64))
                } else if apply(p) {
                    pushed.terminals = true
                    if let a = p["terminal"].string {
                        pushed.changed.insert(a)
                        pushed.events.append(TerminalEvent(type: p["type"].string ?? "", terminal: a, data: p["data"]))
                    }
                }
            default:
                break   // heartbeat: liveness only
            }
        }
        return pushed
    }

    /// One event's change to the terminal it names.
    private mutating func apply(_ p: JSONValue) -> Bool {
        let kind = p["type"].string ?? ""
        let address = p["terminal"]
        let data = p["data"]
        let at = terminals.firstIndex { $0["address"] == address }
        let whole: JSONValue? = switch kind {
        case "created", "restarted": data
        case "labels": data["record"].isNull ? nil : data["record"]
        default: nil
        }
        if let record = whole {
            if let i = at { terminals[i] = record } else { terminals.append(record) }
            return true
        }
        guard let i = at else { return false }
        if kind == "removed" { terminals.remove(at: i); return true }
        var t = terminals[i]
        func set(_ keys: [String]) { for k in keys { t[k] = data[k] } }
        switch kind {
        case "finished", "lost":
            set(["reason", "exit_code", "signal", "finished_ms"])
            t["state"] = kind == "lost" ? "live" : "finished"
            if kind == "lost" { t["pid"] = .null }
            t.removeValue(forKey: "foreground")
        case "status": set(["status", "records", "reported"])
        case "turn": set(["turn"])
        case "title": set(["title"])
        case "labels": set(["labels"])
        case "keep": set(["keep"])
        case "size": set(["cols", "rows"])
        case "foreground": t["foreground"] = data
        default: return false
        }
        terminals[i] = t
        return true
    }
}
