// Headless mod test: runs the app's own ModEngine (JavaScriptCore) with the
// bundled _host.js and mod bundles on macOS, against live data fetched over
// `ssh $MODS_TEST_HOST` with a READ-ONLY allowlist. Every mod is booted as its
// compact copy and its full copies, its timers are fired once, and the rendered
// trees are checked (non-empty, decodable, no thrown exceptions).
//
// Build + run: scripts/mods-test/run.sh
import Foundation
import JavaScriptCore

// MARK: - Config

let env = ProcessInfo.processInfo.environment
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let modsDir = root.appendingPathComponent("App/Resources/Mods")
let sshHost = env["MODS_TEST_HOST"] ?? "localhost"
let testHome = env["MODS_TEST_HOME"] ?? "~"
let verbose = env["MODS_TEST_VERBOSE"] == "1"
let only = env["MODS_TEST_ONLY"].map { Set($0.split(separator: ",").map(String.init)) }

// MARK: - Read-only safety policy for the live box

enum Policy {
    static func check(_ cmd: String, _ args: [String]) throws {
        func deny(_ why: String) -> ModFailure { ModFailure("blocked by test safety policy (\(why)): \(([cmd] + args).joined(separator: " "))") }
        switch cmd {
        case "cat", "echo", "printf", "true":
            return
        case "docker":
            guard let sub = args.first else { throw deny("docker without subcommand") }
            switch sub {
            case "ps", "logs", "inspect": return
            case "exec":
                // docker exec <container> cat <file> | psql ... -c <select> ...
                let rest = Array(args.dropFirst(2))
                if rest.first == "cat" { return }
                if rest.first == "psql" {
                    var i = 0
                    var sawQuery = false
                    while i < rest.count {
                        if rest[i] == "-c", i + 1 < rest.count {
                            let q = rest[i + 1].trimmingCharacters(in: .whitespaces).lowercased()
                            guard q.hasPrefix("select"), !q.contains(";") else { throw deny("non-select psql") }
                            sawQuery = true
                            i += 2
                        } else { i += 1 }
                    }
                    if sawQuery { return }
                }
                throw deny("docker exec")
            default: throw deny("docker \(sub)")
            }
        case "sh":
            guard args.count >= 2, args[0] == "-c" else { throw deny("sh without -c") }
            let script = args[1].replacingOccurrences(of: "2>&1", with: "")
            guard !script.contains(">"), !script.contains(";"), !script.contains("&&"), !script.contains("`"),
                  !script.contains("$(") else { throw deny("shell control") }
            for part in script.split(separator: "|") {
                let word = part.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? ""
                guard ["docker", "grep", "printf", "cat", "tail", "head"].contains(word) else { throw deny("sh \(word)") }
                if word == "docker" {
                    let sub = part.trimmingCharacters(in: .whitespaces).split(separator: " ").dropFirst().first.map(String.init) ?? ""
                    guard ["logs", "ps"].contains(sub) else { throw deny("sh docker \(sub)") }
                }
            }
            return
        case "gh":
            guard args.first == "api", args.count >= 2 else { throw deny("gh non-api") }
            if args[1] == "user" { return }
            if args[1] == "graphql", !args.contains(where: { $0.lowercased().contains("mutation") }),
               !args.contains("-X"), !args.contains("--method") { return }
            throw deny("gh api \(args[1])")
        default:
            throw deny("command not allowlisted")
        }
    }
}

func shQuote(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }

/// Runs argv on the box over ssh with a timeout; returns (code, stdout, stderr).
func sshExec(_ argv: [String], cwd: String?, timeout: TimeInterval = 30) async throws -> ModExecOutput {
    let line = (cwd.map { "cd \(shQuote($0)) && " } ?? "") + "exec " + argv.map(shQuote).joined(separator: " ")
    return try await withCheckedThrowingContinuation { cont in
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        p.arguments = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=10", sshHost, "--", line]
        let out = Pipe(), err = Pipe()
        p.standardOutput = out
        p.standardError = err
        p.standardInput = FileHandle.nullDevice
        var stdoutData = Data(), stderrData = Data()
        let lock = NSLock()
        out.fileHandleForReading.readabilityHandler = { h in let d = h.availableData; lock.lock(); stdoutData.append(d); lock.unlock() }
        err.fileHandleForReading.readabilityHandler = { h in let d = h.availableData; lock.lock(); stderrData.append(d); lock.unlock() }
        let timer = DispatchWorkItem { if p.isRunning { p.terminate() } }
        p.terminationHandler = { proc in
            timer.cancel()
            out.fileHandleForReading.readabilityHandler = nil
            err.fileHandleForReading.readabilityHandler = nil
            let restOut = out.fileHandleForReading.readDataToEndOfFile()
            let restErr = err.fileHandleForReading.readDataToEndOfFile()
            lock.lock(); stdoutData.append(restOut); stderrData.append(restErr)
            let o = String(decoding: stdoutData, as: UTF8.self), e = String(decoding: stderrData, as: UTF8.self)
            lock.unlock()
            if proc.terminationReason == .uncaughtSignal {
                cont.resume(throwing: ModFailure("\(argv.first ?? "") took longer than \(Int(timeout)) s on \(sshHost) and was stopped"))
            } else {
                cont.resume(returning: ModExecOutput(code: Int(proc.terminationStatus), stdout: o, stderr: e))
            }
        }
        do {
            try p.run()
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timer)
        } catch {
            cont.resume(throwing: ModFailure("ssh failed to start: \(error)"))
        }
    }
}

// MARK: - Fake host

@MainActor
final class TestBridge: ModBridge {
    var log: [String] = []
    var execs: [String] = []
    var runs: [String] = []
    var toasts: [String] = []
    var shared: [String: Any] = [:]
    var localStorage: [String: [String: String]] = [:]
    var blocked: [String] = []

    func modExec(_ engine: ModEngine, cmd: String, args: [String], cwd: String?, on: String?) async throws -> ModExecOutput {
        let shown = ([cmd] + args.map { $0.count > 60 ? String($0.prefix(57)) + "…" : $0 }).joined(separator: " ")
        execs.append(shown)
        // Local-on-the-desktop calls the phone handles itself.
        if on == nil || on!.isEmpty {
            if cmd == "open" { return ModExecOutput(code: 0, stdout: "", stderr: "") }
            if ModKeys.pbcopyText(cmd: cmd, args: args) != nil { return ModExecOutput(code: 0, stdout: "", stderr: "") }
        }
        do { try Policy.check(cmd, args) } catch { blocked.append(shown); throw error }
        return try await sshExec([cmd] + args, cwd: cwd)
    }

    func modReadTextFile(_ engine: ModEngine, path: String, on: String?) async throws -> String? {
        if let name = ModKeys.secretName(forPath: path), name == "linear-api-key", let key = env["LINEAR_API_KEY"], !key.isEmpty {
            return key
        }
        execs.append("cat -- \(path)")
        let r = try await sshExec(["cat", "--", path], cwd: nil)
        guard r.code == 0 else { return nil }
        if r.stdout.utf8.count > 1 << 20 { throw ModFailure("\(path) is larger than 1 MiB") }
        return r.stdout
    }

    func modFetch(_ engine: ModEngine, _ request: ModFetchRequest) async throws -> ModFetchResponse {
        guard let url = URL(string: request.url) else { throw ModFailure("bad url \(request.url)") }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = request.method
        for (k, v) in request.headers { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = request.body?.data(using: .utf8)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let http = resp as? HTTPURLResponse
        return ModFetchResponse(status: http?.statusCode ?? 0, url: http?.url?.absoluteString ?? request.url, body: String(decoding: data, as: UTF8.self))
    }

    func modRun(_ engine: ModEngine, name: String, args: Any?) { runs.append("\(name) \(ModEngine.json(args ?? NSNull()))") }
    func modNotify(_ engine: ModEngine, title: String, body: String?, level: String, timeout: Double?) { toasts.append("[\(level)] \(title): \(body ?? "")") }
    func modPlaySound(_ engine: ModEngine, _ sound: String) {}
    func modSetShared(_ engine: ModEngine, key: String, value: Any?) { shared[key] = value }
    func modLocalStorage(_ engine: ModEngine, key: String?, value: String?) {
        let k = ModKeys.localStorageKey(mod: engine.mod, props: engine.props)
        if let key { localStorage[k, default: [:]][key] = value } else { localStorage[k] = [:] }
    }
    func modLog(_ engine: ModEngine, level: String, _ message: String) {
        log.append("[\(engine.mod) \(level)] \(message)")
        if verbose { print("  log [\(level)] \(message)") }
    }
}

// MARK: - Run

@MainActor
func state(bridge: TestBridge) -> [String: Any] {
    [
        "spaces": [["id": "sptest", "index": 0, "name": "demo", "named": true, "folder": "\(testHome)/projects/demo",
                    "machine": sshHost, "branch": NSNull(), "active": true, "status": "idle", "tabs": [] as [Any]]],
        "focused": ["space": "sptest", "tab": NSNull(), "pane": NSNull(), "terminal": NSNull(), "shown": NSNull(), "agent": NSNull(), "cwd": NSNull()],
        "machines": [["name": NSNull(), "layout": "ready"], ["name": sshHost, "layout": "ready"]],
        "layout": ModLayoutModel().tree(),
        "theme": ModTheme.fallback(dark: true),
        "shared": bridge.shared,
        "home": testHome,
        "settings": ["font_family": "JetBrains Mono"],
    ]
}

/// Lets timers and async native calls run until nothing is in flight (or the deadline).
@MainActor
func settle(_ engine: ModEngine, max seconds: Double) async {
    let deadline = Date().addingTimeInterval(seconds)
    var quietSince: Date?
    while Date() < deadline {
        try? await Task.sleep(nanoseconds: 100_000_000)
        if engine.pendingCount == 0 {
            if quietSince == nil { quietSince = Date() }
            if Date().timeIntervalSince(quietSince!) > 0.4 { return }
        } else {
            quietSince = nil
        }
    }
}

struct Outcome { var label: String; var ok: Bool; var lines: [String] }

@MainActor
func runCopy(mod: String, props: [String: Any]?, host: String, bundle: String, bridge: TestBridge, icons: [String: String]) async -> Outcome {
    let label = "\(mod) \(ModKeys.propsJSON(props) == "null" ? "compact" : ModKeys.propsJSON(props))"
    var lines: [String] = []
    var ok = true
    let engine = ModEngine(mod: mod, props: props, bridge: bridge)
    let execsBefore = bridge.execs.count
    let started = Date()
    do {
        try engine.boot(hostSource: host, modSource: bundle, state: state(bridge: bridge),
                        localStorage: bridge.localStorage[ModKeys.localStorageKey(mod: mod, props: props)] ?? [:])
    } catch {
        return Outcome(label: label, ok: false, lines: ["boot failed: \(error.localizedDescription)"])
    }
    _ = engine.render()
    await settle(engine, max: 60)
    // Full views size themselves from on_size_change: report a phone-ish and an iPad-ish width.
    if let first = engine.render(), let sizeKey = findHandler(first, "size") {
        engine.dispatch(sizeKey, ["width": 1024, "height": 700])
    }
    // The app foregrounds: every repeating timer fires once.
    engine.fireRepeatingTimers()
    await settle(engine, max: 60)
    guard let tree = engine.render() else {
        engine.shutdown()
        return Outcome(label: label, ok: false, lines: ["render produced undecodable JSON"])
    }
    let elapsed = Date().timeIntervalSince(started)

    // Checks.
    let texts = tree.texts
    if tree.nodeCount < 3 { ok = false; lines.append("FAIL tree too small (\(tree.nodeCount) nodes)") }
    if texts.isEmpty { ok = false; lines.append("FAIL no text rendered") }
    if texts.contains(where: { $0 == "This mod hit an error" }) { ok = false; lines.append("FAIL render threw") }
    let jsErrors = engine.errors
    if !jsErrors.isEmpty {
        ok = false
        lines.append("FAIL \(jsErrors.count) JS error(s):")
        lines += jsErrors.prefix(5).map { "    " + $0.split(separator: "\n").prefix(3).joined(separator: " | ") }
    }
    let badColors = tree.colors.filter { ModColor(hex: $0) == nil }
    if !badColors.isEmpty { ok = false; lines.append("FAIL unparseable colors: \(Set(badColors).sorted())") }
    for src in tree.svgSources {
        guard let svg = icons[src] else { ok = false; lines.append("FAIL missing icon \(src)"); continue }
        if ModSVGIcon.parse(svg).shapes.isEmpty { ok = false; lines.append("FAIL icon \(src) has no drawable shapes") }
    }
    let handlerCount = countHandlers(tree)
    lines.append("nodes \(tree.nodeCount), texts \(texts.count), handlers \(handlerCount), icons \(tree.svgSources.count), timers \(engine.timerCount), \(String(format: "%.1f", elapsed))s")
    let execs = bridge.execs[execsBefore...]
    lines.append("exec \(execs.count): " + Array(Set(execs.map { $0.split(separator: " ").prefix(3).joined(separator: " ") })).sorted().joined(separator: "; "))
    let sample = texts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.prefix(14).map { $0.count > 48 ? String($0.prefix(45)) + "…" : $0 }
    lines.append("text: " + sample.joined(separator: " · "))
    engine.shutdown()
    return Outcome(label: label, ok: ok, lines: lines)
}

func findHandler(_ n: ModNode, _ kind: String) -> String? {
    if let k = n.handlers[kind] { return k }
    for c in n.children { if let k = findHandler(c, kind) { return k } }
    return nil
}

func countHandlers(_ n: ModNode) -> Int { n.handlers.count + n.children.reduce(0) { $0 + countHandlers($1) } }

@main
struct ModsTest {
    @MainActor
    static func main() async {
        guard let host = try? String(contentsOf: modsDir.appendingPathComponent("_host.js"), encoding: .utf8) else {
            print("FAIL: \(modsDir.path)/_host.js missing"); exit(1)
        }
        let catalogData = (try? Data(contentsOf: modsDir.appendingPathComponent("_catalog.json"))) ?? Data("[]".utf8)
        let catalog = ((try? JSONSerialization.jsonObject(with: catalogData)) as? [[String: Any]]) ?? []
        let iconsData = (try? Data(contentsOf: modsDir.appendingPathComponent("_icons.json"))) ?? Data("{}".utf8)
        let icons = ((try? JSONSerialization.jsonObject(with: iconsData)) as? [String: String]) ?? [:]
        let names = catalog.compactMap { $0["name"] as? String }.filter { only?.contains($0) ?? true }
        if names.isEmpty { print("FAIL: no bundled mods in \(modsDir.path)"); exit(1) }

        let bridge = TestBridge()
        var outcomes: [Outcome] = []
        for name in names {
            guard let bundle = try? String(contentsOf: modsDir.appendingPathComponent("\(name).js"), encoding: .utf8) else {
                outcomes.append(Outcome(label: name, ok: false, lines: ["bundle missing"])); continue
            }
            var copies: [[String: Any]?] = [nil, ["view": "full"]]
            // Extra views a mod offers: MODS_TEST_VIEWS="mod:view,mod:view".
            for pair in (env["MODS_TEST_VIEWS"] ?? "").split(separator: ",") where pair.hasPrefix("\(name):") {
                copies.append(["view": String(pair.dropFirst(name.count + 1))])
            }
            for props in copies {
                print("… \(name) \(ModKeys.propsJSON(props))")
                let o = await runCopy(mod: name, props: props, host: host, bundle: bundle, bridge: bridge, icons: icons)
                outcomes.append(o)
            }
        }

        print("")
        for o in outcomes {
            print("\(o.ok ? "PASS" : "FAIL")  \(o.label)")
            for l in o.lines { print("      \(l)") }
        }
        if !bridge.blocked.isEmpty { print("\nblocked by the read-only policy:\n  " + bridge.blocked.joined(separator: "\n  ")) }
        if !bridge.toasts.isEmpty { print("\nnotify():\n  " + bridge.toasts.joined(separator: "\n  ")) }
        if !bridge.runs.isEmpty { print("\nrun():\n  " + bridge.runs.joined(separator: "\n  ")) }
        let warnings = Set(bridge.log.filter { $0.contains(" warn]") })
        if !warnings.isEmpty { print("\nwarnings:\n  " + warnings.sorted().joined(separator: "\n  ")) }
        let failed = outcomes.filter { !$0.ok }.count
        print("\n\(outcomes.count - failed)/\(outcomes.count) copies passed")
        exit(failed == 0 ? 0 : 1)
    }
}
