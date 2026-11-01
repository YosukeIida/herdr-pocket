Reading additional input from stdin...
OpenAI Codex v0.166.0
--------
workdir: /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
model: gpt-6.1-sol
provider: openai
approval: on-request
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a196ee-a155-72b0-9f25-6beff45a879e
--------
user
Re-review commit fa92895 (git show fa92895), which fixes the 11 findings listed in docs/reviews/2026-11-01-files-changes-notifier-judgement.md. Check only whether each fix is correct and whether the fixes introduce new bugs (FilesView.swift chunk loop and read script, WebPreview content blocking, install-service.sh escaping, ChangesView.swift root/rename/unborn/truncation). Read-only; do not edit. Output a numbered list of remaining or new defects with severity, file:line, scenario and fix, or say none; end with a verdict.
warning: Codex could not update marketplace `impeccable`: trusted Git repository root escapes Codex home
warning: Codex could not update marketplace `ponytail`: trusted Git repository root escapes Codex home
hook: SessionStart
hook: SessionStart
hook: SessionStart
hook: SessionStart Completed
hook: SessionStart Completed
hook: SessionStart Completed
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
指定された修正範囲に絞り、`ponytail-review` スキルで再レビューします。判定記録と差分を照合し、修正の不備と新たな不具合を確認します。
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
---
name: ponytail-review
description: >
  Quality review of a change: is the logic right, is it safe, does it hold
  under real load, is risky code tested, is it fast enough, and is every line
  needed. Reads the connected code, not only the diff. Each finding is
  explained in plain English. Use for "review this", "code review", "review
  the last commit", "review my PR", "is this over-engineered", /ponytail-review.
---

Review a change like the senior developer who will be paged when it breaks.
Order of importance: correct, safe, holds under load, tested, fast, lean.
Lean still matters: every extra line must be read, tested and fixed later.
This is a report the user asked for, so give it in full.

## 1. Understand first

- Review what the user names: uncommitted or staged changes, a branch, a PR
  link, or files. Nothing named: the uncommitted changes, or the last commit
  if there are none.
- Read the diff, then the code it touches: callers of every changed function,
  the functions it calls, the tests, the README.
- Trace the real flow: where data comes in, what is stored, what goes out.
- A change can break code it does not touch. When a signature, return value
  or behavior changes, grep every caller.
- Find the expected load in the repo (README, deploy config): one person
  running a script, or many users and processes at once. Judge scale against
  that, and say which load you assumed.

## 2. Look for

1. **Bug:** wrong result, crash, missed edge case (empty, zero, last item,
   rounding, time zones), a caller broken by the change, a fix applied in one
   caller while the shared function stays broken.
2. **Risk:** security holes (injection, weak randomness, secrets, missing
   checks on input from users), data loss (errors swallowed, writes in the
   wrong order, no transaction).
3. **Scale:** fine for one user, wrong for many: check-then-write races, the
   same work done by every process, memory or lists that only grow, a query
   per item, O(n^2) on big input, per-process state that must be shared.
4. **Missing test:** risky new logic (a branch, a parser, money, security,
   data writes, a bug fix) with no test that fails when it breaks. One good
   test, not coverage.
5. **Speed:** big slowdowns are problems. Small wins (work repeated in a hot
   loop) are suggestions; some software counts every millisecond.
6. **Lean:** code that should not exist or should be smaller.
   - delete: dead code, unused options, speculative features
   - reuse: the repo already has this helper (name the path)
   - stdlib / native: the standard library or platform already does it; a
     new dependency for a few lines
   - yagni: abstraction with one implementation, config nobody sets
   - merge: near-copies that must change together
   - split: one function doing several unrelated jobs, so it is hard to read
     or test. Split by job, never by line count, and never into helpers that
     exist only to make a function shorter.

## 3. Check before you report

- Every finding needs a concrete case: "this input or situation leads to this
  wrong result". No case, no finding.
- Re-read the lines and confirm: the caller exists, the value can really be
  empty, the code really is unused.
- A shortcut marked with a `shortcut:` (or older `ponytail:`) comment that names its limit is a
  decision, not a finding, unless the expected load already crosses it.
- Propose the smallest fix that works. Prefer fixes that delete code. Never
  add layers, frameworks or config the problem does not need.
- No style taste, no "consider", no vague worries.

## 4. Output

Very simple English: short sentences, everyday words. Explain a technical
term the first time you use it. The reader may never have seen this code.

Start with `What this change does:` in two or three sentences.

Then the findings in three groups, skip empty groups:
- **Must fix:** bug, security, data loss, breaks at the expected load.
- **Should fix:** risky code without a test, real slowness, duplication, a
  function that mixes jobs, code that should not exist.
- **Nice to have:** small speed-ups, shorter forms.

Number findings across all groups, so the user can say "fix 2 and 5".
Every finding has all four parts, each one or two short sentences:

2. **Orders land on the wrong day** (`billing/close_day.py:L40-52`)
   - **What this is:** At midnight this job closes the day and bills all orders of that day.
   - **Problem:** It takes "today" from the server clock, which runs in UTC. An order placed
     at 00:30 in Berlin is billed on the day before.
   - **Fix:** Compute the day once in the shop's time zone:
     `datetime.now(ZoneInfo("Europe/Berlin")).date()`. One line, nothing else changes.
   - **If we skip it:** Late orders show the wrong date, and accounting fixes them by hand.

End with:
- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.`
- `Lean: -<N> lines possible.` when lean findings exist.
- `Not checked:` one line, if something mattered and you could not check it.

Nothing found: `What this change does:`, then `Looks good. Ship.` and one line
on what you checked.

Lists findings, changes no code.

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'git show --stat fa92895 && git show fa92895' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit fa92895f198d6a4768990d29ccf6de5652342812
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 06:54:26 2026 +0900

    Fix chunked reads cut short by the stdout cap, keep previews offline, and fix Changes paths
    
    Codex's review of 282034e: an 8 MiB chunk plus its header was truncated and read
    as the end of the file, HTML could still load remote resources, and Changes ran
    diffs outside the repo root, dropped rename sources and failed before the first
    commit. Judgement in docs/reviews/2026-11-01-files-changes-notifier-judgement.md.

 App/Resources/Notify/install-service.sh            |   19 +-
 App/Sources/UI/ChangesView.swift                   |   45 +-
 App/Sources/UI/FilesView.swift                     |   42 +-
 Packages/HerdrKit/Sources/HerdrKit/Contracts.swift |    5 +-
 .../HerdrKit/Sources/HerdrKit/HerdrClient.swift    |    3 +-
 .../HerdrKit/Tests/HerdrKitTests/ClientTests.swift |   10 +
 docs/HANDOVER.md                                   |    9 +-
 .../2026-11-01-files-changes-notifier-codex.md     | 2114 ++++++++++++++++++++
 ...26-11-01-files-changes-notifier-judgement.ja.md |   28 +
 .../2026-11-01-files-changes-notifier-judgement.md |   21 +
 10 files changed, 2263 insertions(+), 33 deletions(-)
commit fa92895f198d6a4768990d29ccf6de5652342812
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 06:54:26 2026 +0900

    Fix chunked reads cut short by the stdout cap, keep previews offline, and fix Changes paths
    
    Codex's review of 282034e: an 8 MiB chunk plus its header was truncated and read
    as the end of the file, HTML could still load remote resources, and Changes ran
    diffs outside the repo root, dropped rename sources and failed before the first
    commit. Judgement in docs/reviews/2026-11-01-files-changes-notifier-judgement.md.

diff --git a/App/Resources/Notify/install-service.sh b/App/Resources/Notify/install-service.sh
index ba4fb25..bae687e 100644
--- a/App/Resources/Notify/install-service.sh
+++ b/App/Resources/Notify/install-service.sh
@@ -7,27 +7,34 @@ d="$HOME/.config/herdr-ios"
 script="$d/herdr-notify.py"
 py="$(command -v python3)"
 
+# XML text for a plist <string>.
+xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
+
 if [ "$(uname)" = Darwin ]; then
   label=dev.herdr.notify
   plist="$HOME/Library/LaunchAgents/$label.plist"
   mkdir -p "$HOME/Library/LaunchAgents"
   # launchd starts jobs with PATH=/usr/bin:/bin:/usr/sbin:/sbin; keep the PATH that found hc and python3 here.
-  cat > "$plist" <<EOF
+  tmp="$plist.new"
+  cat > "$tmp" <<EOF
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
   <key>Label</key><string>$label</string>
-  <key>ProgramArguments</key><array><string>$py</string><string>$script</string></array>
-  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$PATH</string></dict>
+  <key>ProgramArguments</key><array><string>$(xml "$py")</string><string>$(xml "$script")</string></array>
+  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$(xml "$PATH")</string></dict>
   <key>RunAtLoad</key><true/>
   <key>KeepAlive</key><true/>
   <key>ThrottleInterval</key><integer>10</integer>
-  <key>StandardOutPath</key><string>$d/notify.log</string>
-  <key>StandardErrorPath</key><string>$d/notify.log</string>
+  <key>StandardOutPath</key><string>$(xml "$d/notify.log")</string>
+  <key>StandardErrorPath</key><string>$(xml "$d/notify.log")</string>
 </dict>
 </plist>
 EOF
+  # A broken plist must not stop the running notifier.
+  plutil -lint -s "$tmp"
+  mv "$tmp" "$plist"
   pkill -f "$script" 2>/dev/null || true
   launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
   launchctl bootstrap "gui/$(id -u)" "$plist"
@@ -39,7 +46,7 @@ Description=Herdr for iOS push notifications
 After=network-online.target
 
 [Service]
-ExecStart=$py %h/.config/herdr-ios/herdr-notify.py
+ExecStart="$py" "%h/.config/herdr-ios/herdr-notify.py"
 Restart=always
 RestartSec=5
 
diff --git a/App/Sources/UI/ChangesView.swift b/App/Sources/UI/ChangesView.swift
index bfbcae5..ae5f891 100644
--- a/App/Sources/UI/ChangesView.swift
+++ b/App/Sources/UI/ChangesView.swift
@@ -12,11 +12,14 @@ struct ChangesSheet: View {
     struct Change: Hashable, Identifiable {
         var code: String   // porcelain XY, e.g. " M", "A ", "??"
         var path: String
+        var from: String?  // a rename's or copy's source
         var id: String { path }
         var untracked: Bool { code == "??" }
     }
 
     @State private var changes: [Change]?
+    @State private var root = ""
+    @State private var hasHead = true
     @State private var error: String?
 
     var body: some View {
@@ -39,18 +42,33 @@ struct ChangesSheet: View {
             .overlay { if changes == nil && error == nil { ProgressView() } }
             .navigationTitle("Changes · \(title)")
             .navigationBarTitleDisplayMode(.inline)
-            .navigationDestination(for: Change.self) { c in DiffView(folder: folder, change: c) }
+            .navigationDestination(for: Change.self) { c in DiffView(root: root, hasHead: hasHead, change: c) }
             .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
             .task { await load() }
             .refreshable { await load() }
         }
     }
 
+    /// The space folder as an absolute path: argv reaches git without a shell, so "~" is not expanded.
+    private var absoluteFolder: String {
+        if folder.isEmpty || folder == "~" { return store.home }
+        if folder.hasPrefix("~/") { return store.home + folder.dropFirst(1) }
+        return folder
+    }
+
     private func load() async {
         do {
-            let r = try await store.exec(argv: ["git", "-C", folder.isEmpty ? "." : folder, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
+            // Porcelain paths are relative to the repo root, so status and every diff run there.
+            let top = try await store.exec(argv: ["git", "-C", absoluteFolder, "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil)
+            guard top.code == 0 else { error = DiffView.failure(top, "\(title) is not in a git repository."); return }
+            let dir = String(decoding: top.stdout, as: UTF8.self).trimmingCharacters(in: .newlines)
+            let head = try await store.exec(argv: ["git", "-C", dir, "rev-parse", "--verify", "-q", "HEAD"], cwd: nil, on: nil, timeout: 20, input: nil)
+            let r = try await store.exec(argv: ["git", "-C", dir, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
                                          cwd: nil, on: nil, timeout: 20, input: nil)
-            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(folder)"); return }
+            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(dir)"); return }
+            guard !r.truncated else { error = "Too many changes to list here."; return }
+            root = dir
+            hasHead = head.code == 0
             changes = Self.parse(r.stdout)
             error = nil
         } catch {
@@ -66,8 +84,9 @@ struct ChangesSheet: View {
             let f = fields[i]; i += 1
             guard f.count > 3 else { continue }
             let code = String(f.prefix(2))
-            result.append(Change(code: code, path: String(f.dropFirst(3))))
-            if code.contains("R") || code.contains("C") { i += 1 }
+            let moved = code.contains("R") || code.contains("C")
+            result.append(Change(code: code, path: String(f.dropFirst(3)), from: moved && i < fields.count ? fields[i] : nil))
+            if moved { i += 1 }
         }
         return result
     }
@@ -76,7 +95,8 @@ struct ChangesSheet: View {
 /// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
 struct DiffView: View {
     @Environment(AppStore.self) private var store
-    var folder: String
+    var root: String
+    var hasHead: Bool
     var change: ChangesSheet.Change
 
     @State private var lines: [Substring]?
@@ -113,16 +133,19 @@ struct DiffView: View {
     }
 
     private func load() async {
-        let dir = folder.isEmpty ? "." : folder
+        let git = ["git", "-C", root, "--literal-pathspecs", "--no-pager", "diff", "--no-color", "--no-ext-diff", "-M"]
         // --no-index exits 1 when the files differ, which for an untracked file is always.
+        // Before the first commit there is no HEAD; the index holds what that commit will contain.
         let argv = change.untracked
-            ? ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", change.path]
-            : ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "HEAD", "--", change.path]
+            ? git + ["--no-index", "--", "/dev/null", change.path]
+            : git + [hasHead ? "HEAD" : "--cached", "--"] + [change.from, change.path].compactMap { $0 }
         do {
             let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
             guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
             let text = String(decoding: r.stdout, as: UTF8.self)
-            lines = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
+            var out: [Substring] = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
+            if r.truncated { out.append("… the diff is longer than 8 MB and was cut off here.") }
+            lines = out
         } catch {
             self.error = Self.message(error)
         }
@@ -130,7 +153,7 @@ struct DiffView: View {
 
     static func color(_ l: Substring) -> Color {
         if l.hasPrefix("@@") { return HC.working }
-        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") { return HC.dim }
+        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") || l.hasPrefix("rename ") || l.hasPrefix("similarity ") { return HC.dim }
         if l.hasPrefix("+") { return HC.done }
         if l.hasPrefix("-") { return HC.blocked }
         return HC.fg
diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
index acacb92..5644bac 100644
--- a/App/Sources/UI/FilesView.swift
+++ b/App/Sources/UI/FilesView.swift
@@ -32,9 +32,9 @@ struct FilesView: View {
 
     struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }
 
-    /// The most read in one machine.exec. The reply is base64 (4/3) inside JSON in one
-    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
-    static let chunkBytes = Frame.maxPayload / 2
+    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
+    /// and the reply is base64 inside one `Frame.maxPayload` (16 MiB) frame, so half of 8 MB is safe for both.
+    static let chunkBytes = 4_000_000
     /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
     static let maxBytes = 256 << 20
 
@@ -56,7 +56,8 @@ struct FilesView: View {
     """
 
     // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
-    // exits 1 when it is not a regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
+    // exits 1 when it is not a regular file, 4 when its size or mtime changed during this read.
+    // O_NONBLOCK so a FIFO listed as a file cannot hang the read.
     static let readScript = """
     import os, stat, sys
     off, limit = int(sys.argv[2]), int(sys.argv[3])
@@ -71,6 +72,9 @@ struct FilesView: View {
         if not chunk:
             break
         data += chunk
+    after = os.fstat(fd)
+    if (after.st_size, after.st_mtime_ns) != (st.st_size, st.st_mtime_ns):
+        sys.exit(4)
     sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
     """
 
@@ -238,14 +242,15 @@ struct FilesView: View {
     }
 
     /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
-    /// the file changes size or mtime between chunks, or it grows past `maxBytes`.
+    /// the file changes size or mtime during or between chunks, a chunk comes back short, or it is over `maxBytes`.
     private func read(_ path: String, _ name: String) async throws -> Data? {
         var data = Data(), stamp: String?
         while true {
             let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
                                          cwd: nil, on: nil, timeout: 60, input: nil)
             guard !Task.isCancelled else { return nil }
-            guard r.code == 0, !r.timedOut, let nl = r.stdout.firstIndex(of: 10) else {
+            guard r.code != 4 else { error = "\(name) changed while it was being read."; return nil }
+            guard r.code == 0, !r.timedOut, !r.truncated, let nl = r.stdout.firstIndex(of: 10) else {
                 error = Self.failure(r, "Couldn't read \(name)"); return nil
             }
             let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
@@ -254,9 +259,10 @@ struct FilesView: View {
             guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
             stamp = head
             let body = r.stdout[(nl + 1)...]
+            guard body.count == min(Self.chunkBytes, max(size - data.count, 0)) else { error = "\(name) changed while it was being read."; return nil }
             data.append(body)
             if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
-            if body.count < Self.chunkBytes || data.count >= size { return data }
+            if data.count >= size { return data }
         }
     }
 
@@ -270,15 +276,35 @@ struct FilesView: View {
 private struct WebPreview: UIViewRepresentable {
     let url: URL
 
+    /// Blocks every load that is not a local file, so a page from the box can't reach the network.
+    static let localOnly = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^file:"},"action":{"type":"ignore-previous-rules"}}]"#
+
     func makeUIView(context: Context) -> WKWebView {
         let config = WKWebViewConfiguration()
         config.defaultWebpagePreferences.allowsContentJavaScript = false
+        config.websiteDataStore = .nonPersistent()
         let view = WKWebView(frame: .zero, configuration: config)
-        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
+        view.navigationDelegate = context.coordinator
+        let url = url
+        Task { @MainActor in
+            // Nothing loads until the block list is in place.
+            guard let rules = try? await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "herdr-local-only", encodedContentRuleList: Self.localOnly) else { return }
+            view.configuration.userContentController.add(rules)
+            view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
+        }
         return view
     }
 
     func updateUIView(_ view: WKWebView, context: Context) {}
+
+    func makeCoordinator() -> Coordinator { Coordinator() }
+
+    /// Links and redirects stay inside local files.
+    final class Coordinator: NSObject, WKNavigationDelegate {
+        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
+            action.request.url?.isFileURL == true ? .allow : .cancel
+        }
+    }
 }
 
 /// The Files sheet for one space: its own stack so folders push inside the sheet.
diff --git a/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift b/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift
index a682451..7e7cd8f 100644
--- a/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift
+++ b/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift
@@ -46,8 +46,9 @@ public struct ExecResult: Sendable, Equatable {
     public var stdout: Data
     public var stderr: Data
     public var timedOut: Bool
-    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool) {
-        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut
+    public var truncated: Bool   // it wrote more than the core kept (stdout 8 MB, stderr 1 MB)
+    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool, truncated: Bool = false) {
+        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut; self.truncated = truncated
     }
 }
 
diff --git a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
index 7af4b2c..98e2b9c 100644
--- a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
+++ b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
@@ -226,7 +226,8 @@ public final class HerdrClient: @unchecked Sendable {
         return ExecResult(code: r["code"].int,
                           stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
                           stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
-                          timedOut: r["timed_out"].bool ?? false)
+                          timedOut: r["timed_out"].bool ?? false,
+                          truncated: r["truncated"].bool ?? false)
     }
 
     public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
index ae09bc1..89dcccd 100644
--- a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
+++ b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
@@ -194,6 +194,16 @@ final class ClientTests: XCTestCase {
         XCTAssertEqual(res, ExecResult(code: 0, stdout: Data("hi\n".utf8), stderr: Data(), timedOut: false))
     }
 
+    func testExecReportsTruncatedOutput() async throws {
+        let (c, t) = try await connected()
+        async let r = c.exec(argv: ["yes"], on: nil, timeout: 5)
+        let fr = try await t.waitFor { $0.contains { $0.channel == 0 } }
+        let msg = try JSONValue.parse(fr.first { $0.channel == 0 }!.payload)
+        t.reply(msg["id"].int!, ["code": 0, "stdout": "eQ==", "stderr": "", "timed_out": false, "truncated": true])
+        let res = try await r
+        XCTAssertTrue(res.truncated)
+    }
+
     func testSubscribeCreditsAndUpdates() async throws {
         let (c, t) = try await connected()
         async let s = c.subscribe(coalesce: 0)
diff --git a/docs/HANDOVER.md b/docs/HANDOVER.md
index c13b2e9..855f7c1 100644
--- a/docs/HANDOVER.md
+++ b/docs/HANDOVER.md
@@ -49,13 +49,13 @@ All five targets are met on the simulator, and Codex chat was added as well. Eve
   `herdr-core connect` stdio open. Not yet confirmed on a device.
 - Files (this repo's first feature, 6c7e200 + 95acd13 after Codex's review,
   `docs/reviews/2026-11-01-files-judgement.md`): `App/Sources/UI/FilesView.swift`, folder button in
-  a space's toolbar. Lists and reads with python3 on the box; reads are capped at 8 MiB on the box
-  (`Frame.maxPayload / 2`), larger files are refused (`shortcut:` in the code; the code-review
-  document's "read in chunks" is not built yet). `testFilesPreviewInQuickLook` opens a PDF, docx,
+  a space's toolbar. Lists and reads with python3 on the box, 4,000,000 bytes per machine.exec (the core
+  keeps 8 MB of stdout); larger files are read in chunks, each checked by size and mtime, up to 256 MiB. `testFilesPreviewInQuickLook` opens a PDF, docx,
   xlsx and png from `build/preview-fixtures/` (gitignored; recreate with textutil, cupsfilter, sips
   and openpyxl via uvx; the png must be opaque; md, html, json, csv, swift, svg, jpg, gif, heic and
   pptx were added by hand). All of them open; Markdown opens in Chat's renderer instead of Quick Look,
-  which shows the raw source. HTML without a viewport and SVG show small (desktop scale, intrinsic size).
+  which shows the raw source. HTML and SVG open in a WKWebView at phone width, with JavaScript off and
+  every non-file load blocked.
 - Chat (1f37e96): Claude Code and Codex. `testChatRendersAndFolds` and `testChatSendGetsReply` pass
   against throwaway terminals (`hc run --bg --name claude-chat-test claude --strict-mcp-config`,
   and `CODEX_HOME=$HOME/.codex-labteam hc run --bg --name codex-chat-test codex`, both in this repo):
@@ -125,6 +125,5 @@ TEST_RUNNER_HERDR_TEST_BLOCKED_TERMINAL=<address> TEST_RUNNER_HERDR_TEST_BLOCKED
 
 - Chat: Codex thread matching would be exact if Codex exposed its thread id to the terminal. If the Chat code turns out weak to extend,
   opencode and Orca's chat are acceptable references (check licenses first).
-- Files: chunked reads above 8 MiB; HTML/SVG scaled to the screen (WKWebView) if that matters.
 - Run on a real iPhone (needs `Config/Local.xcconfig` with a team id).
 - Citadel: close the channel on handshake failure (fork + upstream PR), see `docs/reviews/PENDING.md`.
diff --git a/docs/reviews/2026-11-01-files-changes-notifier-codex.md b/docs/reviews/2026-11-01-files-changes-notifier-codex.md
new file mode 100644
index 0000000..ebdfe66
--- /dev/null
+++ b/docs/reviews/2026-11-01-files-changes-notifier-codex.md
@@ -0,0 +1,2114 @@
+Reading additional input from stdin...
+OpenAI Codex v0.166.0
+--------
+workdir: /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+model: gpt-6.1-sol
+provider: openai
+approval: on-request
+sandbox: read-only
+reasoning effort: medium
+reasoning summaries: none
+session id: 01a193ee-cd9e-78d2-b581-7521a156b130
+--------
+user
+Review commit 282034e in this repo (run: git show 282034e). It is a native SwiftUI iOS client for herdr-core; the app reaches the box only through herdr-core's machine.exec (argv, stdout base64 capped at 8 MB per call, 16 MiB frame). Changes: (1) App/Resources/Notify/install-service.sh runs the push notifier as a launchd agent on macOS / systemd on Linux / nohup otherwise, used by NotificationSettings.swift and scripts/install-notifier.sh; (2) FilesView.swift reads files in 8 MiB chunks, checking size+mtime per chunk, up to 256 MiB; (3) HTML/SVG open in a WKWebView with JavaScript off; (4) ChangesView.swift lists git status --porcelain -z and shows git diff per file. Review only: correctness bugs, security (untrusted box content, shell quoting, plist injection), data loss, edge cases (empty file, file changing mid-read, renamed files, non-git folders, paths with spaces, folder '~'). Do not edit anything. Output a numbered list of findings with severity (High/Medium/Low), file:line, the failure scenario, and a fix; end with a verdict.
+warning: Codex could not update marketplace `impeccable`: trusted Git repository root escapes Codex home
+warning: Codex could not update marketplace `ponytail`: trusted Git repository root escapes Codex home
+hook: SessionStart
+hook: SessionStart
+hook: SessionStart
+hook: SessionStart Completed
+hook: SessionStart Completed
+hook: SessionStart Completed
+hook: UserPromptSubmit
+hook: UserPromptSubmit
+hook: UserPromptSubmit
+hook: UserPromptSubmit Completed
+hook: UserPromptSubmit Completed
+hook: UserPromptSubmit Completed
+codex
+`git show 282034e` と関連する呼び出し元を読み、指定された境界条件とセキュリティを確認します。ponytail のレビュー手順を使い、変更は加えません。
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'git show 282034e' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+commit 282034e9fe49e45e8b065bb33571f00c5c427e42
+Author: i2 <95607264+YosukeIida@users.noreply.github.com>
+Date:   Sun Nov 1 06:47:30 2026 +0900
+
+    Run the notifier under launchd on macOS, preview large files, HTML and SVG, and show git changes
+    
+    A notifier started with nohup died with the session; launchd keeps it up. Files
+    over 8 MiB are read in chunks checked by size and mtime; HTML and SVG open in a
+    script-free web view at phone width instead of Quick Look's desktop layout; a
+    space's uncommitted changes and their diffs come from the box's git.
+
+diff --git a/App/Resources/Notify/install-service.sh b/App/Resources/Notify/install-service.sh
+new file mode 100644
+index 0000000..ba4fb25
+--- /dev/null
++++ b/App/Resources/Notify/install-service.sh
+@@ -0,0 +1,55 @@
++#!/bin/sh
++# Runs herdr-notify as a service on the box: a launchd agent on macOS, a systemd
++# user service on Linux, nohup where neither is available. Used by the app's
++# Settings → Notifications and by scripts/install-notifier.sh.
++set -eu
++d="$HOME/.config/herdr-ios"
++script="$d/herdr-notify.py"
++py="$(command -v python3)"
++
++if [ "$(uname)" = Darwin ]; then
++  label=dev.herdr.notify
++  plist="$HOME/Library/LaunchAgents/$label.plist"
++  mkdir -p "$HOME/Library/LaunchAgents"
++  # launchd starts jobs with PATH=/usr/bin:/bin:/usr/sbin:/sbin; keep the PATH that found hc and python3 here.
++  cat > "$plist" <<EOF
++<?xml version="1.0" encoding="UTF-8"?>
++<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
++<plist version="1.0">
++<dict>
++  <key>Label</key><string>$label</string>
++  <key>ProgramArguments</key><array><string>$py</string><string>$script</string></array>
++  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$PATH</string></dict>
++  <key>RunAtLoad</key><true/>
++  <key>KeepAlive</key><true/>
++  <key>ThrottleInterval</key><integer>10</integer>
++  <key>StandardOutPath</key><string>$d/notify.log</string>
++  <key>StandardErrorPath</key><string>$d/notify.log</string>
++</dict>
++</plist>
++EOF
++  pkill -f "$script" 2>/dev/null || true
++  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
++  launchctl bootstrap "gui/$(id -u)" "$plist"
++elif systemctl --user show-environment >/dev/null 2>&1; then
++  mkdir -p "$HOME/.config/systemd/user"
++  cat > "$HOME/.config/systemd/user/herdr-notify.service" <<EOF
++[Unit]
++Description=Herdr for iOS push notifications
++After=network-online.target
++
++[Service]
++ExecStart=$py %h/.config/herdr-ios/herdr-notify.py
++Restart=always
++RestartSec=5
++
++[Install]
++WantedBy=default.target
++EOF
++  systemctl --user daemon-reload
++  systemctl --user enable herdr-notify >/dev/null 2>&1 || true
++  systemctl --user restart herdr-notify
++else
++  pkill -f "$script" 2>/dev/null || true
++  nohup "$py" "$script" >"$d/notify.log" 2>&1 &
++fi
+diff --git a/App/Sources/Notify/NotificationSettings.swift b/App/Sources/Notify/NotificationSettings.swift
+index 22895b1..ec7ca63 100644
+--- a/App/Sources/Notify/NotificationSettings.swift
++++ b/App/Sources/Notify/NotificationSettings.swift
+@@ -146,7 +146,7 @@ private struct NotifierSetup: View {
+                         Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(HC.blocked).font(HF.ui(13.5))
+                     }
+                 } footer: {
+-                    Text("Copies herdr-notify (a short Python script) to \(store.machineTitle), runs it as a systemd user service, and sends a test notification.")
++                    Text("Copies herdr-notify (a short Python script) to \(store.machineTitle), runs it as a service (launchd on macOS, systemd on Linux), and sends a test notification.")
+                 }
+             }
+             .navigationTitle("Notifications")
+@@ -171,26 +171,13 @@ private struct NotifierSetup: View {
+     }
+ 
+     private func install() {
+-        guard let keyPEM, let script = Bundle.main.url(forResource: "herdr-notify", withExtension: "py").flatMap({ try? Data(contentsOf: $0) }) else {
++        guard let keyPEM, let script = Bundle.main.url(forResource: "herdr-notify", withExtension: "py").flatMap({ try? Data(contentsOf: $0) }),
++              let service = Bundle.main.url(forResource: "install-service", withExtension: "sh").flatMap({ try? Data(contentsOf: $0) }) else {
+             error = "The notifier script is missing from the app."; return
+         }
+         error = nil
+         let apns: [String: Any] = ["key_id": keyID, "team_id": teamID, "bundle_id": Bundle.main.bundleIdentifier ?? "",
+                                    "key_path": "~/.config/herdr-ios/AuthKey.p8"]
+-        let unit = """
+-        [Unit]
+-        Description=Herdr for iOS push notifications
+-        After=network-online.target
+-
+-        [Service]
+-        ExecStart=/usr/bin/env python3 %h/.config/herdr-ios/herdr-notify.py
+-        Restart=always
+-        RestartSec=5
+-
+-        [Install]
+-        WantedBy=default.target
+-
+-        """
+         Task {
+             do {
+                 step = "Key"
+@@ -200,8 +187,7 @@ private struct NotifierSetup: View {
+                 step = "Script"
+                 try await put("herdr-notify.py", script, mode: "755")
+                 step = "Service"
+-                try await sh(#"mkdir -p "$HOME/.config/systemd/user" && cat > "$HOME/.config/systemd/user/herdr-notify.service""#, input: Data(unit.utf8))
+-                try await sh(#"if systemctl --user show-environment >/dev/null 2>&1; then systemctl --user daemon-reload && systemctl --user enable herdr-notify >/dev/null 2>&1; systemctl --user restart herdr-notify; else pkill -f herdr-notify.py; nohup python3 "$HOME/.config/herdr-ios/herdr-notify.py" >"$HOME/.config/herdr-ios/notify.log" 2>&1 & fi"#)
++                try await sh(#"sh -s"#, input: service)
+                 step = "Test"
+                 await Push.shared.upload(to: store, force: true)
+                 try await sh(#"python3 "$HOME/.config/herdr-ios/herdr-notify.py" --test"#)
+diff --git a/App/Sources/UI/ChangesView.swift b/App/Sources/UI/ChangesView.swift
+new file mode 100644
+index 0000000..bfbcae5
+--- /dev/null
++++ b/App/Sources/UI/ChangesView.swift
+@@ -0,0 +1,155 @@
++import SwiftUI
++import HerdrKit
++
++/// A space's uncommitted git changes on the box: the changed files, then one file's diff.
++/// Runs the box's git through machine.exec, read-only.
++struct ChangesSheet: View {
++    @Environment(AppStore.self) private var store
++    @Environment(\.dismiss) private var dismiss
++    var folder: String
++    var title: String
++
++    struct Change: Hashable, Identifiable {
++        var code: String   // porcelain XY, e.g. " M", "A ", "??"
++        var path: String
++        var id: String { path }
++        var untracked: Bool { code == "??" }
++    }
++
++    @State private var changes: [Change]?
++    @State private var error: String?
++
++    var body: some View {
++        NavigationStack {
++            List {
++                if let error { Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked) }
++                if changes?.isEmpty == true { Text("No uncommitted changes.").font(HF.ui(14)).foregroundStyle(HC.muted) }
++                ForEach(changes ?? []) { c in
++                    NavigationLink(value: c) {
++                        HStack(spacing: 12) {
++                            Text(c.code.replacingOccurrences(of: " ", with: "·")).font(HF.mono(13, .semibold))
++                                .foregroundStyle(c.untracked ? HC.done : HC.working).frame(width: 26, alignment: .leading)
++                            Text(c.path).font(HF.ui(15)).foregroundStyle(HC.fg).lineLimit(2).truncationMode(.head)
++                        }
++                        .accessibilityElement(children: .combine)
++                        .accessibilityLabel(c.path)
++                    }
++                }
++            }
++            .overlay { if changes == nil && error == nil { ProgressView() } }
++            .navigationTitle("Changes · \(title)")
++            .navigationBarTitleDisplayMode(.inline)
++            .navigationDestination(for: Change.self) { c in DiffView(folder: folder, change: c) }
++            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
++            .task { await load() }
++            .refreshable { await load() }
++        }
++    }
++
++    private func load() async {
++        do {
++            let r = try await store.exec(argv: ["git", "-C", folder.isEmpty ? "." : folder, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
++                                         cwd: nil, on: nil, timeout: 20, input: nil)
++            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(folder)"); return }
++            changes = Self.parse(r.stdout)
++            error = nil
++        } catch {
++            self.error = DiffView.message(error)
++        }
++    }
++
++    /// `git status --porcelain=v1 -z`: "XY path\0", and a rename or copy adds its source as the next "\0" field.
++    static func parse(_ out: Data) -> [Change] {
++        let fields = out.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
++        var result: [Change] = [], i = 0
++        while i < fields.count {
++            let f = fields[i]; i += 1
++            guard f.count > 3 else { continue }
++            let code = String(f.prefix(2))
++            result.append(Change(code: code, path: String(f.dropFirst(3))))
++            if code.contains("R") || code.contains("C") { i += 1 }
++        }
++        return result
++    }
++}
++
++/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
++struct DiffView: View {
++    @Environment(AppStore.self) private var store
++    var folder: String
++    var change: ChangesSheet.Change
++
++    @State private var lines: [Substring]?
++    @State private var error: String?
++
++    /// More lines than this are cut off; a phone can't usefully scroll a larger diff.
++    static let maxLines = 5000
++
++    var body: some View {
++        ScrollView([.vertical, .horizontal]) {
++            if let error {
++                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked).padding(16)
++            } else if let lines {
++                LazyVStack(alignment: .leading, spacing: 0) {
++                    ForEach(Array(lines.prefix(Self.maxLines).enumerated()), id: \.offset) { _, l in
++                        Text(l.isEmpty ? " " : String(l)).font(HF.mono(12)).foregroundStyle(Self.color(l))
++                            .padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
++                            .background(Self.background(l))
++                    }
++                    if lines.count > Self.maxLines {
++                        Text("\(lines.count - Self.maxLines) more lines not shown.").font(HF.ui(13)).foregroundStyle(HC.dim).padding(10)
++                    }
++                }
++                .textSelection(.enabled)
++                .accessibilityIdentifier("diffLines")
++            } else {
++                ProgressView().padding(40)
++            }
++        }
++        .background(HC.canvas)
++        .navigationTitle((change.path as NSString).lastPathComponent)
++        .navigationBarTitleDisplayMode(.inline)
++        .task { await load() }
++    }
++
++    private func load() async {
++        let dir = folder.isEmpty ? "." : folder
++        // --no-index exits 1 when the files differ, which for an untracked file is always.
++        let argv = change.untracked
++            ? ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", change.path]
++            : ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "HEAD", "--", change.path]
++        do {
++            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
++            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
++            let text = String(decoding: r.stdout, as: UTF8.self)
++            lines = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
++        } catch {
++            self.error = Self.message(error)
++        }
++    }
++
++    static func color(_ l: Substring) -> Color {
++        if l.hasPrefix("@@") { return HC.working }
++        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") { return HC.dim }
++        if l.hasPrefix("+") { return HC.done }
++        if l.hasPrefix("-") { return HC.blocked }
++        return HC.fg
++    }
++
++    static func background(_ l: Substring) -> Color {
++        if l.hasPrefix("+++") || l.hasPrefix("---") { return .clear }
++        if l.hasPrefix("+") { return HC.done.opacity(0.12) }
++        if l.hasPrefix("-") { return HC.blocked.opacity(0.12) }
++        return .clear
++    }
++
++    static func failure(_ r: ExecResult, _ fallback: String) -> String {
++        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
++        return why.isEmpty ? fallback : String(why.suffix(300))
++    }
++
++    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
++    static func message(_ error: Error) -> String {
++        (error as? HerdrError)?.kind == "spawn_failed" ? "Changes needs git on the box." : error.localizedDescription
++    }
++}
+diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
+index 1374503..acacb92 100644
+--- a/App/Sources/UI/FilesView.swift
++++ b/App/Sources/UI/FilesView.swift
+@@ -1,5 +1,6 @@
+ import SwiftUI
+ import QuickLook
++import WebKit
+ import HerdrKit
+ 
+ /// A space's folder on the box: browse it and open files in Quick Look
+@@ -24,12 +25,18 @@ struct FilesView: View {
+     @State private var fetch: Task<Void, Never>?
+     @State private var preview: URL?
+     @State private var markdown: MarkdownDoc?
++    @State private var progress: String?
++    @State private var web: WebDoc?
++
++    struct WebDoc: Identifiable { var name: String; var url: URL; var id: URL { url } }
+ 
+     struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }
+ 
+-    /// The largest file read in one machine.exec. The reply is base64 (4/3) inside JSON in one
++    /// The most read in one machine.exec. The reply is base64 (4/3) inside JSON in one
+     /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
+-    static let maxBytes = Frame.maxPayload / 2
++    static let chunkBytes = Frame.maxPayload / 2
++    /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
++    static let maxBytes = 256 << 20
+ 
+     // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
+     // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
+@@ -48,23 +55,23 @@ struct FilesView: View {
+     print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
+     """
+ 
+-    // Writes at most argv[2] bytes of the regular file argv[1]; exits 3 when it is larger, 1 when it is not a
+-    // regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
++    // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
++    // exits 1 when it is not a regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
+     static let readScript = """
+     import os, stat, sys
+-    limit = int(sys.argv[2])
++    off, limit = int(sys.argv[2]), int(sys.argv[3])
+     fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
+-    if not stat.S_ISREG(os.fstat(fd).st_mode):
++    st = os.fstat(fd)
++    if not stat.S_ISREG(st.st_mode):
+         sys.exit("not a regular file")
++    os.lseek(fd, off, os.SEEK_SET)
+     data = b""
+-    while len(data) <= limit:
+-        chunk = os.read(fd, min(1 << 20, limit + 1 - len(data)))
++    while len(data) < limit:
++        chunk = os.read(fd, min(1 << 20, limit - len(data)))
+         if not chunk:
+             break
+         data += chunk
+-    if len(data) > limit:
+-        sys.stderr.write("larger than %d bytes" % limit); sys.exit(3)
+-    sys.stdout.buffer.write(data)
++    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
+     """
+ 
+     var body: some View {
+@@ -100,9 +107,19 @@ struct FilesView: View {
+                     .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { markdown = nil }.accessibilityIdentifier("markdownClose") } }
+             }
+         }
++        .sheet(item: $web, onDismiss: nil) { doc in
++            NavigationStack {
++                WebPreview(url: doc.url)
++                    .ignoresSafeArea(edges: .bottom)
++                    .navigationTitle(doc.name)
++                    .navigationBarTitleDisplayMode(.inline)
++                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { web = nil }.accessibilityIdentifier("webClose") } }
++            }
++        }
++        .onChange(of: web?.url) { old, new in if new == nil, let old { Self.discard(old) } }
+         .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
+         // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
+-        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil }
++        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil; progress = nil }
+     }
+ 
+     private func row(_ e: Entry) -> some View {
+@@ -113,6 +130,7 @@ struct FilesView: View {
+             Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
+             Spacer(minLength: 8)
+             if opening == e.name {
++                if let progress { Text(progress).font(HF.ui(13)).foregroundStyle(HC.dim).monospacedDigit() }
+                 ProgressView()
+             } else if !e.isDir {
+                 Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
+@@ -163,21 +181,14 @@ struct FilesView: View {
+ 
+     private func open(_ e: Entry) {
+         guard let dir, opening == nil else { return }
+-        // shortcut: files over maxBytes (8 MiB) are refused; read them in ranges when large files matter.
+-        guard e.size <= Self.maxBytes else {
+-            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over \(Self.maxBytes.formatted(.byteCount(style: .file))) can't be previewed yet."
+-            return
+-        }
++        guard e.size <= Self.maxBytes else { error = Self.tooLarge(e.name, e.size); return }
+         opening = e.name
+         fetch = Task {
+-            defer { if !Task.isCancelled { opening = nil; fetch = nil } }
++            defer { if !Task.isCancelled { opening = nil; fetch = nil; progress = nil } }
+             do {
+-                let r = try await store.exec(argv: ["python3", "-c", Self.readScript, dir + "/" + e.name, String(Self.maxBytes)],
+-                                             cwd: nil, on: nil, timeout: 60, input: nil)
+-                guard !Task.isCancelled else { return }
+-                guard r.code == 0, !r.timedOut else { error = Self.failure(r, "Couldn't read \(e.name)"); return }
++                guard let data = try await read(dir + "/" + e.name, e.name) else { return }
+                 // Why not Quick Look for Markdown: it shows the raw source; Chat's renderer formats it.
+-                if ["md", "markdown"].contains((e.name as NSString).pathExtension.lowercased()), let s = String(data: r.stdout, encoding: .utf8) {
++                if ["md", "markdown"].contains((e.name as NSString).pathExtension.lowercased()), let s = String(data: data, encoding: .utf8) {
+                     error = nil
+                     markdown = MarkdownDoc(name: e.name, text: s)
+                     return
+@@ -188,21 +199,88 @@ struct FilesView: View {
+                     .appendingPathComponent(UUID().uuidString, isDirectory: true)
+                 try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+                 let url = folder.appendingPathComponent(e.name)
+-                try r.stdout.write(to: url, options: .completeFileProtection)
+                 error = nil
+-                preview = url
++                // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
++                switch (e.name as NSString).pathExtension.lowercased() {
++                case "html", "htm":
++                    try Self.fitted(html: data).write(to: url, options: .completeFileProtection)
++                    web = WebDoc(name: e.name, url: url)
++                case "svg":
++                    try data.write(to: url, options: .completeFileProtection)
++                    let page = folder.appendingPathComponent("index.html")
++                    try Self.wrapper(image: e.name).write(to: page, options: .completeFileProtection)
++                    web = WebDoc(name: e.name, url: page)
++                default:
++                    try data.write(to: url, options: .completeFileProtection)
++                    preview = url
++                }
+             } catch {
+                 if !Task.isCancelled { self.error = Self.message(error) }
+             }
+         }
+     }
+ 
++    /// The page with a phone-width viewport when it declares none.
++    static func fitted(html: Data) -> Data {
++        let head = String(decoding: html.prefix(8192), as: UTF8.self).lowercased()
++        if head.contains("name=\"viewport\"") || head.contains("name=viewport") || head.contains("name='viewport'") { return html }
++        return Data(#"<meta name="viewport" content="width=device-width, initial-scale=1">"#.utf8) + html
++    }
++
++    /// A page showing one vector image at the screen width.
++    static func wrapper(image name: String) -> Data {
++        let src = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
++        return Data(#"<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1"><body style="margin:0;background:#fff"><img src="\#(src)" style="display:block;width:100%;height:auto">"#.utf8)
++    }
++
++    private static func tooLarge(_ name: String, _ size: Int) -> String {
++        "\(name) is \(size.formatted(.byteCount(style: .file))); files over \(maxBytes.formatted(.byteCount(style: .file))) can't be previewed."
++    }
++
++    /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
++    /// the file changes size or mtime between chunks, or it grows past `maxBytes`.
++    private func read(_ path: String, _ name: String) async throws -> Data? {
++        var data = Data(), stamp: String?
++        while true {
++            let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
++                                         cwd: nil, on: nil, timeout: 60, input: nil)
++            guard !Task.isCancelled else { return nil }
++            guard r.code == 0, !r.timedOut, let nl = r.stdout.firstIndex(of: 10) else {
++                error = Self.failure(r, "Couldn't read \(name)"); return nil
++            }
++            let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
++            let size = Int(head.split(separator: " ").first ?? "") ?? 0
++            guard stamp == nil || stamp == head else { error = "\(name) changed while it was being read."; return nil }
++            guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
++            stamp = head
++            let body = r.stdout[(nl + 1)...]
++            data.append(body)
++            if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
++            if body.count < Self.chunkBytes || data.count >= size { return data }
++        }
++    }
++
+     /// Deletes a closed preview's downloaded copy (its own folder).
+     private static func discard(_ url: URL) {
+         try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
+     }
+ }
+ 
++/// A downloaded HTML page or SVG, with scripts off and file access limited to its own folder.
++private struct WebPreview: UIViewRepresentable {
++    let url: URL
++
++    func makeUIView(context: Context) -> WKWebView {
++        let config = WKWebViewConfiguration()
++        config.defaultWebpagePreferences.allowsContentJavaScript = false
++        let view = WKWebView(frame: .zero, configuration: config)
++        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
++        return view
++    }
++
++    func updateUIView(_ view: WKWebView, context: Context) {}
++}
++
+ /// The Files sheet for one space: its own stack so folders push inside the sheet.
+ struct FilesSheet: View {
+     @Environment(\.dismiss) private var dismiss
+diff --git a/App/Sources/UI/SpaceView.swift b/App/Sources/UI/SpaceView.swift
+index b47a42b..34189ab 100644
+--- a/App/Sources/UI/SpaceView.swift
++++ b/App/Sources/UI/SpaceView.swift
+@@ -10,6 +10,7 @@ struct SpaceView: View {
+     var spaceID: String
+     @State private var paneIndex = 0
+     @State private var showFiles = false
++    @State private var showChanges = false
+ 
+     private var space: SpaceRef? { store.spaces.first { $0.id == spaceID } }
+ 
+@@ -78,6 +79,10 @@ struct SpaceView: View {
+                     Text(name.isEmpty ? "~" : name).font(HF.ui(16, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
+                 }
+             }
++            ToolbarItem(placement: .topBarTrailing) {
++                Button { showChanges = true } label: { Image(systemName: "plusminus") }
++                    .accessibilityLabel("Changes")
++            }
+             ToolbarItem(placement: .topBarTrailing) {
+                 Button { showFiles = true } label: { Image(systemName: "folder") }
+                     .accessibilityLabel("Files")
+@@ -88,6 +93,7 @@ struct SpaceView: View {
+             }
+         }
+         .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
++        .sheet(isPresented: $showChanges) { ChangesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
+         .onAppear { store.selectedSpaceID = space.id }
+     }
+ }
+diff --git a/README.ja.md b/README.ja.md
+index 26f09a5..23237a5 100644
+--- a/README.ja.md
++++ b/README.ja.md
+@@ -51,7 +51,7 @@
+ ## 通知
+ 
+ iOS はバックグラウンドでアプリの SSH 接続を閉じるため、iPhone は agent が待ち状態に入ったことを検知できない。代わりに user のマシンが通知を送る。
+-- **notifier:** `herdr-notify` は短い Python スクリプトであり、systemd の user サービスとして動く（systemd の user セッションがない環境、たとえば macOS では nohup で起動する）。`hc events` を追い、agent がブロックされるかターンを終えると、user の APNs 鍵を使って HTTP/2 で Apple へ push する。
++- **notifier:** `herdr-notify` は短い Python スクリプトであり、サービスとして動く（macOS では launchd の agent `dev.herdr.notify`、Linux では systemd の user サービス、どちらも無い環境では nohup で起動する）。`hc events` を追い、agent がブロックされるかターンを終えると、user の APNs 鍵を使って HTTP/2 で Apple へ push する。
+ - **iPhone の宛先:** アプリは、開いている接続を通して自身の push token をマシンの `~/.config/herdr-ios/devices/` に渡す。
+ 
+ 設定には有料の Apple Developer アカウントが必要である。
+diff --git a/README.md b/README.md
+index 2b799de..44c4a63 100644
+--- a/README.md
++++ b/README.md
+@@ -49,7 +49,7 @@ The app opens an SSH exec channel to your machine and runs `herdr-core connect`.
+ ## Notifications
+ 
+ iOS closes the app's SSH connection in the background, so the phone can't see an agent start waiting. Your machine sends the notification instead:
+-- **The notifier:** `herdr-notify` is a short Python script running as a systemd user service (started with nohup where there is no systemd user session, e.g. macOS). It follows `hc events` and, when an agent becomes blocked or finishes a turn, pushes to Apple over HTTP/2 with your APNs key.
++- **The notifier:** `herdr-notify` is a short Python script running as a service: a launchd agent (`dev.herdr.notify`) on macOS, a systemd user service on Linux, or nohup where neither exists. It follows `hc events` and, when an agent becomes blocked or finishes a turn, pushes to Apple over HTTP/2 with your APNs key.
+ - **Your phone's address:** the app hands its push token to the machine over the open connection, in `~/.config/herdr-ios/devices/`.
+ 
+ Setup needs a paid Apple Developer account:
+diff --git a/UITests/HerdrUITests.swift b/UITests/HerdrUITests.swift
+index 3c4a6ee..99aeaa0 100644
+--- a/UITests/HerdrUITests.swift
++++ b/UITests/HerdrUITests.swift
+@@ -87,18 +87,39 @@ final class HerdrUITests: XCTestCase {
+             let row = app.buttons[name]
+             XCTAssertTrue(reveal(row, in: app), "no file \(name)")
+             row.tap()
+-            // Quick Look, or the app's own sheet for Markdown.
+-            let done = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'QLOverlayDoneButton' OR identifier == 'markdownClose'")).firstMatch
++            // Quick Look, or the app's own sheet for Markdown, HTML and SVG.
++            let done = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'QLOverlayDoneButton' OR identifier == 'markdownClose' OR identifier == 'webClose'")).firstMatch
+             // Images open full screen with the controls hidden; a tap brings them back.
+-            if !done.waitForExistence(timeout: 15) { app.tap() }
++            if !done.waitForExistence(timeout: 90) { app.tap() }
+             XCTAssertTrue(done.waitForExistence(timeout: 15), "Quick Look did not open \(name)")
+             sleep(2)
+             shot(app, "preview-\(name)")
++            if !done.isHittable { app.tap() }
++            XCTAssertTrue(done.waitForExistence(timeout: 5), "no close button for \(name)")
+             done.tap()
+             XCTAssertTrue(row.waitForExistence(timeout: 10), "did not return to the list after \(name)")
+         }
+     }
+ 
++    /// Changes: from a space ($HERDR_TEST_SPACE) open the uncommitted changes, tap
++    /// $HERDR_TEST_CHANGES_FILE (a path relative to the space folder) and wait for its diff.
++    func testChangesShowDiff() throws {
++        let env = ProcessInfo.processInfo.environment
++        let app = launch(["HERDR_DEBUG_OPEN": try XCTUnwrap(env["HERDR_TEST_SPACE"])])
++        let changes = app.buttons["Changes"]
++        XCTAssertTrue(changes.waitForExistence(timeout: 30), "no Changes button in the space")
++        changes.tap()
++        let row = app.buttons[try XCTUnwrap(env["HERDR_TEST_CHANGES_FILE"])]
++        XCTAssertTrue(reveal(row, in: app), "file not listed as changed")
++        shot(app, "changes-list")
++        row.tap()
++        let diff = app.descendants(matching: .any)["diffLines"]
++        XCTAssertTrue(diff.waitForExistence(timeout: 30), "no diff shown")
++        let added = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '+'")).firstMatch
++        XCTAssertTrue(added.waitForExistence(timeout: 5), "no added line in the diff")
++        shot(app, "changes-diff")
++    }
++
+     /// Chat sends: types $HERDR_TEST_SEND_TEXT into the composer of $HERDR_TEST_SEND_TERMINAL (a
+     /// throwaway Claude Code or Codex), sends it, and waits for a reply line equal to
+     /// $HERDR_TEST_SEND_EXPECT, which must not appear in the text sent.
+diff --git a/docs/HANDOVER.md b/docs/HANDOVER.md
+index 353021c..c13b2e9 100644
+--- a/docs/HANDOVER.md
++++ b/docs/HANDOVER.md
+@@ -125,7 +125,6 @@ TEST_RUNNER_HERDR_TEST_BLOCKED_TERMINAL=<address> TEST_RUNNER_HERDR_TEST_BLOCKED
+ 
+ - Chat: Codex thread matching would be exact if Codex exposed its thread id to the terminal. If the Chat code turns out weak to extend,
+   opencode and Orca's chat are acceptable references (check licenses first).
+-- launchd notifier for macOS (`NotificationSettings.swift:180-205`, `scripts/install-notifier.sh`).
+ - Files: chunked reads above 8 MiB; HTML/SVG scaled to the screen (WKWebView) if that matters.
+ - Run on a real iPhone (needs `Config/Local.xcconfig` with a team id).
+ - Citadel: close the channel on handshake failure (fork + upstream PR), see `docs/reviews/PENDING.md`.
+diff --git a/scripts/install-notifier.sh b/scripts/install-notifier.sh
+index 78fc305..a406649 100755
+--- a/scripts/install-notifier.sh
++++ b/scripts/install-notifier.sh
+@@ -5,7 +5,7 @@
+ #   scripts/install-notifier.sh <ssh host> <AuthKey_XXXXXXXXXX.p8> <team id> <bundle id>
+ #
+ # Puts the APNs key, apns.json and the script in ~/.config/herdr-ios (mode 700,
+-# key 600), installs a systemd user service `herdr-notify`, and starts it.
++# key 600), and runs it as a service (launchd on macOS, systemd on Linux).
+ set -eu
+ 
+ if [ $# -ne 4 ]; then
+@@ -26,18 +26,7 @@ echo "→ script"
+ ssh "$host" 'cat > "$HOME/.config/herdr-ios/herdr-notify.py" && chmod 755 "$HOME/.config/herdr-ios/herdr-notify.py"' < "$here/App/Resources/Notify/herdr-notify.py"
+ 
+ echo "→ service"
+-ssh "$host" 'mkdir -p "$HOME/.config/systemd/user" && cat > "$HOME/.config/systemd/user/herdr-notify.service"' <<'EOF'
+-[Unit]
+-Description=Herdr for iOS push notifications
+-After=network-online.target
+-
+-[Service]
+-ExecStart=/usr/bin/env python3 %h/.config/herdr-ios/herdr-notify.py
+-Restart=always
+-RestartSec=5
+-
+-[Install]
+-WantedBy=default.target
+-EOF
+-ssh "$host" 'systemctl --user daemon-reload && systemctl --user enable herdr-notify >/dev/null 2>&1; systemctl --user restart herdr-notify; sleep 2; systemctl --user is-active herdr-notify && journalctl --user -u herdr-notify -n 3 --no-pager -o cat'
++ssh "$host" sh -s < "$here/App/Resources/Notify/install-service.sh"
++sleep 2
++ssh "$host" "pgrep -f herdr-notify.py >/dev/null && tail -n 3 \"\$HOME/.config/herdr-ios/notify.log\" 2>/dev/null; true"
+ echo "done. Open Herdr on the phone (connected) and allow notifications; then Settings → Notifications → Send a test."
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail/SKILL.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+---
+name: ponytail-review
+description: >
+  Quality review of a change: is the logic right, is it safe, does it hold
+  under real load, is risky code tested, is it fast enough, and is every line
+  needed. Reads the connected code, not only the diff. Each finding is
+  explained in plain English. Use for "review this", "code review", "review
+  the last commit", "review my PR", "is this over-engineered", /ponytail-review.
+---
+
+Review a change like the senior developer who will be paged when it breaks.
+Order of importance: correct, safe, holds under load, tested, fast, lean.
+Lean still matters: every extra line must be read, tested and fixed later.
+This is a report the user asked for, so give it in full.
+
+## 1. Understand first
+
+- Review what the user names: uncommitted or staged changes, a branch, a PR
+  link, or files. Nothing named: the uncommitted changes, or the last commit
+  if there are none.
+- Read the diff, then the code it touches: callers of every changed function,
+  the functions it calls, the tests, the README.
+- Trace the real flow: where data comes in, what is stored, what goes out.
+- A change can break code it does not touch. When a signature, return value
+  or behavior changes, grep every caller.
+- Find the expected load in the repo (README, deploy config): one person
+  running a script, or many users and processes at once. Judge scale against
+  that, and say which load you assumed.
+
+## 2. Look for
+
+1. **Bug:** wrong result, crash, missed edge case (empty, zero, last item,
+   rounding, time zones), a caller broken by the change, a fix applied in one
+   caller while the shared function stays broken.
+2. **Risk:** security holes (injection, weak randomness, secrets, missing
+   checks on input from users), data loss (errors swallowed, writes in the
+   wrong order, no transaction).
+3. **Scale:** fine for one user, wrong for many: check-then-write races, the
+   same work done by every process, memory or lists that only grow, a query
+   per item, O(n^2) on big input, per-process state that must be shared.
+4. **Missing test:** risky new logic (a branch, a parser, money, security,
+   data writes, a bug fix) with no test that fails when it breaks. One good
+   test, not coverage.
+5. **Speed:** big slowdowns are problems. Small wins (work repeated in a hot
+   loop) are suggestions; some software counts every millisecond.
+6. **Lean:** code that should not exist or should be smaller.
+   - delete: dead code, unused options, speculative features
+   - reuse: the repo already has this helper (name the path)
+   - stdlib / native: the standard library or platform already does it; a
+     new dependency for a few lines
+   - yagni: abstraction with one implementation, config nobody sets
+   - merge: near-copies that must change together
+   - split: one function doing several unrelated jobs, so it is hard to read
+     or test. Split by job, never by line count, and never into helpers that
+     exist only to make a function shorter.
+
+## 3. Check before you report
+
+- Every finding needs a concrete case: "this input or situation leads to this
+  wrong result". No case, no finding.
+- Re-read the lines and confirm: the caller exists, the value can really be
+  empty, the code really is unused.
+- A shortcut marked with a `shortcut:` (or older `ponytail:`) comment that names its limit is a
+  decision, not a finding, unless the expected load already crosses it.
+- Propose the smallest fix that works. Prefer fixes that delete code. Never
+  add layers, frameworks or config the problem does not need.
+- No style taste, no "consider", no vague worries.
+
+## 4. Output
+
+Very simple English: short sentences, everyday words. Explain a technical
+term the first time you use it. The reader may never have seen this code.
+
+Start with `What this change does:` in two or three sentences.
+
+Then the findings in three groups, skip empty groups:
+- **Must fix:** bug, security, data loss, breaks at the expected load.
+- **Should fix:** risky code without a test, real slowness, duplication, a
+  function that mixes jobs, code that should not exist.
+- **Nice to have:** small speed-ups, shorter forms.
+
+Number findings across all groups, so the user can say "fix 2 and 5".
+Every finding has all four parts, each one or two short sentences:
+
+2. **Orders land on the wrong day** (`billing/close_day.py:L40-52`)
+   - **What this is:** At midnight this job closes the day and bills all orders of that day.
+   - **Problem:** It takes "today" from the server clock, which runs in UTC. An order placed
+     at 00:30 in Berlin is billed on the day before.
+   - **Fix:** Compute the day once in the shop's time zone:
+     `datetime.now(ZoneInfo("Europe/Berlin")).date()`. One line, nothing else changes.
+   - **If we skip it:** Late orders show the wrong date, and accounting fixes them by hand.
+
+End with:
+- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.`
+- `Lean: -<N> lines possible.` when lean findings exist.
+- `Not checked:` one line, if something mattered and you could not check it.
+
+Nothing found: `What this change does:`, then `Looks good. Ship.` and one line
+on what you checked.
+
+Lists findings, changes no code.
+---
+name: ponytail
+description: >
+  Lazy senior dev mode: the smallest change that fully solves the task, and a
+  reply a busy human understands in one read. Use on any coding task (writing,
+  fixing, refactoring, reviewing, choosing dependencies) and when the user says
+  "ponytail", "be lazy", "simplest solution", "yagni", or complains about
+  over-engineering or bloat. Levels: lite, full (default), ultra.
+argument-hint: "[lite|full|ultra|off]"
+license: MIT
+---
+
+# Ponytail
+
+You are a lazy senior developer. The best code is the code never written. You solve the whole problem with the least new code. End your reply with one or two lines: what you skipped or did not check, and any risk the user must know.
+
+Active for the whole session until the user says "stop ponytail" or "normal mode". Switch level: `/ponytail lite|full|ultra`.
+
+## Before you write
+
+Read the task and the code it touches. List every place your change must reach: callers, tests, fixtures, config, exports. Check what your change could break for users: data it would destroy or expose, callers that stop working. That is scope. Extra features are not.
+
+## The smallest complete change
+
+Take the first option that fully works:
+
+1. Does it need to exist? Skip features, options and flexibility nobody asked for, and name them in one line. A vague request ("build me X") gets the smallest version that does the core job.
+2. Already in this codebase (a helper, component, service, pattern)? Use it the way the surrounding code does.
+3. Standard library or a platform feature? Use it, unless the project has its own. A house component beats a native widget.
+4. An installed dependency? Use it. Never add a dependency for a few lines.
+5. Can it be one line a reader gets at a glance? One line.
+6. Otherwise: the minimum code that works.
+
+- Be lazy about the solution, never about the change itself: finish every part the task needs, including the callers, tests and fixtures your change breaks.
+- No abstraction, wrapper, type conversion, option, config, boilerplate or "for later" code nobody asked for. Keep values in the form the platform already gives you. Deletion beats addition. Keep the structure the codebase already has: its layers, interfaces and conventions.
+- The shortest working diff wins, once you know everything it must touch. A one-liner that needs decoding is not short.
+- Comment only the why the code cannot show, in one line.
+- Bug fix: before you edit, grep every caller of the function you touch, then fix the root cause once in the shared code.
+- Code you move or merge keeps its error handling and validation.
+- Between options of equal size, take the one that is correct on edge cases.
+- Lazy code without its check is unfinished: new non-trivial logic (a branch, a loop, a parser, money or security, or a whole new script or app) leaves one small test or an assert-based self-check. Trivial changes need none.
+- A shortcut with a known limit gets a code comment in this form: `shortcut: <the limit>, <when to upgrade>`.
+
+Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, the calibration real hardware needs, anything the user asked for.
+
+## Levels
+
+| Level | Behavior |
+|-------|----------|
+| **lite** | Build what was asked. Name the smaller option in one line and let the user pick. |
+| **full** | The rules above. Default. |
+| **ultra** | Also question the request: before building, push back on any part the need does not justify. |
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'git status --short; git rev-parse HEAD; nl -ba App/Sources/UI/FilesView.swift; nl -ba App/Sources/UI/ChangesView.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+?? docs/reviews/2026-11-01-files-changes-notifier-codex.md
+282034e9fe49e45e8b065bb33571f00c5c427e42
+     1	import SwiftUI
+     2	import QuickLook
+     3	import WebKit
+     4	import HerdrKit
+     5	
+     6	/// A space's folder on the box: browse it and open files in Quick Look
+     7	/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
+     8	struct FilesView: View {
+     9	    @Environment(AppStore.self) private var store
+    10	    var path: String
+    11	    var title: String
+    12	
+    13	    struct Entry: Identifiable, Hashable {
+    14	        var name: String
+    15	        var isDir: Bool
+    16	        var size: Int
+    17	        var id: String { name }
+    18	    }
+    19	
+    20	    @State private var dir: String?
+    21	    @State private var entries: [Entry] = []
+    22	    @State private var skipped = 0
+    23	    @State private var error: String?
+    24	    @State private var opening: String?
+    25	    @State private var fetch: Task<Void, Never>?
+    26	    @State private var preview: URL?
+    27	    @State private var markdown: MarkdownDoc?
+    28	    @State private var progress: String?
+    29	    @State private var web: WebDoc?
+    30	
+    31	    struct WebDoc: Identifiable { var name: String; var url: URL; var id: URL { url } }
+    32	
+    33	    struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }
+    34	
+    35	    /// The most read in one machine.exec. The reply is base64 (4/3) inside JSON in one
+    36	    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
+    37	    static let chunkBytes = Frame.maxPayload / 2
+    38	    /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
+    39	    static let maxBytes = 256 << 20
+    40	
+    41	    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
+    42	    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
+    43	    static let listScript = """
+    44	    import json, os, sys
+    45	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
+    46	    out, skipped = [], 0
+    47	    with os.scandir(d) as it:
+    48	        for e in it:
+    49	            try:
+    50	                e.name.encode("utf-8")
+    51	                isdir = e.is_dir()
+    52	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
+    53	            except (OSError, UnicodeEncodeError):
+    54	                skipped += 1
+    55	    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
+    56	    """
+    57	
+    58	    // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
+    59	    // exits 1 when it is not a regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
+    60	    static let readScript = """
+    61	    import os, stat, sys
+    62	    off, limit = int(sys.argv[2]), int(sys.argv[3])
+    63	    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
+    64	    st = os.fstat(fd)
+    65	    if not stat.S_ISREG(st.st_mode):
+    66	        sys.exit("not a regular file")
+    67	    os.lseek(fd, off, os.SEEK_SET)
+    68	    data = b""
+    69	    while len(data) < limit:
+    70	        chunk = os.read(fd, min(1 << 20, limit - len(data)))
+    71	        if not chunk:
+    72	            break
+    73	        data += chunk
+    74	    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
+    75	    """
+    76	
+    77	    var body: some View {
+    78	        List {
+    79	            if let error {
+    80	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
+    81	            }
+    82	            ForEach(entries) { e in
+    83	                if e.isDir, let dir {
+    84	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
+    85	                } else {
+    86	                    Button { open(e) } label: { row(e) }
+    87	                        .disabled(opening != nil)
+    88	                }
+    89	            }
+    90	            if skipped > 0 {
+    91	                Text("\(skipped) item(s) with names that can't be shown are hidden.")
+    92	                    .font(HF.ui(13)).foregroundStyle(HC.dim)
+    93	            }
+    94	        }
+    95	        .overlay { if dir == nil && error == nil { ProgressView() } }
+    96	        .navigationTitle(title)
+    97	        .navigationBarTitleDisplayMode(.inline)
+    98	        .task { await load() }
+    99	        .refreshable { await load() }
+   100	        .quickLookPreview($preview)
+   101	        .sheet(item: $markdown) { doc in
+   102	            NavigationStack {
+   103	                ScrollView { ChatMarkdown(text: doc.text).padding(16).frame(maxWidth: .infinity, alignment: .leading) }
+   104	                    .background(HC.canvas)
+   105	                    .navigationTitle(doc.name)
+   106	                    .navigationBarTitleDisplayMode(.inline)
+   107	                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { markdown = nil }.accessibilityIdentifier("markdownClose") } }
+   108	            }
+   109	        }
+   110	        .sheet(item: $web, onDismiss: nil) { doc in
+   111	            NavigationStack {
+   112	                WebPreview(url: doc.url)
+   113	                    .ignoresSafeArea(edges: .bottom)
+   114	                    .navigationTitle(doc.name)
+   115	                    .navigationBarTitleDisplayMode(.inline)
+   116	                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { web = nil }.accessibilityIdentifier("webClose") } }
+   117	            }
+   118	        }
+   119	        .onChange(of: web?.url) { old, new in if new == nil, let old { Self.discard(old) } }
+   120	        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
+   121	        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
+   122	        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil; progress = nil }
+   123	    }
+   124	
+   125	    private func row(_ e: Entry) -> some View {
+   126	        HStack(spacing: 12) {
+   127	            Image(systemName: e.isDir ? "folder" : "doc")
+   128	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
+   129	                .frame(width: 22)
+   130	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
+   131	            Spacer(minLength: 8)
+   132	            if opening == e.name {
+   133	                if let progress { Text(progress).font(HF.ui(13)).foregroundStyle(HC.dim).monospacedDigit() }
+   134	                ProgressView()
+   135	            } else if !e.isDir {
+   136	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
+   137	            }
+   138	        }
+   139	        .accessibilityElement(children: .combine)
+   140	        .accessibilityLabel(e.name)
+   141	    }
+   142	
+   143	    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
+   144	        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+   145	        return why.isEmpty ? fallback : String(why.suffix(300))
+   146	    }
+   147	
+   148	    private func load() async {
+   149	        do {
+   150	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+   151	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+   152	                error = Self.failure(r, "Couldn't list \(path)")
+   153	                return
+   154	            }
+   155	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
+   156	                guard let n = a[0].string else { return nil }
+   157	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
+   158	            })
+   159	            skipped = v["skipped"].int ?? 0
+   160	            dir = d
+   161	            error = nil
+   162	        } catch {
+   163	            self.error = Self.message(error)
+   164	        }
+   165	    }
+   166	
+   167	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
+   168	    private static func message(_ error: Error) -> String {
+   169	        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
+   170	    }
+   171	
+   172	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
+   173	    static func sorted(_ entries: [Entry]) -> [Entry] {
+   174	        entries.sorted { a, b in
+   175	            if a.isDir != b.isDir { return a.isDir }
+   176	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
+   177	            if ad != bd { return bd }
+   178	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
+   179	        }
+   180	    }
+   181	
+   182	    private func open(_ e: Entry) {
+   183	        guard let dir, opening == nil else { return }
+   184	        guard e.size <= Self.maxBytes else { error = Self.tooLarge(e.name, e.size); return }
+   185	        opening = e.name
+   186	        fetch = Task {
+   187	            defer { if !Task.isCancelled { opening = nil; fetch = nil; progress = nil } }
+   188	            do {
+   189	                guard let data = try await read(dir + "/" + e.name, e.name) else { return }
+   190	                // Why not Quick Look for Markdown: it shows the raw source; Chat's renderer formats it.
+   191	                if ["md", "markdown"].contains((e.name as NSString).pathExtension.lowercased()), let s = String(data: data, encoding: .utf8) {
+   192	                    error = nil
+   193	                    markdown = MarkdownDoc(name: e.name, text: s)
+   194	                    return
+   195	                }
+   196	                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
+   197	                let folder = FileManager.default.temporaryDirectory
+   198	                    .appendingPathComponent("preview", isDirectory: true)
+   199	                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
+   200	                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+   201	                let url = folder.appendingPathComponent(e.name)
+   202	                error = nil
+   203	                // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
+   204	                switch (e.name as NSString).pathExtension.lowercased() {
+   205	                case "html", "htm":
+   206	                    try Self.fitted(html: data).write(to: url, options: .completeFileProtection)
+   207	                    web = WebDoc(name: e.name, url: url)
+   208	                case "svg":
+   209	                    try data.write(to: url, options: .completeFileProtection)
+   210	                    let page = folder.appendingPathComponent("index.html")
+   211	                    try Self.wrapper(image: e.name).write(to: page, options: .completeFileProtection)
+   212	                    web = WebDoc(name: e.name, url: page)
+   213	                default:
+   214	                    try data.write(to: url, options: .completeFileProtection)
+   215	                    preview = url
+   216	                }
+   217	            } catch {
+   218	                if !Task.isCancelled { self.error = Self.message(error) }
+   219	            }
+   220	        }
+   221	    }
+   222	
+   223	    /// The page with a phone-width viewport when it declares none.
+   224	    static func fitted(html: Data) -> Data {
+   225	        let head = String(decoding: html.prefix(8192), as: UTF8.self).lowercased()
+   226	        if head.contains("name=\"viewport\"") || head.contains("name=viewport") || head.contains("name='viewport'") { return html }
+   227	        return Data(#"<meta name="viewport" content="width=device-width, initial-scale=1">"#.utf8) + html
+   228	    }
+   229	
+   230	    /// A page showing one vector image at the screen width.
+   231	    static func wrapper(image name: String) -> Data {
+   232	        let src = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
+   233	        return Data(#"<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1"><body style="margin:0;background:#fff"><img src="\#(src)" style="display:block;width:100%;height:auto">"#.utf8)
+   234	    }
+   235	
+   236	    private static func tooLarge(_ name: String, _ size: Int) -> String {
+   237	        "\(name) is \(size.formatted(.byteCount(style: .file))); files over \(maxBytes.formatted(.byteCount(style: .file))) can't be previewed."
+   238	    }
+   239	
+   240	    /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
+   241	    /// the file changes size or mtime between chunks, or it grows past `maxBytes`.
+   242	    private func read(_ path: String, _ name: String) async throws -> Data? {
+   243	        var data = Data(), stamp: String?
+   244	        while true {
+   245	            let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
+   246	                                         cwd: nil, on: nil, timeout: 60, input: nil)
+   247	            guard !Task.isCancelled else { return nil }
+   248	            guard r.code == 0, !r.timedOut, let nl = r.stdout.firstIndex(of: 10) else {
+   249	                error = Self.failure(r, "Couldn't read \(name)"); return nil
+   250	            }
+   251	            let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
+   252	            let size = Int(head.split(separator: " ").first ?? "") ?? 0
+   253	            guard stamp == nil || stamp == head else { error = "\(name) changed while it was being read."; return nil }
+   254	            guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
+   255	            stamp = head
+   256	            let body = r.stdout[(nl + 1)...]
+   257	            data.append(body)
+   258	            if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
+   259	            if body.count < Self.chunkBytes || data.count >= size { return data }
+   260	        }
+   261	    }
+   262	
+   263	    /// Deletes a closed preview's downloaded copy (its own folder).
+   264	    private static func discard(_ url: URL) {
+   265	        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
+   266	    }
+   267	}
+   268	
+   269	/// A downloaded HTML page or SVG, with scripts off and file access limited to its own folder.
+   270	private struct WebPreview: UIViewRepresentable {
+   271	    let url: URL
+   272	
+   273	    func makeUIView(context: Context) -> WKWebView {
+   274	        let config = WKWebViewConfiguration()
+   275	        config.defaultWebpagePreferences.allowsContentJavaScript = false
+   276	        let view = WKWebView(frame: .zero, configuration: config)
+   277	        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
+   278	        return view
+   279	    }
+   280	
+   281	    func updateUIView(_ view: WKWebView, context: Context) {}
+   282	}
+   283	
+   284	/// The Files sheet for one space: its own stack so folders push inside the sheet.
+   285	struct FilesSheet: View {
+   286	    @Environment(\.dismiss) private var dismiss
+   287	    var folder: String
+   288	    var title: String
+   289	
+   290	    var body: some View {
+   291	        NavigationStack {
+   292	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
+   293	                .navigationDestination(for: String.self) { p in
+   294	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
+   295	                }
+   296	                .toolbar {
+   297	                    ToolbarItem(placement: .cancellationAction) {
+   298	                        Button("Close", systemImage: "xmark") { dismiss() }
+   299	                    }
+   300	                }
+   301	        }
+   302	        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
+   303	        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
+   304	    }
+   305	}
+     1	import SwiftUI
+     2	import HerdrKit
+     3	
+     4	/// A space's uncommitted git changes on the box: the changed files, then one file's diff.
+     5	/// Runs the box's git through machine.exec, read-only.
+     6	struct ChangesSheet: View {
+     7	    @Environment(AppStore.self) private var store
+     8	    @Environment(\.dismiss) private var dismiss
+     9	    var folder: String
+    10	    var title: String
+    11	
+    12	    struct Change: Hashable, Identifiable {
+    13	        var code: String   // porcelain XY, e.g. " M", "A ", "??"
+    14	        var path: String
+    15	        var id: String { path }
+    16	        var untracked: Bool { code == "??" }
+    17	    }
+    18	
+    19	    @State private var changes: [Change]?
+    20	    @State private var error: String?
+    21	
+    22	    var body: some View {
+    23	        NavigationStack {
+    24	            List {
+    25	                if let error { Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked) }
+    26	                if changes?.isEmpty == true { Text("No uncommitted changes.").font(HF.ui(14)).foregroundStyle(HC.muted) }
+    27	                ForEach(changes ?? []) { c in
+    28	                    NavigationLink(value: c) {
+    29	                        HStack(spacing: 12) {
+    30	                            Text(c.code.replacingOccurrences(of: " ", with: "·")).font(HF.mono(13, .semibold))
+    31	                                .foregroundStyle(c.untracked ? HC.done : HC.working).frame(width: 26, alignment: .leading)
+    32	                            Text(c.path).font(HF.ui(15)).foregroundStyle(HC.fg).lineLimit(2).truncationMode(.head)
+    33	                        }
+    34	                        .accessibilityElement(children: .combine)
+    35	                        .accessibilityLabel(c.path)
+    36	                    }
+    37	                }
+    38	            }
+    39	            .overlay { if changes == nil && error == nil { ProgressView() } }
+    40	            .navigationTitle("Changes · \(title)")
+    41	            .navigationBarTitleDisplayMode(.inline)
+    42	            .navigationDestination(for: Change.self) { c in DiffView(folder: folder, change: c) }
+    43	            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
+    44	            .task { await load() }
+    45	            .refreshable { await load() }
+    46	        }
+    47	    }
+    48	
+    49	    private func load() async {
+    50	        do {
+    51	            let r = try await store.exec(argv: ["git", "-C", folder.isEmpty ? "." : folder, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
+    52	                                         cwd: nil, on: nil, timeout: 20, input: nil)
+    53	            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(folder)"); return }
+    54	            changes = Self.parse(r.stdout)
+    55	            error = nil
+    56	        } catch {
+    57	            self.error = DiffView.message(error)
+    58	        }
+    59	    }
+    60	
+    61	    /// `git status --porcelain=v1 -z`: "XY path\0", and a rename or copy adds its source as the next "\0" field.
+    62	    static func parse(_ out: Data) -> [Change] {
+    63	        let fields = out.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
+    64	        var result: [Change] = [], i = 0
+    65	        while i < fields.count {
+    66	            let f = fields[i]; i += 1
+    67	            guard f.count > 3 else { continue }
+    68	            let code = String(f.prefix(2))
+    69	            result.append(Change(code: code, path: String(f.dropFirst(3))))
+    70	            if code.contains("R") || code.contains("C") { i += 1 }
+    71	        }
+    72	        return result
+    73	    }
+    74	}
+    75	
+    76	/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
+    77	struct DiffView: View {
+    78	    @Environment(AppStore.self) private var store
+    79	    var folder: String
+    80	    var change: ChangesSheet.Change
+    81	
+    82	    @State private var lines: [Substring]?
+    83	    @State private var error: String?
+    84	
+    85	    /// More lines than this are cut off; a phone can't usefully scroll a larger diff.
+    86	    static let maxLines = 5000
+    87	
+    88	    var body: some View {
+    89	        ScrollView([.vertical, .horizontal]) {
+    90	            if let error {
+    91	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked).padding(16)
+    92	            } else if let lines {
+    93	                LazyVStack(alignment: .leading, spacing: 0) {
+    94	                    ForEach(Array(lines.prefix(Self.maxLines).enumerated()), id: \.offset) { _, l in
+    95	                        Text(l.isEmpty ? " " : String(l)).font(HF.mono(12)).foregroundStyle(Self.color(l))
+    96	                            .padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
+    97	                            .background(Self.background(l))
+    98	                    }
+    99	                    if lines.count > Self.maxLines {
+   100	                        Text("\(lines.count - Self.maxLines) more lines not shown.").font(HF.ui(13)).foregroundStyle(HC.dim).padding(10)
+   101	                    }
+   102	                }
+   103	                .textSelection(.enabled)
+   104	                .accessibilityIdentifier("diffLines")
+   105	            } else {
+   106	                ProgressView().padding(40)
+   107	            }
+   108	        }
+   109	        .background(HC.canvas)
+   110	        .navigationTitle((change.path as NSString).lastPathComponent)
+   111	        .navigationBarTitleDisplayMode(.inline)
+   112	        .task { await load() }
+   113	    }
+   114	
+   115	    private func load() async {
+   116	        let dir = folder.isEmpty ? "." : folder
+   117	        // --no-index exits 1 when the files differ, which for an untracked file is always.
+   118	        let argv = change.untracked
+   119	            ? ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", change.path]
+   120	            : ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "HEAD", "--", change.path]
+   121	        do {
+   122	            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
+   123	            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
+   124	            let text = String(decoding: r.stdout, as: UTF8.self)
+   125	            lines = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
+   126	        } catch {
+   127	            self.error = Self.message(error)
+   128	        }
+   129	    }
+   130	
+   131	    static func color(_ l: Substring) -> Color {
+   132	        if l.hasPrefix("@@") { return HC.working }
+   133	        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") { return HC.dim }
+   134	        if l.hasPrefix("+") { return HC.done }
+   135	        if l.hasPrefix("-") { return HC.blocked }
+   136	        return HC.fg
+   137	    }
+   138	
+   139	    static func background(_ l: Substring) -> Color {
+   140	        if l.hasPrefix("+++") || l.hasPrefix("---") { return .clear }
+   141	        if l.hasPrefix("+") { return HC.done.opacity(0.12) }
+   142	        if l.hasPrefix("-") { return HC.blocked.opacity(0.12) }
+   143	        return .clear
+   144	    }
+   145	
+   146	    static func failure(_ r: ExecResult, _ fallback: String) -> String {
+   147	        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+   148	        return why.isEmpty ? fallback : String(why.suffix(300))
+   149	    }
+   150	
+   151	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
+   152	    static func message(_ error: Error) -> String {
+   153	        (error as? HerdrError)?.kind == "spawn_failed" ? "Changes needs git on the box." : error.localizedDescription
+   154	    }
+   155	}
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "rg -n 'func exec|ExecResult|stdout|truncat|machine.exec|textconv' App/Sources/Store/AppStore.swift Packages/HerdrKit App/Resources/Notify/herdr-notify.py; cat scripts/install-notifier.sh; cat project.yml; cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+Packages/HerdrKit/Sources/herdr-probe/main.swift:18:func out(_ s: String) { print(s); fflush(stdout) }
+Packages/HerdrKit/Sources/herdr-probe/main.swift:109:        out("code=\(r.code.map(String.init) ?? "signal") timed_out=\(r.timedOut) stdout=\(r.stdout.count)B stderr=\(r.stderr.count)B")
+Packages/HerdrKit/Sources/herdr-probe/main.swift:110:        out(String(decoding: r.stdout.prefix(2000), as: UTF8.self))
+Packages/HerdrKit/Sources/herdr-probe/main.swift:129:        out("after cancel: \(String(decoding: after.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))")
+App/Resources/Notify/herdr-notify.py:74:                                 capture_output=True, check=True).stdout
+App/Resources/Notify/herdr-notify.py:95:            out = r.stdout.decode(errors="replace").strip().rsplit("\n", 1)
+App/Resources/Notify/herdr-notify.py:117:        screen = subprocess.run([HC, "read", address, "--lines", "0"], capture_output=True, timeout=8).stdout.decode(errors="replace")
+App/Resources/Notify/herdr-notify.py:213:        p = subprocess.Popen([HC, "events", "--json"], stdout=subprocess.PIPE, text=True, bufsize=1)
+App/Resources/Notify/herdr-notify.py:215:        for line in p.stdout:
+App/Sources/Store/AppStore.swift:428:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
+App/Sources/Store/AppStore.swift:597:        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:145:        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" } }
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:146:        let id = try JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" }!.payload)["id"]
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:192:        t.reply(msg["id"].int!, ["code": 0, "stdout": .string(Data("hi\n".utf8).base64EncodedString()), "stderr": "", "timed_out": false])
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:194:        XCTAssertEqual(res, ExecResult(code: 0, stdout: Data("hi\n".utf8), stderr: Data(), timedOut: false))
+Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:8:    /// Start the process/channel. `onBytes` gets stdout in order; `onClose`
+Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:44:public struct ExecResult: Sendable, Equatable {
+Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:46:    public var stdout: Data
+Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:49:    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool) {
+Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:50:        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:30:                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:218:    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:226:        return ExecResult(code: r["code"].int,
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:227:                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+Packages/HerdrKit/Sources/HerdrKit/ProcessTransport.swift:10:    private let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
+Packages/HerdrKit/Sources/HerdrKit/ProcessTransport.swift:30:        process.standardInput = stdin; process.standardOutput = stdout; process.standardError = stderr
+Packages/HerdrKit/Sources/HerdrKit/ProcessTransport.swift:32:        stdout.fileHandleForReading.readabilityHandler = { [weak self] h in
+#!/bin/sh
+# Installs herdr-notify on a box over SSH: the same files the app's
+# Settings → Notifications → "Set up on <box>" writes.
+#
+#   scripts/install-notifier.sh <ssh host> <AuthKey_XXXXXXXXXX.p8> <team id> <bundle id>
+#
+# Puts the APNs key, apns.json and the script in ~/.config/herdr-ios (mode 700,
+# key 600), and runs it as a service (launchd on macOS, systemd on Linux).
+set -eu
+
+if [ $# -ne 4 ]; then
+  echo "usage: $0 <ssh host> <AuthKey_XXXXXXXXXX.p8> <team id> <bundle id>" >&2
+  exit 2
+fi
+host="$1"; key="$2"; team="$3"; bundle="$4"
+keyid="$(basename "$key" | sed -n 's/^AuthKey_\([A-Z0-9]\{10\}\)\.p8$/\1/p')"
+[ -n "$keyid" ] || { echo "can't read the key id from $(basename "$key") (want AuthKey_XXXXXXXXXX.p8)" >&2; exit 1; }
+here="$(cd "$(dirname "$0")/.." && pwd)"
+
+echo "→ key and config"
+ssh "$host" 'd=$HOME/.config/herdr-ios; mkdir -p "$d/devices" && chmod 700 "$d" && umask 077 && cat > "$d/AuthKey.p8" && chmod 600 "$d/AuthKey.p8"' < "$key"
+printf '{\n  "bundle_id": "%s",\n  "key_id": "%s",\n  "key_path": "~/.config/herdr-ios/AuthKey.p8",\n  "team_id": "%s"\n}\n' "$bundle" "$keyid" "$team" \
+  | ssh "$host" 'umask 077; cat > "$HOME/.config/herdr-ios/apns.json"'
+
+echo "→ script"
+ssh "$host" 'cat > "$HOME/.config/herdr-ios/herdr-notify.py" && chmod 755 "$HOME/.config/herdr-ios/herdr-notify.py"' < "$here/App/Resources/Notify/herdr-notify.py"
+
+echo "→ service"
+ssh "$host" sh -s < "$here/App/Resources/Notify/install-service.sh"
+sleep 2
+ssh "$host" "pgrep -f herdr-notify.py >/dev/null && tail -n 3 \"\$HOME/.config/herdr-ios/notify.log\" 2>/dev/null; true"
+echo "done. Open Herdr on the phone (connected) and allow notifications; then Settings → Notifications → Send a test."
+name: Herdr
+options:
+  bundleIdPrefix: dev.herdr
+  deploymentTarget:
+    iOS: "26.0"
+  createIntermediateGroups: true
+settings:
+  base:
+    CODE_SIGN_STYLE: Automatic
+    SWIFT_VERSION: "5.0"
+    MARKETING_VERSION: "0.1.0"
+    CURRENT_PROJECT_VERSION: "1"
+packages:
+  HerdrKit:
+    path: Packages/HerdrKit
+  Citadel:
+    url: https://github.com/orlandos-nl/Citadel
+    exactVersion: 0.12.1
+  SwiftTerm:
+    url: https://github.com/migueldeicaza/SwiftTerm
+    exactVersion: 1.20.0
+targets:
+  Herdr:
+    type: application
+    platform: iOS
+    configFiles:
+      Debug: Config/Base.xcconfig
+      Release: Config/Base.xcconfig
+    sources:
+      - path: App/Sources
+      - path: App/Resources
+        buildPhase: resources
+        excludes: ["Mods/**", "Mods"]
+      - path: App/Resources/Mods
+        type: folder
+        buildPhase: resources
+    dependencies:
+      - package: HerdrKit
+      - package: Citadel
+      - package: SwiftTerm
+    entitlements:
+      path: App/Herdr.entitlements
+      properties:
+        aps-environment: development
+        com.apple.developer.usernotifications.time-sensitive: true
+    info:
+      path: App/Info.plist
+      properties:
+        CFBundleDisplayName: Herdr
+        UILaunchScreen: {}
+        UIApplicationSceneManifest:
+          UIApplicationSupportsMultipleScenes: true
+        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]
+        UISupportedInterfaceOrientations~ipad: [UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]
+        NSLocalNetworkUsageDescription: "Herdr connects to your machines over SSH on your network."
+        UIAppFonts: [Geist-Regular.ttf, Geist-Medium.ttf, Geist-SemiBold.ttf, Geist-Bold.ttf, Geist-Italic.ttf, Geist-SemiBoldItalic.ttf, JetBrainsMono-Variable.ttf, JetBrainsMono-Italic-Variable.ttf, SymbolsNerdFont-Regular.ttf]
+        ITSAppUsesNonExemptEncryption: false
+    preBuildScripts:
+      - name: Bundle mods
+        script: "\"${SRCROOT}/scripts/bundle-mods.sh\" || echo 'warning: mod bundling failed; using last bundled copies'"
+        basedOnDependencyAnalysis: false
+    settings:
+      base:
+        PRODUCT_BUNDLE_IDENTIFIER: $(HERDR_BUNDLE_ID)
+        TARGETED_DEVICE_FAMILY: "1,2"
+        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
+        ENABLE_USER_SCRIPT_SANDBOXING: NO
+  HerdrUITests:
+    type: bundle.ui-testing
+    platform: iOS
+    configFiles:
+      Debug: Config/Base.xcconfig
+      Release: Config/Base.xcconfig
+    sources: [UITests]
+    dependencies:
+      - target: Herdr
+    settings:
+      base:
+        PRODUCT_BUNDLE_IDENTIFIER: $(HERDR_BUNDLE_ID).uitests
+        TEST_TARGET_NAME: Herdr
+        GENERATE_INFOPLIST_FILE: YES
+schemes:
+  Herdr:
+    build:
+      targets:
+        Herdr: all
+        HerdrUITests: [test]
+    test:
+      targets: [HerdrUITests]
+# 場面ごとの言い方
+
+user が実際に直した表現から作った、場面ごとの書き方。返答でも文書でも、該当する場面ではこの書き方で書く。
+1 行に 1 件。出典は `transcript:<セッション ID の先頭 8 文字>#L<行>`。
+`dotfiles/claude/style-digest.sh` が会話の記録から追記する。未 commit の行は user がまだ確かめていない。
+
+- 【報告の文】動作は定着した漢語で書く（「測って確かめた」ではなく「計測した」）。動詞を開くと AI の文章らしく読まれる。〔transcript:37759ab8#L3516〕
+- 【報告の文】文頭に主語を置く（「同じ Wasm で」「1 本で」から書き出さない）。主語が後ろにあると、何の話かが文末まで分からない。〔transcript:37759ab8#L3516〕
+- 【報告の見出し】何を変えて何を計測したかを見出しに書く（例:「LLM の圧縮・復元を Wasm に変更し、機種間の一致を計測」）。差分が見出しだけで分かる。〔transcript:37759ab8#L3530〕
+- 【技術用語】ソースを Wasm にする操作は「コンパイル」と書く（「Wasm にビルド」ではなく）。用語はその操作を正確に指す語を使う。〔transcript:37759ab8#L3976〕
+- 【予定・必要】やり直しが要ることは「再度計測が必要である」と書く（「取り直します」ではなく）。口語の予定ではなく、書き言葉で必要性を書く。〔transcript:37759ab8#L4002〕
+- 【並べ方】同じ種類のものだけを並べる（「Mac の Safari と iPhone の Safari」。「iPhone と Safari」のように端末とブラウザを同列にしない）。〔transcript:37759ab8#L4030〕
+- 【数値の主語】時間や速さは、何にかかるかを書く（「スマホでの速さ」ではなく「スマホで契約書 1 本を復元するのにかかる時間」）。〔transcript:37759ab8#L4058〕
+- 【語の意味】満たす必要がある数値は「制約」「条件」と書く（「目標」とは書かない）。目標は届かなくてもよい値に使う。〔transcript:37759ab8#L4058〕
+- 【つなぎの語】独立した作業は、関係を示す語でつながずに並べる（「並行して」を使わない）。「並行して」は、マルチスレッド化を複数の文書をまとめて処理することと読み違えさせる。〔transcript:37759ab8#L4086〕
+- 【文末】「である」調の文書では、過去の状態も「であった」と書く（「だった」ではなく）。文体をそろえる。〔transcript:f8e2de53#L139〕
+- 【報告の用語】研究者・オフィスワーカーが読む文書は、分野で定着した用語をそのまま使う（「各 CPU 向けにビルドした版」ではなく「ネイティブビルド」、「計算を複数のスレッドに分ける版」ではなく「マルチスレッド版」）。和語に開くと平易になりすぎ、読み手には硬さが足りなく感じられる。〔transcript:37759ab8#L3601〕
+- 【報告の構成】短い文に情報を載せ、構成は単純にする（課題、実施、結果、次の作業の順）。和語に開いて説明を広げるより、用語 1 語で済ませたほうが 1 文あたりの情報量が高い。〔transcript:37759ab8#L3686〕
+- 【数の単位】同じ対象を数える単位は 1 つに統一し、LLM が数える対象は「トークン」と書く（「2,033 語」と「2,033 位置」を混在させない、「2,125 語」ではなく「2,125 トークン」）。単位が揺れると、同じ数を指しているのか読み手に判別できない。〔transcript:37759ab8#L4147〕
+- 【段落内の文体】同じ段落では「である」調にそろえる（「再度計測が必要。Android は未計測。」の後に「見ていません。」と続けない）。です・ます調と体言止めが混ざると、文の調子が崩れる。〔transcript:37759ab8#L4147〕
+- 【作業の列挙】次にやる作業を複数挙げるときは、「次の作業は 3 つです。」の後に文を並べず、箇条書きにする。並列の項目は、箇条書きのほうが 1 件ずつ区別して読める。〔transcript:37759ab8#L4147〕
+- 【文書の用語】同じ概念は 1 つの語に統一し、省略した語は初出で補う（冒頭に用語表を置き、「一致」「確率」「分布」のように表現が揺れる語を使い分けない）。省略や言い換えが混ざると、読み手が同じものを指すのか判別できず、分かりにくくなる。〔transcript:2c8f2786#L400〕
+- 【進捗報告の箇条書き】各行は体言で止める（「〜しました」ではなく）。終わったことは「済み」を付けて示す。「進捗」の見出しの下に置く項目は終わったことと読めるため、文末で完了を繰り返す必要がない。〔transcript:0994b5e3#L2165〕
+- 【メールへの応答の報告】メールに応じたことは「返信済み」と書く（「回答済み」ではなく）。手段が分かる語のほうが、何をしたかが正確に伝わる。〔transcript:0994b5e3#L2193〕
+- 【進捗報告の項目名】項目名は対象の媒体や種類が分かる語で書く（「登録シート」ではなく「スプレッドシート変更」、「問い合わせ」ではなく「メール問い合わせ」）。同じ週の報告に別種の作業が並ぶため、媒体が分かれば項目名だけで区別できる。〔transcript:0994b5e3#L2256〕
+- 【進捗報告の構成】抽象的な項目名の下に具体を置く階層で書く。読み手は項目名だけで全体をつかめ、必要な項目だけ具体を読める。〔transcript:0994b5e3#L1115〕
+- 【シート変更の依頼】列は記号（O、AL など）ではなくシートの列名で指す（「O（Activity-B）」ではなく列名そのまま）。依頼を受ける側は列名で探すため、記号に置き換えると手間が増える。〔transcript:0994b5e3#L1348〕
+- 【返答の言語】user への報告・説明は、途中経過も含めて日本語で書く（英語の文を混ぜず、「Comparison is done.」のような英文で報告しない）。英語で書くと、読み手が内容を確かめる前に言語を変換する手間が生じる。〔transcript:69ba1421#L2524〕
+- 【依頼文の項目】複数の対象に同じ変更を頼むときは、各項目を書き出す（「宮西さんと同じ変更です」と参照しない）。受け手は項目を 1 つずつ作業するため、別の項目に戻って読む手間が生じる。〔transcript:9b9713a4#L2025〕
+- 【再度の依頼】以前の依頼に触れず、現時点との差分だけを示す（「まだ対応できていません」と書かない）。過去の分を挙げると催促や指摘に読まれる。〔transcript:9b9713a4#L1928〕
+- 【確認の依頼】確認を頼むときは、どのファイルのどの箇所を見て何を決めるかを 1 件ずつ書く（「23 枚の下書きの採否を教えてください」とだけ書かない）。ファイルを 1 枚ずつ開いて探す作業を、依頼する側で済ませておくと、読み手の負担が減る。〔transcript:b9a5a6de#L4377〕
+- 【確認依頼の投稿】自分の見立てを先に書き、そのとおり返信してよいかを聞く形にする（「可否をご確認ください」と相手に判断を丸ごと預けない）。相手は見立てに同意するかどうかだけを答えればよい。〔transcript:6c89b59a#L686〕
+- 【複数の相手への確認】相手ごとに問いを分け、各問いの末尾に「→ 宛先」を付けて誰への問いかを示す（問いをまとめて宛名だけ冒頭に並べない）。宛先を問いごとに見て、自分に向けた問いだけを読める。〔transcript:6c89b59a#L807〕
+- 【未回答の問いの再掲】回答待ちの問いは、記号や番号の範囲（「B〜D」「8〜10 番」）だけで指さず、問いの中身を 1 件ずつ書く。記号だけでは、読み手がどの問いか判別できず、前の発言を遡って探す手間が生じる。〔transcript:51c7e2cb#L698〕
+- 【スライドの結論の行】出典と根拠のある事実だけを書き、評価語を足さない（「本物らしい書類が安く作れるようになった」の「安く」を書かない）。出典にない評価語は AI の文章らしく読まれる。〔transcript:37759ab8#L19888〕
+- 【見出し・カードの語句】何が何をするのかを省かず、対象まで書く（「本物のまま渡せる」「撮影した端末が署名」ではなく、確かめる内容や署名の対象を書く）。対象が省かれると、読み手が意味を決められない。〔transcript:37759ab8#L20059〕
+- 【専門外の聞き手への資料】モデルの大きさ（270M・1B）や CPU の名称（x86）は出さず、身近な比較対象（zip）に置き換える。専門外の聞き手には、数字や名称だけでは何がすごいのか伝わらない。〔transcript:37759ab8#L20089〕
+- 【スライドの本文】見出しは主張の文にし、本文は文章の箇条書きではなく図・カード・大きな数字で示す（べた書きの箇条書きにしない）。単語を拾うだけでそのページの内容が分かるようにするためである。〔transcript:37759ab8#L11820〕
+- 【数字の見せ方】数字は段階で現れるだけにし、0 から数え上げる演出は付けない（「0 → 47.1%」と変化させない）。演出が強いと、内容より動きが目立つ。〔transcript:37759ab8#L20700〕
+- 【アルゴリズムの説明スライド】例は記号や仮の値ではなく、実際の文字列と値で示す。実際の文字列のほうが、何が起きているかを読み手が追える。〔transcript:37759ab8#L13152〕
+- 【カードの文言】口語の言い切りや略した語（「払う店に得が少ない」「サーバ保管で足りる」）を避け、対象を正式な語で書く（「導入する店舗の利益が不明」「サーバ上でのデータ管理の方が利点が多い」）。口語の短縮は AI の文章らしく読まれる。〔transcript:37759ab8#L22085〕
+- 【成果物の呼び方】実行ファイルは「共通の Wasm バイナリ」と書く（「同じ Wasm 1 本」と数えない）。「1 本」は何を数えているのか分からない。〔transcript:37759ab8#L12104〕
+- 【投稿・報告の確認範囲の記載】確認した範囲が一部にとどまる事実は、否定の形で書かない（「10/25・26 の通知にお名前はありません」と書かない）。読み手に、それ以前の通知を疑わせる。〔transcript:068c3505#L2904〕
+- 【略語・専門用語の初出】略語は初出で正式名称を添え、CPU・GPU のどちらの話か、どの層（命令・演算器・言語・API など）の語かを付ける（「ARM の SDOT・i8mm、x86 の AVX-VNNI」とだけ書かない）。読み手がハードウェアとソフトウェアの語に詳しくない場合、語の種類が分からないと文が追えない。〔transcript:8a64ed0c#L4371〕
+- 【段階分けの呼び方】段階を表す語は、その段階が何を表すかのイメージを先に決め、それを伝える語を選ぶ（積み上がっていくものと捉えるなら「レイヤー」、どれだけ大事かの尺度と捉えるなら「重要度」）。番号付きの「層」（「1 層」「層2」）は、何の尺度か、数が大きいほどどうなるのかが読み手に伝わらない。〔transcript:7fa1b5bb#L5904〕
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+web search: 
+exec
+/bin/zsh -lc "nl -ba App/Resources/Notify/install-service.sh; rg -n '8 MiB|8 MB|8388608|8 \\* 1024|stdout|PATH|textconv' docs/2026-11-01_herdr-ios-code-review.md docs/HANDOVER.md; git --version; command -v uv" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+exec
+/bin/zsh -lc "sed -n '215,235p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; rg -n 'func exec|folder:|folder =' App/Sources/Store/AppStore.swift App/Sources/UI/NewSpaceSheet.swift App/Resources/Notify/herdr-notify.py; sed -n '165,240p' App/Sources/Notify/NotificationSettings.swift; sed -n '1,160p' App/Resources/Notify/herdr-notify.py" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+     1	#!/bin/sh
+     2	# Runs herdr-notify as a service on the box: a launchd agent on macOS, a systemd
+     3	# user service on Linux, nohup where neither is available. Used by the app's
+     4	# Settings → Notifications and by scripts/install-notifier.sh.
+     5	set -eu
+     6	d="$HOME/.config/herdr-ios"
+     7	script="$d/herdr-notify.py"
+     8	py="$(command -v python3)"
+     9	
+    10	if [ "$(uname)" = Darwin ]; then
+    11	  label=dev.herdr.notify
+    12	  plist="$HOME/Library/LaunchAgents/$label.plist"
+    13	  mkdir -p "$HOME/Library/LaunchAgents"
+    14	  # launchd starts jobs with PATH=/usr/bin:/bin:/usr/sbin:/sbin; keep the PATH that found hc and python3 here.
+    15	  cat > "$plist" <<EOF
+    16	<?xml version="1.0" encoding="UTF-8"?>
+    17	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
+    18	<plist version="1.0">
+    19	<dict>
+    20	  <key>Label</key><string>$label</string>
+    21	  <key>ProgramArguments</key><array><string>$py</string><string>$script</string></array>
+    22	  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$PATH</string></dict>
+    23	  <key>RunAtLoad</key><true/>
+    24	  <key>KeepAlive</key><true/>
+    25	  <key>ThrottleInterval</key><integer>10</integer>
+    26	  <key>StandardOutPath</key><string>$d/notify.log</string>
+    27	  <key>StandardErrorPath</key><string>$d/notify.log</string>
+    28	</dict>
+    29	</plist>
+    30	EOF
+    31	  pkill -f "$script" 2>/dev/null || true
+    32	  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
+    33	  launchctl bootstrap "gui/$(id -u)" "$plist"
+    34	elif systemctl --user show-environment >/dev/null 2>&1; then
+    35	  mkdir -p "$HOME/.config/systemd/user"
+    36	  cat > "$HOME/.config/systemd/user/herdr-notify.service" <<EOF
+    37	[Unit]
+    38	Description=Herdr for iOS push notifications
+    39	After=network-online.target
+    40	
+    41	[Service]
+    42	ExecStart=$py %h/.config/herdr-ios/herdr-notify.py
+    43	Restart=always
+    44	RestartSec=5
+    45	
+    46	[Install]
+    47	WantedBy=default.target
+    48	EOF
+    49	  systemctl --user daemon-reload
+    50	  systemctl --user enable herdr-notify >/dev/null 2>&1 || true
+    51	  systemctl --user restart herdr-notify
+    52	else
+    53	  pkill -f "$script" 2>/dev/null || true
+    54	  nohup "$py" "$script" >"$d/notify.log" 2>&1 &
+    55	fi
+docs/HANDOVER.md:52:  a space's toolbar. Lists and reads with python3 on the box; reads are capped at 8 MiB on the box
+docs/HANDOVER.md:95:export TEST_RUNNER_HERDR_DEBUG_KEY_PATH=$PWD/docs/private/sim_key
+docs/HANDOVER.md:105:TEST_RUNNER_HERDR_TEST_SPACE=herdr-pocket TEST_RUNNER_HERDR_TEST_FILES_PATH=build/preview-fixtures \
+docs/HANDOVER.md:128:- Files: chunked reads above 8 MiB; HTML/SVG scaled to the screen (WKWebView) if that matters.
+git version 2.54.0
+/etc/profiles/per-user/yosuke/bin/uv
+
+ succeeded in 0ms:
+
+    // MARK: Typed helpers
+
+    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
+    /// exit or timeout is a result, not an error.
+    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
+        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
+        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
+        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
+        if let input { p["input"] = .string(input.base64EncodedString()) }
+        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+        return ExecResult(code: r["code"].int,
+                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
+                          timedOut: r["timed_out"].bool ?? false)
+    }
+
+    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
+        let r = try await call("doc.get", ["name": .string(name)])
+        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
+    }
+rg: App/Sources/UI/NewSpaceSheet.swift: No such file or directory (os error 2)
+App/Sources/Store/AppStore.swift:343:        try await newTab(inSpace: spaceID, argv: argv, task: task, name: name, folder: nil)
+App/Sources/Store/AppStore.swift:347:    func newTab(inSpace spaceID: String, argv: [String]?, task: String?, name: String?, folder: String?) async throws -> String {
+App/Sources/Store/AppStore.swift:352:        let folder = folder?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
+App/Sources/Store/AppStore.swift:364:    func newSpace(folder: String, argv: [String]?, task: String?) async throws -> String {
+App/Sources/Store/AppStore.swift:365:        try await newSpace(folder: folder, argv: argv, task: task, name: nil, tabName: nil)
+App/Sources/Store/AppStore.swift:369:    func newSpace(folder: String, argv: [String]?, task: String?, name: String?, tabName: String?) async throws -> String {
+App/Sources/Store/AppStore.swift:372:        let folder = folder.trimmingCharacters(in: .whitespacesAndNewlines)
+App/Sources/Store/AppStore.swift:376:            HerdrKit.Layout.addSpace(v, id: spaceID, name: name ?? "", folder: folder == self.home ? "" : folder,
+App/Sources/Store/AppStore.swift:428:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
+            }
+        }
+    }
+
+    private var canInstall: Bool {
+        step == nil && keyPEM != nil && keyID.count == 10 && teamID.count == 10 && store.phase == .connected
+    }
+
+    private func install() {
+        guard let keyPEM, let script = Bundle.main.url(forResource: "herdr-notify", withExtension: "py").flatMap({ try? Data(contentsOf: $0) }),
+              let service = Bundle.main.url(forResource: "install-service", withExtension: "sh").flatMap({ try? Data(contentsOf: $0) }) else {
+            error = "The notifier script is missing from the app."; return
+        }
+        error = nil
+        let apns: [String: Any] = ["key_id": keyID, "team_id": teamID, "bundle_id": Bundle.main.bundleIdentifier ?? "",
+                                   "key_path": "~/.config/herdr-ios/AuthKey.p8"]
+        Task {
+            do {
+                step = "Key"
+                try await put("AuthKey.p8", Data(keyPEM.utf8), mode: "600")
+                step = "Config"
+                try await put("apns.json", try JSONSerialization.data(withJSONObject: apns, options: [.prettyPrinted, .sortedKeys]), mode: "600")
+                step = "Script"
+                try await put("herdr-notify.py", script, mode: "755")
+                step = "Service"
+                try await sh(#"sh -s"#, input: service)
+                step = "Test"
+                await Push.shared.upload(to: store, force: true)
+                try await sh(#"python3 "$HOME/.config/herdr-ios/herdr-notify.py" --test"#)
+                step = nil
+                store.toast("Notifications are on", body: "A test notification is on its way.", level: "success")
+                dismiss()
+            } catch {
+                self.error = "\(step ?? "Install") failed: \(error.localizedDescription)"
+                step = nil
+            }
+        }
+    }
+
+    private func put(_ name: String, _ data: Data, mode: String) async throws {
+        try await sh(#"d="$HOME/.config/herdr-ios"; mkdir -p "$d" && chmod 700 "$d" && cat > "$d/$1" && chmod "$2" "$d/$1""#, args: [name, mode], input: data)
+    }
+
+    private func sh(_ script: String, args: [String] = [], input: Data? = nil) async throws {
+        let r = try await store.exec(argv: ["sh", "-c", script, "sh"] + args, cwd: nil, on: nil, timeout: 30, input: input)
+        guard r.code == 0 else {
+            let msg = String(decoding: r.stderr + r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+            throw HerdrError(message: msg.isEmpty ? "exit \(r.code.map(String.init) ?? "signal")" : String(msg.suffix(300)))
+        }
+    }
+}
+#!/usr/bin/env python3
+"""herdr-notify: push notifications for Herdr for iOS, sent from your box.
+
+Follows `hc events` and sends an Apple push to every registered phone when an
+agent starts needing you (blocked) or finishes a turn. It talks to Apple
+directly over HTTP/2 (curl); nothing goes through a third-party relay.
+
+Files (all under ~/.config/herdr-ios):
+  apns.json      {"key_id", "team_id", "bundle_id", "key_path"}  (the app writes it)
+  AuthKey.p8     your APNs auth key (chmod 600)
+  devices/*.json {"token", "env": "sandbox"|"production", "name"}  (one per phone)
+  notify.json    optional: {"on": ["blocked", "done"], "subagents": false}
+
+Usage: herdr-notify.py            run (systemd user service herdr-notify)
+       herdr-notify.py --test     send a test notification to every phone
+"""
+import base64, glob, json, os, re, subprocess, sys, time
+
+HOME = os.path.expanduser("~")
+DIR = os.path.join(HOME, ".config", "herdr-ios")
+HC = next((p for p in [os.path.join(HOME, ".local/bin/hc"), "/usr/local/bin/hc", "/usr/bin/hc"] if os.path.exists(p)), "hc")
+BUSY = {"working", "blocked"}
+
+
+def log(*a):
+    print(time.strftime("%H:%M:%S"), *a, flush=True)
+
+
+def load(path, default):
+    try:
+        with open(path) as f:
+            return json.load(f)
+    except Exception:
+        return default
+
+
+# ---------------------------------------------------------------- APNs
+
+def b64url(b):
+    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()
+
+
+def der_to_raw(sig):
+    """ECDSA DER signature -> raw r||s (64 bytes) as JWT ES256 wants."""
+    i = 2 + (1 if sig[1] & 0x80 else 0)  # skip SEQUENCE header
+    rl = sig[i + 1]; r = sig[i + 2:i + 2 + rl]; i += 2 + rl
+    sl = sig[i + 1]; s = sig[i + 2:i + 2 + sl]
+    return r.lstrip(b"\0").rjust(32, b"\0") + s.lstrip(b"\0").rjust(32, b"\0")
+
+
+class APNs:
+    def __init__(self):
+        self.cfg = load(os.path.join(DIR, "apns.json"), None)
+        self.jwt, self.jwt_at = None, 0
+
+    def ready(self):
+        return bool(self.cfg and all(self.cfg.get(k) for k in ("key_id", "team_id", "bundle_id")))
+
+    def token(self):
+        if self.jwt and time.time() - self.jwt_at < 50 * 60:
+            return self.jwt
+        key_path = os.path.expanduser(self.cfg.get("key_path") or os.path.join(DIR, "AuthKey.p8"))
+        head = b64url(json.dumps({"alg": "ES256", "kid": self.cfg["key_id"]}).encode())
+        body = b64url(json.dumps({"iss": self.cfg["team_id"], "iat": int(time.time())}).encode())
+        msg = f"{head}.{body}".encode()
+        try:
+            from cryptography.hazmat.primitives import hashes, serialization
+            from cryptography.hazmat.primitives.asymmetric import ec
+            with open(key_path, "rb") as f:
+                key = serialization.load_pem_private_key(f.read(), password=None)
+            der = key.sign(msg, ec.ECDSA(hashes.SHA256()))
+        except ImportError:
+            der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path], input=msg,
+                                 capture_output=True, check=True).stdout
+        self.jwt, self.jwt_at = f"{head}.{body}.{b64url(der_to_raw(der))}", time.time()
+        return self.jwt
+
+    def send(self, payload, collapse=None, thread=None):
+        devices = [load(p, {}) for p in sorted(glob.glob(os.path.join(DIR, "devices", "*.json")))]
+        devices = [d for d in devices if d.get("token")]
+        if not devices:
+            log("no phones registered yet (open Herdr on the phone while connected)")
+            return
+        for d in devices:
+            host = "api.sandbox.push.apple.com" if d.get("env") != "production" else "api.push.apple.com"
+            cmd = ["curl", "-sS", "--http2", "-o", "-", "-w", "\n%{http_code}", "--max-time", "15",
+                   "-H", f"authorization: bearer {self.token()}",
+                   "-H", f"apns-topic: {self.cfg['bundle_id']}",
+                   "-H", "apns-push-type: alert",
+                   "-H", f"apns-priority: 10",
+                   "--data-binary", "@-", f"https://{host}/3/device/{d['token']}"]
+            if collapse:
+                cmd[1:1] = ["-H", f"apns-collapse-id: {collapse[:64]}"]
+            r = subprocess.run(cmd, input=json.dumps(payload).encode(), capture_output=True)
+            out = r.stdout.decode(errors="replace").strip().rsplit("\n", 1)
+            code = out[-1] if out else "?"
+            if code != "200":
+                log(f"push to {d.get('name') or d['token'][:8]} failed: {code} {out[0] if len(out) > 1 else r.stderr.decode()[:200]}")
+
+
+# ---------------------------------------------------------------- herdr
+
+def label(rec):
+    """("Tab name", "space") from herdr's `where` label, else the title."""
+    where = (rec.get("labels") or {}).get("where") or ""
+    if " / " in where:
+        space, tab = where.split(" / ", 1)
+        if not tab.isdigit():
+            return tab, space
+        return (rec.get("title") or tab), space
+    return (rec.get("title") or rec.get("address") or "Agent"), None
+
+
+def dialog(address):
+    """The question and options an agent's screen shows while it waits."""
+    try:
+        screen = subprocess.run([HC, "read", address, "--lines", "0"], capture_output=True, timeout=8).stdout.decode(errors="replace")
+    except Exception:
+        return None
+    lines = [l.strip().strip("│┃|").strip() for l in screen.splitlines()]
+    opts, first = [], -1
+    for i in range(len(lines) - 1, -1, -1):
+        m = re.match(r"^(?:[❯›>]\s*)?(\d)[.)]\s+(.+)$", lines[i])
+        if m:
+            opts.insert(0, m.group(2)); first = i
+        elif opts and lines[i]:
+            break
+    if not opts:
+        return None
+    q = []
+    i = first - 1
+    while i >= 0 and len(q) < 3:
+        l = lines[i]
+        if not l or set(l) <= set("─━═-╭╮╰╯"):
+            if q:
+                break
+        else:
+            q.insert(0, l)
+        i -= 1
+    return " ".join(q), opts
+
+
+class Watcher:
+    def __init__(self, apns, cfg):
+        self.apns, self.cfg = apns, cfg
+        self.recs = {}
+
+    def snapshot(self, terminals):
+        self.recs = {t["address"]: t for t in terminals if t.get("address")}
+
+    def word(self, rec):
+        return ((rec or {}).get("status") or {}).get("state")
+
+    def apply(self, ev):
+        addr, typ, data = ev.get("terminal"), ev.get("type"), ev.get("data") or {}
+        if typ in ("created", "restarted") and isinstance(data, dict) and data.get("address"):
+            self.recs[data["address"]] = data
+            return
+        rec = self.recs.get(addr)
+        if typ == "removed":
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+web search: site.git-scm.com/docs/git-diff --no-ext-diff textconv default pathspec relative ...
+hook: PostToolUse
+hook: PostToolUse Completed
+codex
+8 MiB の本文にヘッダーを加えているため、stdout 上限で切り詰められたデータを正常な読了として扱う経路があります。git のパス基準と rename の扱い、WebView の外部通信、サービス定義のエスケープを引き続き確認します。
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+web search: 
+hook: PreToolUse Completed
+hook: PostToolUse
+hook: PostToolUse
+exec
+/bin/zsh -lc "git -C App status --porcelain=v1 -z --untracked-files=all; git -C App ls-files -- Sources/UI/FilesView.swift; git -C App ls-files -- App/Sources/UI/FilesView.swift; nl -ba App/Sources/UI/ChangesView.swift | sed -n '45,135p'; sed -n '420,442p' App/Sources/Store/AppStore.swift; rg -n 'home =|var home|\"home\"|folder.*~' App/Sources/Store/AppStore.swift App/Sources/UI Packages/HerdrKit/Sources" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+?? docs/reviews/2026-11-01-files-changes-notifier-codex.md Sources/UI/FilesView.swift
+    45	            .refreshable { await load() }
+    46	        }
+    47	    }
+    48	
+    49	    private func load() async {
+    50	        do {
+    51	            let r = try await store.exec(argv: ["git", "-C", folder.isEmpty ? "." : folder, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
+    52	                                         cwd: nil, on: nil, timeout: 20, input: nil)
+    53	            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(folder)"); return }
+    54	            changes = Self.parse(r.stdout)
+    55	            error = nil
+    56	        } catch {
+    57	            self.error = DiffView.message(error)
+    58	        }
+    59	    }
+    60	
+    61	    /// `git status --porcelain=v1 -z`: "XY path\0", and a rename or copy adds its source as the next "\0" field.
+    62	    static func parse(_ out: Data) -> [Change] {
+    63	        let fields = out.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
+    64	        var result: [Change] = [], i = 0
+    65	        while i < fields.count {
+    66	            let f = fields[i]; i += 1
+    67	            guard f.count > 3 else { continue }
+    68	            let code = String(f.prefix(2))
+    69	            result.append(Change(code: code, path: String(f.dropFirst(3))))
+    70	            if code.contains("R") || code.contains("C") { i += 1 }
+    71	        }
+    72	        return result
+    73	    }
+    74	}
+    75	
+    76	/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
+    77	struct DiffView: View {
+    78	    @Environment(AppStore.self) private var store
+    79	    var folder: String
+    80	    var change: ChangesSheet.Change
+    81	
+    82	    @State private var lines: [Substring]?
+    83	    @State private var error: String?
+    84	
+    85	    /// More lines than this are cut off; a phone can't usefully scroll a larger diff.
+    86	    static let maxLines = 5000
+    87	
+    88	    var body: some View {
+    89	        ScrollView([.vertical, .horizontal]) {
+    90	            if let error {
+    91	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked).padding(16)
+    92	            } else if let lines {
+    93	                LazyVStack(alignment: .leading, spacing: 0) {
+    94	                    ForEach(Array(lines.prefix(Self.maxLines).enumerated()), id: \.offset) { _, l in
+    95	                        Text(l.isEmpty ? " " : String(l)).font(HF.mono(12)).foregroundStyle(Self.color(l))
+    96	                            .padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
+    97	                            .background(Self.background(l))
+    98	                    }
+    99	                    if lines.count > Self.maxLines {
+   100	                        Text("\(lines.count - Self.maxLines) more lines not shown.").font(HF.ui(13)).foregroundStyle(HC.dim).padding(10)
+   101	                    }
+   102	                }
+   103	                .textSelection(.enabled)
+   104	                .accessibilityIdentifier("diffLines")
+   105	            } else {
+   106	                ProgressView().padding(40)
+   107	            }
+   108	        }
+   109	        .background(HC.canvas)
+   110	        .navigationTitle((change.path as NSString).lastPathComponent)
+   111	        .navigationBarTitleDisplayMode(.inline)
+   112	        .task { await load() }
+   113	    }
+   114	
+   115	    private func load() async {
+   116	        let dir = folder.isEmpty ? "." : folder
+   117	        // --no-index exits 1 when the files differ, which for an untracked file is always.
+   118	        let argv = change.untracked
+   119	            ? ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", change.path]
+   120	            : ["git", "-C", dir, "--no-pager", "diff", "--no-color", "--no-ext-diff", "HEAD", "--", change.path]
+   121	        do {
+   122	            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
+   123	            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
+   124	            let text = String(decoding: r.stdout, as: UTF8.self)
+   125	            lines = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
+   126	        } catch {
+   127	            self.error = Self.message(error)
+   128	        }
+   129	    }
+   130	
+   131	    static func color(_ l: Substring) -> Color {
+   132	        if l.hasPrefix("@@") { return HC.working }
+   133	        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") { return HC.dim }
+   134	        if l.hasPrefix("+") { return HC.done }
+   135	        if l.hasPrefix("-") { return HC.blocked }
+    func interrupt(_ address: String) async throws {
+        _ = try await connectedClient().call("terminal.interrupt", ["terminal": .string(address), "timeout": 10], timeout: 20)
+    }
+    func kill(_ address: String) async throws {
+        _ = try await connectedClient().call("terminal.kill", ["terminal": .string(address)], timeout: 20)
+    }
+
+    // MARK: For mods
+    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
+        try await connectedClient().exec(argv: argv, cwd: cwd, on: on, timeout: timeout, input: input)
+    }
+    func call(_ method: String, _ params: JSONValue) async throws -> JSONValue {
+        try await connectedClient().call(method, params)
+    }
+    func toast(_ title: String, body: String? = nil, level: String = "info") {
+        toast(title, body: body, level: level, address: nil, duration: nil)
+    }
+    func toast(_ title: String, body: String?, level: String, address: String?, duration: Double?) {
+        toasts.append(Toast(title: title, body: body, level: level, address: address, duration: duration))
+        if toasts.count > 8 { toasts.removeFirst(toasts.count - 8) }
+    }
+
+    /// Pull-to-refresh: re-read the layout and terminal table on a healthy
+App/Sources/Store/AppStore.swift:52:    var home: String = "~"
+App/Sources/Store/AppStore.swift:599:        home = h
+App/Sources/Store/AppStore.swift:838:        if let h = defaults.string(forKey: "home." + id.uuidString) { home = h }
+Packages/HerdrKit/Sources/herdr-probe/main.swift:13:let home = ProcessInfo.processInfo.environment["HERDR_PROBE_HOME"] ?? "~"
+App/Sources/UI/FilesView.swift:292:            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
+App/Sources/UI/SpaceView.swift:95:        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
+App/Sources/UI/SpaceView.swift:96:        .sheet(isPresented: $showChanges) { ChangesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
+App/Sources/UI/DemoData.swift:74:        home = "/home/dev"
+Packages/HerdrKit/Sources/HerdrKit/Names.swift:5:    /// A folder as a name: its last part, `~` for home (or ""), `/` for root.
+Packages/HerdrKit/Sources/HerdrKit/Names.swift:6:    public static func folderName(_ path: String, home: String = "~") -> String {
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+web search: site.webkit.org content blockers block image requests WKWebView ...
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'git -C App diff --no-color --no-ext-diff HEAD''^ HEAD -- App/Sources/UI/FilesView.swift; git -C App diff --no-color --no-ext-diff --stat HEAD''^ HEAD -- Sources/UI/FilesView.swift; git -C '"'~' status --porcelain=v1 -z; sed -n '46,58p' docs/HANDOVER.md; git status --short" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+ App/Sources/UI/FilesView.swift | 128 +++++++++++++++++++++++++++++++++--------
+ 1 file changed, 103 insertions(+), 25 deletions(-)
+fatal: cannot change to '~': No such file or directory
+  127.0.0.1. `HerdrUITests.testFirstConnectAsksForHostKey` passes: fingerprint shown before login,
+  equal to `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`, home with live agents only after
+  approval. This answers the spike's open question for the simulator: Citadel keeps the
+  `herdr-core connect` stdio open. Not yet confirmed on a device.
+- Files (this repo's first feature, 6c7e200 + 95acd13 after Codex's review,
+  `docs/reviews/2026-11-01-files-judgement.md`): `App/Sources/UI/FilesView.swift`, folder button in
+  a space's toolbar. Lists and reads with python3 on the box; reads are capped at 8 MiB on the box
+  (`Frame.maxPayload / 2`), larger files are refused (`shortcut:` in the code; the code-review
+  document's "read in chunks" is not built yet). `testFilesPreviewInQuickLook` opens a PDF, docx,
+  xlsx and png from `build/preview-fixtures/` (gitignored; recreate with textutil, cupsfilter, sips
+  and openpyxl via uvx; the png must be opaque; md, html, json, csv, swift, svg, jpg, gif, heic and
+  pptx were added by hand). All of them open; Markdown opens in Chat's renderer instead of Quick Look,
+  which shows the raw source. HTML without a viewport and SVG show small (desktop scale, intrinsic size).
+?? docs/reviews/2026-11-01-files-changes-notifier-codex.md
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+codex
+1. **High — 8 MiB 以上のファイルが切り詰められたまま表示される** — [FilesView.swift:245](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:245)  
+   8 MiB の本文に size・mtime のヘッダーが加わり、stdout 上限を超える。切り詰め後は `body.count < chunkBytes` が成立するため、259 行で読了と判定し、後続チャンクを取得しない。**修正:** ヘッダー分を含めて上限未満に収め、受信長が `min(chunkBytes, size - offset)` と一致することを検証する。
+
+2. **High — HTML が iPhone から任意の宛先へ通信できる** — [FilesView.swift:274](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:274)  
+   JavaScript の無効化は、画像・CSS・iframe・リダイレクトの通信を禁止しない。悪意ある HTML の `<img src="https://attacker.example/...">` だけで、プレビュー時に外部通信が発生する。**修正:** 読み込み前に content rule list でネットワークリソースを遮断し、navigation delegate でも外部遷移を拒否する。リソース要求の遮断は [WebKit の content blocker](https://webkit.org/blog/3476/content-blockers-first-look/) が対象としている。
+
+3. **Medium — 読み取り中の変更を正常なファイルとして受け入れる** — [FilesView.swift:64](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:64)  
+   `fstat` は読み取り前だけである。最終チャンクの読み取り中に上書きされた場合、混在した内容を検出できない。途中で truncate された場合も、短い本文を259行で正常終了として扱う。**修正:** 読み取り後にも `fstat` して変更を拒否し、Swift 側でも期待した本文長を検証する。
+
+4. **Medium — PATH・ホームディレクトリによって plist が壊れる** — [install-service.sh:21](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Resources/Notify/install-service.sh:21)  
+   `$py`・`$script`・`$PATH`・ログパスを XML に直接埋め込んでいる。たとえば PATH に `/opt/R&D/bin` があると不正な XML になり、既存サービスを停止した後の bootstrap が失敗する。XML 要素の注入も可能である。**修正:** 利用可能な Python の `plistlib` で plist を生成し、検証後に既存サービスを停止する。
+
+5. **Medium — repo のサブディレクトリを開くと diff の対象がずれる** — [ChangesView.swift:120](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:120)  
+   porcelain v1 は repo ルート相対のパスを返すが、diff は `folder` を基準に解釈する。`folder=/repo/App`、結果が `App/file.swift` なら `/repo/App/App/file.swift` を指定し、変更がないと表示する。untracked も同様に失敗する。**修正:** repo ルートを取得し、status と diff の実行基準を統一する。[Git の仕様](https://git-scm.com/docs/git-status/2.17.0.html)でも porcelain のパスはルート相対である。
+
+6. **Medium — folder が `~`・`~/project` の場合に開けない** — [ChangesView.swift:51](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:51)  
+   argv に渡した `~` は shell 展開されないため、`git -C '~'` は失敗する。Files 側の `expanduser` と挙動が異なる。**修正:** box 上でホームを展開して絶対パスに解決し、status と diff の両方に使う。
+
+7. **Medium — rename の元パスを捨てるため、正しい rename diff を表示できない** — [ChangesView.swift:70](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:70)  
+   `git mv old.txt new.txt` の元パスを破棄し、`new.txt` だけで diff する。元ファイルの削除が対象から外れ、rename が新規ファイル追加として表示される。**修正:** 元パスも `Change` に保持し、両方を diff の対象にする。
+
+8. **Medium — 初回コミット前の staged ファイルを表示できない** — [ChangesView.swift:120](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:120)  
+   `git init` 後に `git add` したファイルは status に出るが、`HEAD` が存在しないため diff が失敗する。**修正:** unborn HEAD を判定し、この場合は `git diff --cached` で初回コミット予定の内容を表示する。
+
+9. **Medium — 大きな status・diff の切り詰めを表示しない** — [ChangesView.swift:124](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:124)  
+   stdout 上限を超える diff を完全な結果として表示する。status も途中のレコードをファイル名として採用し、残りの変更を欠落させる。5,000 行制限は受信後なので、この問題を防げない。**修正:** box 側で上限と切り詰めを検出し、status は不完全な結果を拒否、diff は省略を明示する。
+
+10. **Medium — Python のパスに空白があると systemd サービスが起動しない** — [install-service.sh:42](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Resources/Notify/install-service.sh:42)  
+    `command -v python3` が `/home/user/My Tools/bin/python3` を返すと、未引用の `ExecStart` は `/home/user/My` を実行ファイルとして解釈する。**修正:** Python の絶対パスを systemd の構文に従って引用・エスケープする。
+
+11. **Low — ファイル名を Git pathspec として解釈する** — [ChangesView.swift:120](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:120)  
+    `--` はオプション解釈を止めるが、glob は無効化しない。`*.txt` という実在ファイルを選ぶと、他の `.txt` の変更も表示し得る。**修正:** tracked ファイルの diff に `--literal-pathspecs` を指定する。
+
+文書との不整合: `docs/HANDOVER.md:52` と `:128` は、チャンク読み取りと HTML/SVG 表示を未実装として記載している。
+
+未実施: simulator・実機・サービスの起動検証。ファイル変更は行っていない。  
+**判定: 修正が必要。特に 1・2 は出荷前に解消すべきである。**
+hook: Stop
+hook: Stop
+hook: Stop Completed
+hook: Stop Completed
+tokens used
+60,984
+1. **High — 8 MiB 以上のファイルが切り詰められたまま表示される** — [FilesView.swift:245](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:245)  
+   8 MiB の本文に size・mtime のヘッダーが加わり、stdout 上限を超える。切り詰め後は `body.count < chunkBytes` が成立するため、259 行で読了と判定し、後続チャンクを取得しない。**修正:** ヘッダー分を含めて上限未満に収め、受信長が `min(chunkBytes, size - offset)` と一致することを検証する。
+
+2. **High — HTML が iPhone から任意の宛先へ通信できる** — [FilesView.swift:274](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:274)  
+   JavaScript の無効化は、画像・CSS・iframe・リダイレクトの通信を禁止しない。悪意ある HTML の `<img src="https://attacker.example/...">` だけで、プレビュー時に外部通信が発生する。**修正:** 読み込み前に content rule list でネットワークリソースを遮断し、navigation delegate でも外部遷移を拒否する。リソース要求の遮断は [WebKit の content blocker](https://webkit.org/blog/3476/content-blockers-first-look/) が対象としている。
+
+3. **Medium — 読み取り中の変更を正常なファイルとして受け入れる** — [FilesView.swift:64](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:64)  
+   `fstat` は読み取り前だけである。最終チャンクの読み取り中に上書きされた場合、混在した内容を検出できない。途中で truncate された場合も、短い本文を259行で正常終了として扱う。**修正:** 読み取り後にも `fstat` して変更を拒否し、Swift 側でも期待した本文長を検証する。
+
+4. **Medium — PATH・ホームディレクトリによって plist が壊れる** — [install-service.sh:21](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Resources/Notify/install-service.sh:21)  
+   `$py`・`$script`・`$PATH`・ログパスを XML に直接埋め込んでいる。たとえば PATH に `/opt/R&D/bin` があると不正な XML になり、既存サービスを停止した後の bootstrap が失敗する。XML 要素の注入も可能である。**修正:** 利用可能な Python の `plistlib` で plist を生成し、検証後に既存サービスを停止する。
+
+5. **Medium — repo のサブディレクトリを開くと diff の対象がずれる** — [ChangesView.swift:120](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:120)  
+   porcelain v1 は repo ルート相対のパスを返すが、diff は `folder` を基準に解釈する。`folder=/repo/App`、結果が `App/file.swift` なら `/repo/App/App/file.swift` を指定し、変更がないと表示する。untracked も同様に失敗する。**修正:** repo ルートを取得し、status と diff の実行基準を統一する。[Git の仕様](https://git-scm.com/docs/git-status/2.17.0.html)でも porcelain のパスはルート相対である。
+
+6. **Medium — folder が `~`・`~/project` の場合に開けない** — [ChangesView.swift:51](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:51)  
+   argv に渡した `~` は shell 展開されないため、`git -C '~'` は失敗する。Files 側の `expanduser` と挙動が異なる。**修正:** box 上でホームを展開して絶対パスに解決し、status と diff の両方に使う。
+
+7. **Medium — rename の元パスを捨てるため、正しい rename diff を表示できない** — [ChangesView.swift:70](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:70)  
+   `git mv old.txt new.txt` の元パスを破棄し、`new.txt` だけで diff する。元ファイルの削除が対象から外れ、rename が新規ファイル追加として表示される。**修正:** 元パスも `Change` に保持し、両方を diff の対象にする。
+
+8. **Medium — 初回コミット前の staged ファイルを表示できない** — [ChangesView.swift:120](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:120)  
+   `git init` 後に `git add` したファイルは status に出るが、`HEAD` が存在しないため diff が失敗する。**修正:** unborn HEAD を判定し、この場合は `git diff --cached` で初回コミット予定の内容を表示する。
+
+9. **Medium — 大きな status・diff の切り詰めを表示しない** — [ChangesView.swift:124](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:124)  
+   stdout 上限を超える diff を完全な結果として表示する。status も途中のレコードをファイル名として採用し、残りの変更を欠落させる。5,000 行制限は受信後なので、この問題を防げない。**修正:** box 側で上限と切り詰めを検出し、status は不完全な結果を拒否、diff は省略を明示する。
+
+10. **Medium — Python のパスに空白があると systemd サービスが起動しない** — [install-service.sh:42](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Resources/Notify/install-service.sh:42)  
+    `command -v python3` が `/home/user/My Tools/bin/python3` を返すと、未引用の `ExecStart` は `/home/user/My` を実行ファイルとして解釈する。**修正:** Python の絶対パスを systemd の構文に従って引用・エスケープする。
+
+11. **Low — ファイル名を Git pathspec として解釈する** — [ChangesView.swift:120](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:120)  
+    `--` はオプション解釈を止めるが、glob は無効化しない。`*.txt` という実在ファイルを選ぶと、他の `.txt` の変更も表示し得る。**修正:** tracked ファイルの diff に `--literal-pathspecs` を指定する。
+
+文書との不整合: `docs/HANDOVER.md:52` と `:128` は、チャンク読み取りと HTML/SVG 表示を未実装として記載している。
+
+未実施: simulator・実機・サービスの起動検証。ファイル変更は行っていない。  
+**判定: 修正が必要。特に 1・2 は出荷前に解消すべきである。**
diff --git a/docs/reviews/2026-11-01-files-changes-notifier-judgement.ja.md b/docs/reviews/2026-11-01-files-changes-notifier-judgement.ja.md
new file mode 100644
index 0000000..a2abd26
--- /dev/null
+++ b/docs/reviews/2026-11-01-files-changes-notifier-judgement.ja.md
@@ -0,0 +1,28 @@
+# 判定: 通知のサービス、大きなファイル、HTML・SVG、Changes のレビュー（2026-11-01）
+
+対象の commit: 282034e。レビューの原文: `2026-11-01-files-changes-notifier-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。
+
+| # | 指摘 | 判定 | 理由と変更 |
+|---|---|---|---|
+| 1 | サイズと mtime の行が加わると、8 MiB のチャンクが core の stdout の上限（8 MB）を超える。短くなったチャンクをファイルの終わりと判定する | 修正 | 実際の不具合であった。15 MB のテスト用 PNG が帯状にしか表示されなかった。チャンクを 4,000,000 バイトにした。各チャンクの長さが `min(チャンク, サイズ - offset)` と一致し、応答が `truncated` でないことを確かめる（`machine.exec` の `truncated` を `ExecResult` で読むようにした） |
+| 2 | JavaScript を無効にしても、画像・CSS・iframe・リダイレクトによる外部通信は止まらない | 修正 | ページを読み込む前に content rule list で `file:` 以外の読み込みをすべて遮断した。navigation delegate も `file:` 以外への遷移を取り消す。データの保存先は永続しないものにした |
+| 3 | 最後のチャンクを読む間の変更や切り詰めを、正常なファイルとして受け入れる | 修正 | スクリプトが読み終えた後にもう一度 `fstat` し、サイズか mtime が変わっていれば終了コード 4 で終わる。アプリは各チャンクの長さを確かめる（指摘 1） |
+| 4 | PATH やホームに `&`・`<` があると plist が壊れ、動いていた通知プロセスを止めた後に起動に失敗する | 修正 | 値を XML 用にエスケープした。plist を一時ファイルに書き、`plutil -lint` で検証してから置き換え、ジョブを起動し直す |
+| 5 | porcelain のパスは repo のルートからの相対パスだが、diff をスペースのフォルダで実行していた | 修正 | 先に `git rev-parse --show-toplevel` を実行し、status と diff をルートで実行する |
+| 6 | argv では `~` と `~/x` が展開されない | 修正 | git を呼ぶ前に、box のホームで展開する |
+| 7 | rename の元のパスを捨て、新規ファイルとして表示する | 修正 | 元のパスを保持し、`-M` を付けて両方のパスを渡す |
+| 8 | 最初の commit の前に staged したファイルの diff を取れない（HEAD が無い） | 修正 | `rev-parse --verify HEAD` で確かめ、HEAD が無ければ `--cached` で diff を取る |
+| 9 | 8 MB を超える status や diff を、切り詰めたことを示さずに表示する | 修正 | 切り詰められた status は表示しない。切り詰められた diff は、その旨の行を末尾に付ける |
+| 10 | python のパスに空白があると、引用していない systemd の unit が壊れる | 修正 | `ExecStart="…" "…"` |
+| 11 | ファイル名を pathspec（`*.txt`）として解釈する | 修正 | `--literal-pathspecs` |
+
+Codex は、`docs/HANDOVER.md` が分割読みと HTML・SVG を未実装と書いたままである点も指摘した。更新した。
+
+確認したこと:
+- HerdrKit のテスト（`testExecReportsTruncatedOutput` を追加）。
+- 読み取りのスクリプトで、15 MB のファイルを 4,000,000 バイトずつ読み、元のファイルとバイト単位で一致すること。
+- サービスのスクリプトの dry run。PATH に `&` と `<` を含めても plist の検証が通り、PATH がそのまま保たれる。
+- 一時 repo での git の argv。rename は rename として表示され、`*.txt` は文字どおりに扱われ、最初の commit の前は `--cached` で表示され、サブフォルダからルートを取得できる。
+- アプリと UI テストの実機向けのビルド。
+
+simulator では未確認である。作業中に Xcode が 27.2 へ自動更新され、simulator を使うには `sudo xcodebuild -runFirstLaunch` が必要になった。
diff --git a/docs/reviews/2026-11-01-files-changes-notifier-judgement.md b/docs/reviews/2026-11-01-files-changes-notifier-judgement.md
new file mode 100644
index 0000000..7eba301
--- /dev/null
+++ b/docs/reviews/2026-11-01-files-changes-notifier-judgement.md
@@ -0,0 +1,21 @@
+# Judgement: review of the notifier service, large files, HTML/SVG and Changes (2026-11-01)
+
+Reviewed commit: 282034e. Raw review: `2026-11-01-files-changes-notifier-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).
+
+| # | Finding | Decision | Why / what changed |
+|---|---|---|---|
+| 1 | The size/mtime line pushes an 8 MiB chunk past the core's 8 MB stdout cap; the short chunk is taken as the end of the file | Fix | A real bug: the 15 MB test PNG showed only a band. Chunks are 4,000,000 bytes; every chunk must be exactly `min(chunk, size - offset)` long and the reply must not be `truncated` (now read from `machine.exec` into `ExecResult`) |
+| 2 | JavaScript off does not stop images, CSS, iframes or redirects from reaching the network | Fix | A content rule list blocks every non-`file:` load before the page loads; the navigation delegate cancels non-file navigations; non-persistent data store |
+| 3 | A change during the last chunk, or a truncation, passes as a good file | Fix | The script `fstat`s again after reading and exits 4 when size or mtime moved; the app checks each chunk's length (finding 1) |
+| 4 | PATH or home with `&` or `<` breaks the plist, after the running notifier was stopped | Fix | Values are XML-escaped; the plist is written to a temporary file and `plutil -lint`ed before it replaces the old one and the job is restarted |
+| 5 | Porcelain paths are relative to the repo root, but diffs ran in the space folder | Fix | `git rev-parse --show-toplevel` first; status and diffs run at the root |
+| 6 | `~` and `~/x` are not expanded in argv | Fix | Expanded with the box's home before calling git |
+| 7 | A rename drops its source and shows as an added file | Fix | The source is kept and both paths are passed with `-M` |
+| 8 | Staged files before the first commit cannot be diffed (no HEAD) | Fix | `rev-parse --verify HEAD`; without HEAD the diff is `--cached` |
+| 9 | A status or diff over 8 MB is cut without notice | Fix | A truncated status is refused; a truncated diff ends with a line saying so |
+| 10 | An unquoted python path with spaces breaks the systemd unit | Fix | `ExecStart="…" "…"` |
+| 11 | File names are pathspecs (`*.txt`) | Fix | `--literal-pathspecs` |
+
+Codex also noted that `docs/HANDOVER.md` still described chunked reads and HTML/SVG as not built; updated.
+
+Checked: HerdrKit tests (new `testExecReportsTruncatedOutput`), the read script reassembling a 15 MB file in 4,000,000-byte chunks byte for byte, the service script dry-run with `&` and `<` in PATH (plist lints, PATH round-trips), the git argv on a scratch repo (rename shown as rename, `*.txt` literal, `--cached` before the first commit, root from a subfolder), and a device build of the app and UI tests. Not yet rerun in the simulator: Xcode updated itself to 27.2 during the session and the simulator needs `sudo xcodebuild -runFirstLaunch`.

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat docs/reviews/2026-11-01-files-changes-notifier-judgement.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
# Judgement: review of the notifier service, large files, HTML/SVG and Changes (2026-11-01)

Reviewed commit: 282034e. Raw review: `2026-11-01-files-changes-notifier-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | The size/mtime line pushes an 8 MiB chunk past the core's 8 MB stdout cap; the short chunk is taken as the end of the file | Fix | A real bug: the 15 MB test PNG showed only a band. Chunks are 4,000,000 bytes; every chunk must be exactly `min(chunk, size - offset)` long and the reply must not be `truncated` (now read from `machine.exec` into `ExecResult`) |
| 2 | JavaScript off does not stop images, CSS, iframes or redirects from reaching the network | Fix | A content rule list blocks every non-`file:` load before the page loads; the navigation delegate cancels non-file navigations; non-persistent data store |
| 3 | A change during the last chunk, or a truncation, passes as a good file | Fix | The script `fstat`s again after reading and exits 4 when size or mtime moved; the app checks each chunk's length (finding 1) |
| 4 | PATH or home with `&` or `<` breaks the plist, after the running notifier was stopped | Fix | Values are XML-escaped; the plist is written to a temporary file and `plutil -lint`ed before it replaces the old one and the job is restarted |
| 5 | Porcelain paths are relative to the repo root, but diffs ran in the space folder | Fix | `git rev-parse --show-toplevel` first; status and diffs run at the root |
| 6 | `~` and `~/x` are not expanded in argv | Fix | Expanded with the box's home before calling git |
| 7 | A rename drops its source and shows as an added file | Fix | The source is kept and both paths are passed with `-M` |
| 8 | Staged files before the first commit cannot be diffed (no HEAD) | Fix | `rev-parse --verify HEAD`; without HEAD the diff is `--cached` |
| 9 | A status or diff over 8 MB is cut without notice | Fix | A truncated status is refused; a truncated diff ends with a line saying so |
| 10 | An unquoted python path with spaces breaks the systemd unit | Fix | `ExecStart="…" "…"` |
| 11 | File names are pathspecs (`*.txt`) | Fix | `--literal-pathspecs` |

Codex also noted that `docs/HANDOVER.md` still described chunked reads and HTML/SVG as not built; updated.

Checked: HerdrKit tests (new `testExecReportsTruncatedOutput`), the read script reassembling a 15 MB file in 4,000,000-byte chunks byte for byte, the service script dry-run with `&` and `<` in PATH (plist lints, PATH round-trips), the git argv on a scratch repo (rename shown as rename, `*.txt` literal, `--cached` before the first commit, root from a subfolder), and a device build of the app and UI tests. In the simulator (Xcode 27.2) after the fixes: `testFilesPreviewInQuickLook` opened a 15 MB PNG (2400×2400, red band at the bottom shown, so read to the end), HTML, SVG, Markdown and PDF; a page loading `http://127.0.0.1:8765/…` made no request to that server, while Safari in the same simulator reached it (4 requests); `testChangesShowDiff` listed an untracked file and showed its diff.

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc 'nl -ba App/Sources/UI/FilesView.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	import SwiftUI
     2	import QuickLook
     3	import WebKit
     4	import HerdrKit
     5	
     6	/// A space's folder on the box: browse it and open files in Quick Look
     7	/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
     8	struct FilesView: View {
     9	    @Environment(AppStore.self) private var store
    10	    var path: String
    11	    var title: String
    12	
    13	    struct Entry: Identifiable, Hashable {
    14	        var name: String
    15	        var isDir: Bool
    16	        var size: Int
    17	        var id: String { name }
    18	    }
    19	
    20	    @State private var dir: String?
    21	    @State private var entries: [Entry] = []
    22	    @State private var skipped = 0
    23	    @State private var error: String?
    24	    @State private var opening: String?
    25	    @State private var fetch: Task<Void, Never>?
    26	    @State private var preview: URL?
    27	    @State private var markdown: MarkdownDoc?
    28	    @State private var progress: String?
    29	    @State private var web: WebDoc?
    30	
    31	    struct WebDoc: Identifiable { var name: String; var url: URL; var id: URL { url } }
    32	
    33	    struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }
    34	
    35	    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
    36	    /// and the reply is base64 inside one `Frame.maxPayload` (16 MiB) frame, so half of 8 MB is safe for both.
    37	    static let chunkBytes = 4_000_000
    38	    /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
    39	    static let maxBytes = 256 << 20
    40	
    41	    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
    42	    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
    43	    static let listScript = """
    44	    import json, os, sys
    45	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    46	    out, skipped = [], 0
    47	    with os.scandir(d) as it:
    48	        for e in it:
    49	            try:
    50	                e.name.encode("utf-8")
    51	                isdir = e.is_dir()
    52	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
    53	            except (OSError, UnicodeEncodeError):
    54	                skipped += 1
    55	    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
    56	    """
    57	
    58	    // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
    59	    // exits 1 when it is not a regular file, 4 when its size or mtime changed during this read.
    60	    // O_NONBLOCK so a FIFO listed as a file cannot hang the read.
    61	    static let readScript = """
    62	    import os, stat, sys
    63	    off, limit = int(sys.argv[2]), int(sys.argv[3])
    64	    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
    65	    st = os.fstat(fd)
    66	    if not stat.S_ISREG(st.st_mode):
    67	        sys.exit("not a regular file")
    68	    os.lseek(fd, off, os.SEEK_SET)
    69	    data = b""
    70	    while len(data) < limit:
    71	        chunk = os.read(fd, min(1 << 20, limit - len(data)))
    72	        if not chunk:
    73	            break
    74	        data += chunk
    75	    after = os.fstat(fd)
    76	    if (after.st_size, after.st_mtime_ns) != (st.st_size, st.st_mtime_ns):
    77	        sys.exit(4)
    78	    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
    79	    """
    80	
    81	    var body: some View {
    82	        List {
    83	            if let error {
    84	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
    85	            }
    86	            ForEach(entries) { e in
    87	                if e.isDir, let dir {
    88	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
    89	                } else {
    90	                    Button { open(e) } label: { row(e) }
    91	                        .disabled(opening != nil)
    92	                }
    93	            }
    94	            if skipped > 0 {
    95	                Text("\(skipped) item(s) with names that can't be shown are hidden.")
    96	                    .font(HF.ui(13)).foregroundStyle(HC.dim)
    97	            }
    98	        }
    99	        .overlay { if dir == nil && error == nil { ProgressView() } }
   100	        .navigationTitle(title)
   101	        .navigationBarTitleDisplayMode(.inline)
   102	        .task { await load() }
   103	        .refreshable { await load() }
   104	        .quickLookPreview($preview)
   105	        .sheet(item: $markdown) { doc in
   106	            NavigationStack {
   107	                ScrollView { ChatMarkdown(text: doc.text).padding(16).frame(maxWidth: .infinity, alignment: .leading) }
   108	                    .background(HC.canvas)
   109	                    .navigationTitle(doc.name)
   110	                    .navigationBarTitleDisplayMode(.inline)
   111	                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { markdown = nil }.accessibilityIdentifier("markdownClose") } }
   112	            }
   113	        }
   114	        .sheet(item: $web, onDismiss: nil) { doc in
   115	            NavigationStack {
   116	                WebPreview(url: doc.url)
   117	                    .ignoresSafeArea(edges: .bottom)
   118	                    .navigationTitle(doc.name)
   119	                    .navigationBarTitleDisplayMode(.inline)
   120	                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { web = nil }.accessibilityIdentifier("webClose") } }
   121	            }
   122	        }
   123	        .onChange(of: web?.url) { old, new in if new == nil, let old { Self.discard(old) } }
   124	        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
   125	        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
   126	        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil; progress = nil }
   127	    }
   128	
   129	    private func row(_ e: Entry) -> some View {
   130	        HStack(spacing: 12) {
   131	            Image(systemName: e.isDir ? "folder" : "doc")
   132	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
   133	                .frame(width: 22)
   134	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
   135	            Spacer(minLength: 8)
   136	            if opening == e.name {
   137	                if let progress { Text(progress).font(HF.ui(13)).foregroundStyle(HC.dim).monospacedDigit() }
   138	                ProgressView()
   139	            } else if !e.isDir {
   140	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
   141	            }
   142	        }
   143	        .accessibilityElement(children: .combine)
   144	        .accessibilityLabel(e.name)
   145	    }
   146	
   147	    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
   148	        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
   149	        return why.isEmpty ? fallback : String(why.suffix(300))
   150	    }
   151	
   152	    private func load() async {
   153	        do {
   154	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
   155	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
   156	                error = Self.failure(r, "Couldn't list \(path)")
   157	                return
   158	            }
   159	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
   160	                guard let n = a[0].string else { return nil }
   161	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
   162	            })
   163	            skipped = v["skipped"].int ?? 0
   164	            dir = d
   165	            error = nil
   166	        } catch {
   167	            self.error = Self.message(error)
   168	        }
   169	    }
   170	
   171	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
   172	    private static func message(_ error: Error) -> String {
   173	        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
   174	    }
   175	
   176	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
   177	    static func sorted(_ entries: [Entry]) -> [Entry] {
   178	        entries.sorted { a, b in
   179	            if a.isDir != b.isDir { return a.isDir }
   180	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
   181	            if ad != bd { return bd }
   182	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
   183	        }
   184	    }
   185	
   186	    private func open(_ e: Entry) {
   187	        guard let dir, opening == nil else { return }
   188	        guard e.size <= Self.maxBytes else { error = Self.tooLarge(e.name, e.size); return }
   189	        opening = e.name
   190	        fetch = Task {
   191	            defer { if !Task.isCancelled { opening = nil; fetch = nil; progress = nil } }
   192	            do {
   193	                guard let data = try await read(dir + "/" + e.name, e.name) else { return }
   194	                // Why not Quick Look for Markdown: it shows the raw source; Chat's renderer formats it.
   195	                if ["md", "markdown"].contains((e.name as NSString).pathExtension.lowercased()), let s = String(data: data, encoding: .utf8) {
   196	                    error = nil
   197	                    markdown = MarkdownDoc(name: e.name, text: s)
   198	                    return
   199	                }
   200	                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
   201	                let folder = FileManager.default.temporaryDirectory
   202	                    .appendingPathComponent("preview", isDirectory: true)
   203	                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
   204	                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
   205	                let url = folder.appendingPathComponent(e.name)
   206	                error = nil
   207	                // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
   208	                switch (e.name as NSString).pathExtension.lowercased() {
   209	                case "html", "htm":
   210	                    try Self.fitted(html: data).write(to: url, options: .completeFileProtection)
   211	                    web = WebDoc(name: e.name, url: url)
   212	                case "svg":
   213	                    try data.write(to: url, options: .completeFileProtection)
   214	                    let page = folder.appendingPathComponent("index.html")
   215	                    try Self.wrapper(image: e.name).write(to: page, options: .completeFileProtection)
   216	                    web = WebDoc(name: e.name, url: page)
   217	                default:
   218	                    try data.write(to: url, options: .completeFileProtection)
   219	                    preview = url
   220	                }
   221	            } catch {
   222	                if !Task.isCancelled { self.error = Self.message(error) }
   223	            }
   224	        }
   225	    }
   226	
   227	    /// The page with a phone-width viewport when it declares none.
   228	    static func fitted(html: Data) -> Data {
   229	        let head = String(decoding: html.prefix(8192), as: UTF8.self).lowercased()
   230	        if head.contains("name=\"viewport\"") || head.contains("name=viewport") || head.contains("name='viewport'") { return html }
   231	        return Data(#"<meta name="viewport" content="width=device-width, initial-scale=1">"#.utf8) + html
   232	    }
   233	
   234	    /// A page showing one vector image at the screen width.
   235	    static func wrapper(image name: String) -> Data {
   236	        let src = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
   237	        return Data(#"<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1"><body style="margin:0;background:#fff"><img src="\#(src)" style="display:block;width:100%;height:auto">"#.utf8)
   238	    }
   239	
   240	    private static func tooLarge(_ name: String, _ size: Int) -> String {
   241	        "\(name) is \(size.formatted(.byteCount(style: .file))); files over \(maxBytes.formatted(.byteCount(style: .file))) can't be previewed."
   242	    }
   243	
   244	    /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
   245	    /// the file changes size or mtime during or between chunks, a chunk comes back short, or it is over `maxBytes`.
   246	    private func read(_ path: String, _ name: String) async throws -> Data? {
   247	        var data = Data(), stamp: String?
   248	        while true {
   249	            let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
   250	                                         cwd: nil, on: nil, timeout: 60, input: nil)
   251	            guard !Task.isCancelled else { return nil }
   252	            guard r.code != 4 else { error = "\(name) changed while it was being read."; return nil }
   253	            guard r.code == 0, !r.timedOut, !r.truncated, let nl = r.stdout.firstIndex(of: 10) else {
   254	                error = Self.failure(r, "Couldn't read \(name)"); return nil
   255	            }
   256	            let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
   257	            let size = Int(head.split(separator: " ").first ?? "") ?? 0
   258	            guard stamp == nil || stamp == head else { error = "\(name) changed while it was being read."; return nil }
   259	            guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
   260	            stamp = head
   261	            let body = r.stdout[(nl + 1)...]
   262	            guard body.count == min(Self.chunkBytes, max(size - data.count, 0)) else { error = "\(name) changed while it was being read."; return nil }
   263	            data.append(body)
   264	            if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
   265	            if data.count >= size { return data }
   266	        }
   267	    }
   268	
   269	    /// Deletes a closed preview's downloaded copy (its own folder).
   270	    private static func discard(_ url: URL) {
   271	        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
   272	    }
   273	}
   274	
   275	/// A downloaded HTML page or SVG, with scripts off and file access limited to its own folder.
   276	private struct WebPreview: UIViewRepresentable {
   277	    let url: URL
   278	
   279	    /// Blocks every load that is not a local file, so a page from the box can't reach the network.
   280	    static let localOnly = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^file:"},"action":{"type":"ignore-previous-rules"}}]"#
   281	
   282	    func makeUIView(context: Context) -> WKWebView {
   283	        let config = WKWebViewConfiguration()
   284	        config.defaultWebpagePreferences.allowsContentJavaScript = false
   285	        config.websiteDataStore = .nonPersistent()
   286	        let view = WKWebView(frame: .zero, configuration: config)
   287	        view.navigationDelegate = context.coordinator
   288	        let url = url
   289	        Task { @MainActor in
   290	            // Nothing loads until the block list is in place.
   291	            guard let rules = try? await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "herdr-local-only", encodedContentRuleList: Self.localOnly) else { return }
   292	            view.configuration.userContentController.add(rules)
   293	            view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
   294	        }
   295	        return view
   296	    }
   297	
   298	    func updateUIView(_ view: WKWebView, context: Context) {}
   299	
   300	    func makeCoordinator() -> Coordinator { Coordinator() }
   301	
   302	    /// Links and redirects stay inside local files.
   303	    final class Coordinator: NSObject, WKNavigationDelegate {
   304	        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
   305	            action.request.url?.isFileURL == true ? .allow : .cancel
   306	        }
   307	    }
   308	}
   309	
   310	/// The Files sheet for one space: its own stack so folders push inside the sheet.
   311	struct FilesSheet: View {
   312	    @Environment(\.dismiss) private var dismiss
   313	    var folder: String
   314	    var title: String
   315	
   316	    var body: some View {
   317	        NavigationStack {
   318	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
   319	                .navigationDestination(for: String.self) { p in
   320	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
   321	                }
   322	                .toolbar {
   323	                    ToolbarItem(placement: .cancellationAction) {
   324	                        Button("Close", systemImage: "xmark") { dismiss() }
   325	                    }
   326	                }
   327	        }
   328	        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
   329	        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
   330	    }
   331	}

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc 'nl -ba App/Sources/UI/ChangesView.swift; nl -ba App/Resources/Notify/install-service.sh; cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	import SwiftUI
     2	import HerdrKit
     3	
     4	/// A space's uncommitted git changes on the box: the changed files, then one file's diff.
     5	/// Runs the box's git through machine.exec, read-only.
     6	struct ChangesSheet: View {
     7	    @Environment(AppStore.self) private var store
     8	    @Environment(\.dismiss) private var dismiss
     9	    var folder: String
    10	    var title: String
    11	
    12	    struct Change: Hashable, Identifiable {
    13	        var code: String   // porcelain XY, e.g. " M", "A ", "??"
    14	        var path: String
    15	        var from: String?  // a rename's or copy's source
    16	        var id: String { path }
    17	        var untracked: Bool { code == "??" }
    18	    }
    19	
    20	    @State private var changes: [Change]?
    21	    @State private var root = ""
    22	    @State private var hasHead = true
    23	    @State private var error: String?
    24	
    25	    var body: some View {
    26	        NavigationStack {
    27	            List {
    28	                if let error { Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked) }
    29	                if changes?.isEmpty == true { Text("No uncommitted changes.").font(HF.ui(14)).foregroundStyle(HC.muted) }
    30	                ForEach(changes ?? []) { c in
    31	                    NavigationLink(value: c) {
    32	                        HStack(spacing: 12) {
    33	                            Text(c.code.replacingOccurrences(of: " ", with: "·")).font(HF.mono(13, .semibold))
    34	                                .foregroundStyle(c.untracked ? HC.done : HC.working).frame(width: 26, alignment: .leading)
    35	                            Text(c.path).font(HF.ui(15)).foregroundStyle(HC.fg).lineLimit(2).truncationMode(.head)
    36	                        }
    37	                        .accessibilityElement(children: .combine)
    38	                        .accessibilityLabel(c.path)
    39	                    }
    40	                }
    41	            }
    42	            .overlay { if changes == nil && error == nil { ProgressView() } }
    43	            .navigationTitle("Changes · \(title)")
    44	            .navigationBarTitleDisplayMode(.inline)
    45	            .navigationDestination(for: Change.self) { c in DiffView(root: root, hasHead: hasHead, change: c) }
    46	            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
    47	            .task { await load() }
    48	            .refreshable { await load() }
    49	        }
    50	    }
    51	
    52	    /// The space folder as an absolute path: argv reaches git without a shell, so "~" is not expanded.
    53	    private var absoluteFolder: String {
    54	        if folder.isEmpty || folder == "~" { return store.home }
    55	        if folder.hasPrefix("~/") { return store.home + folder.dropFirst(1) }
    56	        return folder
    57	    }
    58	
    59	    private func load() async {
    60	        do {
    61	            // Porcelain paths are relative to the repo root, so status and every diff run there.
    62	            let top = try await store.exec(argv: ["git", "-C", absoluteFolder, "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil)
    63	            guard top.code == 0 else { error = DiffView.failure(top, "\(title) is not in a git repository."); return }
    64	            let dir = String(decoding: top.stdout, as: UTF8.self).trimmingCharacters(in: .newlines)
    65	            let head = try await store.exec(argv: ["git", "-C", dir, "rev-parse", "--verify", "-q", "HEAD"], cwd: nil, on: nil, timeout: 20, input: nil)
    66	            let r = try await store.exec(argv: ["git", "-C", dir, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
    67	                                         cwd: nil, on: nil, timeout: 20, input: nil)
    68	            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(dir)"); return }
    69	            guard !r.truncated else { error = "Too many changes to list here."; return }
    70	            root = dir
    71	            hasHead = head.code == 0
    72	            changes = Self.parse(r.stdout)
    73	            error = nil
    74	        } catch {
    75	            self.error = DiffView.message(error)
    76	        }
    77	    }
    78	
    79	    /// `git status --porcelain=v1 -z`: "XY path\0", and a rename or copy adds its source as the next "\0" field.
    80	    static func parse(_ out: Data) -> [Change] {
    81	        let fields = out.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
    82	        var result: [Change] = [], i = 0
    83	        while i < fields.count {
    84	            let f = fields[i]; i += 1
    85	            guard f.count > 3 else { continue }
    86	            let code = String(f.prefix(2))
    87	            let moved = code.contains("R") || code.contains("C")
    88	            result.append(Change(code: code, path: String(f.dropFirst(3)), from: moved && i < fields.count ? fields[i] : nil))
    89	            if moved { i += 1 }
    90	        }
    91	        return result
    92	    }
    93	}
    94	
    95	/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
    96	struct DiffView: View {
    97	    @Environment(AppStore.self) private var store
    98	    var root: String
    99	    var hasHead: Bool
   100	    var change: ChangesSheet.Change
   101	
   102	    @State private var lines: [Substring]?
   103	    @State private var error: String?
   104	
   105	    /// More lines than this are cut off; a phone can't usefully scroll a larger diff.
   106	    static let maxLines = 5000
   107	
   108	    var body: some View {
   109	        ScrollView([.vertical, .horizontal]) {
   110	            if let error {
   111	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked).padding(16)
   112	            } else if let lines {
   113	                LazyVStack(alignment: .leading, spacing: 0) {
   114	                    ForEach(Array(lines.prefix(Self.maxLines).enumerated()), id: \.offset) { _, l in
   115	                        Text(l.isEmpty ? " " : String(l)).font(HF.mono(12)).foregroundStyle(Self.color(l))
   116	                            .padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
   117	                            .background(Self.background(l))
   118	                    }
   119	                    if lines.count > Self.maxLines {
   120	                        Text("\(lines.count - Self.maxLines) more lines not shown.").font(HF.ui(13)).foregroundStyle(HC.dim).padding(10)
   121	                    }
   122	                }
   123	                .textSelection(.enabled)
   124	                .accessibilityIdentifier("diffLines")
   125	            } else {
   126	                ProgressView().padding(40)
   127	            }
   128	        }
   129	        .background(HC.canvas)
   130	        .navigationTitle((change.path as NSString).lastPathComponent)
   131	        .navigationBarTitleDisplayMode(.inline)
   132	        .task { await load() }
   133	    }
   134	
   135	    private func load() async {
   136	        let git = ["git", "-C", root, "--literal-pathspecs", "--no-pager", "diff", "--no-color", "--no-ext-diff", "-M"]
   137	        // --no-index exits 1 when the files differ, which for an untracked file is always.
   138	        // Before the first commit there is no HEAD; the index holds what that commit will contain.
   139	        let argv = change.untracked
   140	            ? git + ["--no-index", "--", "/dev/null", change.path]
   141	            : git + [hasHead ? "HEAD" : "--cached", "--"] + [change.from, change.path].compactMap { $0 }
   142	        do {
   143	            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
   144	            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
   145	            let text = String(decoding: r.stdout, as: UTF8.self)
   146	            var out: [Substring] = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
   147	            if r.truncated { out.append("… the diff is longer than 8 MB and was cut off here.") }
   148	            lines = out
   149	        } catch {
   150	            self.error = Self.message(error)
   151	        }
   152	    }
   153	
   154	    static func color(_ l: Substring) -> Color {
   155	        if l.hasPrefix("@@") { return HC.working }
   156	        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") || l.hasPrefix("rename ") || l.hasPrefix("similarity ") { return HC.dim }
   157	        if l.hasPrefix("+") { return HC.done }
   158	        if l.hasPrefix("-") { return HC.blocked }
   159	        return HC.fg
   160	    }
   161	
   162	    static func background(_ l: Substring) -> Color {
   163	        if l.hasPrefix("+++") || l.hasPrefix("---") { return .clear }
   164	        if l.hasPrefix("+") { return HC.done.opacity(0.12) }
   165	        if l.hasPrefix("-") { return HC.blocked.opacity(0.12) }
   166	        return .clear
   167	    }
   168	
   169	    static func failure(_ r: ExecResult, _ fallback: String) -> String {
   170	        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
   171	        return why.isEmpty ? fallback : String(why.suffix(300))
   172	    }
   173	
   174	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
   175	    static func message(_ error: Error) -> String {
   176	        (error as? HerdrError)?.kind == "spawn_failed" ? "Changes needs git on the box." : error.localizedDescription
   177	    }
   178	}
     1	#!/bin/sh
     2	# Runs herdr-notify as a service on the box: a launchd agent on macOS, a systemd
     3	# user service on Linux, nohup where neither is available. Used by the app's
     4	# Settings → Notifications and by scripts/install-notifier.sh.
     5	set -eu
     6	d="$HOME/.config/herdr-ios"
     7	script="$d/herdr-notify.py"
     8	py="$(command -v python3)"
     9	
    10	# XML text for a plist <string>.
    11	xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
    12	
    13	if [ "$(uname)" = Darwin ]; then
    14	  label=dev.herdr.notify
    15	  plist="$HOME/Library/LaunchAgents/$label.plist"
    16	  mkdir -p "$HOME/Library/LaunchAgents"
    17	  # launchd starts jobs with PATH=/usr/bin:/bin:/usr/sbin:/sbin; keep the PATH that found hc and python3 here.
    18	  tmp="$plist.new"
    19	  cat > "$tmp" <<EOF
    20	<?xml version="1.0" encoding="UTF-8"?>
    21	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    22	<plist version="1.0">
    23	<dict>
    24	  <key>Label</key><string>$label</string>
    25	  <key>ProgramArguments</key><array><string>$(xml "$py")</string><string>$(xml "$script")</string></array>
    26	  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$(xml "$PATH")</string></dict>
    27	  <key>RunAtLoad</key><true/>
    28	  <key>KeepAlive</key><true/>
    29	  <key>ThrottleInterval</key><integer>10</integer>
    30	  <key>StandardOutPath</key><string>$(xml "$d/notify.log")</string>
    31	  <key>StandardErrorPath</key><string>$(xml "$d/notify.log")</string>
    32	</dict>
    33	</plist>
    34	EOF
    35	  # A broken plist must not stop the running notifier.
    36	  plutil -lint -s "$tmp"
    37	  mv "$tmp" "$plist"
    38	  pkill -f "$script" 2>/dev/null || true
    39	  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    40	  launchctl bootstrap "gui/$(id -u)" "$plist"
    41	elif systemctl --user show-environment >/dev/null 2>&1; then
    42	  mkdir -p "$HOME/.config/systemd/user"
    43	  cat > "$HOME/.config/systemd/user/herdr-notify.service" <<EOF
    44	[Unit]
    45	Description=Herdr for iOS push notifications
    46	After=network-online.target
    47	
    48	[Service]
    49	ExecStart="$py" "%h/.config/herdr-ios/herdr-notify.py"
    50	Restart=always
    51	RestartSec=5
    52	
    53	[Install]
    54	WantedBy=default.target
    55	EOF
    56	  systemctl --user daemon-reload
    57	  systemctl --user enable herdr-notify >/dev/null 2>&1 || true
    58	  systemctl --user restart herdr-notify
    59	else
    60	  pkill -f "$script" 2>/dev/null || true
    61	  nohup "$py" "$script" >"$d/notify.log" 2>&1 &
    62	fi
# 場面ごとの言い方

user が実際に直した表現から作った、場面ごとの書き方。返答でも文書でも、該当する場面ではこの書き方で書く。
1 行に 1 件。出典は `transcript:<セッション ID の先頭 8 文字>#L<行>`。
`dotfiles/claude/style-digest.sh` が会話の記録から追記する。未 commit の行は user がまだ確かめていない。

- 【報告の文】動作は定着した漢語で書く（「測って確かめた」ではなく「計測した」）。動詞を開くと AI の文章らしく読まれる。〔transcript:37759ab8#L3516〕
- 【報告の文】文頭に主語を置く（「同じ Wasm で」「1 本で」から書き出さない）。主語が後ろにあると、何の話かが文末まで分からない。〔transcript:37759ab8#L3516〕
- 【報告の見出し】何を変えて何を計測したかを見出しに書く（例:「LLM の圧縮・復元を Wasm に変更し、機種間の一致を計測」）。差分が見出しだけで分かる。〔transcript:37759ab8#L3530〕
- 【技術用語】ソースを Wasm にする操作は「コンパイル」と書く（「Wasm にビルド」ではなく）。用語はその操作を正確に指す語を使う。〔transcript:37759ab8#L3976〕
- 【予定・必要】やり直しが要ることは「再度計測が必要である」と書く（「取り直します」ではなく）。口語の予定ではなく、書き言葉で必要性を書く。〔transcript:37759ab8#L4002〕
- 【並べ方】同じ種類のものだけを並べる（「Mac の Safari と iPhone の Safari」。「iPhone と Safari」のように端末とブラウザを同列にしない）。〔transcript:37759ab8#L4030〕
- 【数値の主語】時間や速さは、何にかかるかを書く（「スマホでの速さ」ではなく「スマホで契約書 1 本を復元するのにかかる時間」）。〔transcript:37759ab8#L4058〕
- 【語の意味】満たす必要がある数値は「制約」「条件」と書く（「目標」とは書かない）。目標は届かなくてもよい値に使う。〔transcript:37759ab8#L4058〕
- 【つなぎの語】独立した作業は、関係を示す語でつながずに並べる（「並行して」を使わない）。「並行して」は、マルチスレッド化を複数の文書をまとめて処理することと読み違えさせる。〔transcript:37759ab8#L4086〕
- 【文末】「である」調の文書では、過去の状態も「であった」と書く（「だった」ではなく）。文体をそろえる。〔transcript:f8e2de53#L139〕
- 【報告の用語】研究者・オフィスワーカーが読む文書は、分野で定着した用語をそのまま使う（「各 CPU 向けにビルドした版」ではなく「ネイティブビルド」、「計算を複数のスレッドに分ける版」ではなく「マルチスレッド版」）。和語に開くと平易になりすぎ、読み手には硬さが足りなく感じられる。〔transcript:37759ab8#L3601〕
- 【報告の構成】短い文に情報を載せ、構成は単純にする（課題、実施、結果、次の作業の順）。和語に開いて説明を広げるより、用語 1 語で済ませたほうが 1 文あたりの情報量が高い。〔transcript:37759ab8#L3686〕
- 【数の単位】同じ対象を数える単位は 1 つに統一し、LLM が数える対象は「トークン」と書く（「2,033 語」と「2,033 位置」を混在させない、「2,125 語」ではなく「2,125 トークン」）。単位が揺れると、同じ数を指しているのか読み手に判別できない。〔transcript:37759ab8#L4147〕
- 【段落内の文体】同じ段落では「である」調にそろえる（「再度計測が必要。Android は未計測。」の後に「見ていません。」と続けない）。です・ます調と体言止めが混ざると、文の調子が崩れる。〔transcript:37759ab8#L4147〕
- 【作業の列挙】次にやる作業を複数挙げるときは、「次の作業は 3 つです。」の後に文を並べず、箇条書きにする。並列の項目は、箇条書きのほうが 1 件ずつ区別して読める。〔transcript:37759ab8#L4147〕
- 【文書の用語】同じ概念は 1 つの語に統一し、省略した語は初出で補う（冒頭に用語表を置き、「一致」「確率」「分布」のように表現が揺れる語を使い分けない）。省略や言い換えが混ざると、読み手が同じものを指すのか判別できず、分かりにくくなる。〔transcript:2c8f2786#L400〕
- 【進捗報告の箇条書き】各行は体言で止める（「〜しました」ではなく）。終わったことは「済み」を付けて示す。「進捗」の見出しの下に置く項目は終わったことと読めるため、文末で完了を繰り返す必要がない。〔transcript:0994b5e3#L2165〕
- 【メールへの応答の報告】メールに応じたことは「返信済み」と書く（「回答済み」ではなく）。手段が分かる語のほうが、何をしたかが正確に伝わる。〔transcript:0994b5e3#L2193〕
- 【進捗報告の項目名】項目名は対象の媒体や種類が分かる語で書く（「登録シート」ではなく「スプレッドシート変更」、「問い合わせ」ではなく「メール問い合わせ」）。同じ週の報告に別種の作業が並ぶため、媒体が分かれば項目名だけで区別できる。〔transcript:0994b5e3#L2256〕
- 【進捗報告の構成】抽象的な項目名の下に具体を置く階層で書く。読み手は項目名だけで全体をつかめ、必要な項目だけ具体を読める。〔transcript:0994b5e3#L1115〕
- 【シート変更の依頼】列は記号（O、AL など）ではなくシートの列名で指す（「O（Activity-B）」ではなく列名そのまま）。依頼を受ける側は列名で探すため、記号に置き換えると手間が増える。〔transcript:0994b5e3#L1348〕
- 【返答の言語】user への報告・説明は、途中経過も含めて日本語で書く（英語の文を混ぜず、「Comparison is done.」のような英文で報告しない）。英語で書くと、読み手が内容を確かめる前に言語を変換する手間が生じる。〔transcript:69ba1421#L2524〕
- 【依頼文の項目】複数の対象に同じ変更を頼むときは、各項目を書き出す（「宮西さんと同じ変更です」と参照しない）。受け手は項目を 1 つずつ作業するため、別の項目に戻って読む手間が生じる。〔transcript:9b9713a4#L2025〕
- 【再度の依頼】以前の依頼に触れず、現時点との差分だけを示す（「まだ対応できていません」と書かない）。過去の分を挙げると催促や指摘に読まれる。〔transcript:9b9713a4#L1928〕
- 【確認の依頼】確認を頼むときは、どのファイルのどの箇所を見て何を決めるかを 1 件ずつ書く（「23 枚の下書きの採否を教えてください」とだけ書かない）。ファイルを 1 枚ずつ開いて探す作業を、依頼する側で済ませておくと、読み手の負担が減る。〔transcript:b9a5a6de#L4377〕
- 【確認依頼の投稿】自分の見立てを先に書き、そのとおり返信してよいかを聞く形にする（「可否をご確認ください」と相手に判断を丸ごと預けない）。相手は見立てに同意するかどうかだけを答えればよい。〔transcript:6c89b59a#L686〕
- 【複数の相手への確認】相手ごとに問いを分け、各問いの末尾に「→ 宛先」を付けて誰への問いかを示す（問いをまとめて宛名だけ冒頭に並べない）。宛先を問いごとに見て、自分に向けた問いだけを読める。〔transcript:6c89b59a#L807〕
- 【未回答の問いの再掲】回答待ちの問いは、記号や番号の範囲（「B〜D」「8〜10 番」）だけで指さず、問いの中身を 1 件ずつ書く。記号だけでは、読み手がどの問いか判別できず、前の発言を遡って探す手間が生じる。〔transcript:51c7e2cb#L698〕
- 【スライドの結論の行】出典と根拠のある事実だけを書き、評価語を足さない（「本物らしい書類が安く作れるようになった」の「安く」を書かない）。出典にない評価語は AI の文章らしく読まれる。〔transcript:37759ab8#L19888〕
- 【見出し・カードの語句】何が何をするのかを省かず、対象まで書く（「本物のまま渡せる」「撮影した端末が署名」ではなく、確かめる内容や署名の対象を書く）。対象が省かれると、読み手が意味を決められない。〔transcript:37759ab8#L20059〕
- 【専門外の聞き手への資料】モデルの大きさ（270M・1B）や CPU の名称（x86）は出さず、身近な比較対象（zip）に置き換える。専門外の聞き手には、数字や名称だけでは何がすごいのか伝わらない。〔transcript:37759ab8#L20089〕
- 【スライドの本文】見出しは主張の文にし、本文は文章の箇条書きではなく図・カード・大きな数字で示す（べた書きの箇条書きにしない）。単語を拾うだけでそのページの内容が分かるようにするためである。〔transcript:37759ab8#L11820〕
- 【数字の見せ方】数字は段階で現れるだけにし、0 から数え上げる演出は付けない（「0 → 47.1%」と変化させない）。演出が強いと、内容より動きが目立つ。〔transcript:37759ab8#L20700〕
- 【アルゴリズムの説明スライド】例は記号や仮の値ではなく、実際の文字列と値で示す。実際の文字列のほうが、何が起きているかを読み手が追える。〔transcript:37759ab8#L13152〕
- 【カードの文言】口語の言い切りや略した語（「払う店に得が少ない」「サーバ保管で足りる」）を避け、対象を正式な語で書く（「導入する店舗の利益が不明」「サーバ上でのデータ管理の方が利点が多い」）。口語の短縮は AI の文章らしく読まれる。〔transcript:37759ab8#L22085〕
- 【成果物の呼び方】実行ファイルは「共通の Wasm バイナリ」と書く（「同じ Wasm 1 本」と数えない）。「1 本」は何を数えているのか分からない。〔transcript:37759ab8#L12104〕
- 【投稿・報告の確認範囲の記載】確認した範囲が一部にとどまる事実は、否定の形で書かない（「10/25・26 の通知にお名前はありません」と書かない）。読み手に、それ以前の通知を疑わせる。〔transcript:068c3505#L2904〕
- 【略語・専門用語の初出】略語は初出で正式名称を添え、CPU・GPU のどちらの話か、どの層（命令・演算器・言語・API など）の語かを付ける（「ARM の SDOT・i8mm、x86 の AVX-VNNI」とだけ書かない）。読み手がハードウェアとソフトウェアの語に詳しくない場合、語の種類が分からないと文が追えない。〔transcript:8a64ed0c#L4371〕
- 【段階分けの呼び方】段階を表す語は、その段階が何を表すかのイメージを先に決め、それを伝える語を選ぶ（積み上がっていくものと捉えるなら「レイヤー」、どれだけ大事かの尺度と捉えるなら「重要度」）。番号付きの「層」（「1 層」「層2」）は、何の尺度か、数が大きいほどどうなるのかが読み手に伝わらない。〔transcript:7fa1b5bb#L5904〕

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc 'git status --short; git diff fa92895''^ fa92895 -- App/Sources/UI/FilesView.swift Packages/HerdrKit/Sources/HerdrKit/Contracts.swift Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
?? docs/reviews/2026-11-01-files-changes-notifier-fixes-codex.md
diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
index acacb92..5644bac 100644
--- a/App/Sources/UI/FilesView.swift
+++ b/App/Sources/UI/FilesView.swift
@@ -32,9 +32,9 @@ struct FilesView: View {
 
     struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }
 
-    /// The most read in one machine.exec. The reply is base64 (4/3) inside JSON in one
-    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
-    static let chunkBytes = Frame.maxPayload / 2
+    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
+    /// and the reply is base64 inside one `Frame.maxPayload` (16 MiB) frame, so half of 8 MB is safe for both.
+    static let chunkBytes = 4_000_000
     /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
     static let maxBytes = 256 << 20
 
@@ -56,7 +56,8 @@ struct FilesView: View {
     """
 
     // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
-    // exits 1 when it is not a regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
+    // exits 1 when it is not a regular file, 4 when its size or mtime changed during this read.
+    // O_NONBLOCK so a FIFO listed as a file cannot hang the read.
     static let readScript = """
     import os, stat, sys
     off, limit = int(sys.argv[2]), int(sys.argv[3])
@@ -71,6 +72,9 @@ struct FilesView: View {
         if not chunk:
             break
         data += chunk
+    after = os.fstat(fd)
+    if (after.st_size, after.st_mtime_ns) != (st.st_size, st.st_mtime_ns):
+        sys.exit(4)
     sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
     """
 
@@ -238,14 +242,15 @@ struct FilesView: View {
     }
 
     /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
-    /// the file changes size or mtime between chunks, or it grows past `maxBytes`.
+    /// the file changes size or mtime during or between chunks, a chunk comes back short, or it is over `maxBytes`.
     private func read(_ path: String, _ name: String) async throws -> Data? {
         var data = Data(), stamp: String?
         while true {
             let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
                                          cwd: nil, on: nil, timeout: 60, input: nil)
             guard !Task.isCancelled else { return nil }
-            guard r.code == 0, !r.timedOut, let nl = r.stdout.firstIndex(of: 10) else {
+            guard r.code != 4 else { error = "\(name) changed while it was being read."; return nil }
+            guard r.code == 0, !r.timedOut, !r.truncated, let nl = r.stdout.firstIndex(of: 10) else {
                 error = Self.failure(r, "Couldn't read \(name)"); return nil
             }
             let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
@@ -254,9 +259,10 @@ struct FilesView: View {
             guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
             stamp = head
             let body = r.stdout[(nl + 1)...]
+            guard body.count == min(Self.chunkBytes, max(size - data.count, 0)) else { error = "\(name) changed while it was being read."; return nil }
             data.append(body)
             if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
-            if body.count < Self.chunkBytes || data.count >= size { return data }
+            if data.count >= size { return data }
         }
     }
 
@@ -270,15 +276,35 @@ struct FilesView: View {
 private struct WebPreview: UIViewRepresentable {
     let url: URL
 
+    /// Blocks every load that is not a local file, so a page from the box can't reach the network.
+    static let localOnly = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^file:"},"action":{"type":"ignore-previous-rules"}}]"#
+
     func makeUIView(context: Context) -> WKWebView {
         let config = WKWebViewConfiguration()
         config.defaultWebpagePreferences.allowsContentJavaScript = false
+        config.websiteDataStore = .nonPersistent()
         let view = WKWebView(frame: .zero, configuration: config)
-        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
+        view.navigationDelegate = context.coordinator
+        let url = url
+        Task { @MainActor in
+            // Nothing loads until the block list is in place.
+            guard let rules = try? await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "herdr-local-only", encodedContentRuleList: Self.localOnly) else { return }
+            view.configuration.userContentController.add(rules)
+            view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
+        }
         return view
     }
 
     func updateUIView(_ view: WKWebView, context: Context) {}
+
+    func makeCoordinator() -> Coordinator { Coordinator() }
+
+    /// Links and redirects stay inside local files.
+    final class Coordinator: NSObject, WKNavigationDelegate {
+        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
+            action.request.url?.isFileURL == true ? .allow : .cancel
+        }
+    }
 }
 
 /// The Files sheet for one space: its own stack so folders push inside the sheet.
diff --git a/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift b/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift
index a682451..7e7cd8f 100644
--- a/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift
+++ b/Packages/HerdrKit/Sources/HerdrKit/Contracts.swift
@@ -46,8 +46,9 @@ public struct ExecResult: Sendable, Equatable {
     public var stdout: Data
     public var stderr: Data
     public var timedOut: Bool
-    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool) {
-        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut
+    public var truncated: Bool   // it wrote more than the core kept (stdout 8 MB, stderr 1 MB)
+    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool, truncated: Bool = false) {
+        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut; self.truncated = truncated
     }
 }
 
diff --git a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
index 7af4b2c..98e2b9c 100644
--- a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
+++ b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
@@ -226,7 +226,8 @@ public final class HerdrClient: @unchecked Sendable {
         return ExecResult(code: r["code"].int,
                           stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
                           stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
-                          timedOut: r["timed_out"].bool ?? false)
+                          timedOut: r["timed_out"].bool ?? false,
+                          truncated: r["truncated"].bool ?? false)
     }
 
     public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
index ae09bc1..89dcccd 100644
--- a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
+++ b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
@@ -194,6 +194,16 @@ final class ClientTests: XCTestCase {
         XCTAssertEqual(res, ExecResult(code: 0, stdout: Data("hi\n".utf8), stderr: Data(), timedOut: false))
     }
 
+    func testExecReportsTruncatedOutput() async throws {
+        let (c, t) = try await connected()
+        async let r = c.exec(argv: ["yes"], on: nil, timeout: 5)
+        let fr = try await t.waitFor { $0.contains { $0.channel == 0 } }
+        let msg = try JSONValue.parse(fr.first { $0.channel == 0 }!.payload)
+        t.reply(msg["id"].int!, ["code": 0, "stdout": "eQ==", "stderr": "", "timed_out": false, "truncated": true])
+        let res = try await r
+        XCTAssertTrue(res.truncated)
+    }
+
     func testSubscribeCreditsAndUpdates() async throws {
         let (c, t) = try await connected()
         async let s = c.subscribe(coalesce: 0)

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "rg -n 'func exec|var home|home =|ExecResult|WebPreview|ChangesSheet|DiffView' App/Sources Packages/HerdrKit/Sources README.md UITests" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
Packages/HerdrKit/Sources/herdr-probe/main.swift:13:let home = ProcessInfo.processInfo.environment["HERDR_PROBE_HOME"] ?? "~"
App/Sources/Store/AppStore.swift:52:    var home: String = "~"
App/Sources/Store/AppStore.swift:428:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
App/Sources/Store/AppStore.swift:599:        home = h
App/Sources/Store/AppStore.swift:838:        if let h = defaults.string(forKey: "home." + id.uuidString) { home = h }
App/Sources/Chat/TranscriptScript.swift:23:home = os.path.expanduser('~')
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:44:public struct ExecResult: Sendable, Equatable {
App/Sources/Chat/CodexTranscriptScript.swift:21:home = os.path.expanduser('~')
App/Sources/UI/ChangesView.swift:6:struct ChangesSheet: View {
App/Sources/UI/ChangesView.swift:45:            .navigationDestination(for: Change.self) { c in DiffView(root: root, hasHead: hasHead, change: c) }
App/Sources/UI/ChangesView.swift:63:            guard top.code == 0 else { error = DiffView.failure(top, "\(title) is not in a git repository."); return }
App/Sources/UI/ChangesView.swift:68:            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(dir)"); return }
App/Sources/UI/ChangesView.swift:75:            self.error = DiffView.message(error)
App/Sources/UI/ChangesView.swift:96:struct DiffView: View {
App/Sources/UI/ChangesView.swift:100:    var change: ChangesSheet.Change
App/Sources/UI/ChangesView.swift:169:    static func failure(_ r: ExecResult, _ fallback: String) -> String {
App/Sources/UI/FilesView.swift:116:                WebPreview(url: doc.url)
App/Sources/UI/FilesView.swift:147:    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
App/Sources/UI/FilesView.swift:276:private struct WebPreview: UIViewRepresentable {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:226:        return ExecResult(code: r["code"].int,
App/Sources/UI/SpaceView.swift:96:        .sheet(isPresented: $showChanges) { ChangesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
App/Sources/UI/DemoData.swift:74:        home = "/home/dev"
App/Sources/Mods/ModHub.swift:308:        let r: ExecResult

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '1,155p' App/Sources/UI/ChangesView.swift; sed -n '242,320p' App/Sources/UI/FilesView.swift; sed -n '420,445p' App/Sources/Store/AppStore.swift; sed -n '580,608p' App/Sources/Store/AppStore.swift; sed -n '825,845p' App/Sources/Store/AppStore.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
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
        var from: String?  // a rename's or copy's source
        var id: String { path }
        var untracked: Bool { code == "??" }
    }

    @State private var changes: [Change]?
    @State private var root = ""
    @State private var hasHead = true
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
            .navigationDestination(for: Change.self) { c in DiffView(root: root, hasHead: hasHead, change: c) }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    /// The space folder as an absolute path: argv reaches git without a shell, so "~" is not expanded.
    private var absoluteFolder: String {
        if folder.isEmpty || folder == "~" { return store.home }
        if folder.hasPrefix("~/") { return store.home + folder.dropFirst(1) }
        return folder
    }

    private func load() async {
        do {
            // Porcelain paths are relative to the repo root, so status and every diff run there.
            let top = try await store.exec(argv: ["git", "-C", absoluteFolder, "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil)
            guard top.code == 0 else { error = DiffView.failure(top, "\(title) is not in a git repository."); return }
            let dir = String(decoding: top.stdout, as: UTF8.self).trimmingCharacters(in: .newlines)
            let head = try await store.exec(argv: ["git", "-C", dir, "rev-parse", "--verify", "-q", "HEAD"], cwd: nil, on: nil, timeout: 20, input: nil)
            let r = try await store.exec(argv: ["git", "-C", dir, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
                                         cwd: nil, on: nil, timeout: 20, input: nil)
            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(dir)"); return }
            guard !r.truncated else { error = "Too many changes to list here."; return }
            root = dir
            hasHead = head.code == 0
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
            let moved = code.contains("R") || code.contains("C")
            result.append(Change(code: code, path: String(f.dropFirst(3)), from: moved && i < fields.count ? fields[i] : nil))
            if moved { i += 1 }
        }
        return result
    }
}

/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
struct DiffView: View {
    @Environment(AppStore.self) private var store
    var root: String
    var hasHead: Bool
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
        let git = ["git", "-C", root, "--literal-pathspecs", "--no-pager", "diff", "--no-color", "--no-ext-diff", "-M"]
        // --no-index exits 1 when the files differ, which for an untracked file is always.
        // Before the first commit there is no HEAD; the index holds what that commit will contain.
        let argv = change.untracked
            ? git + ["--no-index", "--", "/dev/null", change.path]
            : git + [hasHead ? "HEAD" : "--cached", "--"] + [change.from, change.path].compactMap { $0 }
        do {
            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
            let text = String(decoding: r.stdout, as: UTF8.self)
            var out: [Substring] = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
            if r.truncated { out.append("… the diff is longer than 8 MB and was cut off here.") }
            lines = out
        } catch {
            self.error = Self.message(error)
        }
    }

    static func color(_ l: Substring) -> Color {
        if l.hasPrefix("@@") { return HC.working }
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
    func interrupt(_ address: String) async throws {
        _ = try await connectedClient().call("terminal.interrupt", ["terminal": .string(address), "timeout": 10], timeout: 20)
    }
    func kill(_ address: String) async throws {
        _ = try await connectedClient().call("terminal.kill", ["terminal": .string(address)], timeout: 20)
    }

    // MARK: For mods
    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
        try await connectedClient().exec(argv: argv, cwd: cwd, on: on, timeout: timeout, input: input)
    }
    func call(_ method: String, _ params: JSONValue) async throws -> JSONValue {
        try await connectedClient().call(method, params)
    }
    func toast(_ title: String, body: String? = nil, level: String = "info") {
        toast(title, body: body, level: level, address: nil, duration: nil)
    }
    func toast(_ title: String, body: String?, level: String, address: String?, duration: Double?) {
        toasts.append(Toast(title: title, body: body, level: level, address: address, duration: duration))
        if toasts.count > 8 { toasts.removeFirst(toasts.count - 8) }
    }

    /// Pull-to-refresh: re-read the layout and terminal table on a healthy
    /// connection; reconnect only when there isn't one.
    func refresh() async {
        guard phase == .connected, let c = client else { reconnect(); return }

    private func teardownClient() {
        subscription?.onUpdate = nil; subscription?.onClose = nil; subscription?.onLost = nil
        subscription = nil
        if let c = client { c.onDisconnect = nil; c.close() }
        client = nil
    }

    private func clearLiveState() {
        terminals = [:]; doc = LayoutDoc(value: .null, version: 0); spaces = []; hello = nil
        attentionState = AttentionTracker()
    }

    private func learnHome(gen: Int) async {
        guard let c = client,
              let r = try? await c.exec(argv: ["sh", "-c", "printf %s \"$HOME\""], timeout: 10),
              r.code == 0, gen == generation else { return }
        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard h.hasPrefix("/"), h != home else { return }
        home = h
        if let id = activeMachineID { defaults.set(h, forKey: "home." + id.uuidString) }
    }

    // MARK: Events

    private func wire(_ sub: EventSubscription, gen: Int) {
        subscription = sub
        sub.onUpdate = { [weak self] u in
            guard let self, gen == self.generation else { return }
        }
        activeMachineID = defaults.string(forKey: "activeMachine").flatMap(UUID.init(uuidString:)).flatMap { id in
            machines.contains { $0.id == id } ? id : nil
        } ?? machines.first?.id
    }

    private struct ViewState: Codable {
        var space: String?
        var tabs: [String: String]
    }

    private func loadMachineState() {
        guard let id = activeMachineID else { return }
        if let h = defaults.string(forKey: "home." + id.uuidString) { home = h }
        restoringView = true
        defer { restoringView = false }
        if let d = defaults.data(forKey: "view." + id.uuidString), let v = try? JSONDecoder().decode(ViewState.self, from: d) {
            selectedSpaceID = v.space
            selectedTabBySpace = v.tabs
        } else {
            selectedSpaceID = nil

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "git show fa92895:App/Sources/UI/ChangesView.swift | nl -ba; rg -n 'truncated|MAX_STDOUT|8 \\* 1024|8_000_000' docs README.md Packages App --glob '"'!*-codex.md'"'; rg -n 'Changes|preview|256|HTML|SVG' README.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	import SwiftUI
     2	import HerdrKit
     3	
     4	/// A space's uncommitted git changes on the box: the changed files, then one file's diff.
     5	/// Runs the box's git through machine.exec, read-only.
     6	struct ChangesSheet: View {
     7	    @Environment(AppStore.self) private var store
     8	    @Environment(\.dismiss) private var dismiss
     9	    var folder: String
    10	    var title: String
    11	
    12	    struct Change: Hashable, Identifiable {
    13	        var code: String   // porcelain XY, e.g. " M", "A ", "??"
    14	        var path: String
    15	        var from: String?  // a rename's or copy's source
    16	        var id: String { path }
    17	        var untracked: Bool { code == "??" }
    18	    }
    19	
    20	    @State private var changes: [Change]?
    21	    @State private var root = ""
    22	    @State private var hasHead = true
    23	    @State private var error: String?
    24	
    25	    var body: some View {
    26	        NavigationStack {
    27	            List {
    28	                if let error { Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked) }
    29	                if changes?.isEmpty == true { Text("No uncommitted changes.").font(HF.ui(14)).foregroundStyle(HC.muted) }
    30	                ForEach(changes ?? []) { c in
    31	                    NavigationLink(value: c) {
    32	                        HStack(spacing: 12) {
    33	                            Text(c.code.replacingOccurrences(of: " ", with: "·")).font(HF.mono(13, .semibold))
    34	                                .foregroundStyle(c.untracked ? HC.done : HC.working).frame(width: 26, alignment: .leading)
    35	                            Text(c.path).font(HF.ui(15)).foregroundStyle(HC.fg).lineLimit(2).truncationMode(.head)
    36	                        }
    37	                        .accessibilityElement(children: .combine)
    38	                        .accessibilityLabel(c.path)
    39	                    }
    40	                }
    41	            }
    42	            .overlay { if changes == nil && error == nil { ProgressView() } }
    43	            .navigationTitle("Changes · \(title)")
    44	            .navigationBarTitleDisplayMode(.inline)
    45	            .navigationDestination(for: Change.self) { c in DiffView(root: root, hasHead: hasHead, change: c) }
    46	            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
    47	            .task { await load() }
    48	            .refreshable { await load() }
    49	        }
    50	    }
    51	
    52	    /// The space folder as an absolute path: argv reaches git without a shell, so "~" is not expanded.
    53	    private var absoluteFolder: String {
    54	        if folder.isEmpty || folder == "~" { return store.home }
    55	        if folder.hasPrefix("~/") { return store.home + folder.dropFirst(1) }
    56	        return folder
    57	    }
    58	
    59	    private func load() async {
    60	        do {
    61	            // Porcelain paths are relative to the repo root, so status and every diff run there.
    62	            let top = try await store.exec(argv: ["git", "-C", absoluteFolder, "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil)
    63	            guard top.code == 0 else { error = DiffView.failure(top, "\(title) is not in a git repository."); return }
    64	            let dir = String(decoding: top.stdout, as: UTF8.self).trimmingCharacters(in: .newlines)
    65	            let head = try await store.exec(argv: ["git", "-C", dir, "rev-parse", "--verify", "-q", "HEAD"], cwd: nil, on: nil, timeout: 20, input: nil)
    66	            let r = try await store.exec(argv: ["git", "-C", dir, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
    67	                                         cwd: nil, on: nil, timeout: 20, input: nil)
    68	            guard r.code == 0 else { error = DiffView.failure(r, "Couldn't read git status in \(dir)"); return }
    69	            guard !r.truncated else { error = "Too many changes to list here."; return }
    70	            root = dir
    71	            hasHead = head.code == 0
    72	            changes = Self.parse(r.stdout)
    73	            error = nil
    74	        } catch {
    75	            self.error = DiffView.message(error)
    76	        }
    77	    }
    78	
    79	    /// `git status --porcelain=v1 -z`: "XY path\0", and a rename or copy adds its source as the next "\0" field.
    80	    static func parse(_ out: Data) -> [Change] {
    81	        let fields = out.split(separator: 0, omittingEmptySubsequences: true).map { String(decoding: $0, as: UTF8.self) }
    82	        var result: [Change] = [], i = 0
    83	        while i < fields.count {
    84	            let f = fields[i]; i += 1
    85	            guard f.count > 3 else { continue }
    86	            let code = String(f.prefix(2))
    87	            let moved = code.contains("R") || code.contains("C")
    88	            result.append(Change(code: code, path: String(f.dropFirst(3)), from: moved && i < fields.count ? fields[i] : nil))
    89	            if moved { i += 1 }
    90	        }
    91	        return result
    92	    }
    93	}
    94	
    95	/// One file's diff against HEAD (or against nothing for an untracked file), coloured by line.
    96	struct DiffView: View {
    97	    @Environment(AppStore.self) private var store
    98	    var root: String
    99	    var hasHead: Bool
   100	    var change: ChangesSheet.Change
   101	
   102	    @State private var lines: [Substring]?
   103	    @State private var error: String?
   104	
   105	    /// More lines than this are cut off; a phone can't usefully scroll a larger diff.
   106	    static let maxLines = 5000
   107	
   108	    var body: some View {
   109	        ScrollView([.vertical, .horizontal]) {
   110	            if let error {
   111	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked).padding(16)
   112	            } else if let lines {
   113	                LazyVStack(alignment: .leading, spacing: 0) {
   114	                    ForEach(Array(lines.prefix(Self.maxLines).enumerated()), id: \.offset) { _, l in
   115	                        Text(l.isEmpty ? " " : String(l)).font(HF.mono(12)).foregroundStyle(Self.color(l))
   116	                            .padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
   117	                            .background(Self.background(l))
   118	                    }
   119	                    if lines.count > Self.maxLines {
   120	                        Text("\(lines.count - Self.maxLines) more lines not shown.").font(HF.ui(13)).foregroundStyle(HC.dim).padding(10)
   121	                    }
   122	                }
   123	                .textSelection(.enabled)
   124	                .accessibilityIdentifier("diffLines")
   125	            } else {
   126	                ProgressView().padding(40)
   127	            }
   128	        }
   129	        .background(HC.canvas)
   130	        .navigationTitle((change.path as NSString).lastPathComponent)
   131	        .navigationBarTitleDisplayMode(.inline)
   132	        .task { await load() }
   133	    }
   134	
   135	    private func load() async {
   136	        let git = ["git", "-C", root, "--literal-pathspecs", "--no-pager", "diff", "--no-color", "--no-ext-diff", "-M"]
   137	        // --no-index exits 1 when the files differ, which for an untracked file is always.
   138	        // Before the first commit there is no HEAD; the index holds what that commit will contain.
   139	        let argv = change.untracked
   140	            ? git + ["--no-index", "--", "/dev/null", change.path]
   141	            : git + [hasHead ? "HEAD" : "--cached", "--"] + [change.from, change.path].compactMap { $0 }
   142	        do {
   143	            let r = try await store.exec(argv: argv, cwd: nil, on: nil, timeout: 30, input: nil)
   144	            guard r.code == 0 || (change.untracked && r.code == 1) else { error = Self.failure(r, "Couldn't diff \(change.path)"); return }
   145	            let text = String(decoding: r.stdout, as: UTF8.self)
   146	            var out: [Substring] = text.isEmpty ? ["No textual changes (mode or staging only)."] : text.split(separator: "\n", omittingEmptySubsequences: false)
   147	            if r.truncated { out.append("… the diff is longer than 8 MB and was cut off here.") }
   148	            lines = out
   149	        } catch {
   150	            self.error = Self.message(error)
   151	        }
   152	    }
   153	
   154	    static func color(_ l: Substring) -> Color {
   155	        if l.hasPrefix("@@") { return HC.working }
   156	        if l.hasPrefix("+++") || l.hasPrefix("---") || l.hasPrefix("diff ") || l.hasPrefix("index ") || l.hasPrefix("rename ") || l.hasPrefix("similarity ") { return HC.dim }
   157	        if l.hasPrefix("+") { return HC.done }
   158	        if l.hasPrefix("-") { return HC.blocked }
   159	        return HC.fg
   160	    }
   161	
   162	    static func background(_ l: Substring) -> Color {
   163	        if l.hasPrefix("+++") || l.hasPrefix("---") { return .clear }
   164	        if l.hasPrefix("+") { return HC.done.opacity(0.12) }
   165	        if l.hasPrefix("-") { return HC.blocked.opacity(0.12) }
   166	        return .clear
   167	    }
   168	
   169	    static func failure(_ r: ExecResult, _ fallback: String) -> String {
   170	        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
   171	        return why.isEmpty ? fallback : String(why.suffix(300))
   172	    }
   173	
   174	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
   175	    static func message(_ error: Error) -> String {
   176	        (error as? HerdrError)?.kind == "spawn_failed" ? "Changes needs git on the box." : error.localizedDescription
   177	    }
   178	}
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:49:    public var truncated: Bool   // it wrote more than the core kept (stdout 8 MB, stderr 1 MB)
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:50:    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool, truncated: Bool = false) {
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:51:        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut; self.truncated = truncated
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:230:                          truncated: r["truncated"].bool ?? false)
App/Sources/UI/ChangesView.swift:69:            guard !r.truncated else { error = "Too many changes to list here."; return }
App/Sources/UI/ChangesView.swift:147:            if r.truncated { out.append("… the diff is longer than 8 MB and was cut off here.") }
App/Sources/UI/FilesView.swift:253:            guard r.code == 0, !r.timedOut, !r.truncated, let nl = r.stdout.firstIndex(of: 10) else {
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:182:        XCTAssertEqual(JSONValue.number(1.8e19).uint64, 18_000_000_000_000_000_000)
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:202:        t.reply(msg["id"].int!, ["code": 0, "stdout": "eQ==", "stderr": "", "timed_out": false, "truncated": true])
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:204:        XCTAssertTrue(res.truncated)
docs/reviews/2026-11-01-files-changes-notifier-judgement.ja.md:7:| 1 | サイズと mtime の行が加わると、8 MiB のチャンクが core の stdout の上限（8 MB）を超える。短くなったチャンクをファイルの終わりと判定する | 修正 | 実際の不具合であった。15 MB のテスト用 PNG が帯状にしか表示されなかった。チャンクを 4,000,000 バイトにした。各チャンクの長さが `min(チャンク, サイズ - offset)` と一致し、応答が `truncated` でないことを確かめる（`machine.exec` の `truncated` を `ExecResult` で読むようにした） |
docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:38:| `machine.exec`（PDF 3.4 MB を `cat`） | 445 ms | 3394636 bytes で元のファイルと一致し、`truncated` は false |
docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:57:- 送ったバイナリの大きさの上限。`machine.exec` の出力は `truncated` を返す。どの大きさで打ち切られるかは確かめていない。
docs/2026-11-01_herdr-core-mobile-client-spike.md:36:| `machine.exec` (`cat` of a 3.4 MB PDF) | 445 ms | 3394636 bytes, matched the original file, `truncated` is false |
docs/2026-11-01_herdr-core-mobile-client-spike.md:55:- The size limit for transferred binaries. The output of `machine.exec` returns `truncated`. The size at which it truncates was not checked.
docs/reviews/2026-11-01-files-changes-notifier-judgement.md:7:| 1 | The size/mtime line pushes an 8 MiB chunk past the core's 8 MB stdout cap; the short chunk is taken as the end of the file | Fix | A real bug: the 15 MB test PNG showed only a band. Chunks are 4,000,000 bytes; every chunk must be exactly `min(chunk, size - offset)` long and the reply must not be `truncated` (now read from `machine.exec` into `ExecResult`) |
docs/reviews/2026-11-01-files-changes-notifier-judgement.md:15:| 9 | A status or diff over 8 MB is cut without notice | Fix | A truncated status is refused; a truncated diff ends with a line saying so |
3:A fork of [zzulanas/herdr-ios](https://github.com/zzulanas/herdr-ios) that adds file preview; working rules are in `AGENTS.md`.
26:- **Spaces and tabs.** The same spaces, tabs and panes as the desktop app, read live from the core's `herdr-app` layout document. Changes you make on one screen show up on the other.
32:- **Files.** Browse a space's folder on the box and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. Files over 8 MiB are not previewed yet.

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "command -v uv; command -v swift; git log -3 --oneline; rg --files /Users/yosuke/workspace/github.com | rg 'herdr-core/.+(exec|machine)'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 exited 1 in 167ms:
/etc/profiles/per-user/yosuke/bin/uv
/usr/bin/swift
c7a8d33 Wait for slow previews and hidden Quick Look controls in the Files test
fa92895 Fix chunked reads cut short by the stdout cap, keep previews offline, and fix Changes paths
282034e Run the notifier under launchd on macOS, preview large files, HTML and SVG, and show git changes

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
チャンク読み取りの修正では、受信長と `truncated` の両方を検証しています。Changes の切り詰め警告は、既存の 5,000 行制限によって表示対象から外れる経路があります。systemd の引用処理も、特殊文字を含むパスについて仕様と照合します。
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg -n 'learnHome|phase = .connected|loadMachineState' App/Sources/Store/AppStore.swift; sed -n '32,60p' docs/reviews/2026-11-01-files-changes-notifier-judgement.ja.md; git diff fa92895 HEAD -- App/Sources/UI/FilesView.swift App/Sources/UI/ChangesView.swift App/Resources/Notify/install-service.sh; rg -n 'Files|8 MiB|256' docs/HANDOVER.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
99:        loadMachineState()
153:            loadMachineState()
515:            phase = .connected
520:            Task { [weak self] in await self?.learnHome(gen: gen) }
593:    private func learnHome(gen: Int) async {
836:    private func loadMachineState() {
50:- Files (this repo's first feature, 6c7e200 + 95acd13 after Codex's review,
51:  `docs/reviews/2026-11-01-files-judgement.md`): `App/Sources/UI/FilesView.swift`, folder button in
53:  keeps 8 MB of stdout); larger files are read in chunks, each checked by size and mtime, up to 256 MiB. `testFilesPreviewInQuickLook` opens a PDF, docx,
70:  the blocked (Amber), Codex send and read, and Files tests pass again.
104:# Files (needs build/preview-fixtures)
107:  xcodebuild test "${B[@]}" -only-testing:HerdrUITests/HerdrUITests/testFilesPreviewInQuickLook

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: 'specifiers'
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
1. **Medium — systemd のパスのエスケープが不完全** — [install-service.sh:49](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Resources/Notify/install-service.sh:49)  
   Python が `/home/user/My "Tools"/bin/python3` にある場合、追加された二重引用符とパス内の引用符が衝突し、サービスが起動しない。空白だけのパスは修正されている。**修正:** `$py` 内の引用符・バックスラッシュを [systemd の構文](https://www.freedesktop.org/software/systemd/man/latest/systemd.syntax.html#Quoting)に従ってエスケープし、`%` もリテラルとして処理する。

2. **Low — diff の切り詰め警告が行数制限で消える** — [ChangesView.swift:147](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:147)  
   8 MB で切り詰められた応答が 5,000 行を超えると、末尾に追加した警告は `lines.prefix(5000)` の対象外になる。画面には受信済み部分から算出した「残り N 行」だけが表示され、未受信部分の存在が伝わらない。**修正:** 切り詰め状態を別に保持し、行数制限の外で警告を表示する。

文書との不整合: [README.md:32](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/README.md:32) は依然「8 MiB 超は未対応」と記載しているが、実装は 256 MiB まで対応している。

未実施: simulator・サービス起動・テスト実行。読み取り専用 sandbox の一時ファイル作成制限により、追加の実行検証は完了していない。編集は行っていない。  
**判定: 修正が必要。上記以外の指定範囲に、残存・新規の不具合は認めなかった。**
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
63,073
1. **Medium — systemd のパスのエスケープが不完全** — [install-service.sh:49](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Resources/Notify/install-service.sh:49)  
   Python が `/home/user/My "Tools"/bin/python3` にある場合、追加された二重引用符とパス内の引用符が衝突し、サービスが起動しない。空白だけのパスは修正されている。**修正:** `$py` 内の引用符・バックスラッシュを [systemd の構文](https://www.freedesktop.org/software/systemd/man/latest/systemd.syntax.html#Quoting)に従ってエスケープし、`%` もリテラルとして処理する。

2. **Low — diff の切り詰め警告が行数制限で消える** — [ChangesView.swift:147](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ChangesView.swift:147)  
   8 MB で切り詰められた応答が 5,000 行を超えると、末尾に追加した警告は `lines.prefix(5000)` の対象外になる。画面には受信済み部分から算出した「残り N 行」だけが表示され、未受信部分の存在が伝わらない。**修正:** 切り詰め状態を別に保持し、行数制限の外で警告を表示する。

文書との不整合: [README.md:32](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/README.md:32) は依然「8 MiB 超は未対応」と記載しているが、実装は 256 MiB まで対応している。

未実施: simulator・サービス起動・テスト実行。読み取り専用 sandbox の一時ファイル作成制限により、追加の実行検証は完了していない。編集は行っていない。  
**判定: 修正が必要。上記以外の指定範囲に、残存・新規の不具合は認めなかった。**
