import SwiftUI
import UIKit
import AVFoundation
import Observation
import os
import HerdrKit

/// A mod copy asked to be shown as a sheet (expand ⤢, "Open as pane", layout.show).
struct ModSheet: Identifiable, Equatable {
    let id = UUID()
    var mod: String
    var propsJSON: String
    /// The copy that asked; its panel presents the sheet.
    var requester: String
    /// Opened through shared("big.view"): dismissing clears it.
    var isBigView: Bool

    var props: [String: Any]? {
        guard let data = propsJSON.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

/// The app's mod host: owns every running mod copy, answers their native calls
/// (SPEC §7 routing) and feeds them live data from the AppStore.
@MainActor
@Observable
final class ModHub {
    static let shared = ModHub()

    /// Height cap for scrolling lists inside compact (card) copies.
    var compactListMaxHeight: CGFloat = 230

    private(set) var sheet: ModSheet?
    private(set) var layoutModel: ModLayoutModel = {
        let catalog = ModCatalog.all()
        ModLayoutModel.blocks = Dictionary(uniqueKeysWithValues: catalog.compactMap { m in m.block.map { (m.name, $0) } })
        var m = ModLayoutModel()
        m.mods = catalog.map(\.name)
        return m
    }()
    /// Bumped when the Linear key (or another secret) changes.
    private(set) var secretsVersion = 0

    @ObservationIgnored private weak var store: AppStore?
    @ObservationIgnored private var runtimes: [String: ModRuntime] = [:]
    /// Views showing each full copy; a full copy stops when its last view goes.
    @ObservationIgnored private var refs: [String: Int] = [:]
    @ObservationIgnored private var sharedValues: [String: Any] = [:]
    @ObservationIgnored private var dark = true
    @ObservationIgnored private var observing = false
    @ObservationIgnored private var lastConnected = false
    @ObservationIgnored private let logger = Logger(subsystem: "com.zzulanas.herdr", category: "mods")
    @ObservationIgnored private var hostSource: String?
    @ObservationIgnored private var foregroundObserver: NSObjectProtocol?

    private static let sharedKey = "mods.shared.v1"
    private static let layoutKey = "mods.layout.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.sharedKey),
           let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            sharedValues = obj
        }
        // Which big view is open is per-session UI state, not something to restore.
        sharedValues["big.view"] = nil
        if let data = UserDefaults.standard.data(forKey: Self.layoutKey),
           let sizes = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            layoutModel.sizes = sizes
        }
        layoutModel.mods = ModCatalog.all().map(\.name)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { ModHub.shared.becameActive() }
        }
    }

    // MARK: Store link

    func attach(_ store: AppStore) {
        if self.store !== store {
            self.store = store
            observing = false
        }
        guard !observing else { return }
        observing = true
        observeStore()
    }

    func setDark(_ dark: Bool) {
        guard dark != self.dark else { return }
        self.dark = dark
        pushState()
    }

    private func observeStore() {
        guard let store else { observing = false; return }
        withObservationTracking {
            _ = store.spaces
            _ = store.selectedSpaceID
            _ = store.selectedTabBySpace
            _ = store.phase
            _ = store.home
            _ = store.hello
        } onChange: {
            Task { @MainActor in
                let hub = ModHub.shared
                hub.pushState()
                hub.observing = false
                hub.attachAgain()
            }
        }
        let connected = store.phase == .connected
        if connected != lastConnected {
            lastConnected = connected
            if connected { runtimes.values.forEach { $0.startIfReady() } }
        }
    }

    private func attachAgain() {
        guard let store else { return }
        attach(store)
    }

    var isConnected: Bool { store?.phase == .connected }

    // MARK: Copies

    func runtime(mod: String, props: [String: Any]?) -> ModRuntime {
        let key = ModKeys.copyKey(mod: mod, props: props)
        if let r = runtimes[key] { return r }
        let r = ModRuntime(hub: self, mod: mod, props: props, key: key)
        runtimes[key] = r
        return r
    }

    /// A view started showing `runtime` (balanced by `release`).
    func retain(_ runtime: ModRuntime) {
        guard runtime.props != nil, runtimes[runtime.key] === runtime else { return }
        refs[runtime.key, default: 0] += 1
    }

    /// Full copies (sheets, panes) stop when the last view showing them goes; compact ones live on.
    func release(_ runtime: ModRuntime) {
        guard runtime.props != nil, runtimes[runtime.key] === runtime else { return }
        let n = (refs[runtime.key] ?? 1) - 1
        if n > 0 { refs[runtime.key] = n; return }
        refs[runtime.key] = nil
        runtime.stop()
        runtimes[runtime.key] = nil
    }

    /// Opens a compact copy's full view as a sheet (long-press "Open full view").
    func openFull(from runtime: ModRuntime) {
        present(mod: runtime.mod, props: ["view": "full"], requester: runtime.key, bigView: false)
    }

    /// Restarts every copy (Settings "Reload mods", or after the Linear key changes).
    func reloadAll() {
        for r in runtimes.values { r.restart() }
    }

    func loadHostSource() -> String? {
        if let hostSource { return hostSource }
        guard let url = ModCatalog.file("_host", "js"),
              var s = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        // Optional local quirks for the builder's own mods (Config/host-local.js).
        if let local = ModCatalog.file("_local", "js"), let l = try? String(contentsOf: local, encoding: .utf8) {
            s += "\n;\n" + l
        }
        hostSource = s
        return s
    }

    func localStorage(for mod: String, props: [String: Any]?) -> [String: String] {
        UserDefaults.standard.dictionary(forKey: ModKeys.localStorageKey(mod: mod, props: props)) as? [String: String] ?? [:]
    }

    // MARK: Live state for theme(), spaces(), focused(), machines(), layout(), shared()

    func state() -> [String: Any] {
        let connected = store?.phase == .connected
        let machineName = store?.hello?.coreName ?? ""
        var spaces: [[String: Any]] = []
        let selected = store?.selectedSpaceID
        for (i, s) in (store?.spaces ?? []).enumerated() {
            spaces.append([
                "id": s.id, "index": i, "name": store?.spaceName(s) ?? s.name, "named": !s.name.isEmpty,
                "folder": s.folder, "machine": "devhub", "branch": NSNull(), "active": s.id == selected,
                "status": "idle",
                "tabs": s.tabs.enumerated().map { j, t in ["id": t.id, "name": store?.tabName(t, index: j) ?? t.name] },
            ])
        }
        var focused: Any = NSNull()
        if let sid = selected {
            let tab: Any = store?.selectedTabBySpace[sid] ?? NSNull()
            focused = ["space": sid, "tab": tab, "pane": NSNull(), "terminal": NSNull(), "shown": NSNull(), "agent": NSNull(), "cwd": NSNull()]
        }
        var machines: [[String: Any]] = [["name": NSNull(), "layout": "ready"],
                                         ["name": "devhub", "layout": connected ? "ready" : "unavailable"]]
        if machineName != "devhub" { machines.append(["name": machineName, "layout": connected ? "ready" : "unavailable"]) }
        return [
            "spaces": spaces,
            "focused": focused,
            "machines": machines,
            "layout": layoutModel.tree(),
            "theme": ModTheme.tokens(dark: dark, overrides: HerdrTheme.tokens(dark: dark)),
            "shared": sharedValues,
            "home": store?.home ?? "~",
            "settings": ["font_family": "JetBrains Mono", "dark": dark],
        ]
    }

    private func pushState() {
        let s = state()
        for r in runtimes.values { r.setState(s) }
    }

    private func becameActive() {
        for r in runtimes.values { r.becameActive() }
    }

    // MARK: Sheets

    func dismissSheet() {
        guard let sheet else { return }
        self.sheet = nil
        if sheet.isBigView, sharedValues["big.view"] != nil {
            sharedValues["big.view"] = nil
            persistShared()
            pushState()
        }
        // The sheet's ModPanelView releases its copy when it disappears.
    }

    func sheetBinding(for requester: String) -> Binding<ModSheet?> {
        Binding(
            get: { [weak self] in self?.sheet?.requester == requester ? self?.sheet : nil },
            set: { [weak self] value in if value == nil, self?.sheet?.requester == requester { self?.dismissSheet() } }
        )
    }

    private func present(mod: String, props: [String: Any]?, requester: String, bigView: Bool) {
        guard ModCatalog.all().contains(where: { $0.name == mod }) else {
            logger.info("mod \(mod, privacy: .public) is not bundled; not presenting")
            return
        }
        sheet = ModSheet(mod: mod, propsJSON: ModKeys.propsJSON(props), requester: requester, isBigView: bigView)
    }

    // MARK: Fold state

    func foldedHeight(of mod: String) -> CGFloat? { layoutModel.foldedHeight(mod).map { CGFloat($0) } }

    private func persistLayout() {
        if let data = try? JSONEncoder().encode(layoutModel.sizes) { UserDefaults.standard.set(data, forKey: Self.layoutKey) }
    }

    private func persistShared() {
        var clean = sharedValues
        clean["big.view"] = nil
        if JSONSerialization.isValidJSONObject(clean), let data = try? JSONSerialization.data(withJSONObject: clean) {
            UserDefaults.standard.set(data, forKey: Self.sharedKey)
        }
    }

    // MARK: Secrets

    func setSecret(_ name: String, _ value: String?) {
        ModSecrets.set(name, value)
        secretsVersion += 1
        // Linear reads its key in refresh(): restart its copies so it reads the new one now.
        for r in runtimes.values where r.mod == "linear" { r.restart() }
    }
}

// MARK: - Native calls (SPEC §7)

extension ModHub: ModBridge {
    /// "devhub" (the mods' hard-coded name), the core's own name or the machine label all mean "the box we're on".
    private func route(_ on: String?) -> String? {
        guard let on, !on.isEmpty else { return nil }
        if on == "devhub" || on == store?.hello?.coreName { return nil }
        if let id = store?.activeMachineID, let m = store?.machines.first(where: { $0.id == id }), m.label == on { return nil }
        return on
    }

    func modExec(_ engine: ModEngine, cmd: String, args: [String], cwd: String?, on: String?) async throws -> ModExecOutput {
        // Calls with no `on` ran on the Mac in the desktop app.
        if on == nil || on?.isEmpty == true {
            if cmd == "open" {
                guard let s = args.first, let url = URL(string: s), url.scheme != nil else {
                    return ModExecOutput(code: 1, stdout: "", stderr: "open: no URL")
                }
                let ok = await UIApplication.shared.open(url)
                return ModExecOutput(code: ok ? 0 : 1, stdout: "", stderr: ok ? "" : "could not open \(s)")
            }
            if let text = ModKeys.pbcopyText(cmd: cmd, args: args) {
                UIPasteboard.general.string = text
                return ModExecOutput(code: 0, stdout: "", stderr: "")
            }
        }
        guard let store else { throw ModFailure("devhub is not connected") }
        guard store.phase == .connected else { throw ModFailure("devhub is unreachable") }
        let target = route(on)
        let machine = on ?? store.hello?.coreName ?? "devhub"
        let r: ExecResult
        do {
            r = try await store.exec(argv: [cmd] + args, cwd: cwd, on: target, timeout: 30, input: nil)
        } catch let e as HerdrError {
            throw ModFailure(e.message)
        }
        if r.timedOut { throw ModFailure("\(cmd) took longer than 30 s on \(machine) and was stopped") }
        return ModExecOutput(code: r.code ?? -1,
                             stdout: String(decoding: r.stdout, as: UTF8.self),
                             stderr: String(decoding: r.stderr, as: UTF8.self))
    }

    func modReadTextFile(_ engine: ModEngine, path: String, on: String?) async throws -> String? {
        if let name = ModKeys.secretName(forPath: path), let value = ModSecrets.get(name) {
            return value
        }
        // Everything else is a file on the box (the phone has no ~/.config of its own).
        let r = try await modExec(engine, cmd: "cat", args: ["--", path], cwd: nil, on: on ?? "devhub")
        guard r.code == 0 else { return nil }
        if r.stdout.utf8.count > 1 << 20 { throw ModFailure("\(path) is larger than 1 MiB") }
        return r.stdout
    }

    func modFetch(_ engine: ModEngine, _ request: ModFetchRequest) async throws -> ModFetchResponse {
        guard let url = URL(string: request.url), let scheme = url.scheme, ["http", "https"].contains(scheme) else {
            throw ModFailure("fetch: bad URL \(request.url)")
        }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = request.method.uppercased()
        for (k, v) in request.headers { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = request.body.map { Data($0.utf8) }
        let (data, response) = try await URLSession.shared.data(for: req)
        let http = response as? HTTPURLResponse
        return ModFetchResponse(status: http?.statusCode ?? 0, url: http?.url?.absoluteString ?? request.url,
                                body: String(decoding: data, as: UTF8.self))
    }

    func modRun(_ engine: ModEngine, name: String, args: Any?) {
        let a = args as? [String: Any] ?? [:]
        let requester = ModKeys.copyKey(mod: engine.mod, props: engine.props)
        switch name {
        case "layout.resize":
            if layoutModel.resize(a) {
                persistLayout()
                pushState()
            }
        case "layout.show":
            // toggleFull(): setShared("big.view", mod) then layout.select + layout.show {id:"big"}.
            let mod = sharedValues["big.view"] as? String ?? engine.mod
            present(mod: mod, props: ["view": "full"], requester: requester, bigView: true)
        case "layout.hide":
            if sheet?.isBigView == true { dismissSheet() }
        case "layout.select":
            break
        case "layout.set":
            // A new work-body floating entry {content:{mod, props}} becomes a sheet.
            if let content = Self.floatingContents(in: a["layout"]).first, let mod = content["mod"] as? String {
                present(mod: mod, props: content["props"] as? [String: Any], requester: requester, bigView: false)
            }
        case "pane.split":
            if let mod = a["mod"] as? String {
                present(mod: mod, props: a["props"] as? [String: Any], requester: requester, bigView: false)
            } else if let argv = a["argv"] as? [String] {
                startTerminal(space: nil, argv: argv, task: a["task"] as? String, name: a["name"] as? String, folder: a["folder"] as? String)
            }
        case "tab.new":
            startTerminal(space: a["space"] as? String, argv: a["argv"] as? [String], task: a["task"] as? String,
                          name: (a["name"] as? String) ?? (a["tab"] as? String), folder: a["folder"] as? String)
        case "space.new":
            guard let store else { return }
            let folder = a["folder"] as? String ?? store.home
            let argv = a["argv"] as? [String]
            let task = a["task"] as? String
            let name = a["name"] as? String, tabName = a["tab"] as? String
            Task { @MainActor in
                do {
                    // newSpace selects the new space itself (it returns the terminal address).
                    _ = try await store.newSpace(folder: folder, argv: argv, task: task, name: name, tabName: tabName)
                } catch {
                    store.toast("Couldn't start a space", body: error.localizedDescription, level: "error")
                }
            }
        case "space.select":
            if let id = a["id"] as? String { store?.selectedSpaceID = id }
        default:
            logger.info("mod \(engine.mod, privacy: .public) run(\(name, privacy: .public)) ignored on iOS")
        }
    }

    private func startTerminal(space: String?, argv: [String]?, task: String?, name: String?, folder: String? = nil) {
        guard let store else { return }
        guard let spaceID = space ?? store.selectedSpaceID ?? store.spaces.first?.id else {
            store.toast("No space to start in", body: "Create a space first.", level: "warning")
            return
        }
        Task { @MainActor in
            do {
                _ = try await store.newTab(inSpace: spaceID, argv: argv, task: task, name: name, folder: folder)
                store.selectedSpaceID = spaceID
            } catch {
                store.toast("Couldn't start \(argv?.first ?? "a terminal")", body: error.localizedDescription, level: "error")
            }
        }
    }

    private static func floatingContents(in layout: Any?) -> [[String: Any]] {
        var out: [[String: Any]] = []
        func walk(_ node: Any?) {
            guard let n = node as? [String: Any] else { return }
            for f in n["floating"] as? [[String: Any]] ?? [] {
                if let c = f["content"] as? [String: Any], c["mod"] != nil { out.append(c) }
            }
            for c in n["children"] as? [Any] ?? [] { walk(c) }
        }
        walk(layout)
        return out
    }

    func modNotify(_ engine: ModEngine, title: String, body: String?, level: String, timeout: Double?) {
        let level = ["info", "success", "warning", "error"].contains(level) ? level : "info"
        // Mods pass milliseconds (desktop notify API).
        store?.toast(title, body: body, level: level, address: nil, duration: timeout.flatMap { $0 > 0 ? $0 / 1000 : nil })
    }

    func modPlaySound(_ engine: ModEngine, _ sound: String) {
        let style: UINotificationFeedbackGenerator.FeedbackType = sound == "done" ? .success : .warning
        UINotificationFeedbackGenerator().notificationOccurred(style)
        Sounds.play(sound == "done" ? "done" : "request")
    }

    func modSetShared(_ engine: ModEngine, key: String, value: Any?) {
        let before = sharedValues[key].map { ModEngine.json($0) } ?? "null"
        let after = value.map { ModEngine.json($0) } ?? "null"
        guard before != after else { return }
        sharedValues[key] = value
        persistShared()
        pushState()
    }

    func modLocalStorage(_ engine: ModEngine, key: String?, value: String?) {
        let k = ModKeys.localStorageKey(mod: engine.mod, props: engine.props)
        guard let key else { UserDefaults.standard.removeObject(forKey: k); return }
        var dict = UserDefaults.standard.dictionary(forKey: k) as? [String: String] ?? [:]
        dict[key] = value
        UserDefaults.standard.set(dict, forKey: k)
    }

    func modLog(_ engine: ModEngine, level: String, _ message: String) {
        switch level {
        case "error": logger.error("[\(engine.mod, privacy: .public)] \(message, privacy: .public)")
        case "warn": logger.warning("[\(engine.mod, privacy: .public)] \(message, privacy: .public)")
        default: logger.debug("[\(engine.mod, privacy: .public)] \(message, privacy: .public)")
        }
    }
}

// MARK: - One copy

@MainActor
@Observable
final class ModRuntime {
    enum Phase: Equatable { case waiting, running, failed(String) }

    let mod: String
    let props: [String: Any]?
    let key: String
    private(set) var phase: Phase = .waiting
    private(set) var tree: ModNode?
    /// Bumped on every render so views can react to scroll handles etc.
    private(set) var generation = 0

    @ObservationIgnored private weak var hub: ModHub?
    @ObservationIgnored private var engine: ModEngine?
    @ObservationIgnored private var hoveredKey: String?
    @ObservationIgnored private var hoverEnd: Task<Void, Never>?
    @ObservationIgnored private var lastJSON: String?

    init(hub: ModHub, mod: String, props: [String: Any]?, key: String) {
        self.hub = hub
        self.mod = mod
        self.props = props
        self.key = key
    }

    /// Boots once the box is connected (the mods' first refresh needs it).
    func startIfReady() {
        guard engine == nil, let hub, hub.isConnected else { return }
        guard let host = hub.loadHostSource() else { phase = .failed("The mod host is missing from the app bundle."); return }
        guard let url = ModCatalog.file(mod, "js"),
              let source = try? String(contentsOf: url, encoding: .utf8) else {
            phase = .failed("\(mod) is not bundled with the app."); return
        }
        let engine = ModEngine(mod: mod, props: props, bridge: hub)
        engine.onRenderRequest = { [weak self] in self?.render() }
        do {
            try engine.boot(hostSource: host, modSource: source, state: hub.state(),
                            localStorage: hub.localStorage(for: mod, props: props))
            self.engine = engine
            phase = .running
            render()
        } catch {
            engine.shutdown()
            phase = .failed(error.localizedDescription)
        }
    }

    func stop() {
        engine?.shutdown()
        engine = nil
        tree = nil
        lastJSON = nil
        hoverEnd?.cancel(); hoverEnd = nil; hoveredKey = nil
        phase = .waiting
    }

    func restart() {
        stop()
        startIfReady()
    }

    func setState(_ state: [String: Any]) {
        if engine == nil {
            // A failed copy waits for Retry / Reload instead of re-booting on every push.
            if case .failed = phase { return }
            startIfReady(); return
        }
        engine?.setState(state)
    }

    func becameActive() { engine?.fireRepeatingTimers() }

    func render() {
        guard let engine else { return }
        let json = engine.renderJSON()
        // Most pushes (selection, theme, shared values) don't change the tree: skip the decode and rebuild.
        guard json != lastJSON, let t = ModNode.decode(json) else { return }
        lastJSON = json
        tree = t
        generation &+= 1
    }

    // MARK: Events from the renderer

    @discardableResult
    func dispatch(_ key: String, _ arg: Any? = nil) -> Bool { engine?.dispatch(key, arg) ?? false }

    /// Long-press stands in for hover: one hovered element at a time.
    /// Touch has no "mouse left": the hover ends after a few seconds.
    func hover(_ key: String) {
        if let old = hoveredKey, old != key { engine?.dispatch(old, false) }
        hoveredKey = key
        engine?.dispatch(key, true)
        hoverEnd?.cancel()
        hoverEnd = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, let self, self.hoveredKey == key else { return }
            self.hoveredKey = nil
            self.engine?.dispatch(key, false)
        }
    }

    func input(_ id: String, _ value: String) { engine?.input(id, value: value) }
}
