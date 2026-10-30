import Foundation

/// Program identity: which icon and name a terminal shows (port of herdr-app
/// `programs.rs` `resolve`, table from `defaults/programs.json`).
public enum Programs {
    public struct Entry: Sendable, Hashable {
        public var key: String
        public var name: String
        public var match: [String]
        public var tile: String
        public var color: String
        public var tint: Bool
    }

    public struct Program: Sendable, Hashable {
        /// Table key ("claude", "shell", "program", ...); also the icon name (`icons/<key>.svg`).
        public var key: String
        /// What to show ("Claude Code", "zsh", "htop" ...).
        public var name: String
        public var tile: String
        public var color: String
        public var tint: Bool
        public var isShell: Bool
        /// It reports status (an agent).
        public var isAgent: Bool
        public var icon: String { "\(key == "R" ? "r" : key).svg" }
    }

    private static let byKey: [String: Entry] = Dictionary(table.map { ($0.key.lowercased(), $0) }, uniquingKeysWith: { a, _ in a })
    private static let byAlias: [String: Entry] = {
        var m: [String: Entry] = [:]
        for e in table.sorted(by: { $0.key < $1.key }) { for a in e.match where m[a.lowercased()] == nil { m[a.lowercased()] = e } }
        return m
    }()

    public static func find(_ name: String) -> Entry? {
        let l = name.lowercased()
        return byKey[l] ?? byAlias[l]
    }

    /// `agentName(app)`: the table key for a status app (`claude-code` -> `claude`).
    public static func agentKey(_ app: String?) -> String {
        guard let app, !app.isEmpty else { return "unknown" }
        return find(app)?.key ?? "other"
    }

    /// Identity from the status app (if any) and argv (`foreground.argv` when non-empty, else `argv`).
    public static func identify(app: String?, argv: [String]) -> Program {
        if let app, !app.isEmpty {
            if let e = find(app) { return shown(e, name: nil, shell: false, agent: true) }
            return shown(entry("agent"), name: app, shell: false, agent: true)
        }
        // The app's wrapper: `sh -c '"$@"; exec "${SHELL:-sh}" -i' sh <cmd>...`.
        if argv.count > 4, shells.contains(base(argv[0])), argv[1].hasPrefix("-"), argv[1].hasSuffix("c"),
           argv[2].contains("\"$@\"") || argv[2] == "command $argv[2..]; exec $argv[1] -i" {
            return identify(app: nil, argv: Array(argv[4...]))
        }
        guard let firstArg = argv.first else { return shown(entry("shell"), name: nil, shell: true, agent: false) }
        let first = base(firstArg)
        if interpreters.contains(first) {
            for arg in argv.dropFirst() where !arg.hasPrefix("-") {
                let name = base(arg)
                let stem = [".js", ".mjs", ".cjs", ".ts", ".py", ".rb"].first { name.hasSuffix($0) }.map { String(name.dropLast($0.count)) } ?? name
                if let e = find(stem), !interpreters.contains(e.key) { return shown(e, name: nil, shell: false, agent: false) }
            }
        }
        if let e = find(first) { return shown(e, name: nil, shell: false, agent: false) }
        if shells.contains(first) { return shown(entry("shell"), name: first, shell: true, agent: false) }
        var e = entry("program")
        e.tile = hashColor(first); e.color = "#ffffff"
        return shown(e, name: first, shell: false, agent: false)
    }

    public static func identify(_ t: TerminalRecord) -> Program { identify(app: t.statusApp, argv: t.argv) }

    static func base(_ s: String) -> String {
        var b = s.split(whereSeparator: { $0 == "/" || $0 == "\\" }).last.map(String.init) ?? s
        while b.hasPrefix("-") { b.removeFirst() }
        if b.lowercased().hasSuffix(".exe") { b.removeLast(4) }
        return b
    }

    private static func entry(_ key: String) -> Entry {
        byKey[key] ?? Entry(key: key, name: key.capitalized, match: [], tile: "#1c1d21", color: "#d6d8db", tint: true)
    }

    private static func shown(_ e: Entry, name: String?, shell: Bool, agent: Bool) -> Program {
        Program(key: e.key, name: name ?? e.name, tile: e.tile, color: e.color, tint: e.tint, isShell: shell, isAgent: agent)
    }

    /// A color for a program nobody listed, the same every time (FNV-1a).
    static func hashColor(_ s: String) -> String {
        let palette = ["#6d5bd0", "#2f80ed", "#0f9d8a", "#d9822b", "#c2417d", "#3a7d44", "#8a5a44", "#4e5d94"]
        let h = s.utf8.reduce(UInt32(2166136261)) { ($0 ^ UInt32($1)) &* 16777619 }
        return palette[Int(h % UInt32(palette.count))]
    }
}
