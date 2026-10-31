import Foundation

/// Display names (herdr-app `model.rs`, `terminal.rs`, agents mod).
public enum Names {
    /// A folder as a name: its last part, `~` for home (or ""), `/` for root.
    public static func folderName(_ path: String, home: String = "~") -> String {
        let trim: (String) -> Substring = { s in
            var t = Substring(s)
            while let l = t.last, l == "/" || l == "\\" { t.removeLast() }
            return t
        }
        let p = trim(path)
        if path.isEmpty || p == trim(home) { return "~" }
        if p.isEmpty { return String(path.prefix(1)) }
        return p.split(whereSeparator: { $0 == "/" || $0 == "\\" }).last.map(String.init) ?? String(p)
    }

    /// `name`, else the folder of the space's first terminal (git top if known,
    /// else its live cwd), else the space's folder.
    public static func spaceName(_ s: SpaceRef, firstTerminalCwd: String?, home: String) -> String {
        if !s.name.isEmpty { return s.name }
        return folderName(firstTerminalCwd ?? s.folder, home: home)
    }

    public static func tabName(_ t: TabRef, index: Int) -> String {
        t.name.isEmpty ? "\(index + 1)" : t.name
    }

    static func isSpinner(_ c: Unicode.Scalar) -> Bool {
        switch c.value {
        case 0x2800...0x28FF, 0x00B7, 0x2722, 0x2733, 0x2736, 0x273B, 0x273D, 0x25D0...0x25D3: return true
        default: return false
        }
    }

    /// A title as shown: an agent's leading spinner frames ("✳ Fix the tests",
    /// braille dots) removed. Strips only a run that contains a spinner, ends in
    /// whitespace and leaves something behind.
    public static func shownTitle(_ title: String) -> String {
        let scalars = title.unicodeScalars
        guard let restStart = scalars.firstIndex(where: { !(isSpinner($0) || $0.properties.isWhitespace) }) else { return title }
        let lead = scalars[scalars.startIndex..<restStart]
        guard !lead.isEmpty, lead.contains(where: isSpinner), let last = lead.last, last.properties.isWhitespace else { return title }
        return String(scalars[restStart...])
    }

    /// Leading non-letter/digit characters removed, trimmed (agents mod `clean`).
    public static func clean(_ s: String) -> String {
        let scalars = s.unicodeScalars
        let start = scalars.firstIndex { $0.properties.isAlphabetic || $0.properties.numericType != nil } ?? scalars.endIndex
        return String(scalars[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A title says something: non-empty, not the program's name or key, not a
    /// path, no `@` (user@host prompts).
    public static func isTelling(_ title: String, program: Programs.Program) -> Bool {
        let live = clean(title)
        guard !live.isEmpty, live != program.name, live.lowercased() != program.key.lowercased(), !live.contains("@") else { return false }
        // Paths: checked before cleaning too (cleaning eats the leading "~/").
        let shown = shownTitle(title).trimmingCharacters(in: .whitespaces)
        if live.hasPrefix("~") || live.hasPrefix("/") || shown.hasPrefix("~") || shown.hasPrefix("/") { return false }
        let u = Array(live.unicodeScalars)
        if u.count >= 3, u[0].properties.isAlphabetic, u[0].isASCII, u[1] == ":", u[2] == "\\" { return false }
        return true
    }

    /// Agent row label: a tab someone named (other than after its program)
    /// wins; else the terminal's own title when telling; else the tab's name.
    public static func agentLabel(title: String, program: Programs.Program, tab: TabRef?, tabIndex: Int) -> String {
        if let tab, !tab.name.isEmpty, tab.name != program.name { return tab.name }
        if isTelling(title, program: program) { return clean(title) }
        if let tab { return tabName(tab, index: tabIndex) }
        return title.isEmpty ? program.name : shownTitle(title)
    }

    /// Sub-agent / peek name: `name ?? template ?? program name ?? address`.
    public static func subAgentName(_ t: TerminalRecord) -> String {
        if let n = t.name, !n.isEmpty { return n }
        if let tpl = t.raw["template"].string, !tpl.isEmpty { return tpl }
        let p = Programs.identify(t)
        return p.name.isEmpty ? t.address : p.name
    }
}
