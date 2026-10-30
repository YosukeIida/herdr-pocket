import SwiftUI

// SwiftUI renderer for the element trees the mods record (ModNode). A
// flexbox-ish subset: rows/columns with gap, grow, alignment and justify;
// padding/margins, fixed and full sizes, paint, borders, absolute overlays,
// vertical scroll, text with inherited styles, Lucide-style svg icons,
// markdown, inputs and the spin/opacity loop animations.

struct ModRenderContext {
    let runtime: ModRuntime
    /// Compact (card) copies cap the height of their scroll areas.
    let compact: Bool
}

/// Text styles inherited down the tree.
struct ModTextStyle {
    var size: Double = 13
    var color: String?
    var weight: Int?
    var family: String?
    var italic = false
    var underline = false
    var strike = false
    var truncate = false
    var lineLimit: Int?
    var align: String?

    static let root = ModTextStyle()

    func merged(_ s: ModStyle) -> ModTextStyle {
        var t = self
        if let v = s.textSize { t.size = v }
        if let v = s.textColor { t.color = v }
        if let v = s.weight { t.weight = v }
        if let v = s.family { t.family = v }
        if let v = s.italic { t.italic = v }
        if let v = s.underline { t.underline = v }
        if let v = s.strike { t.strike = v }
        if let v = s.truncate { t.truncate = v }
        if let v = s.lineLimit { t.lineLimit = v }
        if let v = s.textAlign { t.align = v }
        return t
    }

    var font: Font {
        let w: Font.Weight = switch weight ?? 400 {
        case ..<350: .light
        case ..<450: .regular
        case ..<550: .medium
        case ..<650: .semibold
        case ..<750: .bold
        default: .heavy
        }
        let mono = family.map { $0.localizedCaseInsensitiveContains("mono") || $0.localizedCaseInsensitiveContains("code") } ?? false
        var f = mono ? HF.mono(size, w) : HF.ui(size, w)
        if italic { f = f.italic() }
        return f
    }

    var swiftColor: Color { color.flatMap(Color.init(modHex:)) ?? HC.fg }

    var textAlignment: TextAlignment {
        switch align { case "center": .center; case "right", "end": .trailing; default: .leading }
    }
}

extension Color {
    init?(modHex: String) {
        guard let c = ModColor(hex: modHex) else { return nil }
        self = Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
    }
}

struct ModNodeView: View {
    let node: ModNode
    let text: ModTextStyle
    let ctx: ModRenderContext
    /// The parent's main axis ("row" or "col"), for grow and stretch.
    var parentDir: String
    /// The parent stretches children on the cross axis.
    var stretch: Bool
    /// The available width is decided by an ancestor (not a content-sized row item),
    /// so stretching to it is safe; otherwise stretching would make the node greedy.
    var bounded: Bool = true

    var body: some View {
        if node.handlers["click"] != nil || node.handlers["hover"] != nil || node.handlers["rclick"] != nil {
            interactive
        } else {
            ModStyledNode(node: node, style: node.style, text: text, ctx: ctx, parentDir: parentDir, stretch: stretch, bounded: bounded)
                .modTooltip(node.tooltip, ctx: ctx)
        }
    }

    @ViewBuilder private var interactive: some View {
        let runtime = ctx.runtime
        let click = node.handlers["click"]
        let rclick = node.handlers["rclick"]
        let hover = node.handlers["hover"]
        Button {
            if let click { runtime.dispatch(click) }
        } label: {
            EmptyView()
        }
        .buttonStyle(ModPressStyle(node: node, text: text, ctx: ctx, parentDir: parentDir, stretch: stretch, bounded: bounded))
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
            if let hover { runtime.hover(hover) }
        }, isEnabled: hover != nil)
        .contextMenu(rclick != nil || node.tooltip != nil ? ContextMenu {
            if let tip = node.tooltip, !tip.isEmpty { Text(tip) }
            if let rclick {
                Button("More", systemImage: "ellipsis.circle") { runtime.dispatch(rclick, ["button": "right"]) }
            }
            if ctx.compact { OpenFullButton(runtime: runtime) }
        } : nil)
    }
}

private struct OpenFullButton: View {
    let runtime: ModRuntime
    var body: some View {
        Button("Open full view", systemImage: "arrow.up.left.and.arrow.down.right") { ModHub.shared.openFull(from: runtime) }
    }
}

/// Applies the mod's hover style while the element is pressed.
private struct ModPressStyle: ButtonStyle {
    let node: ModNode
    let text: ModTextStyle
    let ctx: ModRenderContext
    let parentDir: String
    let stretch: Bool
    let bounded: Bool

    func makeBody(configuration: Configuration) -> some View {
        let style = configuration.isPressed ? node.style.applying(node.hover ?? Self.defaultPressed) : node.style
        ModStyledNode(node: node, style: style, text: text, ctx: ctx, parentDir: parentDir, stretch: stretch, bounded: bounded)
            .contentShape(.rect)
            .opacity(configuration.isPressed && node.hover == nil ? 0.6 : 1)
    }

    private static let defaultPressed = ModStyle()
}

private extension View {
    /// The tooltip's menu replaces the card's own long-press menu, so compact
    /// copies repeat "Open full view" in it.
    @ViewBuilder func modTooltip(_ tip: String?, ctx: ModRenderContext) -> some View {
        if let tip, !tip.isEmpty {
            self.contextMenu {
                Text(tip)
                if ctx.compact { OpenFullButton(runtime: ctx.runtime) }
            }
        } else {
            self
        }
    }
}

/// One node with a given (possibly pressed) style.
private struct ModStyledNode: View {
    let node: ModNode
    let style: ModStyle
    let text: ModTextStyle
    let ctx: ModRenderContext
    let parentDir: String
    let stretch: Bool
    let bounded: Bool

    private var stretches: Bool { bounded && (stretch && style.selfAlign == nil || style.selfAlign == .stretch) }

    /// Whether this node's own width is decided from outside (passed to its children).
    private var selfBounded: Bool {
        if style.w != nil { return true }
        if style.grow > 0 && parentDir == "row" { return true }
        return parentDir == "col" && stretches
    }

    /// svg().size(n) sets the frame; the glyph fills it. Falls back to the text size.
    private func iconSize(_ t: ModTextStyle) -> Double {
        if case .points(let w)? = style.w, w > 0 { return w }
        if case .points(let h)? = style.h, h > 0 { return h }
        return t.size
    }

    var body: some View {
        let t = text.merged(style)
        content(t)
            .modBox(style, parentDir: parentDir, stretch: stretches, compact: ctx.compact)
            .modAnimations(style)
            .modSizeReport(node.handlers["size"], runtime: ctx.runtime)
    }

    @ViewBuilder private func content(_ t: ModTextStyle) -> some View {
        switch node.kind {
        case .text:
            Text(node.text ?? "")
                .font(t.font)
                .foregroundStyle(t.swiftColor)
                .underline(t.underline)
                .strikethrough(t.strike)
                .multilineTextAlignment(t.textAlignment)
                .lineLimit(t.truncate ? 1 : t.lineLimit)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: !t.truncate && t.lineLimit == nil)
        case .svg:
            ModIconView(src: node.src ?? "", color: t.swiftColor, size: iconSize(t))
        case .md:
            ModMarkdownView(markdown: node.markdown ?? "", text: t)
        case .input:
            if let input = node.input {
                ModInputView(info: input, text: t, runtime: ctx.runtime)
            }
        case .none:
            EmptyView()
        case .div, .vlist:
            ModContainer(node: node, style: style, text: t, ctx: ctx, bounded: selfBounded)
        }
    }
}

/// Children laid out per the node's direction, with absolute children overlaid.
private struct ModContainer: View {
    let node: ModNode
    let style: ModStyle
    let text: ModTextStyle
    let ctx: ModRenderContext
    let bounded: Bool

    var body: some View {
        let flow = node.children.filter { !$0.style.absolute }
        let floating = node.children.filter { $0.style.absolute }
        laidOut(flow)
            .overlay(alignment: .topLeading) {
                if !floating.isEmpty {
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(floating.enumerated()), id: \.offset) { _, c in
                            ModNodeView(node: c, text: text, ctx: ctx, parentDir: "col", stretch: false)
                                .modAbsolute(c.style)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .modScroll(style, scroll: node.scroll, compact: ctx.compact, onScroll: node.handlers["scroll"].map { key in
                { [runtime = ctx.runtime] in runtime.dispatch(key, ["delta": ["x": 0, "y": 0], "touch": true]) }
            })
    }

    @ViewBuilder private func laidOut(_ children: [ModNode]) -> some View {
        let dir = style.dir ?? "col"
        if dir == "row" {
            let spacing = style.gapX ?? style.gap
            if style.wrap {
                ModWrapLayout(spacing: spacing, lineSpacing: style.gapY ?? style.gap) {
                    rowChildren(children)
                }
            } else {
                HStack(alignment: vAlign, spacing: spacing) {
                    if style.justify == .end || style.justify == .center || style.justify == .around { Spacer(minLength: 0) }
                    rowChildren(children)
                    if style.justify == .center || style.justify == .around { Spacer(minLength: 0) }
                }
            }
        } else {
            let stretch = style.dir == nil || style.items == nil || style.items == .stretch
            let spacing = style.gapY ?? style.gap
            VStack(alignment: hAlign, spacing: spacing) {
                if style.justify == .end || style.justify == .center { Spacer(minLength: 0) }
                ForEach(Array(children.enumerated()), id: \.offset) { i, c in
                    if i > 0, style.justify == .between { Spacer(minLength: 0) }
                    ModNodeView(node: c, text: text, ctx: ctx, parentDir: "col", stretch: stretch, bounded: bounded)
                }
                if style.justify == .center { Spacer(minLength: 0) }
            }
        }
    }

    @ViewBuilder private func rowChildren(_ children: [ModNode]) -> some View {
        ForEach(Array(children.enumerated()), id: \.offset) { i, c in
            if i > 0, style.justify == .between || style.justify == .around { Spacer(minLength: 0) }
            ModNodeView(node: c, text: text, ctx: ctx, parentDir: "row", stretch: false, bounded: false)
        }
    }

    private var vAlign: VerticalAlignment {
        // No items_*: flexbox stretches; top is the closest SwiftUI fit (h_flex sets center itself).
        switch style.items { case .end: .bottom; case .center: .center; default: .top }
    }
    private var hAlign: HorizontalAlignment {
        switch style.items { case .center: .center; case .end: .trailing; default: .leading }
    }
}

// MARK: Box model

private extension View {
    func modBox(_ s: ModStyle, parentDir: String, stretch: Bool, compact: Bool) -> some View {
        let grow = s.grow > 0
        let width: CGFloat? = if case .points(let v) = s.w { CGFloat(v) } else { nil }
        let height: CGFloat? = if case .points(let v) = s.h { CGFloat(v) } else { nil }
        let fullW = s.w == .full || (grow && parentDir == "row") || (stretch && parentDir == "col" && width == nil)
        let fullH = s.h == .full || (grow && parentDir == "col" && !compact)
        let radius = CGFloat(s.radius)
        return self
            .padding(EdgeInsets(top: s.pt, leading: s.pl, bottom: s.pb, trailing: s.pr))
            .frame(width: width, height: height)
            .frame(minWidth: s.minW.map { CGFloat($0) }, maxWidth: fullW ? .infinity : s.maxW.map { CGFloat($0) },
                   minHeight: s.minH.map { CGFloat($0) }, maxHeight: fullH ? .infinity : s.maxH.map { CGFloat($0) },
                   alignment: .topLeading)
            .layoutPriority(grow ? 1 : (s.shrink == 0 ? 2 : 0))
            .fixedSize(horizontal: s.shrink == 0 && parentDir == "row" && width == nil && !grow, vertical: false)
            .background {
                if let bg = s.bg, let c = Color(modHex: bg) {
                    RoundedRectangle(cornerRadius: radius, style: .continuous).fill(c)
                }
            }
            .overlay { ModBorder(style: s) }
            .modClip(s.clip, radius: radius)
            .opacity(s.opacity ?? 1)
            .padding(EdgeInsets(top: s.mt, leading: s.ml, bottom: s.mb, trailing: s.mr))
    }

    @ViewBuilder func modClip(_ on: Bool, radius: CGFloat) -> some View {
        if on { clipShape(.rect(cornerRadius: radius, style: .continuous)) } else { self }
    }

    func modAbsolute(_ s: ModStyle) -> some View {
        let fill = s.top == 0 && s.left == 0 && s.right == 0 && s.bottom == 0
        return self
            .frame(maxWidth: fill || (s.left != nil && s.right != nil) ? .infinity : nil,
                   maxHeight: fill || (s.top != nil && s.bottom != nil) ? .infinity : nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity,
                   alignment: Alignment(horizontal: s.left == nil && s.right != nil ? .trailing : .leading,
                                        vertical: s.top == nil && s.bottom != nil ? .bottom : .top))
            .padding(EdgeInsets(top: s.top ?? 0, leading: s.left ?? 0, bottom: s.bottom ?? 0, trailing: s.right ?? 0))
            .allowsHitTesting(true)
    }

    /// `onScroll` runs when the person starts dragging (the mod's on_scroll_wheel).
    @ViewBuilder func modScroll(_ s: ModStyle, scroll: ModNode.ScrollInfo?, compact: Bool, onScroll: (() -> Void)? = nil) -> some View {
        if s.scrollY {
            ModScrollArea(bottom: scroll?.bottom ?? 0, horizontal: false, onScroll: onScroll) { self }
                .frame(maxHeight: compact ? ModHub.shared.compactListMaxHeight : .infinity)
        } else if s.scrollX {
            ModScrollArea(bottom: 0, horizontal: true, onScroll: onScroll) { self }
        } else {
            self
        }
    }

    @ViewBuilder func modAnimations(_ s: ModStyle) -> some View {
        if let ms = s.spin, ms > 0 {
            modifier(ModSpin(period: ms / 1000))
        } else if let loop = s.loop {
            modifier(ModPulse(loop: loop))
        } else {
            self
        }
    }

    @ViewBuilder func modSizeReport(_ key: String?, runtime: ModRuntime) -> some View {
        if let key {
            onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                runtime.dispatch(key, ["width": Double(size.width.rounded()), "height": Double(size.height.rounded())])
            }
        } else {
            self
        }
    }
}

private struct ModBorder: View {
    let style: ModStyle

    var body: some View {
        if style.hasBorder {
            let color = style.borderColor.flatMap(Color.init(modHex:)) ?? HC.border
            let r = CGFloat(style.radius)
            if style.bt == style.bb, style.bl == style.br, style.bt == style.bl {
                RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(color, lineWidth: CGFloat(style.bt))
            } else {
                ZStack {
                    if style.bt > 0 { color.frame(height: style.bt).frame(maxHeight: .infinity, alignment: .top) }
                    if style.bb > 0 { color.frame(height: style.bb).frame(maxHeight: .infinity, alignment: .bottom) }
                    if style.bl > 0 { color.frame(width: style.bl).frame(maxWidth: .infinity, alignment: .leading) }
                    if style.br > 0 { color.frame(width: style.br).frame(maxWidth: .infinity, alignment: .trailing) }
                }
                .allowsHitTesting(false)
            }
        }
    }
}

private struct ModScrollArea<Content: View>: View {
    let bottom: Int
    let horizontal: Bool
    var onScroll: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(horizontal ? .horizontal : .vertical) {
                content
                Color.clear.frame(width: 1, height: 1).id("end")
            }
            .scrollIndicators(.hidden)
            .onChange(of: bottom) { _, _ in proxy.scrollTo("end", anchor: .bottom) }
            .onScrollPhaseChange { _, phase in
                if phase == .interacting { onScroll?() }
            }
        }
    }
}

private struct ModSpin: ViewModifier {
    let period: Double
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(on ? 360 : 0))
            .animation(.linear(duration: max(0.2, period)).repeatForever(autoreverses: false), value: on)
            .onAppear { on = true }
    }
}

private struct ModPulse: ViewModifier {
    let loop: ModLoop
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .opacity(on ? loop.to : loop.from)
            .animation(.easeInOut(duration: loop.period / 2000).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}

// MARK: Leaves

/// Parsed icons, shared by every copy.
@MainActor
enum ModIcons {
    private static var parsed: [String: ModSVGIcon] = [:]
    private static let sources: [String: String] = {
        guard let url = ModCatalog.file("_icons", "json"),
              let data = try? Data(contentsOf: url),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: String] else { return [:] }
        return obj
    }()

    static func icon(_ src: String) -> ModSVGIcon? {
        if let i = parsed[src] { return i }
        var key = src
        if sources[key] == nil, let alt = sources.keys.first(where: { $0.hasSuffix("/" + (src.split(separator: "/").last.map(String.init) ?? src)) }) {
            key = alt
        }
        guard let svg = sources[key] else { return nil }
        let i = ModSVGIcon.parse(svg)
        parsed[src] = i
        return i
    }
}

private struct ModIconView: View {
    let src: String
    let color: Color
    let size: Double

    var body: some View {
        if let icon = ModIcons.icon(src), !icon.shapes.isEmpty {
            Canvas { gc, sz in
                let vb = icon.viewBox
                let scale = min(sz.width / vb.width, sz.height / vb.height)
                gc.translateBy(x: (sz.width - vb.width * scale) / 2, y: (sz.height - vb.height * scale) / 2)
                gc.scaleBy(x: scale, y: scale)
                gc.translateBy(x: -vb.minX, y: -vb.minY)
                for s in icon.shapes {
                    let path = Path(s.path)
                    let shading = GraphicsContext.Shading.color(color.opacity(Double(s.opacity)))
                    if s.fill { gc.fill(path, with: shading) }
                    if s.stroke {
                        gc.stroke(path, with: shading, style: StrokeStyle(lineWidth: s.lineWidth,
                                                                         lineCap: s.roundCaps ? .round : .butt,
                                                                         lineJoin: s.roundCaps ? .round : .miter))
                    }
                }
            }
            .frame(width: size, height: size)
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }
}

private struct ModMarkdownView: View {
    let markdown: String
    let text: ModTextStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(ModMarkdown.blocks(markdown).enumerated()), id: \.offset) { _, b in
                block(b)
            }
        }
        .font(text.font)
        .foregroundStyle(text.swiftColor)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func block(_ b: ModMarkdown.Block) -> some View {
        switch b {
        case .heading(let level, let s):
            Text(ModMarkdown.inline(s))
                .font(.system(size: text.size + max(0, 5 - Double(level)) * 1.5, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        case .item(let marker, let indent, let s):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(marker).foregroundStyle(HC.dim)
                Text(ModMarkdown.inline(s)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(indent) * 12)
        case .code(let s):
            ScrollView(.horizontal) {
                Text(s).font(HF.mono(max(10, text.size - 1.5))).padding(8)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HC.raised, in: .rect(cornerRadius: 6))
        case .quote(let s):
            Text(ModMarkdown.inline(s))
                .foregroundStyle(HC.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)
                .overlay(alignment: .leading) { HC.border.frame(width: 2) }
        case .rule:
            HC.border.frame(height: 1)
        case .paragraph(let s):
            Text(ModMarkdown.inline(s)).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A small block-level markdown splitter (headings, lists, code fences,
/// quotes, rules, paragraphs); inline styles go through AttributedString.
/// Results are cached by source text, since mods re-render often.
@MainActor
enum ModMarkdown {
    enum Block: Equatable {
        case heading(Int, String), item(String, Int, String), code(String), quote(String), rule, paragraph(String)
    }

    private static var cache: [String: [Block]] = [:]
    private static var inlineCache: [String: AttributedString] = [:]

    static func inline(_ s: String) -> AttributedString {
        if let a = inlineCache[s] { return a }
        let a = (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(s)
        if inlineCache.count > 512 { inlineCache.removeAll() }
        inlineCache[s] = a
        return a
    }

    static func blocks(_ md: String) -> [Block] {
        if let b = cache[md] { return b }
        let b = parse(md)
        if cache.count > 64 { cache.removeAll() }
        cache[md] = b
        return b
    }

    static func parse(_ md: String) -> [Block] {
        var out: [Block] = []
        var para: [String] = []
        var code: [String]?
        func flush() {
            if !para.isEmpty { out.append(.paragraph(para.joined(separator: " "))); para = [] }
        }
        for raw in md.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if var c = code {
                if trimmed.hasPrefix("```") { out.append(.code(c.joined(separator: "\n"))); code = nil }
                else { c.append(line); code = c }
                continue
            }
            if trimmed.hasPrefix("```") { flush(); code = []; continue }
            if trimmed.isEmpty { flush(); continue }
            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix { $0 == "#" }.count
                let rest = trimmed.dropFirst(level)
                if level <= 6, rest.first == " " {
                    flush(); out.append(.heading(level, rest.trimmingCharacters(in: .whitespaces))); continue
                }
            }
            if ["---", "***", "___"].contains(trimmed) { flush(); out.append(.rule); continue }
            if trimmed.hasPrefix(">") {
                flush(); out.append(.quote(trimmed.dropFirst().trimmingCharacters(in: .whitespaces))); continue
            }
            let indent = (line.prefix { $0 == " " }.count) / 2
            if let f = trimmed.first, "-*+".contains(f), trimmed.dropFirst().first == " " {
                flush()
                var text = String(trimmed.dropFirst(2))
                var marker = "•"
                if text.hasPrefix("[ ] ") { marker = "☐"; text.removeFirst(4) }
                else if text.lowercased().hasPrefix("[x] ") { marker = "☑"; text.removeFirst(4) }
                out.append(.item(marker, indent, text)); continue
            }
            if let dot = trimmed.firstIndex(where: { $0 == "." || $0 == ")" }),
               !trimmed[..<dot].isEmpty, trimmed[..<dot].allSatisfy(\.isNumber),
               trimmed[trimmed.index(after: dot)...].first == " " {
                flush()
                out.append(.item(String(trimmed[...dot]), indent, trimmed[trimmed.index(dot, offsetBy: 2)...].trimmingCharacters(in: .whitespaces)))
                continue
            }
            para.append(trimmed)
        }
        if let c = code { out.append(.code(c.joined(separator: "\n"))) }
        flush()
        return out
    }
}

private struct ModInputView: View {
    let info: ModNode.InputInfo
    let text: ModTextStyle
    let runtime: ModRuntime
    @State private var value = ""

    var body: some View {
        TextField(info.placeholder, text: $value)
            .font(text.font)
            .foregroundStyle(text.swiftColor)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onAppear { value = info.value }
            .onChange(of: info.value) { _, v in if v != value { value = v } }
            .onChange(of: value) { _, v in if v != info.value { runtime.input(info.id, v) } }
    }
}

/// flex_wrap rows.
private struct ModWrapLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0, widest: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > maxW { y += line + lineSpacing; x = 0; line = 0 }
            x += s.width + spacing
            line = max(line, s.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + line)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + s.width > bounds.maxX { y += line + lineSpacing; x = bounds.minX; line = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            line = max(line, s.height)
        }
    }
}
