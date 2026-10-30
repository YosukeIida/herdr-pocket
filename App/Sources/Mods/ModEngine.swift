import Foundation
import JavaScriptCore

// One mod copy running in its own JSContext on the main thread (mods are small:
// a render is a few hundred builder calls). Foundation + JavaScriptCore only, so
// the macOS headless test (scripts/mods-test) runs this exact code.
//
// Wiring: _host.js calls the global __native(name, json); sync calls answer with
// a JSON string, async ones carry a `pid` and are settled later through
// __host.settle(pid, ok, json). Swift drives the copy through __host.*.

struct ModExecOutput: Sendable {
    var code: Int
    var stdout: String
    var stderr: String
}

struct ModFetchRequest: Sendable {
    var url: String
    var method: String
    var headers: [String: String]
    var body: String?
}

struct ModFetchResponse: Sendable {
    var status: Int
    var url: String
    var body: String
}

struct ModFailure: Error, LocalizedError {
    var message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// What a mod copy needs from its host (the app's ModHub, or the test harness).
@MainActor
protocol ModBridge: AnyObject {
    func modExec(_ engine: ModEngine, cmd: String, args: [String], cwd: String?, on: String?) async throws -> ModExecOutput
    func modReadTextFile(_ engine: ModEngine, path: String, on: String?) async throws -> String?
    func modFetch(_ engine: ModEngine, _ request: ModFetchRequest) async throws -> ModFetchResponse
    func modRun(_ engine: ModEngine, name: String, args: Any?)
    func modNotify(_ engine: ModEngine, title: String, body: String?, level: String, timeout: Double?)
    func modPlaySound(_ engine: ModEngine, _ sound: String)
    func modSetShared(_ engine: ModEngine, key: String, value: Any?)
    /// key nil = cleared.
    func modLocalStorage(_ engine: ModEngine, key: String?, value: String?)
    func modLog(_ engine: ModEngine, level: String, _ message: String)
}

@MainActor
final class ModEngine {
    let mod: String
    /// nil for the compact (sidebar) copy, e.g. ["view": "full"] for a sheet copy.
    let props: [String: Any]?
    weak var bridge: ModBridge?

    /// Called once per coalesced render request (next main-queue turn).
    var onRenderRequest: (() -> Void)?

    private(set) var booted = false
    /// Uncaught exceptions and handler errors, newest last (capped).
    private(set) var errors: [String] = []
    /// Number of exec/readTextFile/fetch calls made, for diagnostics.
    private(set) var nativeCalls: [String: Int] = [:]

    private let context: JSContext
    private var host: JSValue?
    private var timers: [Int: DispatchWorkItem] = [:]
    private var inflight = 0
    private var alive = true
    private var renderQueued = false

    init(mod: String, props: [String: Any]?, bridge: ModBridge?) {
        self.mod = mod
        self.props = props
        self.bridge = bridge
        self.context = JSContext()!
        context.name = "mod:\(mod)"
        context.exceptionHandler = { [weak self] ctx, exception in
            ctx?.exception = exception
            let text = Self.describe(exception)
            MainActor.assumeIsolated { self?.record(text) }
        }
        let native: @convention(block) (String, String) -> String? = { [weak self] name, json in
            MainActor.assumeIsolated { self?.handleNative(name, json) }
        }
        context.setObject(native, forKeyedSubscript: "__native" as NSString)
    }

    /// Evaluates the host shim and the bundled mod, then constructs and inits the view.
    func boot(hostSource: String, modSource: String, state: [String: Any], localStorage: [String: String]) throws {
        guard !booted else { return }
        context.evaluateScript(hostSource, withSourceURL: URL(string: "herdr://host/_host.js"))
        if let e = context.exception { context.exception = nil; throw ModFailure("host: \(Self.describe(e))") }
        guard let host = context.objectForKeyedSubscript("__host"), host.isObject else { throw ModFailure("host shim did not load") }
        self.host = host

        let factory = context.evaluateScript(modSource, withSourceURL: URL(string: "herdr://mods/\(mod).js"))
        if let e = context.exception { context.exception = nil; throw ModFailure("\(mod): \(Self.describe(e))") }
        guard let factory, factory.isObject else { throw ModFailure("\(mod): bundle is not a function") }

        let boot: [String: Any] = ["mod": mod, "props": props ?? NSNull(), "localStorage": localStorage, "state": state]
        let result = host.invokeMethod("boot", withArguments: [factory, Self.json(boot)])
        if let e = context.exception { context.exception = nil; throw ModFailure("\(mod) init: \(Self.describe(e))") }
        guard result?.toBool() == true else { throw ModFailure("\(mod): boot failed") }
        booted = true
    }

    /// Pushes live data (spaces, focused, machines, layout, theme, shared, home, settings).
    func setState(_ state: [String: Any]) {
        guard alive, booted else { return }
        host?.invokeMethod("setState", withArguments: [Self.json(state)])
    }

    /// Runs view.render(cx) and returns the tree JSON.
    func renderJSON() -> String {
        guard alive, let host else { return "{\"t\":\"none\"}" }
        renderQueued = false
        return host.invokeMethod("render", withArguments: [])?.toString() ?? "{\"t\":\"none\"}"
    }

    func render() -> ModNode? { ModNode.decode(renderJSON()) }

    /// Invokes a handler of the last render. Returns true when the handler stopped propagation.
    @discardableResult
    func dispatch(_ key: String, _ arg: Any? = nil) -> Bool {
        guard alive, let host else { return false }
        let r = host.invokeMethod("dispatch", withArguments: [key, arg.map(Self.json) ?? "null"])
        return r?.toBool() ?? false
    }

    func input(_ stateID: String, value: String) {
        guard alive else { return }
        host?.invokeMethod("input", withArguments: [stateID, value])
    }

    /// Runs every cx.timer.every / setInterval callback once now (app came to the foreground).
    func fireRepeatingTimers() {
        guard alive, booted else { return }
        host?.invokeMethod("fireRepeating", withArguments: [])
    }

    /// Async native calls not yet answered.
    var pendingCount: Int { inflight }
    var timerCount: Int { timers.count }

    func shutdown() {
        alive = false
        timers.values.forEach { $0.cancel() }
        timers.removeAll()
        onRenderRequest = nil
        host = nil
    }

    // MARK: Native calls from JS

    private func handleNative(_ name: String, _ json: String) -> String? {
        guard alive else { return nil }
        let args = Self.parse(json) as? [String: Any] ?? [:]
        switch name {
        case "render":
            scheduleRender()
        case "timer":
            guard let id = (args["id"] as? NSNumber)?.intValue else { return nil }
            let ms = (args["ms"] as? NSNumber)?.doubleValue ?? 0
            timers[id]?.cancel()
            let item = DispatchWorkItem { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, self.alive else { return }
                    self.timers[id] = nil
                    self.host?.invokeMethod("fire", withArguments: [id])
                }
            }
            timers[id] = item
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, ms) / 1000, execute: item)
        case "clearTimer":
            if let id = (args["id"] as? NSNumber)?.intValue { timers.removeValue(forKey: id)?.cancel() }
        case "exec":
            runAsync(args) { bridge, engine in
                let out = try await bridge.modExec(engine, cmd: args["cmd"] as? String ?? "",
                                                   args: (args["args"] as? [Any])?.map { "\($0)" } ?? [],
                                                   cwd: args["cwd"] as? String, on: args["on"] as? String)
                return ["code": out.code, "stdout": out.stdout, "stderr": out.stderr]
            }
        case "readTextFile":
            runAsync(args) { bridge, engine in
                if let text = try await bridge.modReadTextFile(engine, path: args["path"] as? String ?? "", on: args["on"] as? String) {
                    return text
                }
                return NSNull()
            }
        case "fetch":
            runAsync(args) { bridge, engine in
                let headers = (args["headers"] as? [String: Any])?.mapValues { "\($0)" } ?? [:]
                let req = ModFetchRequest(url: args["url"] as? String ?? "", method: args["method"] as? String ?? "GET",
                                          headers: headers, body: args["body"] as? String)
                let r = try await bridge.modFetch(engine, req)
                return ["status": r.status, "url": r.url, "body": r.body]
            }
        case "run":
            let n = args["name"] as? String ?? ""
            let a = args["args"].flatMap { $0 is NSNull ? nil : $0 }
            // Off the JS stack: run may present UI or re-enter the engine.
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, self.alive else { return }
                    self.bridge?.modRun(self, name: n, args: a)
                }
            }
        case "notify":
            bridge?.modNotify(self, title: args["title"] as? String ?? "", body: args["body"] as? String,
                              level: args["level"] as? String ?? "info", timeout: (args["timeout"] as? NSNumber)?.doubleValue)
        case "playSound":
            bridge?.modPlaySound(self, args["sound"] as? String ?? "")
        case "setShared":
            let key = args["k"] as? String ?? ""
            let value = args["v"].flatMap { $0 is NSNull ? nil : $0 }
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, self.alive else { return }
                    self.bridge?.modSetShared(self, key: key, value: value)
                }
            }
        case "ls.set":
            bridge?.modLocalStorage(self, key: args["k"] as? String ?? "", value: args["v"] as? String)
        case "ls.clear":
            bridge?.modLocalStorage(self, key: nil, value: nil)
        case "log":
            bridge?.modLog(self, level: args["level"] as? String ?? "log", args["msg"] as? String ?? "")
        case "error":
            record("\(args["where"] as? String ?? "js"): \(args["msg"] as? String ?? "")")
        default:
            bridge?.modLog(self, level: "warn", "unknown native call \(name)")
        }
        return nil
    }

    private func runAsync(_ args: [String: Any], _ work: @escaping @MainActor (ModBridge, ModEngine) async throws -> Any) {
        guard let pid = (args["pid"] as? NSNumber)?.intValue else { return }
        guard let bridge else { settle(pid, ok: false, value: "the mod host is gone"); return }
        inflight += 1
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let value = try await work(bridge, self)
                self.inflight -= 1
                self.settle(pid, ok: true, value: value)
            } catch {
                self.inflight -= 1
                self.settle(pid, ok: false, value: (error as? LocalizedError)?.errorDescription ?? "\(error)")
            }
        }
    }

    private func settle(_ pid: Int, ok: Bool, value: Any) {
        guard alive else { return }
        host?.invokeMethod("settle", withArguments: [pid, ok, Self.json(value)])
    }

    private func scheduleRender() {
        guard !renderQueued else { return }
        renderQueued = true
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.alive, self.renderQueued else { return }
                if let cb = self.onRenderRequest { cb() } else { self.renderQueued = false }
            }
        }
    }

    private func record(_ text: String) {
        errors.append(text)
        if errors.count > 50 { errors.removeFirst(errors.count - 50) }
        bridge?.modLog(self, level: "error", text)
    }

    // MARK: JSON helpers

    nonisolated static func json(_ value: Any) -> String {
        if value is NSNull { return "null" }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value) {
            return String(decoding: data, as: UTF8.self)
        }
        // Fragments (strings, numbers, bools).
        if let data = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed) {
            return String(decoding: data, as: UTF8.self)
        }
        return "null"
    }

    nonisolated static func parse(_ json: String) -> Any? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }

    nonisolated static func describe(_ exception: JSValue?) -> String {
        guard let exception else { return "unknown error" }
        let message = exception.toString() ?? "error"
        let line = exception.objectForKeyedSubscript("line")?.toString() ?? "?"
        let stack = exception.objectForKeyedSubscript("stack")?.toString() ?? ""
        return stack.isEmpty || stack == "undefined" ? "\(message) (line \(line))" : "\(message) (line \(line))\n\(stack)"
    }
}
