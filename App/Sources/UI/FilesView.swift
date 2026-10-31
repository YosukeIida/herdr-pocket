import SwiftUI
import QuickLook
import HerdrKit

/// A space's folder on the box: browse it and open files in Quick Look
/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
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
    @State private var skipped = 0
    @State private var error: String?
    @State private var opening: String?
    @State private var fetch: Task<Void, Never>?
    @State private var preview: URL?

    /// The largest file read in one machine.exec. The reply is base64 (4/3) inside JSON in one
    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
    static let maxBytes = Frame.maxPayload / 2

    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
    static let listScript = """
    import json, os, sys
    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    out, skipped = [], 0
    with os.scandir(d) as it:
        for e in it:
            try:
                e.name.encode("utf-8")
                isdir = e.is_dir()
                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
            except (OSError, UnicodeEncodeError):
                skipped += 1
    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
    """

    // Writes at most argv[2] bytes of the regular file argv[1]; exit 3 when it is larger or not a
    // regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
    static let readScript = """
    import os, stat, sys
    limit = int(sys.argv[2])
    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
    if not stat.S_ISREG(os.fstat(fd).st_mode):
        sys.exit("not a regular file")
    data = b""
    while len(data) <= limit:
        chunk = os.read(fd, min(1 << 20, limit + 1 - len(data)))
        if not chunk:
            break
        data += chunk
    if len(data) > limit:
        sys.stderr.write("larger than %d bytes" % limit); sys.exit(3)
    sys.stdout.buffer.write(data)
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
                    Button { open(e) } label: { row(e) }
                        .disabled(opening != nil)
                }
            }
            if skipped > 0 {
                Text("\(skipped) item(s) with names that can't be shown are hidden.")
                    .font(HF.ui(13)).foregroundStyle(HC.dim)
            }
        }
        .overlay { if dir == nil && error == nil { ProgressView() } }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .quickLookPreview($preview)
        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil }
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

    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return why.isEmpty ? fallback : String(why.suffix(300))
    }

    private func load() async {
        do {
            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
                error = Self.failure(r, "Couldn't list \(path)")
                return
            }
            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
                guard let n = a[0].string else { return nil }
                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
            })
            skipped = v["skipped"].int ?? 0
            dir = d
            error = nil
        } catch {
            self.error = Self.message(error)
        }
    }

    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
    private static func message(_ error: Error) -> String {
        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
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

    private func open(_ e: Entry) {
        guard let dir, opening == nil else { return }
        // shortcut: files over maxBytes (8 MiB) are refused; read them in ranges when large files matter.
        guard e.size <= Self.maxBytes else {
            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over \(Self.maxBytes.formatted(.byteCount(style: .file))) can't be previewed yet."
            return
        }
        opening = e.name
        fetch = Task {
            defer { if !Task.isCancelled { opening = nil; fetch = nil } }
            do {
                let r = try await store.exec(argv: ["python3", "-c", Self.readScript, dir + "/" + e.name, String(Self.maxBytes)],
                                             cwd: nil, on: nil, timeout: 60, input: nil)
                guard !Task.isCancelled else { return }
                guard r.code == 0, !r.timedOut else { error = Self.failure(r, "Couldn't read \(e.name)"); return }
                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
                let folder = FileManager.default.temporaryDirectory
                    .appendingPathComponent("preview", isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let url = folder.appendingPathComponent(e.name)
                try r.stdout.write(to: url, options: .completeFileProtection)
                error = nil
                preview = url
            } catch {
                if !Task.isCancelled { self.error = Self.message(error) }
            }
        }
    }

    /// Deletes a closed preview's downloaded copy (its own folder).
    private static func discard(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
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
        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
    }
}
