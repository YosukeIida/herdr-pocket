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
        /// A Contents search's first matching line.
        var snippet: String? = nil
        var id: String { name }
    }

    enum Scope: Hashable { case names, contents }

    @State private var query = ""
    @State private var scope = Scope.names
    @State private var results: [Entry]?
    @State private var partial = false
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

    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
    /// and the reply is base64 inside one `Frame.maxPayload` (16 MiB) frame, so half of 8 MB is safe for both.
    static let chunkBytes = 4_000_000
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
    // exits 1 when it is not a regular file, 4 when its size or mtime changed during this read.
    // O_NONBLOCK so a FIFO listed as a file cannot hang the read.
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
    after = os.fstat(fd)
    if (after.st_size, after.st_mtime_ns) != (st.st_size, st.st_mtime_ns):
        sys.exit(4)
    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
    """

    // Prints {"results": [[relative path, is_dir, size, snippet]], "partial"}: names (folders too) or text lines
    // containing argv[2], case-insensitively, under argv[1]. Stops at 200 results or 8 seconds.
    static let searchScript = """
    import json, os, stat, subprocess, sys, time
    root, q, mode = sys.argv[1], sys.argv[2].lower(), sys.argv[3]

    def paths():
        # In a git work tree, what git lists (tracked and untracked, minus .gitignore), with their folders.
        try:
            r = subprocess.run(["git", "-C", root, "ls-files", "-co", "--exclude-standard", "-z"], capture_output=True, timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            r = None
        if r is not None and r.returncode == 0:
            seen = set()
            for p in sorted(os.fsdecode(x) for x in r.stdout.split(b"\\0") if x):
                parts = p.split("/")
                for i in range(1, len(parts)):
                    d = "/".join(parts[:i])
                    if d not in seen:
                        seen.add(d)
                        yield d, True
                yield p, False
            return
        # shortcut: outside git, prunes a fixed list of heavy folders; read ignore files if results get noisy.
        skip = {".git", "node_modules", ".venv", "__pycache__", ".build", "DerivedData", ".direnv"}
        for d, dirs, files in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in skip)
            rel = os.path.relpath(d, root)
            for n, isdir in [(x, True) for x in dirs] + [(x, False) for x in sorted(files)]:
                yield (n if rel == "." else os.path.join(rel, n)), isdir

    out, start, partial = [], time.monotonic(), False
    for p, isdir in paths():
        if time.monotonic() - start > 8:
            partial = True
            break
        if isdir and mode != "names":
            continue
        try:
            p.encode("utf-8")
            full = os.path.join(root, p)
            if mode == "names":
                if q not in os.path.basename(p).lower():
                    continue
                out.append([p, isdir, 0 if isdir else os.lstat(full).st_size, None])
            else:
                st = os.stat(full)
                if not stat.S_ISREG(st.st_mode) or st.st_size > 1 << 20:
                    continue
                with open(full, "rb") as f:
                    data = f.read()
                if b"\\0" in data[:8192]:
                    continue
                line = next((l for l in data.decode("utf-8", "replace").splitlines() if q in l.lower()), None)
                if line is None:
                    continue
                out.append([p, False, st.st_size, line.strip()[:200]])
        except (OSError, UnicodeEncodeError):
            continue
        if len(out) >= 200:
            partial = True
            break
    print(json.dumps({"results": out, "partial": partial}))
    """

    var body: some View {
        List {
            if let error {
                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
            }
            if !query.isEmpty {
                if let results {
                    if results.isEmpty { Text("No matches.").font(HF.ui(14)).foregroundStyle(HC.dim) }
                    ForEach(results) { e in
                        if e.isDir, let dir {
                            NavigationLink(value: dir + "/" + e.name) { row(e) }
                        } else {
                            Button { open(e) } label: { row(e) }.disabled(opening != nil)
                        }
                    }
                    if partial { Text("Showing the first matches only.").font(HF.ui(13)).foregroundStyle(HC.dim) }
                } else {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            } else {
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
        }
        .overlay { if dir == nil && error == nil { ProgressView() } }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find files")
        .searchScopes($scope) {
            Text("Names").tag(Scope.names)
            Text("Contents").tag(Scope.contents)
        }
        .task(id: "\(scope)\u{0}\(query)\u{0}\(dir ?? "")") { await search() }
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
            VStack(alignment: .leading, spacing: 2) {
                Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1).truncationMode(.head)
                if let s = e.snippet { Text(s).font(HF.mono(12)).foregroundStyle(HC.dim).lineLimit(2) }
            }
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

    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
    private func search() async {
        results = nil; partial = false
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, let dir else { return }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        do {
            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
                                         cwd: nil, on: nil, timeout: 20, input: nil)
            guard !Task.isCancelled else { return }
            guard r.code == 0, let v = try? JSONValue.parse(r.stdout) else { error = Self.failure(r, "Couldn't search \(dir)"); return }
            results = (v["results"].array ?? []).compactMap { a in
                guard let n = a[0].string else { return nil }
                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0, snippet: a[3].string)
            }
            partial = v["partial"].bool ?? false
            error = nil
        } catch {
            if !Task.isCancelled { self.error = Self.message(error) }
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
                let base = (e.name as NSString).lastPathComponent
                let url = folder.appendingPathComponent(base)
                error = nil
                // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
                switch (e.name as NSString).pathExtension.lowercased() {
                case "html", "htm":
                    try Self.fitted(html: data).write(to: url, options: .completeFileProtection)
                    web = WebDoc(name: e.name, url: url)
                case "svg":
                    try data.write(to: url, options: .completeFileProtection)
                    let page = folder.appendingPathComponent("index.html")
                    try Self.wrapper(image: base).write(to: page, options: .completeFileProtection)
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
    /// the file changes size or mtime during or between chunks, a chunk comes back short, or it is over `maxBytes`.
    private func read(_ path: String, _ name: String) async throws -> Data? {
        var data = Data(), stamp: String?
        while true {
            let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
                                         cwd: nil, on: nil, timeout: 60, input: nil)
            guard !Task.isCancelled else { return nil }
            guard r.code != 4 else { error = "\(name) changed while it was being read."; return nil }
            guard r.code == 0, !r.timedOut, !r.truncated, let nl = r.stdout.firstIndex(of: 10) else {
                error = Self.failure(r, "Couldn't read \(name)"); return nil
            }
            let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
            let size = Int(head.split(separator: " ").first ?? "") ?? 0
            guard stamp == nil || stamp == head else { error = "\(name) changed while it was being read."; return nil }
            guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
            stamp = head
            let body = r.stdout[(nl + 1)...]
            guard body.count == min(Self.chunkBytes, max(size - data.count, 0)) else { error = "\(name) changed while it was being read."; return nil }
            data.append(body)
            if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
            if data.count >= size { return data }
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

    /// Blocks every load that is not a local file, so a page from the box can't reach the network.
    static let localOnly = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^file:"},"action":{"type":"ignore-previous-rules"}}]"#

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        let url = url
        Task { @MainActor in
            // Nothing loads until the block list is in place.
            guard let rules = try? await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "herdr-local-only", encodedContentRuleList: Self.localOnly) else { return }
            view.configuration.userContentController.add(rules)
            view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Links and redirects stay inside local files.
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            action.request.url?.isFileURL == true ? .allow : .cancel
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
        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
    }
}
