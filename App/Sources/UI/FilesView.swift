import SwiftUI
import QuickLook
import WebKit
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
    @State private var markdown: MarkdownDoc?
    @State private var progress: String?
    @State private var web: WebDoc?

    struct WebDoc: Identifiable { var name: String; var url: URL; var id: URL { url } }

    struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }

    /// The most read in one machine.exec. The reply is base64 (4/3) inside JSON in one
    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
    static let chunkBytes = Frame.maxPayload / 2
    /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
    static let maxBytes = 256 << 20

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

    // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
    // exits 1 when it is not a regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
    static let readScript = """
    import os, stat, sys
    off, limit = int(sys.argv[2]), int(sys.argv[3])
    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
    st = os.fstat(fd)
    if not stat.S_ISREG(st.st_mode):
        sys.exit("not a regular file")
    os.lseek(fd, off, os.SEEK_SET)
    data = b""
    while len(data) < limit:
        chunk = os.read(fd, min(1 << 20, limit - len(data)))
        if not chunk:
            break
        data += chunk
    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
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
        .sheet(item: $markdown) { doc in
            NavigationStack {
                ScrollView { ChatMarkdown(text: doc.text).padding(16).frame(maxWidth: .infinity, alignment: .leading) }
                    .background(HC.canvas)
                    .navigationTitle(doc.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { markdown = nil }.accessibilityIdentifier("markdownClose") } }
            }
        }
        .sheet(item: $web, onDismiss: nil) { doc in
            NavigationStack {
                WebPreview(url: doc.url)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle(doc.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { web = nil }.accessibilityIdentifier("webClose") } }
            }
        }
        .onChange(of: web?.url) { old, new in if new == nil, let old { Self.discard(old) } }
        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil; progress = nil }
    }

    private func row(_ e: Entry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: e.isDir ? "folder" : "doc")
                .foregroundStyle(e.isDir ? HC.working : HC.muted)
                .frame(width: 22)
            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
            Spacer(minLength: 8)
            if opening == e.name {
                if let progress { Text(progress).font(HF.ui(13)).foregroundStyle(HC.dim).monospacedDigit() }
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
        guard e.size <= Self.maxBytes else { error = Self.tooLarge(e.name, e.size); return }
        opening = e.name
        fetch = Task {
            defer { if !Task.isCancelled { opening = nil; fetch = nil; progress = nil } }
            do {
                guard let data = try await read(dir + "/" + e.name, e.name) else { return }
                // Why not Quick Look for Markdown: it shows the raw source; Chat's renderer formats it.
                if ["md", "markdown"].contains((e.name as NSString).pathExtension.lowercased()), let s = String(data: data, encoding: .utf8) {
                    error = nil
                    markdown = MarkdownDoc(name: e.name, text: s)
                    return
                }
                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
                let folder = FileManager.default.temporaryDirectory
                    .appendingPathComponent("preview", isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let url = folder.appendingPathComponent(e.name)
                error = nil
                // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
                switch (e.name as NSString).pathExtension.lowercased() {
                case "html", "htm":
                    try Self.fitted(html: data).write(to: url, options: .completeFileProtection)
                    web = WebDoc(name: e.name, url: url)
                case "svg":
                    try data.write(to: url, options: .completeFileProtection)
                    let page = folder.appendingPathComponent("index.html")
                    try Self.wrapper(image: e.name).write(to: page, options: .completeFileProtection)
                    web = WebDoc(name: e.name, url: page)
                default:
                    try data.write(to: url, options: .completeFileProtection)
                    preview = url
                }
            } catch {
                if !Task.isCancelled { self.error = Self.message(error) }
            }
        }
    }

    /// The page with a phone-width viewport when it declares none.
    static func fitted(html: Data) -> Data {
        let head = String(decoding: html.prefix(8192), as: UTF8.self).lowercased()
        if head.contains("name=\"viewport\"") || head.contains("name=viewport") || head.contains("name='viewport'") { return html }
        return Data(#"<meta name="viewport" content="width=device-width, initial-scale=1">"#.utf8) + html
    }

    /// A page showing one vector image at the screen width.
    static func wrapper(image name: String) -> Data {
        let src = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return Data(#"<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1"><body style="margin:0;background:#fff"><img src="\#(src)" style="display:block;width:100%;height:auto">"#.utf8)
    }

    private static func tooLarge(_ name: String, _ size: Int) -> String {
        "\(name) is \(size.formatted(.byteCount(style: .file))); files over \(maxBytes.formatted(.byteCount(style: .file))) can't be previewed."
    }

    /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
    /// the file changes size or mtime between chunks, or it grows past `maxBytes`.
    private func read(_ path: String, _ name: String) async throws -> Data? {
        var data = Data(), stamp: String?
        while true {
            let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
                                         cwd: nil, on: nil, timeout: 60, input: nil)
            guard !Task.isCancelled else { return nil }
            guard r.code == 0, !r.timedOut, let nl = r.stdout.firstIndex(of: 10) else {
                error = Self.failure(r, "Couldn't read \(name)"); return nil
            }
            let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
            let size = Int(head.split(separator: " ").first ?? "") ?? 0
            guard stamp == nil || stamp == head else { error = "\(name) changed while it was being read."; return nil }
            guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
            stamp = head
            let body = r.stdout[(nl + 1)...]
            data.append(body)
            if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
            if body.count < Self.chunkBytes || data.count >= size { return data }
        }
    }

    /// Deletes a closed preview's downloaded copy (its own folder).
    private static func discard(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}

/// A downloaded HTML page or SVG, with scripts off and file access limited to its own folder.
private struct WebPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = WKWebView(frame: .zero, configuration: config)
        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}
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
