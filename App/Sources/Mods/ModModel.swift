import Foundation

// Platform-independent pieces of the mod host: the theme handed to theme(), the
// synthetic layout() tree, and props/localStorage keys. Foundation only (the
// headless test compiles this file too).

enum ModTheme {
    /// SPEC §6 Graphite (dark) / Paper (light), plus ansi0...15. The app's
    /// HerdrTheme.tokens(dark:) is layered on top when it has values.
    static func fallback(dark: Bool) -> [String: String] {
        var t: [String: String] = dark ? [
            "background": "#17191d", "surface": "#17191d", "canvas": "#131518", "chrome": "#101114",
            "popover": "#25272b", "raised": "#2c2e31", "hover": "#ffffff0e", "selected": "#ffffff17",
            "border": "#ffffff18", "input": "#ffffff24", "foreground": "#eeeeef", "muted": "#98999b",
            "dim": "#696a6d", "ring": "#aeaeb0", "selection": "#394454", "accent": "#96b2d7",
            "accent_foreground": "#17191d", "working": "#e5c07b", "blocked": "#f0705f", "done": "#76a8ff",
            "idle": "#696a6d", "unknown": "#696a6d", "solid": "#eeeeef", "solid_foreground": "#111215",
            "terminal_foreground": "#d2d4d9", "cursor": "#d2d4d9",
        ] : [
            "background": "#ffffff", "surface": "#ffffff", "canvas": "#fafaf9", "chrome": "#f1f1ee",
            "popover": "#ffffff", "raised": "#f6f6f6", "hover": "#0000000c", "selected": "#00000012",
            "border": "#00000017", "input": "#00000026", "foreground": "#1b1b1e", "muted": "#69696a",
            "dim": "#969698", "ring": "#5f5f62", "selection": "#cfdcf5", "accent": "#1f62d0",
            "accent_foreground": "#ffffff", "working": "#9a6700", "blocked": "#c93c2c", "done": "#2f6fe4",
            "idle": "#a8a8aa", "unknown": "#a8a8aa", "solid": "#1b1b1e", "solid_foreground": "#ffffff",
            "terminal_foreground": "#25272c", "cursor": "#25272c",
        ]
        let ansi = dark
            ? ["#45484f", "#dc8c95", "#a6bd91", "#d8be87", "#96b2d7", "#b5a2ce", "#8cbdc3", "#d2d4d9",
               "#818793", "#f0a5ad", "#bad5a2", "#ead2a1", "#b0cbef", "#cbb7e6", "#a4d5db", "#f0f0f2"]
            : ["#25272c", "#c62a2a", "#1a7f37", "#8f5d00", "#1f62d0", "#7a45c8", "#0f6f74", "#5f6068",
               "#7b7e87", "#d1242f", "#1f883d", "#9a6700", "#0969da", "#8250df", "#1b7c83", "#111214"]
        for (i, c) in ansi.enumerated() { t["ansi\(i)"] = c }
        return t
    }

    /// Fallback with `overrides` on top (only well-formed hex values are taken).
    static func tokens(dark: Bool, overrides: [String: String]) -> [String: String] {
        var t = fallback(dark: dark)
        for (k, v) in overrides where ModColor(hex: v) != nil { t[k] = v }
        return t
    }
}

/// The synthetic layout() the mods read: a 268 px sidebar holding one block per
/// mod (fold = px ≤ 45 per SPEC §7) and a work body with the "big" stack.
struct ModLayoutModel {
    /// Block id per mod, as in the desktop layout (a mod finds itself by it to
    /// fold). Defaults to the mod's name; Config/mods.txt can name another.
    static func blockID(for mod: String) -> String { blocks[mod] ?? mod }
    /// Filled from the bundled catalog by ModHub.
    nonisolated(unsafe) static var blocks: [String: String] = [:]
    static let foldedMaxPx = 45.0
    static let sidebarPx = 268.0

    /// block id -> {"px": n} or {"weight": n}
    var sizes: [String: [String: Double]] = [:]
    var mods: [String] = []

    func size(of block: String) -> [String: Double] { sizes[block] ?? ["weight": 1] }

    func isFolded(_ mod: String) -> Bool {
        guard let px = size(of: Self.blockID(for: mod))["px"] else { return false }
        return px <= Self.foldedMaxPx
    }

    func foldedHeight(_ mod: String) -> Double? {
        guard let px = size(of: Self.blockID(for: mod))["px"], px <= Self.foldedMaxPx else { return nil }
        return px
    }

    /// layout.resize {id, px | weight}. Returns false when nothing changed.
    mutating func resize(_ args: [String: Any]) -> Bool {
        guard let id = args["id"] as? String else { return false }
        var next: [String: Double]
        if let px = (args["px"] as? NSNumber)?.doubleValue { next = ["px": px] }
        else if let w = (args["weight"] as? NSNumber)?.doubleValue { next = ["weight": w] }
        else { return false }
        if next == size(of: id) { return false }
        if next == ["weight": 1] { sizes[id] = nil } else { sizes[id] = next }
        return true
    }

    func tree() -> [String: Any] {
        let blocks: [[String: Any]] = mods.map { mod in
            ["id": Self.blockID(for: mod), "type": "block", "size": size(of: Self.blockID(for: mod)), "content": ["mod": mod]]
        }
        let full: [[String: Any]] = mods.map { mod in
            ["id": "\(Self.blockID(for: mod))-full", "type": "block", "size": ["weight": 1],
             "content": ["mod": mod, "props": ["view": "full", "slot": "big"]]]
        }
        return [
            "id": "root", "type": "row", "size": ["weight": 1],
            "children": [
                ["id": "sidebar", "type": "column", "size": ["px": Self.sidebarPx], "children": blocks],
                ["id": "work-body", "type": "column", "size": ["weight": 1], "floating": [] as [Any],
                 "children": [["id": "big", "type": "stack", "size": ["weight": 1], "children": full]]],
            ],
        ]
    }
}

enum ModKeys {
    /// Canonical JSON of a copy's props ("null" for the compact copy).
    static func propsJSON(_ props: [String: Any]?) -> String {
        guard let props, JSONSerialization.isValidJSONObject(props),
              let data = try? JSONSerialization.data(withJSONObject: props, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }

    static func copyKey(mod: String, props: [String: Any]?) -> String { "\(mod)|\(propsJSON(props))" }
    static func localStorageKey(mod: String, props: [String: Any]?) -> String { "ls.\(mod).\(propsJSON(props))" }

    /// readTextFile paths served from the Keychain: "<anything>/.config/herdr-secrets/<name>" -> name.
    static func secretName(forPath path: String) -> String? {
        let marker = "/.config/herdr-secrets/"
        guard let r = path.range(of: marker, options: .backwards) else { return nil }
        let name = String(path[r.upperBound...])
        return name.isEmpty || name.contains("/") ? nil : name
    }

    /// The text written to the clipboard by `sh -c '... | pbcopy' sh <text>`, if this is that call.
    static func pbcopyText(cmd: String, args: [String]) -> String? {
        if cmd == "pbcopy" { return "" }
        guard cmd == "sh", args.count >= 3, args[0] == "-c", args[1].contains("pbcopy") else { return nil }
        return args.count >= 4 ? args[3] : ""
    }
}
