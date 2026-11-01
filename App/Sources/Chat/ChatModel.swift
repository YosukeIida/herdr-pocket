import SwiftUI
import HerdrKit

/// One entry the box-side script emitted (TranscriptScript).
enum ChatEntry {
    case user(String, Date?)
    case note(String)
    case command(String)
    case compact
    case text(String)
    case tool(id: String, name: String, summary: String, detail: String, at: Date?)
    case result(id: String, isError: Bool, output: String)
    case duration(ms: Int)
}

struct ToolCall: Identifiable, Equatable {
    var id: String
    var name: String
    var summary: String
    var detail: String
    var output: String?
    var isError = false
}

enum ChatStep: Identifiable, Equatable {
    case text(Int, String)
    case tools(Int, [ToolCall])
    var id: Int { switch self { case .text(let i, _), .tools(let i, _): i } }
    var toolCount: Int { if case .tools(_, let c) = self { c.count } else { 0 } }
}

/// One prompt and everything the agent did in answer.
struct ChatTurn: Identifiable, Equatable {
    enum Prompt: Equatable { case user(String), note(String), command(String) }
    var id: Int
    var prompt: Prompt?
    var compacted = false
    var steps: [ChatStep] = []
    var durationMs: Int?
    var startedAt: Date?
}

/// Reads an agent's Claude Code or Codex transcript from the box and folds it into
/// turns. Polls quickly while the agent works, slowly otherwise; never
/// attaches to (or resizes) the terminal.
@MainActor @Observable
final class ChatModel {
    enum Phase: Equatable { case loading, ready, unavailable(String), failed(String) }

    let address: String
    private(set) var phase: Phase = .loading
    private(set) var turns: [ChatTurn] = []
    /// The transcript continues above what was loaded (we only read its tail).
    private(set) var hasEarlier = false
    private(set) var loadingEarlier = false
    private(set) var revision = 0

    private var entries: [ChatEntry] = []
    private var session = ""
    private var offset: Int64 = -1
    /// Where the loaded part of the transcript begins.
    private var start: Int64 = 0
    /// The sequence number of `entries[0]`; earlier windows count down, so ids already shown never change.
    private var firstSeq = 0
    private var loop: Task<Void, Never>?
    private var wake: CheckedContinuation<Void, Never>?
    private var sleeper: Task<Void, Never>?
    private weak var store: AppStore?

    init(address: String) { self.address = address }

    func start(store: AppStore) {
        self.store = store
        #if DEBUG
        if AppStore.isDemo { loadDemo(); return }
        #endif
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.load()
                guard !Task.isCancelled else { return }
                await self.pause()
            }
        }
    }

    func stop() {
        loop?.cancel(); loop = nil
        sleeper?.cancel(); sleeper = nil
        wake?.resume(); wake = nil
    }

    /// Something changed (status, turn): read now instead of waiting.
    func nudge() { wake?.resume(); wake = nil }

    private func pause() async {
        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            wake = c
            // Cancelled so an earlier pause's timer can never end this one early.
            sleeper?.cancel()
            sleeper = Task { [weak self] in
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                self?.nudge()
            }
        }
    }

    /// The transcript script and its leading arguments for this terminal.
    private func invocation(_ store: AppStore) -> [String]? {
        guard let rec = store.terminals[address] else { return nil }
        let codex = store.programKey(of: address) == "codex"
        let context: JSONValue = codex ? ["title": .string(rec.title), "cwd": .string(rec.cwd)] : rec.raw["argv"]
        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
                rec.raw["pid"].int.map(String.init) ?? "0", String(decoding: context.encoded(), as: UTF8.self)]
    }

    /// Reads the window above what is loaded and puts it in front.
    func loadEarlier() async {
        guard hasEarlier, !loadingEarlier, let store, store.phase == .connected, let call = invocation(store) else { return }
        loadingEarlier = true
        defer { loadingEarlier = false }
        guard let r = try? await store.exec(argv: call + [session, "-1", String(start)], cwd: nil, on: nil, timeout: 20, input: nil),
              r.code == 0 else { return }
        var lines = r.stdout.split(separator: UInt8(ascii: "\n"))
        // Anything else (the session changed meanwhile) leaves the chat as it is.
        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())), head["earlier"].bool == true,
              head["session"].string == session else { return }
        let earlier = lines.compactMap { (try? JSONValue.parse(Data($0))).flatMap(Self.entry) }
        entries = earlier + entries
        firstSeq -= earlier.count
        start = Int64(head["start"].double ?? 0)
        hasEarlier = start > 0
        rebuild()
    }

    private func load() async {
        guard let store, store.phase == .connected, let call = invocation(store) else { return }
        for _ in 0..<4 {   // follow "more" a few times on a big backlog
            do {
                let r = try await store.exec(argv: call + [session, String(offset)],
                                             cwd: nil, on: nil, timeout: 20, input: nil)
                guard r.code == 0 else {
                    let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                    phase = .failed(err.isEmpty ? "Couldn't read the conversation." : String(err.suffix(300)))
                    return
                }
                if !apply(r.stdout) { return }
            } catch {
                if case .ready = phase {} else { phase = .failed(error.localizedDescription) }
                return
            }
        }
    }

    /// Returns true when the box has more to send right away.
    private func apply(_ data: Data) -> Bool {
        var lines = data.split(separator: UInt8(ascii: "\n"))
        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())) else { return false }
        if let why = head["why"].string {
            let agent = store?.programKey(of: address) == "codex" ? "Codex" : "Claude Code"
            phase = .unavailable(why == "no-session"
                ? "No \(agent) conversation found for this terminal yet."
                : "\(agent)'s transcript for this session isn't on disk yet.")
            return false
        }
        let fresh = head["fresh"].bool ?? false
        if fresh {
            entries = []
            firstSeq = 0
            session = head["session"].string ?? ""
            start = Int64(head["start"].double ?? 0)
            hasEarlier = start > 0
        }
        offset = Int64(head["next"].double ?? Double(offset))
        var added = false
        for line in lines {
            guard let e = try? JSONValue.parse(Data(line)), let entry = Self.entry(e) else { continue }
            entries.append(entry); added = true
        }
        if fresh || added { rebuild() }
        phase = .ready
        return head["more"].bool ?? false
    }

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
    }()

    private static func entry(_ e: JSONValue) -> ChatEntry? {
        let t = e["t"].string ?? ""
        let ts = e["ts"].string.flatMap { iso.date(from: $0) }
        switch e["k"].string {
        case "user": return .user(t, ts)
        case "note": return .note(t)
        case "cmd": return .command(t)
        case "compact": return .compact
        case "text": return .text(t)
        case "tool": return .tool(id: e["id"].string ?? "", name: e["name"].string ?? "Tool",
                                  summary: e["sum"].string ?? "", detail: e["detail"].string ?? "", at: ts)
        case "result": return .result(id: e["id"].string ?? "", isError: e["err"].bool ?? false, output: e["out"].string ?? "")
        case "dur": return .duration(ms: e["ms"].int ?? 0)
        default: return nil
        }
    }

    /// Folds entries into turns: a prompt starts one; texts and tool calls
    /// follow; consecutive tool calls share a group; results attach by id.
    private func rebuild() {
        var out: [ChatTurn] = []
        var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
        // A turn takes its entry's sequence number times two, a step that number plus one: one entry makes at most one of each.
        var seq = 0
        func next() -> Int { seq * 2 }
        func step() -> Int { seq * 2 + 1 }
        func current() -> Int {
            if out.isEmpty { out.append(ChatTurn(id: next())) }
            return out.count - 1
        }
        for (i, e) in entries.enumerated() {
            seq = firstSeq + i
            switch e {
            case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
            case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
            case .command(let s): out.append(ChatTurn(id: next(), prompt: .command(s)))
            case .compact:
                // A boundary and its "continued from" summary arrive together: one marker.
                if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
                out.append(ChatTurn(id: next(), compacted: true))
            case .text(let s):
                let i = current(); out[i].steps.append(.text(step(), s))
            case .tool(let id, let name, let sum, let detail, let at):
                let i = current()
                if out[i].startedAt == nil { out[i].startedAt = at }
                let call = ToolCall(id: id, name: name, summary: sum, detail: detail)
                if case .tools(let sid, var calls)? = out[i].steps.last {
                    calls.append(call)
                    out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
                    where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
                } else {
                    out[i].steps.append(.tools(step(), [call]))
                    where_[id] = (i, out[i].steps.count - 1, 0)
                }
            case .result(let id, let err, let output):
                guard let w = where_[id], case .tools(let sid, var calls) = out[w.turn].steps[w.step] else { continue }
                calls[w.call].output = output
                calls[w.call].isError = err
                out[w.turn].steps[w.step] = .tools(sid, calls)
            case .duration(let ms):
                if !out.isEmpty { out[out.count - 1].durationMs = ms }
            }
        }
        // A trailing "continued from earlier" marker with nothing after it reads oddly; keep it, it's honest.
        turns = out
        revision += 1
    }
}

// MARK: Display helpers

enum ToolStyle {
    static func symbol(_ name: String) -> String {
        switch name {
        case "Bash", "BashOutput", "KillShell": "terminal"
        case "Read": "doc.text"
        case "Edit", "MultiEdit": "pencil"
        case "Write", "NotebookEdit": "square.and.pencil"
        case "Grep", "Glob", "ToolSearch": "magnifyingglass"
        case "WebSearch", "WebFetch": "globe"
        case "Agent", "Task", "SendMessage": "person.2"
        case "TodoWrite": "checklist"
        case "Skill": "sparkles"
        case "Workflow": "point.3.connected.trianglepath.dotted"
        default: name.hasPrefix("mcp__") ? "puzzlepiece.extension" : "wrench.and.screwdriver"
        }
    }

    /// "mcp__claude-artifacts__get_artifact" -> "claude-artifacts · get_artifact"
    static func title(_ name: String) -> String {
        guard name.hasPrefix("mcp__") else { return name }
        let parts = name.dropFirst(5).components(separatedBy: "__")
        return parts.count >= 2 ? "\(parts[0]) · \(parts.dropFirst().joined(separator: "__"))" : String(name.dropFirst(5))
    }

    static func duration(ms: Int) -> String {
        let s = ms / 1000
        if s < 60 { return "\(max(s, 1))s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \((s % 3600) / 60)m"
    }
}

#if DEBUG
// A canned conversation for screenshots (HERDR_DEMO=1).
extension ChatModel {
    fileprivate func loadDemo() {
        let now = Date()
        entries = [
            .user("Add a global time slider to the analytics dashboard so every chart shares one range", now.addingTimeInterval(-900)),
            .text("I'll start by looking at how the dashboard wires its charts together."),
            .tool(id: "a", name: "Read", summary: "~/projects/webapp/src/dashboard/Dashboard.tsx", detail: "", at: nil),
            .result(id: "a", isError: false, output: "214 lines"),
            .tool(id: "b", name: "Grep", summary: "useTimeRange", detail: "", at: nil),
            .result(id: "b", isError: false, output: "Found 7 files"),
            .tool(id: "c", name: "Edit", summary: "~/projects/webapp/src/dashboard/TimeSlider.tsx", detail: "+ export function TimeSlider({ range, onChange }: TimeSliderProps) {\n+   const [draft, setDraft] = useState(range);", at: nil),
            .result(id: "c", isError: false, output: "Updated with 48 additions and 3 removals"),
            .tool(id: "d", name: "Bash", summary: "Run the dashboard tests", detail: "npm test -- dashboard", at: nil),
            .result(id: "d", isError: false, output: "Tests: 42 passed, 42 total"),
            .text("""
            Every chart on the dashboard now follows **one shared time range**.

            **What changed**
            - A new `TimeSlider` sits in the dashboard header; dragging it updates every chart after a short debounce.
            - Charts read the range from `useTimeRange()` instead of keeping their own.

            | Chart | Before | After |
            |---|---|---|
            | Net flow | own range | shared |
            | Volume | own range | shared |
            | Latency | fixed 24h | shared |

            Tests pass (42/42). Want me to persist the range in the URL so links keep it?
            """),
            .duration(ms: 318_000),
            .user("Yes, put it in the URL", now.addingTimeInterval(-95)),
            .text("Adding a `range` query parameter and reading it on load."),
            .tool(id: "e", name: "Edit", summary: "~/projects/webapp/src/dashboard/useTimeRange.ts", detail: "", at: nil),
            .result(id: "e", isError: false, output: "Updated"),
            .tool(id: "f", name: "Bash", summary: "Type-check the project", detail: "npx tsc --noEmit", at: nil),
        ]
        rebuild()
        phase = .ready
    }
}
#endif
