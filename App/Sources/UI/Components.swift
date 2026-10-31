import SwiftUI
import HerdrKit

// MARK: Status marks

/// Herdr's status mark: spinner (working), "Needs you" pill (blocked),
/// filled dot (done), hollow ring (idle). `.none` draws nothing.
struct StatusMark: View {
    var attention: Attention
    /// Compact form: blocked becomes a small "!" square (tabs, chips, nav bar).
    var compact = false

    var body: some View {
        mark.accessibilityLabel(label)
    }

    private var label: String {
        switch attention {
        case .working: "Working"
        case .blocked: "Needs you"
        case .done: "Done"
        case .idle: "Idle"
        case .none: ""
        }
    }

    @ViewBuilder private var mark: some View {
        switch attention {
        case .working:
            Spinner(color: HC.working, size: 12)
        case .blocked:
            if compact {
                Text("!")
                    .font(HF.ui(10.5, .bold))
                    .foregroundStyle(HC.blocked)
                    .frame(width: 15, height: 15)
                    .background(HC.blocked.opacity(0.15), in: .rect(cornerRadius: 4))
            } else {
                Text("Needs you")
                    .font(HF.ui(11, .semibold, relativeTo: .caption))
                    .foregroundStyle(HC.blocked)
                    .padding(.horizontal, 6)
                    .frame(height: 19)
                    .background(HC.blocked.opacity(0.15), in: .rect(cornerRadius: 5))
                    .fixedSize()
            }
        case .done:
            Circle().fill(HC.done).frame(width: 7, height: 7).frame(width: 12, height: 12)
        case .idle:
            Circle().strokeBorder(HC.idle, lineWidth: 1.5).frame(width: 7, height: 7).frame(width: 12, height: 12)
        case .none:
            EmptyView()
        }
    }
}

/// 24-unit spinner: 0.24-opacity ring + quarter arc, stroke 3.2/24, one turn per 900 ms.
struct Spinner: View {
    var color: Color
    var size: CGFloat = 12
    @State private var spinning = false

    var body: some View {
        let stroke = size * 3.2 / 24
        ZStack {
            Circle().stroke(color.opacity(0.24), lineWidth: stroke)
            Circle().trim(from: 0, to: 0.25)
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: spinning)
        }
        .padding(stroke / 2 + size * 0.1)
        .frame(width: size, height: size)
        .onAppear { spinning = true }
        .accessibilityLabel("Working")
    }
}

// MARK: Space badge

struct SpaceBadge: View {
    var name: String
    var colorKey: String?
    var size: CGFloat = 22

    var body: some View {
        let noColor = name == "~"
        Text(name.first.map { String($0).uppercased() } ?? "?")
            .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
            .foregroundStyle(noColor ? HC.muted : .white)
            .frame(width: size, height: size)
            .background(noColor ? HC.selected : HC.badge(colorKey), in: .rect(cornerRadius: size * 5 / 18))
    }

    /// Stable color for a space when the desktop's shared.json assignment isn't known.
    static func colorKey(for spaceID: String) -> String {
        var h: UInt32 = 2166136261
        for b in spaceID.utf8 { h = (h ^ UInt32(b)) &* 16777619 }
        return HerdrTheme.badgeOrder[Int(h % UInt32(HerdrTheme.badgeOrder.count))]
    }
}

// MARK: Program icon

struct ProgramIcon: View {
    var program: String?
    var size: CGFloat = 18

    var body: some View {
        let info = ProgramCatalog.info(program) ?? ProgramCatalog.info(program == nil ? "shell" : "program")
        if let info {
            Image("prog-\(info.key)")
                .resizable()
                .renderingMode(info.tint ? .template : .original)
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(HC.muted)
                .frame(width: size, height: size)
                .accessibilityLabel(info.name)
        } else {
            Image(systemName: "terminal").font(.system(size: size * 0.8)).foregroundStyle(HC.muted)
                .frame(width: size, height: size)
        }
    }
}

// MARK: Rows

/// Agent row: program icon, label, time since, status mark. 44pt touch row.
struct AgentRowView: View {
    var row: AgentRow
    var indent = false
    var machine: String? = nil
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Accessibility sizes: time and status move under the name so it isn't squeezed to "OAu…".
        if typeSize.isAccessibilitySize {
            HStack(alignment: .top, spacing: 10) {
                if indent { elbow }
                ProgramIcon(program: row.program, size: indent ? 15 : 18).padding(.top, 3)
                VStack(alignment: .leading, spacing: 4) {
                    name.lineLimit(3)
                    HStack(spacing: 8) {
                        StatusMark(attention: row.attention)
                        if let since = herdrSince(row.since) {
                            Text(since).font(HF.ui(12.5, relativeTo: .caption)).foregroundStyle(HC.dim).monospacedDigit()
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
        } else {
            row1
        }
    }

    private var elbow: some View {
        TreeElbow().stroke(HC.input, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 14, height: 22)
            .padding(.leading, 10)
    }

    private var name: some View {
        Text(row.label)
            .font(HF.ui(indent ? 14.5 : 15.5, .medium))
            .foregroundStyle(row.attention == .idle ? HC.muted : HC.fg)
    }

    private var row1: some View {
        HStack(spacing: 10) {
            if indent { elbow }
            ProgramIcon(program: row.program, size: indent ? 15 : 18)
            name.lineLimit(1)
            Spacer(minLength: 6)
            if let since = herdrSince(row.since) {
                Text(since).font(HF.ui(12.5, relativeTo: .caption)).foregroundStyle(HC.dim).monospacedDigit()
            }
            StatusMark(attention: row.attention)
        }
        .frame(minHeight: indent ? 38 : HM.rowHeight)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// The 1.5pt rounded tree line for sub-agents.
struct TreeElbow: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY - 6))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY - 6))
        p.addQuadCurve(to: CGPoint(x: r.minX + 6, y: r.midY), control: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        return p
    }
}

/// Grouped card container with hairline separators between rows.
struct CardList<Item: Identifiable, Row: View>: View {
    var items: [Item]
    var insetSeparator: CGFloat = 40
    @ViewBuilder var row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                row(item)
                    .padding(.horizontal, 14)
                if i < items.count - 1 {
                    Rectangle().fill(HC.border).frame(height: HM.hairline).padding(.leading, insetSeparator)
                }
            }
        }
        .herdrCard()
    }
}

struct SectionLabel: View {
    var title: String
    var count: Int? = nil
    var tint: Color? = nil
    var body: some View {
        HStack(spacing: 6) {
            Text(title).herdrSectionHeader().foregroundStyle(tint ?? HC.dim)
            if let count { Text("\(count)").herdrSectionHeader().monospacedDigit() }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.top, 18)
        .padding(.bottom, 6)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Connection dot: ansi2 when connected, working while connecting, blocked when failed, dim otherwise.
struct ConnectionDot: View {
    var phase: ConnectionPhase
    var body: some View {
        Circle().fill(color).frame(width: 7, height: 7)
    }
    private var color: Color {
        switch phase {
        case .connected: HC.connected
        case .connecting: HC.working
        case .failed: HC.blocked
        case .idle: HC.dim
        }
    }
}

// MARK: Helpers

extension AppStore {
    /// Display title for the active machine (core name once connected).
    var machineTitle: String {
        if let h = hello, !h.coreName.isEmpty { return h.coreName }
        return machines.first(where: { $0.id == activeMachineID })?.label ?? machines.first?.label ?? "Herdr"
    }

    var activeMachine: MachineConfig? {
        machines.first(where: { $0.id == activeMachineID }) ?? machines.first
    }

    /// Program key for a terminal: the store's answer, else a local guess from argv.
    func programKey(of address: String) -> String? {
        if let p = programName(of: address) { return p }
        guard let rec = terminals[address] else { return nil }
        return ProgramGuess.key(statusApp: rec.statusApp, argv: rec.argv)
    }

    /// Folder shortened with ~ (folderName semantics, full path form).
    func tildePath(_ path: String) -> String {
        guard !path.isEmpty else { return "~" }
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }
}

/// Lightweight program identity used when the store has no answer (Program identity).
enum ProgramGuess {
    static let shells: Set<String> = ["zsh", "bash", "fish", "sh", "dash", "nu", "pwsh", "powershell", "cmd", "elvish", "xonsh", "tcsh", "csh", "ksh", "ion"]
    static let interpreters: Set<String> = ["node", "bun", "bunx", "deno", "python", "python3", "npx", "pnpm", "yarn", "uv", "uvx", "ruby", "bundle", "env", "sudo", "nice", "time", "watch", "nodemon"]

    static func key(statusApp: String?, argv: [String]) -> String? {
        if let app = statusApp, !app.isEmpty {
            if let hit = ProgramCatalog.all.values.first(where: { $0.key == app || ($0.run?.first == app) }) { return hit.key }
            if app == "claude-code" { return "claude" }
            return "agent"
        }
        return fromArgv(argv[...])
    }

    private static func fromArgv(_ argv: ArraySlice<String>) -> String? {
        guard let first = argv.first else { return nil }
        let a = Array(argv)
        // Wrapper: [sh, -c, "…\"$@\"…", sh, …]
        if a.count > 4, shells.contains(base(a[0])), a[1] == "-c", a[2].contains("\"$@\"") {
            return fromArgv(argv.dropFirst(4))
        }
        // bash -lc "exec claude ..." style: look at the command word.
        if a.count >= 3, shells.contains(base(a[0])), a[1].hasPrefix("-"), a[1].contains("c") {
            let words = a[2].split(separator: " ").map(String.init).filter { $0 != "exec" && !$0.contains("=") }
            if let w = words.first { return lookup(base(w)) ?? "program" }
        }
        let b = base(first)
        if shells.contains(b) { return "shell" }
        if interpreters.contains(b), argv.count > 1 {
            let rest = argv.dropFirst().drop(while: { $0.hasPrefix("-") })
            if let s = rest.first { return lookup(stem(s)) ?? "program" }
        }
        return lookup(b) ?? "program"
    }

    private static func lookup(_ name: String) -> String? {
        if ProgramCatalog.all[name] != nil { return name }
        return ProgramCatalog.all.values.first(where: { $0.run?.first == name })?.key
    }
    private static func base(_ s: String) -> String { String(s.split(separator: "/").last ?? Substring(s)) }
    private static func stem(_ s: String) -> String {
        let b = base(s)
        return b.split(separator: ".").first.map(String.init) ?? b
    }
}
