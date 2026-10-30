import Foundation
import CoreGraphics

// A small SVG reader for the mods' icons (Lucide-style strokes): <path>, <circle>,
// <ellipse>, <line>, <polyline>, <polygon>, <rect>, with stroke-width,
// stroke-opacity/opacity and fill none/currentColor. Everything is tinted with
// the inherited text color, like the desktop. CoreGraphics only (the headless
// test parses the bundled icons with it too).

struct ModSVGIcon {
    struct Shape {
        var path: CGPath
        var stroke: Bool
        var fill: Bool
        var lineWidth: CGFloat
        var opacity: CGFloat
        var roundCaps: Bool
    }

    var viewBox: CGRect
    var shapes: [Shape]

    static func parse(_ svg: String) -> ModSVGIcon {
        let rootAttrs = attributes(of: firstTag(named: "svg", in: svg) ?? "")
        var viewBox = CGRect(x: 0, y: 0, width: 24, height: 24)
        if let vb = rootAttrs["viewBox"] {
            let n = vb.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
            if n.count == 4, n[2] > 0, n[3] > 0 { viewBox = CGRect(x: n[0], y: n[1], width: n[2], height: n[3]) }
        } else if let w = rootAttrs["width"].flatMap(Double.init), let h = rootAttrs["height"].flatMap(Double.init), w > 0, h > 0 {
            viewBox = CGRect(x: 0, y: 0, width: w, height: h)
        }
        let rootStroke = rootAttrs["stroke"].map { $0 != "none" } ?? false
        let rootFill = rootAttrs["fill"].map { $0 != "none" } ?? !rootStroke
        let rootWidth = rootAttrs["stroke-width"].flatMap(Double.init) ?? 1
        let rootRound = rootAttrs["stroke-linecap"] == "round"

        var shapes: [Shape] = []
        let pattern = try! NSRegularExpression(pattern: #"<(path|circle|ellipse|line|polyline|polygon|rect)\b([^>]*?)/?>"#)
        let ns = svg as NSString
        for m in pattern.matches(in: svg, range: NSRange(location: 0, length: ns.length)) {
            let tag = ns.substring(with: m.range(at: 1))
            let a = attributes(of: ns.substring(with: m.range(at: 2)))
            func d(_ k: String) -> CGFloat { CGFloat(a[k].flatMap(Double.init) ?? 0) }
            let path = CGMutablePath()
            switch tag {
            case "path":
                guard let data = a["d"] else { continue }
                var parser = PathParser(data)
                parser.build(into: path)
            case "circle":
                let r = d("r")
                guard r > 0 else { continue }
                path.addEllipse(in: CGRect(x: d("cx") - r, y: d("cy") - r, width: 2 * r, height: 2 * r))
            case "ellipse":
                let rx = d("rx"), ry = d("ry")
                guard rx > 0, ry > 0 else { continue }
                path.addEllipse(in: CGRect(x: d("cx") - rx, y: d("cy") - ry, width: 2 * rx, height: 2 * ry))
            case "line":
                path.move(to: CGPoint(x: d("x1"), y: d("y1")))
                path.addLine(to: CGPoint(x: d("x2"), y: d("y2")))
            case "polyline", "polygon":
                let n = (a["points"] ?? "").split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
                guard n.count >= 4 else { continue }
                path.move(to: CGPoint(x: n[0], y: n[1]))
                var i = 2
                while i + 1 < n.count { path.addLine(to: CGPoint(x: n[i], y: n[i + 1])); i += 2 }
                if tag == "polygon" { path.closeSubpath() }
            case "rect":
                let rect = CGRect(x: d("x"), y: d("y"), width: d("width"), height: d("height"))
                guard rect.width > 0, rect.height > 0 else { continue }
                let rx = min(a["rx"].flatMap(Double.init).map { CGFloat($0) } ?? d("ry"), rect.width / 2)
                let ry = min(a["ry"].flatMap(Double.init).map { CGFloat($0) } ?? rx, rect.height / 2)
                path.addRoundedRect(in: rect, cornerWidth: rx, cornerHeight: ry)
            default:
                continue
            }
            let stroke = a["stroke"].map { $0 != "none" } ?? rootStroke
            let fill = a["fill"].map { $0 != "none" } ?? rootFill
            let opacity = (a["stroke-opacity"] ?? a["opacity"] ?? a["fill-opacity"]).flatMap(Double.init) ?? 1
            shapes.append(Shape(path: path, stroke: stroke, fill: fill,
                                lineWidth: CGFloat(a["stroke-width"].flatMap(Double.init) ?? rootWidth),
                                opacity: CGFloat(opacity),
                                roundCaps: a["stroke-linecap"].map { $0 == "round" } ?? rootRound))
        }
        return ModSVGIcon(viewBox: viewBox, shapes: shapes)
    }

    private static func firstTag(named name: String, in s: String) -> String? {
        guard let r = s.range(of: "<\(name)\\b[^>]*>", options: .regularExpression) else { return nil }
        return String(s[r])
    }

    private static func attributes(of s: String) -> [String: String] {
        var out: [String: String] = [:]
        let re = try! NSRegularExpression(pattern: #"([A-Za-z_:][-\w:.]*)\s*=\s*"([^"]*)""#)
        let ns = s as NSString
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            out[ns.substring(with: m.range(at: 1))] = ns.substring(with: m.range(at: 2))
        }
        return out
    }
}

/// SVG path data: M L H V C S Q T A Z, absolute and relative, compact numbers and arc flags.
private struct PathParser {
    let chars: [Character]
    var i = 0

    init(_ d: String) { chars = Array(d) }

    mutating func build(into path: CGMutablePath) {
        var cmd: Character = "M"
        var cur = CGPoint.zero, start = CGPoint.zero
        var lastCtrl: CGPoint? = nil
        var lastQuad: CGPoint? = nil
        var guardCount = 0
        while true {
            skipSeparators()
            guard i < chars.count, guardCount < 100_000 else { break }
            guardCount += 1
            if chars[i].isLetter {
                cmd = chars[i]
                i += 1
                if cmd == "Z" || cmd == "z" {
                    path.closeSubpath()
                    cur = start
                    lastCtrl = nil; lastQuad = nil
                    continue
                }
            } else if !(chars[i].isNumber || chars[i] == "-" || chars[i] == "+" || chars[i] == ".") {
                i += 1 // stray character
                continue
            }
            let rel = cmd.isLowercase
            let base = rel ? cur : .zero
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: base.x + x, y: base.y + y) }
            switch cmd.uppercased().first! {
            case "M":
                guard let x = number(), let y = number() else { return }
                cur = pt(x, y); start = cur
                path.move(to: cur)
                cmd = rel ? "l" : "L" // further pairs are line-tos
                lastCtrl = nil; lastQuad = nil
            case "L":
                guard let x = number(), let y = number() else { return }
                cur = pt(x, y)
                if path.isEmpty { path.move(to: cur) } else { path.addLine(to: cur) }
                lastCtrl = nil; lastQuad = nil
            case "H":
                guard let x = number() else { return }
                cur = CGPoint(x: rel ? cur.x + x : x, y: cur.y)
                path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case "V":
                guard let y = number() else { return }
                cur = CGPoint(x: cur.x, y: rel ? cur.y + y : y)
                path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case "C":
                guard let x1 = number(), let y1 = number(), let x2 = number(), let y2 = number(),
                      let x = number(), let y = number() else { return }
                let c2 = pt(x2, y2)
                let end = pt(x, y)
                path.addCurve(to: end, control1: pt(x1, y1), control2: c2)
                cur = end; lastCtrl = c2; lastQuad = nil
            case "S":
                guard let x2 = number(), let y2 = number(), let x = number(), let y = number() else { return }
                let c1 = lastCtrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = pt(x2, y2)
                let end = pt(x, y)
                path.addCurve(to: end, control1: c1, control2: c2)
                cur = end; lastCtrl = c2; lastQuad = nil
            case "Q":
                guard let x1 = number(), let y1 = number(), let x = number(), let y = number() else { return }
                let c = pt(x1, y1)
                let end = pt(x, y)
                path.addQuadCurve(to: end, control: c)
                cur = end; lastQuad = c; lastCtrl = nil
            case "T":
                guard let x = number(), let y = number() else { return }
                let c = lastQuad.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let end = pt(x, y)
                path.addQuadCurve(to: end, control: c)
                cur = end; lastQuad = c; lastCtrl = nil
            case "A":
                guard let rx = number(), let ry = number(), let rot = number(),
                      let large = flag(), let sweep = flag(), let x = number(), let y = number() else { return }
                let end = pt(x, y)
                addArc(path, from: cur, to: end, rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep)
                cur = end; lastCtrl = nil; lastQuad = nil
            default:
                return
            }
        }
    }

    private mutating func skipSeparators() {
        while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i] == "\n" || chars[i] == "\t" || chars[i] == "\r" { i += 1 }
    }

    private mutating func number() -> CGFloat? {
        skipSeparators()
        var s = ""
        var sawDot = false, sawExp = false
        if i < chars.count, chars[i] == "-" || chars[i] == "+" { s.append(chars[i]); i += 1 }
        while i < chars.count {
            let c = chars[i]
            if c.isNumber { s.append(c) }
            else if c == ".", !sawDot, !sawExp { sawDot = true; s.append(c) }
            else if c == "e" || c == "E", !sawExp, !s.isEmpty {
                sawExp = true; s.append(c)
                if i + 1 < chars.count, chars[i + 1] == "-" || chars[i + 1] == "+" { i += 1; s.append(chars[i]) }
            } else { break }
            i += 1
        }
        return Double(s).map { CGFloat($0) }
    }

    private mutating func flag() -> Bool? {
        skipSeparators()
        guard i < chars.count, chars[i] == "0" || chars[i] == "1" else { return nil }
        defer { i += 1 }
        return chars[i] == "1"
    }

    /// SVG endpoint arc -> center parameterization -> cubic segments (SVG 1.1 F.6.5).
    private func addArc(_ path: CGMutablePath, from p0: CGPoint, to p1: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat,
                        rotation: CGFloat, large: Bool, sweep: Bool) {
        var rx = abs(rx0), ry = abs(ry0)
        guard rx > 0, ry > 0, p0 != p1 else { path.addLine(to: p1); return }
        let phi = rotation * .pi / 180
        let cosP = cos(phi), sinP = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cosP * dx + sinP * dy
        let y1 = -sinP * dx + cosP * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var coef = den == 0 ? 0 : sqrt(max(0, num / den))
        if large == sweep { coef = -coef }
        let cx1 = coef * rx * y1 / ry
        let cy1 = -coef * ry * x1 / rx
        let cx = cosP * cx1 - sinP * cy1 + (p0.x + p1.x) / 2
        let cy = sinP * cx1 + cosP * cy1 + (p0.y + p1.y) / 2
        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
        var delta = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
        if !sweep, delta > 0 { delta -= 2 * .pi }
        if sweep, delta < 0 { delta += 2 * .pi }
        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let step = delta / CGFloat(segments)
        let k = 4 / 3 * tan(step / 4)
        var t = theta1
        func point(_ a: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cos(a) * cosP - ry * sin(a) * sinP, y: cy + rx * cos(a) * sinP + ry * sin(a) * cosP)
        }
        func deriv(_ a: CGFloat) -> CGPoint {
            CGPoint(x: -rx * sin(a) * cosP - ry * cos(a) * sinP, y: -rx * sin(a) * sinP + ry * cos(a) * cosP)
        }
        for _ in 0..<segments {
            let a0 = t, a1 = t + step
            let s = point(a0), e = point(a1)
            let d0 = deriv(a0), d1 = deriv(a1)
            path.addCurve(to: e, control1: CGPoint(x: s.x + k * d0.x, y: s.y + k * d0.y),
                          control2: CGPoint(x: e.x - k * d1.x, y: e.y - k * d1.y))
            t = a1
        }
    }
}
