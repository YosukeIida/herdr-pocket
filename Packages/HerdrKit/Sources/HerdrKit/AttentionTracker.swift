import Foundation

/// Herdr's seen rules (app `model.rs:437-505`) as a pure,
/// persistable value.
public struct AttentionTracker: Codable, Equatable, Sendable {
    public struct Agent: Codable, Equatable, Sendable {
        public var word: String?
        public var seen: Bool
        /// When the word last changed (ms since 1970; 0 = unknown).
        public var since: UInt64
        /// Last turn this device knows about (iOS extra).
        public var turn: UInt64
        public init(word: String? = nil, seen: Bool = true, since: UInt64 = 0, turn: UInt64 = 0) {
            self.word = word; self.seen = seen; self.since = since; self.turn = turn
        }
    }

    public enum Alert: Equatable, Sendable { case blocked, done }

    public private(set) var agents: [String: Agent] = [:]

    public init(agents: [String: Agent] = [:]) { self.agents = agents }

    public static func isBusy(_ w: String?) -> Bool { w == "working" || w == "blocked" || w == "error" }
    public static func isBlocked(_ w: String?) -> Bool { w == "blocked" || w == "error" }

    /// Applies a status word. Returns true when the word changed.
    @discardableResult
    public mutating func setWord(_ address: String, _ word: String?, looking: Bool, turn: UInt64? = nil,
                                 now: UInt64 = Self.nowMs()) -> Bool {
        var a = agents[address] ?? Agent(seen: true)
        if let turn { a.turn = max(a.turn, turn) }
        defer { agents[address] = a }
        if a.word == word { return false }
        let wasBusy = a.word == "working" || a.word == "blocked"
        if word == "working" || word == "blocked" {
            a.seen = true
        } else if word != nil && wasBusy {
            a.seen = looking
        }
        a.word = word
        a.since = now
        return true
    }

    /// Marks what the person is looking at as seen. Returns true if anything changed.
    @discardableResult
    public mutating func markSeen(_ addresses: some Sequence<String>) -> Bool {
        var changed = false
        for addr in addresses where agents[addr]?.seen == false {
            agents[addr]?.seen = true; changed = true
        }
        return changed
    }

    /// What the UI shows.
    public func display(_ address: String) -> Attention {
        guard let a = agents[address], let w = a.word else { return .none }
        switch w {
        case "working": return .working
        case "blocked", "error": return .blocked
        default: return a.seen ? .idle : .done
        }
    }

    /// Needing you always alerts; finishing alerts only if not looking.
    public static func alert(prev: String?, new: String?, looking: Bool) -> Alert? {
        if isBlocked(new) && !isBlocked(prev) { return .blocked }
        if isBusy(prev) && new != nil && !isBusy(new) && !looking { return .done }
        return nil
    }

    /// Restores a saved tracker against the current records: `seen` carries
    /// over only when the word is unchanged; a turn that grew while away and
    /// ended not busy counts as an unseen finish.
    public mutating func restore(_ saved: AttentionTracker, current: [TerminalRecord], now: UInt64 = Self.nowMs()) {
        for t in current where t.isLive {
            let word = t.statusWord
            if agents[t.address] != nil { continue }
            guard let s = saved.agents[t.address] else {
                agents[t.address] = Agent(word: word, seen: true, since: 0, turn: t.turn)
                continue
            }
            var a = Agent(word: word, seen: true, since: s.word == word ? s.since : now, turn: t.turn)
            if s.word == word { a.seen = s.seen }
            if t.turn > s.turn && word != nil && !(word == "working" || word == "blocked") { a.seen = false }
            agents[t.address] = a
        }
    }

    /// Forget terminals that are gone.
    public mutating func prune(keeping live: Set<String>) {
        agents = agents.filter { live.contains($0.key) }
    }

    public static func nowMs() -> UInt64 { UInt64(Date().timeIntervalSince1970 * 1000) }
}

extension Attention {
    /// Max-priority rollup (tab/space status).
    public static func rollup(_ s: some Sequence<Attention>) -> Attention { s.max() ?? .none }
}
