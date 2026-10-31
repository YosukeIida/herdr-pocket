import SwiftUI
import HerdrKit

/// A space's uncommitted git changes on the box: the changed files, then one file's diff.
/// Runs the box's git through machine.exec, read-only.
struct ChangesSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var folder: String
    var title: String

    struct Change: Hashable, Identifiable {
        var code: String   // porcelain XY, e.g. " M", "A ", "??"
        var path: String
        var id: String { path }
        var untracked: Bool { code == "??" }
    }

    @State private var changes: [Change]?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                if let error { Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked) }
                if changes?.isEmpty == true { Text("No uncommitted changes.").font(HF.ui(14)).foregroundStyle(HC.muted) }
                ForEach(changes ?? []) { c in
                    NavigationLink(value: c) {
                        HStack(spacing: 12) {
                            Text(c.code.replacingOccurrences(of: " ", with: "·")).font(HF.mono(13, .semibold))
                                .foregroundStyle(c.untracked ? HC.done : HC.working).frame(width: 26, alignment: .leading)
                            Text(c.path).font(HF.ui(15)).foregroundStyle(HC.fg).lineLimit(2).truncationMode(.head)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(c.path)
                    }
                }
            }
            .overlay { if changes == nil && error == nil { ProgressView() } }
            .navigationTitle("Changes · \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Change.self) { c in DiffView(folder: folder, change: c) }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            let r = try await store.exec(argv: ["git", "-C", folder.isEmpty ? "." : folder, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
                                         cwd: nil, on: nil, timeout: 20, input: nil)
            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(folder)"); return }
            changes = Self.parse(r.stdout)
            error = nil
        } catch {
            self.error = DiffView.message(error)
        }
    }

    /// `git status --porcelain=v1 -z`: "XY path\0", and a rename or copy adds its source as the next "\0" field.
    static func parse(_ out: Data) -> [Change] {
        let fields = out.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
        var result: [Change] = [], i = 0
        while i < fields.count {
            let f = fields[i]; i += 1
            guard f.count > 3 else { continue }
            let code = String(f.prefix(2))
            result.append(Change(code: code, path: String(f.dropFirst(3))))
            if code.contains("R") || code.contains("C") { i += 1 }
        }
        return result
    }
}

/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
struct DiffView: View {
    @Environment(AppStore.self) private var store
    var folder: String
    var change: ChangesSheet.Change

    @State private var lines: [Substring]?
    @State private var error: String?

    /// More lines than this are cut off; a phone can't usefully scroll a larger diff.
    static let maxLines = 5000

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            if let error {
                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked).padding(16)
            } else if let lines {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.prefix(Self.maxLines).enumerated()), id: \.offset) { _, l in
                        Text(l.isEmpty ? " " : String(l)).font(HF.mono(12)).foregroundStyle(Self.color(l))
                            .padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Self.background(l))
                    }
                    if lines.count > Self.maxLines {
                        Text("\(lines.count - Self.maxLines) more lines not shown.").font(HF.ui(13)).foregroundStyle(HC.dim).padding(10)
                    }
                }
                .textSelection(.enabled)
                .accessibilityIdentifier("diffLines")
            } else {
                ProgressView().padding(40)
            }
        }
        .background(HC.canvas)
        .navigationTitle((change.path as NSString).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        let dir = folder.isEmpty ? "." : folder
        // --no-index exits 1 when the files differ, which for an untracked file is always.
        let argv = change.untracked
            ? ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", change.path]
            : ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "HEAD", "--", change.path]
        do {
            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
            let text = String(decoding: r.stdout, as: UTF8.self)
            lines = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
        } catch {
            self.error = Self.message(error)
        }
    }

    static func color(_ l: Substring) -> Color {
        if l.hasPrefix("@@") { return HC.working }
        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") { return HC.dim }
        if l.hasPrefix("+") { return HC.done }
        if l.hasPrefix("-") { return HC.blocked }
        return HC.fg
    }

    static func background(_ l: Substring) -> Color {
        if l.hasPrefix("+++") || l.hasPrefix("---") { return .clear }
        if l.hasPrefix("+") { return HC.done.opacity(0.12) }
        if l.hasPrefix("-") { return HC.blocked.opacity(0.12) }
        return .clear
    }

    static func failure(_ r: ExecResult, _ fallback: String) -> String {
        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return why.isEmpty ? fallback : String(why.suffix(300))
    }

    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
    static func message(_ error: Error) -> String {
        (error as? HerdrError)?.kind == "spawn_failed" ? "Changes needs git on the box." : error.localizedDescription
    }
}
