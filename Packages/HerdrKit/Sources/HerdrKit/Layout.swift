import Foundation

// The `herdr-app` layout document: parsing into SpaceRef/TabRef/
// PaneRef, and edit recipes applied to the RAW JSON so fields this client
// doesn't model (sizes, styles, floating blocks, ...) survive the round trip.

extension LayoutDoc {
    /// Spaces in document order, with defaults for missing fields.
    public var spaces: [SpaceRef] { Layout.spaces(from: value) }
}

public enum Layout {
    public static let docName = "herdr-app"

    // MARK: Ids

    /// `prefix` + 32 lowercase hex from 128 random bits (app `model.rs:157-161`).
    public static func newID(_ prefix: String) -> String {
        var g = SystemRandomNumberGenerator()
        let a = g.next() as UInt64, b = g.next() as UInt64
        return prefix + hex16(a) + hex16(b)
    }

    private static func hex16(_ v: UInt64) -> String {
        let s = String(v, radix: 16)
        return String(repeating: "0", count: 16 - s.count) + s
    }

    // MARK: Parse

    public static func spaces(from value: JSONValue) -> [SpaceRef] {
        (value["spaces"].array ?? []).compactMap { sp in
            guard sp.object != nil else { return nil }
            return SpaceRef(id: sp["id"].string ?? "", name: sp["name"].string ?? "", folder: sp["folder"].string ?? "",
                            tabs: (sp["tabs"].array ?? []).compactMap(tab(from:)))
        }
    }

    static func tab(from t: JSONValue) -> TabRef? {
        guard t.object != nil else { return nil }
        return TabRef(id: t["id"].string ?? "", name: t["name"].string ?? "", panes: panes(of: t["root"]))
    }

    /// Pre-order DFS (node, then children left to right) of blocks holding a
    /// terminal or a mod.
    public static func panes(of node: JSONValue) -> [PaneRef] {
        var out: [PaneRef] = []
        walk(node) { n in
            let c = n["content"]
            let terminal = c["terminal"].string, mod = c["mod"].string
            if terminal != nil || mod != nil {
                out.append(PaneRef(id: n["id"].string ?? "", terminal: terminal, mod: mod, modProps: c["props"]))
            }
        }
        return out
    }

    static func walk(_ node: JSONValue, _ visit: (JSONValue) -> Void) {
        guard node.object != nil else { return }
        visit(node)
        for c in node["children"].array ?? [] { walk(c, visit) }
    }

    // MARK: Lookups

    public struct PaneLocation: Equatable, Sendable {
        public var space: String, tab: String, pane: String
        public var spaceIndex: Int, tabIndex: Int
        public init(space: String, tab: String, pane: String, spaceIndex: Int, tabIndex: Int) {
            self.space = space; self.tab = tab; self.pane = pane
            self.spaceIndex = spaceIndex; self.tabIndex = tabIndex
        }
    }

    public static func locate(pane: String, in value: JSONValue) -> PaneLocation? {
        for (si, sp) in spaces(from: value).enumerated() {
            for (ti, t) in sp.tabs.enumerated() where t.panes.contains(where: { $0.id == pane }) {
                return PaneLocation(space: sp.id, tab: t.id, pane: pane, spaceIndex: si, tabIndex: ti)
            }
        }
        return nil
    }

    /// The first pane showing `terminal`.
    public static func locate(terminal: String, in value: JSONValue) -> PaneLocation? {
        for (si, sp) in spaces(from: value).enumerated() {
            for (ti, t) in sp.tabs.enumerated() {
                if let p = t.panes.first(where: { $0.terminal == terminal }) {
                    return PaneLocation(space: sp.id, tab: t.id, pane: p.id, spaceIndex: si, tabIndex: ti)
                }
            }
        }
        return nil
    }

    // MARK: Edits (raw JSON in, raw JSON out)

    public enum EditError: Error, Equatable, LocalizedError {
        case notFound(String)
        public var errorDescription: String? {
            if case .notFound(let what) = self { return "\(what) is no longer in the layout" }
            return nil
        }
    }

    /// A one-pane tab (the root id equals the tab id).
    public static func tabJSON(id: String, name: String, paneID: String, terminal: String) -> JSONValue {
        ["id": .string(id), "name": .string(name),
         "root": ["id": .string(id), "type": "row",
                  "children": [["id": .string(paneID), "type": "block", "content": ["terminal": .string(terminal)]]]]]
    }

    /// Inserts a new tab after `after` (or at the end) in `space`.
    public static func addTab(_ value: JSONValue, space: String, after: String?, tab: JSONValue) throws -> JSONValue {
        var v = normalized(value)
        var spaces = v["spaces"].array ?? []
        guard let si = spaces.firstIndex(where: { $0["id"].string == space }) else { throw EditError.notFound("That space") }
        var tabs = spaces[si]["tabs"].array ?? []
        let at = after.flatMap { a in tabs.firstIndex { $0["id"].string == a } }.map { $0 + 1 } ?? tabs.count
        tabs.insert(tab, at: at)
        spaces[si]["tabs"] = .array(tabs)
        v["spaces"] = .array(spaces)
        return v
    }

    /// `{"id":SP,"name":NAME,"folder":FOLDER,"tabs":[TAB]}`, inserted after `after` (or at the end).
    public static func addSpace(_ value: JSONValue, id: String, name: String = "", folder: String, tab: JSONValue,
                                after: String? = nil) -> JSONValue {
        var v = normalized(value)
        var spaces = v["spaces"].array ?? []
        let sp: JSONValue = ["id": .string(id), "name": .string(name), "folder": .string(folder), "tabs": [tab]]
        let at = after.flatMap { a in spaces.firstIndex { $0["id"].string == a } }.map { $0 + 1 } ?? spaces.count
        spaces.insert(sp, at: at)
        v["spaces"] = .array(spaces)
        return v
    }

    public static func renameTab(_ value: JSONValue, tab: String, to name: String) throws -> JSONValue {
        var v = normalized(value)
        var spaces = v["spaces"].array ?? []
        for si in spaces.indices {
            var tabs = spaces[si]["tabs"].array ?? []
            if let ti = tabs.firstIndex(where: { $0["id"].string == tab }) {
                tabs[ti]["name"] = .string(name)
                spaces[si]["tabs"] = .array(tabs)
                v["spaces"] = .array(spaces)
                return v
            }
        }
        throw EditError.notFound("That tab")
    }

    public static func renameSpace(_ value: JSONValue, space: String, to name: String) throws -> JSONValue {
        var v = normalized(value)
        var spaces = v["spaces"].array ?? []
        guard let si = spaces.firstIndex(where: { $0["id"].string == space }) else { throw EditError.notFound("That space") }
        spaces[si]["name"] = .string(name)
        v["spaces"] = .array(spaces)
        return v
    }

    public struct Removal: Equatable, Sendable {
        public var value: JSONValue
        /// The tab that went away because it had no panes left.
        public var removedTab: String?
        /// The space that went away because it had no tabs left.
        public var removedSpace: String?
        /// The terminal the pane showed.
        public var terminal: String?
    }

    /// Removes a pane: its weight goes to the previous sibling (else the next),
    /// rows/columns left empty vanish, ones left with one child give way to it
    /// (which takes their size); the root is never replaced. A tab left without
    /// panes is removed, and a space left without tabs.
    public static func removePane(_ value: JSONValue, pane: String) throws -> Removal {
        var v = normalized(value)
        var spaces = v["spaces"].array ?? []
        for si in spaces.indices {
            var tabs = spaces[si]["tabs"].array ?? []
            for ti in tabs.indices {
                var root = tabs[ti]["root"]
                let terminal = panes(of: root).first { $0.id == pane }?.terminal
                let wasThere = panes(of: root).contains { $0.id == pane }
                guard wasThere else { continue }
                var r = Removal(value: .null, terminal: terminal)
                if root["id"].string == pane {
                    root = ["id": tabs[ti]["id"], "type": "row", "children": []]
                } else {
                    _ = removeNode(&root, pane)
                    collapse(&root)
                }
                if panes(of: root).isEmpty {
                    r.removedTab = tabs[ti]["id"].string
                    tabs.remove(at: ti)
                } else {
                    tabs[ti]["root"] = root
                }
                if tabs.isEmpty {
                    r.removedSpace = spaces[si]["id"].string
                    spaces.remove(at: si)
                } else {
                    spaces[si]["tabs"] = .array(tabs)
                }
                v["spaces"] = .array(spaces)
                r.value = v
                return r
            }
        }
        throw EditError.notFound("That pane")
    }

    /// `null` (never written) reads as `{spaces:[]}`.
    static func normalized(_ value: JSONValue) -> JSONValue {
        value.object == nil ? ["spaces": []] : value
    }

    private static func isLine(_ n: JSONValue) -> Bool {
        let t = n["type"].string
        return t == "row" || t == "column"
    }

    private static func weight(_ size: JSONValue) -> Double? {
        if size.isNull { return 1 }
        if let w = size["weight"].double { return w }
        return nil   // px
    }

    @discardableResult
    static func removeNode(_ node: inout JSONValue, _ id: String) -> Bool {
        guard var c = node["children"].array else { return false }
        if let i = c.firstIndex(where: { $0["id"].string == id }) {
            let removed = c.remove(at: i)
            if isLine(node), let gone = weight(removed["size"]) {
                let n = max(i - 1, 0)
                if c.indices.contains(n), let w = weight(c[n]["size"]) {
                    c[n]["size"] = ["weight": .number(w + gone)]
                }
            }
            if node["type"].string == "stack", node["active"].string == id {
                node["active"] = c.indices.contains(i) ? c[i]["id"] : (c.last?["id"] ?? .null)
            }
            node["children"] = .array(c)
            return true
        }
        for j in c.indices {
            var child = c[j]
            if removeNode(&child, id) {
                c[j] = child
                node["children"] = .array(c)
                return true
            }
        }
        return false
    }

    static func collapse(_ node: inout JSONValue) {
        guard var c = node["children"].array else { return }
        for j in c.indices { collapse(&c[j]) }
        if node["type"].string != "stack" {
            c.removeAll { isLine($0) && ($0["children"].array ?? []).isEmpty }
            for j in c.indices where isLine(c[j]) && (c[j]["children"].array?.count ?? 0) == 1 {
                let size = c[j]["size"]
                guard var only = c[j]["children"].array?.first else { continue }
                if size.isNull { only.removeValue(forKey: "size") } else { only["size"] = size }
                c[j] = only
            }
        }
        node["children"] = .array(c)
    }
}
