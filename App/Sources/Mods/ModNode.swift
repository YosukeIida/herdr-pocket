import Foundation

// The element tree one mod render produces (see App/Resources/Mods/_host.js for
// the JSON shape). Foundation-only: the macOS headless test decodes with it too.

enum ModLength: Equatable {
    case points(Double)
    case full
}

enum ModAlign: String { case start, center, end, stretch }
enum ModJustify: String { case start, center, end, between, around }

struct ModLoop: Equatable {
    var from: Double
    var to: Double
    var period: Double
}

/// One node's own style (text styles are inherited by the renderer).
struct ModStyle: Equatable {
    var dir: String?            // "row" | "col" | nil (block)
    var items: ModAlign?
    var selfAlign: ModAlign?
    var justify: ModJustify?
    var gap: Double = 0
    var gapX: Double?
    var gapY: Double?
    var wrap = false
    var grow: Double = 0
    var shrink: Double = 1
    var basis0 = false
    var w: ModLength?
    var h: ModLength?
    var minW: Double?
    var minH: Double?
    var maxW: Double?
    var maxH: Double?
    var pt: Double = 0, pr: Double = 0, pb: Double = 0, pl: Double = 0
    var mt: Double = 0, mr: Double = 0, mb: Double = 0, ml: Double = 0
    var absolute = false
    var top: Double?, left: Double?, right: Double?, bottom: Double?
    var bg: String?
    var radius: Double = 0
    var opacity: Double?
    var bt: Double = 0, br: Double = 0, bb: Double = 0, bl: Double = 0
    var borderColor: String?
    var clip = false
    // text (inherited)
    var textSize: Double?
    var textColor: String?
    var weight: Int?
    var family: String?
    var italic: Bool?
    var underline: Bool?
    var strike: Bool?
    var truncate: Bool?
    var lineLimit: Int?
    var textAlign: String?
    var selectable = false
    var plain = false
    // scroll & animation
    var scrollY = false
    var scrollX = false
    var spin: Double?
    var loop: ModLoop?

    var hasBorder: Bool { bt > 0 || br > 0 || bb > 0 || bl > 0 }
    var hasPadding: Bool { pt != 0 || pr != 0 || pb != 0 || pl != 0 }
    var hasMargin: Bool { mt != 0 || mr != 0 || mb != 0 || ml != 0 }

    init() {}

    init(_ d: [String: Any]) {
        func num(_ k: String) -> Double? {
            // JSONSerialization gives NSNumber for numbers and booleans alike.
            guard let n = d[k] as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { return nil }
            let v = n.doubleValue
            return v.isFinite ? v : nil
        }
        func length(_ k: String) -> ModLength? {
            if let s = d[k] as? String { return s == "full" ? .full : Double(s).map(ModLength.points) }
            return num(k).map(ModLength.points)
        }
        dir = d["dir"] as? String
        items = (d["items"] as? String).flatMap(ModAlign.init(rawValue:))
        selfAlign = (d["self"] as? String).flatMap(ModAlign.init(rawValue:))
        justify = (d["justify"] as? String).flatMap(ModJustify.init(rawValue:))
        gap = num("gap") ?? 0
        gapX = num("gapX"); gapY = num("gapY")
        wrap = d["wrap"] as? Bool ?? false
        grow = num("grow") ?? 0
        shrink = num("shrink") ?? 1
        basis0 = d["basis0"] as? Bool ?? false
        w = length("w"); h = length("h")
        minW = num("minW"); minH = num("minH"); maxW = num("maxW"); maxH = num("maxH")
        pt = num("pt") ?? 0; pr = num("pr") ?? 0; pb = num("pb") ?? 0; pl = num("pl") ?? 0
        mt = num("mt") ?? 0; mr = num("mr") ?? 0; mb = num("mb") ?? 0; ml = num("ml") ?? 0
        absolute = (d["pos"] as? String) == "abs"
        top = num("top"); left = num("left"); right = num("right"); bottom = num("bottom")
        bg = d["bg"] as? String
        radius = num("r") ?? 0
        opacity = num("op")
        bt = num("bt") ?? 0; br = num("br") ?? 0; bb = num("bb") ?? 0; bl = num("bl") ?? 0
        borderColor = d["bc"] as? String
        clip = d["clip"] as? Bool ?? false
        textSize = num("ts")
        textColor = d["tc"] as? String
        weight = num("fw").map { Int($0) }
        family = d["ff"] as? String
        italic = d["it"] as? Bool
        underline = d["ul"] as? Bool
        strike = d["strike"] as? Bool
        truncate = (d["trunc"] as? Bool) ?? ((d["nowrap"] as? Bool) == true ? true : nil)
        lineLimit = num("lines").map { Int($0) }
        textAlign = d["ta"] as? String
        selectable = d["sel"] as? Bool ?? false
        plain = d["plain"] as? Bool ?? false
        scrollY = d["scrollY"] as? Bool ?? false
        scrollX = d["scrollX"] as? Bool ?? false
        spin = num("spin")
        if let l = d["loop"] as? [String: Any] {
            loop = ModLoop(from: (l["from"] as? NSNumber)?.doubleValue ?? 0,
                           to: (l["to"] as? NSNumber)?.doubleValue ?? 1,
                           period: max(50, (l["period"] as? NSNumber)?.doubleValue ?? 1000))
        }
    }

    /// The pressed ("hover") overlay: only paint and text color apply.
    func applying(_ o: ModStyle?) -> ModStyle {
        guard let o else { return self }
        var s = self
        if let v = o.bg { s.bg = v }
        if let v = o.textColor { s.textColor = v }
        if let v = o.opacity { s.opacity = v }
        if let v = o.borderColor { s.borderColor = v }
        return s
    }
}

final class ModNode: Identifiable {
    enum Kind: String { case div, svg, text, input, md, vlist, none }

    struct InputInfo: Equatable { var id: String; var placeholder: String; var value: String }
    struct ScrollInfo: Equatable { var id: String; var bottom: Int }

    let kind: Kind
    let elementID: String?
    let style: ModStyle
    let hover: ModStyle?
    let tooltip: String?
    let text: String?
    let src: String?
    let markdown: String?
    let input: InputInfo?
    let scroll: ScrollInfo?
    let rowHeight: Double?
    /// Handler kind ("click", "rclick", "hover", "scroll", "size") -> dispatch key.
    let handlers: [String: String]
    let children: [ModNode]

    init(_ d: [String: Any]) {
        kind = (d["t"] as? String).flatMap(Kind.init(rawValue:)) ?? .none
        elementID = d["id"] as? String
        style = (d["s"] as? [String: Any]).map(ModStyle.init) ?? ModStyle()
        hover = (d["hv"] as? [String: Any]).map(ModStyle.init)
        tooltip = d["tip"] as? String
        text = d["v"] as? String
        src = d["src"] as? String
        markdown = d["md"] as? String
        if let i = d["input"] as? [String: Any], let id = i["id"] as? String {
            input = InputInfo(id: id, placeholder: i["ph"] as? String ?? "", value: i["val"] as? String ?? "")
        } else { input = nil }
        if let s = d["scroll"] as? [String: Any], let id = s["id"] as? String {
            scroll = ScrollInfo(id: id, bottom: (s["bottom"] as? NSNumber)?.intValue ?? 0)
        } else { scroll = nil }
        rowHeight = (d["rowH"] as? NSNumber)?.doubleValue
        handlers = (d["h"] as? [String: String]) ?? [:]
        children = (d["c"] as? [Any])?.compactMap { ($0 as? [String: Any]).map(ModNode.init) } ?? []
    }

    static func decode(_ json: String) -> ModNode? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return ModNode(obj)
    }

    var isText: Bool { kind == .text }
    var isInteractive: Bool { handlers["click"] != nil || handlers["rclick"] != nil || handlers["hover"] != nil || tooltip != nil }

    // MARK: Inspection (tests, debugging)

    var nodeCount: Int { 1 + children.reduce(0) { $0 + $1.nodeCount } }

    /// All text in document order (text nodes and markdown).
    var texts: [String] {
        var out: [String] = []
        func walk(_ n: ModNode) {
            if let t = n.text, !t.isEmpty { out.append(t) }
            if let m = n.markdown, !m.isEmpty { out.append(m) }
            n.children.forEach(walk)
        }
        walk(self)
        return out
    }

    /// Every color string used anywhere in the tree.
    var colors: [String] {
        var out: [String] = []
        func walk(_ n: ModNode) {
            for s in [n.style, n.hover].compactMap({ $0 }) {
                out += [s.bg, s.textColor, s.borderColor].compactMap { $0 }
            }
            n.children.forEach(walk)
        }
        walk(self)
        return out
    }

    var svgSources: Set<String> {
        var out = Set<String>()
        func walk(_ n: ModNode) {
            if let s = n.src { out.insert(s) }
            n.children.forEach(walk)
        }
        walk(self)
        return out
    }
}

/// "#rgb", "#rgba", "#rrggbb" or "#rrggbbaa" (alpha last) -> components 0...1.
struct ModColor: Equatable {
    var r: Double, g: Double, b: Double, a: Double

    init(r: Double, g: Double, b: Double, a: Double) { self.r = r; self.g = g; self.b = b; self.a = a }

    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("#") else { return nil }
        s.removeFirst()
        guard s.allSatisfy(\.isHexDigit) else { return nil }
        if s.count == 3 || s.count == 4 { s = String(s.flatMap { [$0, $0] }) }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        if s.count == 6 {
            r = Double((v >> 16) & 0xff) / 255; g = Double((v >> 8) & 0xff) / 255; b = Double(v & 0xff) / 255; a = 1
        } else {
            r = Double((v >> 24) & 0xff) / 255; g = Double((v >> 16) & 0xff) / 255
            b = Double((v >> 8) & 0xff) / 255; a = Double(v & 0xff) / 255
        }
    }
}
