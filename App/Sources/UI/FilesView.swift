import SwiftUI
import QuickLook
import HerdrKit

/// A space's folder on the box: browse it and open files in Quick Look
/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
struct FilesView: View {
    @Environment(AppStore.self) private var store
    var path: String
    var title: String

    struct Entry: Identifiable, Hashable {
        var name: String
        var isDir: Bool
        var size: Int
        var id: String { name }
    }

    @State private var dir: String?
    @State private var entries: [Entry] = []
    @State private var error: String?
    @State private var opening: String?
    @State private var preview: URL?

    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
    static let maxBytes = 12 << 20

    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
    static let listScript = """
    import json, os, sys
    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    out = []
    with os.scandir(d) as it:
        for e in it:
            try:
                isdir = e.is_dir()
                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
            except OSError:
                pass
    print(json.dumps({"dir": d, "entries": out}))
    """

    var body: some View {
        List {
            if let error {
                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
            }
            ForEach(entries) { e in
                if e.isDir, let dir {
                    NavigationLink(value: dir + "/" + e.name) { row(e) }
                } else {
                    Button { Task { await open(e) } } label: { row(e) }
                        .disabled(opening != nil)
                }
            }
        }
        .overlay { if dir == nil && error == nil { ProgressView() } }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .quickLookPreview($preview)
    }

    private func row(_ e: Entry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: e.isDir ? "folder" : "doc")
                .foregroundStyle(e.isDir ? HC.working : HC.muted)
                .frame(width: 22)
            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
            Spacer(minLength: 8)
            if opening == e.name {
                ProgressView()
            } else if !e.isDir {
                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(e.name)
    }

    private func load() async {
        do {
            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
                return
            }
            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
                guard let n = a[0].string else { return nil }
                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
            })
            dir = d
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
    static func sorted(_ entries: [Entry]) -> [Entry] {
        entries.sorted { a, b in
            if a.isDir != b.isDir { return a.isDir }
            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
            if ad != bd { return bd }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    private func open(_ e: Entry) async {
        guard let dir else { return }
        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
        guard e.size <= Self.maxBytes else {
            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
            return
        }
        opening = e.name
        defer { opening = nil }
        do {
            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
                return
            }
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent(e.name)
            try r.stdout.write(to: url, options: .completeFileProtection)
            error = nil
            preview = url
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// The Files sheet for one space: its own stack so folders push inside the sheet.
struct FilesSheet: View {
    @Environment(\.dismiss) private var dismiss
    var folder: String
    var title: String

    var body: some View {
        NavigationStack {
            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
                .navigationDestination(for: String.self) { p in
                    FilesView(path: p, title: (p as NSString).lastPathComponent)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", systemImage: "xmark") { dismiss() }
                    }
                }
        }
    }
}
