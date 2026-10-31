import SwiftUI
import UIKit
import HerdrKit

enum HerdrTheme {
    /// Token name -> "#rrggbb[aa]" for dark (Graphite) or light (Paper);
    /// includes ansi0..ansi15, working/blocked/done/idle, background, foreground, ...
    /// The mod host passes this to mods' theme().
    static func tokens(dark: Bool) -> [String: String] { dark ? graphite : paper }

    // MARK: Palettes (resolved with settings.rs rules)

    private static let graphiteAnsi = ["#45484f", "#dc8c95", "#a6bd91", "#d8be87", "#96b2d7", "#b5a2ce", "#8cbdc3", "#d2d4d9",
                                       "#818793", "#f0a5ad", "#bad5a2", "#ead2a1", "#b0cbef", "#cbb7e6", "#a4d5db", "#f0f0f2"]
    private static let paperAnsi = ["#25272c", "#c62a2a", "#1a7f37", "#8f5d00", "#1f62d0", "#7a45c8", "#0f6f74", "#5f6068",
                                    "#7b7e87", "#d1242f", "#1f883d", "#9a6700", "#0969da", "#8250df", "#1b7c83", "#111214"]

    static let graphite: [String: String] = {
        var t: [String: String] = [
            "background": "#17191d", "surface": "#17191d", "canvas": "#131518", "chrome": "#101114",
            "popover": "#25272b", "raised": "#2c2e31", "hover": "#ffffff0e", "selected": "#ffffff17",
            "border": "#ffffff18", "input": "#ffffff24", "foreground": "#eeeeef", "muted": "#98999b",
            "dim": "#696a6d", "ring": "#aeaeb0", "terminal_foreground": "#d2d4d9", "cursor": "#d2d4d9",
            "selection": "#394454", "accent": "#96b2d7", "accent_foreground": "#17191d",
            "working": "#e5c07b", "blocked": "#f0705f", "done": "#76a8ff", "idle": "#696a6d", "unknown": "#696a6d",
            "solid": "#eeeeef", "solid_foreground": "#111215",
        ]
        for (i, c) in graphiteAnsi.enumerated() { t["ansi\(i)"] = c }
        return t
    }()

    static let paper: [String: String] = {
        var t: [String: String] = [
            "background": "#ffffff", "surface": "#ffffff", "canvas": "#fafaf9", "chrome": "#f1f1ee",
            "popover": "#ffffff", "raised": "#f6f6f6", "hover": "#0000000c", "selected": "#00000012",
            "border": "#00000017", "input": "#00000026", "foreground": "#1b1b1e", "muted": "#69696a",
            "dim": "#969698", "ring": "#5f5f62", "terminal_foreground": "#25272c", "cursor": "#25272c",
            "selection": "#cfdcf5", "accent": "#1f62d0", "accent_foreground": "#ffffff",
            "working": "#9a6700", "blocked": "#c93c2c", "done": "#2f6fe4", "idle": "#a8a8aa", "unknown": "#a8a8aa",
            "solid": "#1b1b1e", "solid_foreground": "#ffffff",
        ]
        for (i, c) in paperAnsi.enumerated() { t["ansi\(i)"] = c }
        return t
    }()

    /// Space badge palette (spaces/main.js:37): fixed, theme-independent.
    static let badgeColors: [String: String] = [
        "ansi6": "#22a99a", "ansi3": "#e3814f", "ansi4": "#5b8def",
        "ansi5": "#8b7cf6", "ansi2": "#3fae6a", "ansi1": "#d9649a",
    ]
    static let badgeOrder = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"]
}

// MARK: Hex parsing

extension UIColor {
    /// "#rgb", "#rrggbb" or "#rrggbbaa". Bad input gives clear.
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else {
            self.init(white: 0, alpha: 0); return
        }
        let has8 = s.count == 8
        let r = CGFloat((v >> (has8 ? 24 : 16)) & 0xff) / 255
        let g = CGFloat((v >> (has8 ? 16 : 8)) & 0xff) / 255
        let b = CGFloat((v >> (has8 ? 8 : 0)) & 0xff) / 255
        let a = has8 ? CGFloat(v & 0xff) / 255 : 1
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// A color that follows the trait collection: Graphite in dark, Paper in light.
    static func herdr(_ token: String) -> UIColor {
        let dark = UIColor(hex: HerdrTheme.graphite[token] ?? "#ff00ff")
        let light = UIColor(hex: HerdrTheme.paper[token] ?? "#ff00ff")
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }
}

extension Color {
    init(hex: String) { self.init(uiColor: UIColor(hex: hex)) }
}

// MARK: Semantic colors (dynamic; no environment plumbing needed)

/// Herdr design tokens as SwiftUI colors. They resolve per color scheme.
enum HC {
    static let background = Color(uiColor: .herdr("background"))
    static let canvas = Color(uiColor: .herdr("canvas"))
    static let chrome = Color(uiColor: .herdr("chrome"))
    static let popover = Color(uiColor: .herdr("popover"))
    static let raised = Color(uiColor: .herdr("raised"))
    static let hover = Color(uiColor: .herdr("hover"))
    static let selected = Color(uiColor: .herdr("selected"))
    static let border = Color(uiColor: .herdr("border"))
    static let input = Color(uiColor: .herdr("input"))
    static let fg = Color(uiColor: .herdr("foreground"))
    static let muted = Color(uiColor: .herdr("muted"))
    static let dim = Color(uiColor: .herdr("dim"))
    static let ring = Color(uiColor: .herdr("ring"))
    static let accent = Color(uiColor: .herdr("accent"))
    static let accentFg = Color(uiColor: .herdr("accent_foreground"))
    static let working = Color(uiColor: .herdr("working"))
    static let blocked = Color(uiColor: .herdr("blocked"))
    static let done = Color(uiColor: .herdr("done"))
    static let idle = Color(uiColor: .herdr("idle"))
    static let solid = Color(uiColor: .herdr("solid"))
    static let solidFg = Color(uiColor: .herdr("solid_foreground"))
    static let connected = Color(uiColor: .herdr("ansi2"))

    static func status(_ a: Attention) -> Color {
        switch a {
        case .working: working
        case .blocked: blocked
        case .done: done
        case .idle, .none: idle
        }
    }

    static func badge(_ key: String?) -> Color {
        Color(hex: HerdrTheme.badgeColors[key ?? "ansi6"] ?? "#22a99a")
    }
}

// MARK: Fonts

enum HF {
    /// PostScript names verified with CTFontManagerCreateFontDescriptorsFromURL.
    static let uiName = "Geist-Regular"
    static let monoName = "JetBrainsMono-Regular"
    static let monoBold = "JetBrainsMono-Regular_Bold"
    static let monoItalic = "JetBrainsMono-Italic"
    static let monoBoldItalic = "JetBrainsMono-Italic_Bold-Italic"

    /// Geist UI text, scaled with Dynamic Type relative to `style`.
    /// Geist ships as static faces (no variable axis), so a weight picks its
    /// face by name; `.weight()` on a custom font would silently stay Regular.
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular, italic: Bool = false, relativeTo style: Font.TextStyle = .body) -> Font {
        Font.custom(uiFace(weight, italic: italic), size: size, relativeTo: style)
    }

    static func uiFace(_ weight: Font.Weight, italic: Bool = false) -> String {
        if italic { return weight == .regular || weight == .light || weight == .thin || weight == .ultraLight ? "Geist-Italic" : "Geist-SemiBoldItalic" }
        switch weight {
        case .medium: return "Geist-Medium"
        case .semibold: return "Geist-SemiBold"
        case .bold, .heavy, .black: return "Geist-Bold"
        default: return uiName
        }
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom(monoName, size: size).weight(weight)
    }

    static func terminalFonts(size: CGFloat) -> (normal: UIFont, bold: UIFont, italic: UIFont, boldItalic: UIFont) {
        let normal = UIFont(name: monoName, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        let bold = UIFont(name: monoBold, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .bold)
        let italic = UIFont(name: monoItalic, size: size) ?? normal
        let boldItalic = UIFont(name: monoBoldItalic, size: size) ?? bold
        return (normal, bold, italic, boldItalic)
    }
}

// MARK: Metrics

enum HM {
    static let rowHeight: CGFloat = 44          // touch-friendly version of the 30pt desktop row
    static let rowRadius: CGFloat = 10
    static let cardRadius: CGFloat = 14
    static let chipRadius: CGFloat = 9
    static let hairline: CGFloat = 1 / UIScreen.main.scale
}

// MARK: Small shared styles

extension View {
    /// Herdr card: background fill, hairline border, radius 10-ish. Content surface (no glass).
    func herdrCard(radius: CGFloat = HM.cardRadius, focused: Bool = false) -> some View {
        self
            .background(HC.background, in: .rect(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(focused ? HC.accent : HC.border, lineWidth: 1))
    }

    /// Section header: 11.5 medium dim, sentence case.
    func herdrSectionHeader() -> some View {
        self.font(HF.ui(12.5, .medium, relativeTo: .footnote)).foregroundStyle(HC.dim)
    }
}

/// Short relative time like the agents list: "<1m", "5m", "2h", "3d".
func herdrSince(_ date: Date?, now: Date = .now) -> String? {
    guard let date else { return nil }
    let s = max(0, now.timeIntervalSince(date))
    if s < 60 { return "<1m" }
    if s < 3600 { return "\(Int(s / 60))m" }
    if s < 86400 { return "\(Int(s / 3600))h" }
    return "\(Int(s / 86400))d"
}
