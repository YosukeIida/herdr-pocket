import Foundation
import HerdrKit

// herdr-probe: exercise HerdrClient against a real core over `ssh -T <host>`.
// READ-ONLY by design: it never calls doc.set, terminal.run/kill/send/keys or
// attaches without observe:true.
//
//   herdr-probe [--host <ssh host>] hello | list | doc [--raw FILE] | events [SECS]
//                                   | attach <terminal> | exec <cmd> [args...]

var args = Array(CommandLine.arguments.dropFirst())
var host = ProcessInfo.processInfo.environment["HERDR_PROBE_HOST"] ?? "localhost"
let home = ProcessInfo.processInfo.environment["HERDR_PROBE_HOME"] ?? "~"
if let i = args.firstIndex(of: "--host"), i + 1 < args.count { host = args[i + 1]; args.removeSubrange(i...i + 1) }
let command = args.first ?? "hello"
let rest = Array(args.dropFirst())

func out(_ s: String) { print(s); fflush(stdout) }
func die(_ s: String) -> Never { FileHandle.standardError.write(Data((s + "\n").utf8)); exit(1) }

let client = HerdrClient(transport: ProcessTransport.ssh(host))
client.callbackQueue = DispatchQueue(label: "probe.callbacks")
client.onDisconnect = { out("! disconnected: \($0.localizedDescription)") }

do {
    let t0 = Date()
    let hello = try await client.connect()
    out("hello: core=\(hello.coreName) id=\(hello.coreID) version=\(hello.version) methods=\(hello.methods.count) (\(Int(Date().timeIntervalSince(t0) * 1000)) ms)")

    switch command {
    case "hello":
        let st = try await client.call("server.status")
        out("server.status: \(st.jsonString.prefix(400))")
        let m = try await client.call("machine.list")
        out("machine.list: \(m.jsonString.prefix(300))")

    case "list":
        let ts = try await client.listTerminals()
        out("\(ts.count) live terminals")
        for t in ts {
            let prog = Programs.identify(app: t.statusApp, argv: t.argv)
            out("\(t.address)\t\(t.statusWord ?? "-")\t\(prog.key)\tturn=\(t.turn)\t\(t.cols)x\(t.rows)\t\(Names.shownTitle(t.title))\t\(t.cwd)")
        }

    case "doc":
        let doc = try await client.docGet()
        out("doc version \(doc.version), \(doc.value.encoded().count) bytes")
        if let i = rest.firstIndex(of: "--raw"), i + 1 < rest.count {
            try doc.value.encoded().write(to: URL(fileURLWithPath: rest[i + 1]))
            out("raw doc written to \(rest[i + 1])")
        }
        let live = Dictionary(try await client.listTerminals().map { ($0.address, $0) }, uniquingKeysWith: { a, _ in a })
        for sp in doc.spaces {
            let firstCwd = sp.tabs.lazy.flatMap(\.panes).compactMap(\.terminal).first.flatMap { live[$0]?.cwd }
            out("space \(sp.id.prefix(10))… \"\(Names.spaceName(sp, firstTerminalCwd: firstCwd, home: home))\" folder=\(sp.folder) tabs=\(sp.tabs.count)")
            for (i, t) in sp.tabs.enumerated() {
                let terms = t.panes.map { p in p.terminal.map { "\($0)[\(live[$0]?.statusWord ?? "·")]" } ?? "mod:\(p.mod ?? "?")" }
                out("    tab \(Names.tabName(t, index: i)) panes: \(terms.joined(separator: " "))")
            }
        }

    case "events":
        let secs = Double(rest.first ?? "20") ?? 20
        let sub = try await client.subscribe()
        out("subscribed: channel \(sub.channel), seq \(sub.snapshotSeq), \(sub.snapshot.count) terminals (\(sub.snapshot.filter(\.isLive).count) live)")
        sub.onUpdate = { u in
            for e in u.pushed.events {
                out("  seq≤\(u.seq) \(e.type) \(e.terminal) \(e.data.jsonString.prefix(140))")
            }
            for d in u.pushed.docs { out("  doc \(d.name) v\(d.version.map(String.init) ?? "?") machine=\(d.machine ?? "-")") }
            if u.pushed.missed { out("  missed: snapshot replaced (\(u.terminals.count))") }
        }
        sub.onClose = { out("  events channel closed by core") }
        try await Task.sleep(for: .seconds(secs))
        out("done after \(Int(secs)) s: \(sub.lineCount) lines (heartbeats included), \(sub.terminals.count) terminals tracked")
        sub.cancel()

    case "attach":
        guard let addr = rest.first else { die("attach <terminal>") }
        let rec = TerminalRecord(raw: try await client.call("terminal.get", ["terminal": .string(addr)]))
        let stream = try await client.attach(terminal: addr, cols: rec.cols, rows: rec.rows, history: 200, observe: true)
        out("attached \(addr) observe:true on channel \(stream.channel) at \(rec.cols)x\(rec.rows)")
        let lock = NSLock()
        var total = 0, chunks = 0
        var first: Data?
        var all = Data()
        stream.onData = { d in lock.withLock { total += d.count; chunks += 1; if first == nil { first = d }; all.append(d) } }
        stream.onClose = { why in out("  closed by core: \(why.jsonString)") }
        stream.onLost = { out("  lost") }
        try await Task.sleep(for: .seconds(3))
        lock.withLock {
            out("first paint: \(first?.count ?? 0) bytes; total \(total) bytes in \(chunks) chunks over 3 s")
            if let f = first {
                let sample = String(decoding: f.prefix(160), as: UTF8.self).unicodeScalars
                    .map { $0.value < 0x20 || $0.value == 0x7f ? String(format: "\\x%02x", $0.value) : String($0) }.joined()
                out("sample: \(sample)")
                let plain = String(decoding: all, as: UTF8.self)
                let osc7501 = plain.components(separatedBy: "\u{1b}]7501;").count - 1
                out("contains reset prefix: \(plain.hasPrefix("\u{1b}[!p")); OSC 7501 records: \(osc7501)")
            }
        }
        stream.detach()
        try await Task.sleep(for: .milliseconds(300))
        out("detached; connection still up: \(client.isConnected)")

    case "exec":
        guard !rest.isEmpty else { die("exec <cmd> [args...]") }
        let r = try await client.exec(argv: rest, timeout: 20)
        out("code=\(r.code.map(String.init) ?? "signal") timed_out=\(r.timedOut) stdout=\(r.stdout.count)B stderr=\(r.stderr.count)B")
        out(String(decoding: r.stdout.prefix(2000), as: UTF8.self))
        if !r.stderr.isEmpty { out("stderr: " + String(decoding: r.stderr.prefix(500), as: UTF8.self)) }

    case "calls":
        // Concurrency + error mapping + cancellation (all read-only).
        async let a = client.call("terminal.list", ["all": false])
        async let b = client.call("server.status")
        async let c = client.docGet()
        let (ra, rb, rc) = try await (a, b, c)
        out("3 concurrent calls ok: \(ra["terminals"].array?.count ?? 0) terminals, uptime \(rb["uptime_ms"].jsonString), doc v\(rc.version)")
        do { _ = try await client.call("terminal.get", ["terminal": "t99999"]) } catch let e as HerdrError {
            out("error mapping: code=\(e.code) kind=\(e.kind ?? "-") text=\(e.localizedDescription)")
        }
        let task = Task { try await client.exec(argv: ["sleep", "20"], timeout: 30) }
        try await Task.sleep(for: .milliseconds(500))
        task.cancel()
        let r = await task.result
        out("cancelled exec -> \(r)")
        let after = try await client.exec(argv: ["echo", "still-alive"])
        out("after cancel: \(String(decoding: after.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))")

    default:
        die("unknown command \(command)")
    }
    client.close()
} catch {
    die("error: \(error.localizedDescription)\nstderr: \(client.stderrText)")
}
