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
session id: 01a19342-1792-7dd3-b335-9974e0c19af6
--------
user
You are reviewing commits 407eccd, 362b8bc and 1b740be in this repo (run: git show 407eccd 362b8bc 1b740be). Context: docs/2026-11-01_herdr-ios-code-review.md lists the problems they fix (Chat nudge on title, host key trust on first use stored in UserDefaults, requiredMethods). Review only; do not edit files. For each finding give: severity (high/medium/low), file:line, the concrete failure scenario, and a suggested fix. Check in particular: (1) whether ChatModel's pause/nudge can still resume a continuation twice or leak one, given everything runs on the MainActor; (2) whether HostKeys.Unknown really stops before any credential is sent with Citadel 0.12.1 / NIOSSH, and every path that shows a failure lets the user approve (RootView, MainView banner, Settings); (3) anything else broken by moving pins to the Keychain. Say 'no findings' for a point if there are none. Be concise.
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
指定の3コミットと関連コード、Citadel／NIOSSH の認証順序を読み取り専用で確認します。レビュー用の Ponytail スキルを適用し、再現条件が確認できた指摘に絞ります。

hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'git show 407eccd 362b8bc 1b740be' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 407eccdb208fbc4b9b8612dcd6e2a4734b230b16
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:38:45 2026 +0900

    Stop re-reading the transcript on every terminal title change
    
    While an agent works its title changes about every 0.1 s (the spinner), and
    each change woke Chat, so the box ran the transcript script almost back to
    back. Status and turn changes are enough to notice new output. An earlier
    pause's timer could also end the next pause early; it is now cancelled.

diff --git a/App/Sources/Chat/ChatModel.swift b/App/Sources/Chat/ChatModel.swift
index 584bcb3..1f97a61 100644
--- a/App/Sources/Chat/ChatModel.swift
+++ b/App/Sources/Chat/ChatModel.swift
@@ -59,6 +59,7 @@ final class ChatModel {
     private var offset: Int64 = -1
     private var loop: Task<Void, Never>?
     private var wake: CheckedContinuation<Void, Never>?
+    private var sleeper: Task<Void, Never>?
     private weak var store: AppStore?
 
     init(address: String) { self.address = address }
@@ -80,10 +81,11 @@ final class ChatModel {
 
     func stop() {
         loop?.cancel(); loop = nil
+        sleeper?.cancel(); sleeper = nil
         wake?.resume(); wake = nil
     }
 
-    /// Something changed (status, turn, title): read now instead of waiting.
+    /// Something changed (status, turn): read now instead of waiting.
     func nudge() { wake?.resume(); wake = nil }
 
     private func pause() async {
@@ -91,9 +93,12 @@ final class ChatModel {
         let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
         await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
             wake = c
-            Task { [weak self] in
+            // Cancelled so an earlier pause's timer can never end this one early.
+            sleeper?.cancel()
+            sleeper = Task { [weak self] in
                 try? await Task.sleep(for: delay)
-                self?.wake?.resume(); self?.wake = nil
+                guard !Task.isCancelled else { return }
+                self?.nudge()
             }
         }
     }
diff --git a/App/Sources/Chat/ChatView.swift b/App/Sources/Chat/ChatView.swift
index dd11409..3d05359 100644
--- a/App/Sources/Chat/ChatView.swift
+++ b/App/Sources/Chat/ChatView.swift
@@ -43,7 +43,6 @@ struct ChatView: View {
         .onDisappear { model.stop() }
         .onChange(of: rec?.statusWord) { _, _ in model.nudge() }
         .onChange(of: rec?.turn) { _, _ in model.nudge() }
-        .onChange(of: rec?.title) { _, _ in model.nudge() }
         .onChange(of: store.phase) { _, p in if p == .connected { model.nudge() } }
         .onChange(of: scenePhase) { _, p in if p == .active { model.nudge() } }
     }

commit 362b8bcbaefe944c287fea45317f6e29debbebb3
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:38:46 2026 +0900

    Ask before pinning a new host key, and keep pins in the Keychain
    
    The first connection pinned whatever key it saw and showed the fingerprint
    only afterwards, so a man in the middle on that first connection would be
    trusted, and with password login would receive the password. Now an unknown
    host stops the connection before authentication and the failure screen shows
    the fingerprint to approve. Pins move from UserDefaults to the Keychain;
    existing pins are not migrated, so each host is approved once more.

diff --git a/App/Sources/Net/CitadelTransport.swift b/App/Sources/Net/CitadelTransport.swift
index ea6f558..3ed1107 100644
--- a/App/Sources/Net/CitadelTransport.swift
+++ b/App/Sources/Net/CitadelTransport.swift
@@ -107,7 +107,7 @@ final class CitadelTransport: ByteTransport, @unchecked Sendable {
 
     /// SSH failures in words a person can act on.
     static func friendly(_ error: Error, host: String, user: String) -> Error {
-        if error is HostKeys.Mismatch { return error }
+        if error is HostKeys.Mismatch || error is HostKeys.Unknown { return error }
         if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
             return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
                               hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
diff --git a/App/Sources/Net/HostKeys.swift b/App/Sources/Net/HostKeys.swift
index d2000c1..2d3f96f 100644
--- a/App/Sources/Net/HostKeys.swift
+++ b/App/Sources/Net/HostKeys.swift
@@ -3,10 +3,8 @@ import Crypto
 import NIOCore
 import NIOSSH
 
-/// Trust-on-first-use host keys, pinned per host:port in UserDefaults.
+/// Host keys pinned per host:port in the Keychain, after the person approves the first one.
 enum HostKeys {
-    private static let prefix = "hostkey."
-
     struct Mismatch: LocalizedError {
         var host: String
         var expected: String
@@ -16,21 +14,28 @@ enum HostKeys {
         }
     }
 
+    /// A host seen for the first time. Nothing is pinned and no credentials were sent yet.
+    struct Unknown: LocalizedError, Equatable {
+        var host: String
+        var port: Int
+        var line: String
+        var fingerprint: String { HostKeys.fingerprint(line) }
+        var errorDescription: String? {
+            "First connection to \(host). Check its host key before trusting it: \(fingerprint)"
+        }
+    }
+
     /// The pinned key's fingerprint, for display.
     static func pinnedFingerprint(host: String, port: Int) -> String? {
         pinned(host: host, port: port).map(fingerprint)
     }
 
-    static func pinned(host: String, port: Int) -> String? {
-        UserDefaults.standard.string(forKey: prefix + "\(host):\(port)")
-    }
+    static func pinned(host: String, port: Int) -> String? { KeyStore.hostKey("\(host):\(port)") }
 
-    static func forget(host: String, port: Int) {
-        UserDefaults.standard.removeObject(forKey: prefix + "\(host):\(port)")
-    }
+    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }
 
-    static func pin(_ line: String, host: String, port: Int) {
-        UserDefaults.standard.set(line, forKey: prefix + "\(host):\(port)")
+    static func pin(_ line: String, host: String, port: Int) throws {
+        try KeyStore.setHostKey(line, for: "\(host):\(port)")
     }
 
     /// `SHA256:<base64>` like ssh-keygen -l.
@@ -41,7 +46,8 @@ enum HostKeys {
         return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
     }
 
-    /// Validator for Citadel: pins on first sight, fails on change.
+    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
+    /// so the app can show the fingerprint and pin it on approval.
     final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
         let host: String, port: Int
         init(host: String, port: Int) { self.host = host; self.port = port }
@@ -56,8 +62,7 @@ enum HostKeys {
                                                             got: HostKeys.fingerprint(line)))
                 }
             } else {
-                HostKeys.pin(line, host: host, port: port)
-                validationCompletePromise.succeed(())
+                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
             }
         }
     }
diff --git a/App/Sources/Net/KeyStore.swift b/App/Sources/Net/KeyStore.swift
index 0902806..b7dd639 100644
--- a/App/Sources/Net/KeyStore.swift
+++ b/App/Sources/Net/KeyStore.swift
@@ -91,6 +91,17 @@ enum KeyStore {
         }
     }
 
+    // MARK: Host keys
+
+    static func hostKey(_ hostPort: String) -> String? {
+        (try? read(account: "hostkey." + hostPort)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
+    }
+
+    static func setHostKey(_ line: String?, for hostPort: String) throws {
+        let account = "hostkey." + hostPort
+        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
+    }
+
     // MARK: Keychain
 
     private static func query(_ account: String) -> [String: Any] {
diff --git a/App/Sources/Store/AppStore.swift b/App/Sources/Store/AppStore.swift
index 3dd1dff..5d529ee 100644
--- a/App/Sources/Store/AppStore.swift
+++ b/App/Sources/Store/AppStore.swift
@@ -218,6 +218,21 @@ final class AppStore {
     /// The last connect failed because the host key changed.
     private(set) var hostKeyMismatch = false
 
+    /// The last connect stopped at a host seen for the first time; its key waits for approval.
+    private(set) var unknownHostKey: HostKeys.Unknown?
+
+    /// Pins the approved first-seen host key and connects again.
+    func trustHostKey(_ key: HostKeys.Unknown) {
+        do {
+            try HostKeys.pin(key.line, host: key.host, port: key.port)
+        } catch {
+            phase = .failed("Couldn't save the host key: \(error.localizedDescription)")
+            return
+        }
+        unknownHostKey = nil
+        reconnect()
+    }
+
     /// Pull-to-refresh / screens that want a step index rather than text.
     /// 0 SSH, 1 starting core, 2 hello, 3 events + layout; -1 when not connecting.
     private(set) var connectStep = -1
@@ -504,6 +519,7 @@ final class AppStore {
             phase = .connected
             connectStep = -1
             hostKeyMismatch = false
+            unknownHostKey = nil
             attempt = 0
             Task { [weak self] in await self?.learnHome(gen: gen) }
         } catch {
@@ -514,7 +530,7 @@ final class AppStore {
     }
 
     private static func isRetryable(_ error: Error) -> Bool {
-        if error is HostKeys.Mismatch || error is KeyStore.KeyError { return false }
+        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return false }
         if let e = error as? HerdrError, ["auth", "needs_update", "not_installed"].contains(e.kind ?? "") { return false }
         return true
     }
@@ -524,6 +540,7 @@ final class AppStore {
         teardownClient()
         if !retry { reconnectTask?.cancel(); reconnectTask = nil }
         hostKeyMismatch = error is HostKeys.Mismatch
+        unknownHostKey = error as? HostKeys.Unknown
         connectStep = -1
         phase = .failed((error as? LocalizedError)?.errorDescription ?? "\(error)")
         // Only keep trying on our own when there's a session to get back to.
diff --git a/App/Sources/UI/ConnectionViews.swift b/App/Sources/UI/ConnectionViews.swift
index ec20878..4cda07e 100644
--- a/App/Sources/UI/ConnectionViews.swift
+++ b/App/Sources/UI/ConnectionViews.swift
@@ -274,6 +274,24 @@ struct FailureView: View {
                     .controlSize(.large)
                 }
                 .padding(.top, 6)
+                if let key = store.unknownHostKey {
+                    VStack(alignment: .leading, spacing: 8) {
+                        Text("New host key").font(HF.ui(15, .semibold))
+                        Text(key.fingerprint)
+                            .font(HF.mono(12.5))
+                            .textSelection(.enabled)
+                            .accessibilityIdentifier("hostKeyFingerprint")
+                        Text("On \(key.host), compare it with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
+                            .font(HF.ui(13)).foregroundStyle(HC.muted)
+                        Button { store.trustHostKey(key) } label: {
+                            Label("Trust and connect", systemImage: "checkmark.shield")
+                        }
+                        .buttonStyle(.glassProminent)
+                        .font(HF.ui(15, .medium))
+                    }
+                    .padding(14)
+                    .herdrCard()
+                }
                 if store.hostKeyMismatch, let m = store.activeMachine {
                     Button(role: .destructive) { confirmForget = true } label: {
                         Label("Forget host key", systemImage: "key.slash")
@@ -286,7 +304,7 @@ struct FailureView: View {
                             store.reconnect()
                         }
                     } message: {
-                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; the next key it presents will be trusted.")
+                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; you will be asked to approve the key it presents next.")
                     }
                 }
                 Text("Check that the host is reachable (e.g. Tailscale is on), the key is in authorized_keys, and herdr-core is installed in ~/.local/bin.")
diff --git a/App/Sources/UI/RootView.swift b/App/Sources/UI/RootView.swift
index 57156ff..b5bc68c 100644
--- a/App/Sources/UI/RootView.swift
+++ b/App/Sources/UI/RootView.swift
@@ -15,7 +15,8 @@ struct RootView: View {
         switch store.phase {
         case .connected: return .main
         case .connecting: return hadSession ? .main : .connecting
-        case .failed: return hadSession ? .main : .failed
+        // A first-seen host key needs the approval card on the failure screen even mid-session.
+        case .failed: return hadSession && store.unknownHostKey == nil ? .main : .failed
         // Idle with nothing to show (e.g. Cancel on the connecting screen): the
         // failure screen offers Connect and Edit machine instead of a dead spinner.
         case .idle: return hadSession ? .main : .failed

commit 1b740be0f3661954c95ec02bba3cd180f0de64bf
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:38:46 2026 +0900

    List every core method the app calls in requiredMethods
    
    The hello check missed terminal.get/read/send/keys/interrupt, machine.list
    and server.status, so a core lacking them connected and failed later on the
    screen that needed them.

diff --git a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
index 1fdb6b3..3c3f88a 100644
--- a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
+++ b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
@@ -25,8 +25,10 @@ public final class HerdrClient: @unchecked Sendable {
     public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }
 
     /// Methods the app calls; a core lacking one can't serve it.
-    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.kill", "terminal.label", "terminal.attach",
-                                         "terminal.keep", "doc.get", "doc.set", "events.subscribe", "machine.exec"]
+    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
+                                         "terminal.attach", "terminal.keep", "terminal.read", "terminal.send", "terminal.keys",
+                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+                                         "machine.list", "server.status"]
     public static let minCoreVersion = "0.1.11"
     public static let generation: UInt64 = 1
 
diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
index 2e7a840..ae09bc1 100644
--- a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
+++ b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
@@ -40,7 +40,7 @@ final class FakeTransport: ByteTransport, @unchecked Sendable {
 }
 
 final class ClientTests: XCTestCase {
-    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec"]}}"# + "\n").utf8)
+    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
 
     func connected() async throws -> (HerdrClient, FakeTransport) {
         let t = FakeTransport()

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail/SKILL.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
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
---
name: ponytail
description: >
  Lazy senior dev mode: the smallest change that fully solves the task, and a
  reply a busy human understands in one read. Use on any coding task (writing,
  fixing, refactoring, reviewing, choosing dependencies) and when the user says
  "ponytail", "be lazy", "simplest solution", "yagni", or complains about
  over-engineering or bloat. Levels: lite, full (default), ultra.
argument-hint: "[lite|full|ultra|off]"
license: MIT
---

# Ponytail

You are a lazy senior developer. The best code is the code never written. You solve the whole problem with the least new code. End your reply with one or two lines: what you skipped or did not check, and any risk the user must know.

Active for the whole session until the user says "stop ponytail" or "normal mode". Switch level: `/ponytail lite|full|ultra`.

## Before you write

Read the task and the code it touches. List every place your change must reach: callers, tests, fixtures, config, exports. Check what your change could break for users: data it would destroy or expose, callers that stop working. That is scope. Extra features are not.

## The smallest complete change

Take the first option that fully works:

1. Does it need to exist? Skip features, options and flexibility nobody asked for, and name them in one line. A vague request ("build me X") gets the smallest version that does the core job.
2. Already in this codebase (a helper, component, service, pattern)? Use it the way the surrounding code does.
3. Standard library or a platform feature? Use it, unless the project has its own. A house component beats a native widget.
4. An installed dependency? Use it. Never add a dependency for a few lines.
5. Can it be one line a reader gets at a glance? One line.
6. Otherwise: the minimum code that works.

- Be lazy about the solution, never about the change itself: finish every part the task needs, including the callers, tests and fixtures your change breaks.
- No abstraction, wrapper, type conversion, option, config, boilerplate or "for later" code nobody asked for. Keep values in the form the platform already gives you. Deletion beats addition. Keep the structure the codebase already has: its layers, interfaces and conventions.
- The shortest working diff wins, once you know everything it must touch. A one-liner that needs decoding is not short.
- Comment only the why the code cannot show, in one line.
- Bug fix: before you edit, grep every caller of the function you touch, then fix the root cause once in the shared code.
- Code you move or merge keeps its error handling and validation.
- Between options of equal size, take the one that is correct on edge cases.
- Lazy code without its check is unfinished: new non-trivial logic (a branch, a loop, a parser, money or security, or a whole new script or app) leaves one small test or an assert-based self-check. Trivial changes need none.
- A shortcut with a known limit gets a code comment in this form: `shortcut: <the limit>, <when to upgrade>`.

Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, the calibration real hardware needs, anything the user asked for.

## Levels

| Level | Behavior |
|-------|----------|
| **lite** | Build what was asked. Name the smaller option in one line and let the user pick. |
| **full** | The rules above. Default. |
| **ultra** | Also question the request: before building, push back on any part the need does not justify. |

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "git status --short; rg --files -g '*resolved' -g '*ChatModel*' -g '*HostKeys*' -g '*AGENTS*'; cat App/Sources/Chat/ChatModel.swift App/Sources/Net/KeyStore.swift App/Sources/Net/CitadelTransport.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
?? docs/reviews/
Herdr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
AGENTS.md
AGENTS.ja.md
App/Sources/Chat/ChatModel.swift
App/Sources/Net/HostKeys.swift
import SwiftUI
import HerdrKit

/// One entry the box-side script emitted (TranscriptScript).
enum ChatEntry {
    case user(String, Date?)
    case note(String)
    case command(String)
    case compact
    case text(String)
    case tool(id: String, name: String, summary: String, detail: String, at: Date?)
    case result(id: String, isError: Bool, output: String)
    case duration(ms: Int)
}

struct ToolCall: Identifiable, Equatable {
    var id: String
    var name: String
    var summary: String
    var detail: String
    var output: String?
    var isError = false
}

enum ChatStep: Identifiable, Equatable {
    case text(Int, String)
    case tools(Int, [ToolCall])
    var id: Int { switch self { case .text(let i, _), .tools(let i, _): i } }
    var toolCount: Int { if case .tools(_, let c) = self { c.count } else { 0 } }
}

/// One prompt and everything the agent did in answer.
struct ChatTurn: Identifiable, Equatable {
    enum Prompt: Equatable { case user(String), note(String), command(String) }
    var id: Int
    var prompt: Prompt?
    var compacted = false
    var steps: [ChatStep] = []
    var durationMs: Int?
    var startedAt: Date?
}

/// Reads an agent's Claude Code transcript from the box and folds it into
/// turns. Polls quickly while the agent works, slowly otherwise; never
/// attaches to (or resizes) the terminal.
@MainActor @Observable
final class ChatModel {
    enum Phase: Equatable { case loading, ready, unavailable(String), failed(String) }

    let address: String
    private(set) var phase: Phase = .loading
    private(set) var turns: [ChatTurn] = []
    /// The transcript continues above what was loaded (we only read its tail).
    private(set) var hasEarlier = false
    private(set) var revision = 0

    private var entries: [ChatEntry] = []
    private var session = ""
    private var offset: Int64 = -1
    private var loop: Task<Void, Never>?
    private var wake: CheckedContinuation<Void, Never>?
    private var sleeper: Task<Void, Never>?
    private weak var store: AppStore?

    init(address: String) { self.address = address }

    func start(store: AppStore) {
        self.store = store
        #if DEBUG
        if AppStore.isDemo { loadDemo(); return }
        #endif
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.load()
                await self.pause()
            }
        }
    }

    func stop() {
        loop?.cancel(); loop = nil
        sleeper?.cancel(); sleeper = nil
        wake?.resume(); wake = nil
    }

    /// Something changed (status, turn): read now instead of waiting.
    func nudge() { wake?.resume(); wake = nil }

    private func pause() async {
        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            wake = c
            // Cancelled so an earlier pause's timer can never end this one early.
            sleeper?.cancel()
            sleeper = Task { [weak self] in
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                self?.nudge()
            }
        }
    }

    private func load() async {
        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
        let argv = String(decoding: rec.raw["argv"].encoded(), as: UTF8.self)
        for _ in 0..<4 {   // follow "more" a few times on a big backlog
            do {
                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
                                             cwd: nil, on: nil, timeout: 20, input: nil)
                guard r.code == 0 else {
                    let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                    phase = .failed(err.isEmpty ? "Couldn't read the conversation." : String(err.suffix(300)))
                    return
                }
                if !apply(r.stdout) { return }
            } catch {
                if case .ready = phase {} else { phase = .failed(error.localizedDescription) }
                return
            }
        }
    }

    /// Returns true when the box has more to send right away.
    private func apply(_ data: Data) -> Bool {
        var lines = data.split(separator: UInt8(ascii: "\n"))
        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())) else { return false }
        if let why = head["why"].string {
            phase = .unavailable(why == "no-session"
                ? "No Claude Code conversation found for this terminal yet."
                : "Claude Code's transcript for this session isn't on disk yet.")
            return false
        }
        let fresh = head["fresh"].bool ?? false
        if fresh {
            entries = []
            session = head["session"].string ?? ""
            hasEarlier = (head["start"].int ?? 0) > 0
        }
        offset = Int64(head["next"].double ?? Double(offset))
        var added = false
        for line in lines {
            guard let e = try? JSONValue.parse(Data(line)), let entry = Self.entry(e) else { continue }
            entries.append(entry); added = true
        }
        if fresh || added { rebuild() }
        phase = .ready
        return head["more"].bool ?? false
    }

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
    }()

    private static func entry(_ e: JSONValue) -> ChatEntry? {
        let t = e["t"].string ?? ""
        let ts = e["ts"].string.flatMap { iso.date(from: $0) }
        switch e["k"].string {
        case "user": return .user(t, ts)
        case "note": return .note(t)
        case "cmd": return .command(t)
        case "compact": return .compact
        case "text": return .text(t)
        case "tool": return .tool(id: e["id"].string ?? "", name: e["name"].string ?? "Tool",
                                  summary: e["sum"].string ?? "", detail: e["detail"].string ?? "", at: ts)
        case "result": return .result(id: e["id"].string ?? "", isError: e["err"].bool ?? false, output: e["out"].string ?? "")
        case "dur": return .duration(ms: e["ms"].int ?? 0)
        default: return nil
        }
    }

    /// Folds entries into turns: a prompt starts one; texts and tool calls
    /// follow; consecutive tool calls share a group; results attach by id.
    private func rebuild() {
        var out: [ChatTurn] = []
        var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
        var n = 0
        func next() -> Int { n += 1; return n }
        func current() -> Int {
            if out.isEmpty { out.append(ChatTurn(id: next())) }
            return out.count - 1
        }
        for e in entries {
            switch e {
            case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
            case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
            case .command(let s): out.append(ChatTurn(id: next(), prompt: .command(s)))
            case .compact:
                // A boundary and its "continued from" summary arrive together: one marker.
                if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
                out.append(ChatTurn(id: next(), compacted: true))
            case .text(let s):
                let i = current(); out[i].steps.append(.text(next(), s))
            case .tool(let id, let name, let sum, let detail, let at):
                let i = current()
                if out[i].startedAt == nil { out[i].startedAt = at }
                let call = ToolCall(id: id, name: name, summary: sum, detail: detail)
                if case .tools(let sid, var calls)? = out[i].steps.last {
                    calls.append(call)
                    out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
                    where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
                } else {
                    out[i].steps.append(.tools(next(), [call]))
                    where_[id] = (i, out[i].steps.count - 1, 0)
                }
            case .result(let id, let err, let output):
                guard let w = where_[id], case .tools(let sid, var calls) = out[w.turn].steps[w.step] else { continue }
                calls[w.call].output = output
                calls[w.call].isError = err
                out[w.turn].steps[w.step] = .tools(sid, calls)
            case .duration(let ms):
                if !out.isEmpty { out[out.count - 1].durationMs = ms }
            }
        }
        // A trailing "continued from earlier" marker with nothing after it reads oddly; keep it, it's honest.
        turns = out
        revision += 1
    }
}

// MARK: Display helpers

enum ToolStyle {
    static func symbol(_ name: String) -> String {
        switch name {
        case "Bash", "BashOutput", "KillShell": "terminal"
        case "Read": "doc.text"
        case "Edit", "MultiEdit": "pencil"
        case "Write", "NotebookEdit": "square.and.pencil"
        case "Grep", "Glob", "ToolSearch": "magnifyingglass"
        case "WebSearch", "WebFetch": "globe"
        case "Agent", "Task", "SendMessage": "person.2"
        case "TodoWrite": "checklist"
        case "Skill": "sparkles"
        case "Workflow": "point.3.connected.trianglepath.dotted"
        default: name.hasPrefix("mcp__") ? "puzzlepiece.extension" : "wrench.and.screwdriver"
        }
    }

    /// "mcp__claude-artifacts__get_artifact" -> "claude-artifacts · get_artifact"
    static func title(_ name: String) -> String {
        guard name.hasPrefix("mcp__") else { return name }
        let parts = name.dropFirst(5).components(separatedBy: "__")
        return parts.count >= 2 ? "\(parts[0]) · \(parts.dropFirst().joined(separator: "__"))" : String(name.dropFirst(5))
    }

    static func duration(ms: Int) -> String {
        let s = ms / 1000
        if s < 60 { return "\(max(s, 1))s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \((s % 3600) / 60)m"
    }
}

#if DEBUG
// A canned conversation for screenshots (HERDR_DEMO=1).
extension ChatModel {
    fileprivate func loadDemo() {
        let now = Date()
        entries = [
            .user("Add a global time slider to the analytics dashboard so every chart shares one range", now.addingTimeInterval(-900)),
            .text("I'll start by looking at how the dashboard wires its charts together."),
            .tool(id: "a", name: "Read", summary: "~/projects/webapp/src/dashboard/Dashboard.tsx", detail: "", at: nil),
            .result(id: "a", isError: false, output: "214 lines"),
            .tool(id: "b", name: "Grep", summary: "useTimeRange", detail: "", at: nil),
            .result(id: "b", isError: false, output: "Found 7 files"),
            .tool(id: "c", name: "Edit", summary: "~/projects/webapp/src/dashboard/TimeSlider.tsx", detail: "+ export function TimeSlider({ range, onChange }: TimeSliderProps) {\n+   const [draft, setDraft] = useState(range);", at: nil),
            .result(id: "c", isError: false, output: "Updated with 48 additions and 3 removals"),
            .tool(id: "d", name: "Bash", summary: "Run the dashboard tests", detail: "npm test -- dashboard", at: nil),
            .result(id: "d", isError: false, output: "Tests: 42 passed, 42 total"),
            .text("""
            Every chart on the dashboard now follows **one shared time range**.

            **What changed**
            - A new `TimeSlider` sits in the dashboard header; dragging it updates every chart after a short debounce.
            - Charts read the range from `useTimeRange()` instead of keeping their own.

            | Chart | Before | After |
            |---|---|---|
            | Net flow | own range | shared |
            | Volume | own range | shared |
            | Latency | fixed 24h | shared |

            Tests pass (42/42). Want me to persist the range in the URL so links keep it?
            """),
            .duration(ms: 318_000),
            .user("Yes, put it in the URL", now.addingTimeInterval(-95)),
            .text("Adding a `range` query parameter and reading it on load."),
            .tool(id: "e", name: "Edit", summary: "~/projects/webapp/src/dashboard/useTimeRange.ts", detail: "", at: nil),
            .result(id: "e", isError: false, output: "Updated"),
            .tool(id: "f", name: "Bash", summary: "Type-check the project", detail: "npx tsc --noEmit", at: nil),
        ]
        rebuild()
        phase = .ready
    }
}
#endif
import Foundation
import Security
import Crypto
import Citadel

/// The app's SSH identity and saved passwords, in the Keychain
/// (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: never synced or backed up).
enum KeyStore {
    private static let service = "com.zzulanas.herdr.ssh"
    private static let keyAccount = "ed25519"

    enum KeyError: LocalizedError {
        case keychain(OSStatus)
        case badKey(String)
        var errorDescription: String? {
            switch self {
            case .keychain(let s): "Keychain error \(s)"
            case .badKey(let why): why
            }
        }
    }

    /// The signing key: a DEBUG override file, else the Keychain, else a new one (saved).
    static func signingKey() throws -> Curve25519.Signing.PrivateKey {
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment["HERDR_DEBUG_KEY_PATH"], !path.isEmpty {
            let text = try String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8)
            return try parseOpenSSH(text)
        }
        #endif
        if let raw = try read(account: keyAccount) {
            return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
        }
        let key = Curve25519.Signing.PrivateKey()
        try write(key.rawRepresentation, account: keyAccount)
        return key
    }

    /// OpenSSH one-line public key: `ssh-ed25519 AAAA… herdr-ios`.
    static func publicKeyLine() -> String {
        guard let key = try? signingKey() else { return "" }
        return publicKeyLine(for: key.publicKey)
    }

    static func publicKeyLine(for pub: Curve25519.Signing.PublicKey, comment: String = "herdr-ios") -> String {
        var blob = Data()
        func sshString(_ d: Data) {
            withUnsafeBytes(of: UInt32(d.count).bigEndian) { blob.append(contentsOf: $0) }
            blob.append(d)
        }
        sshString(Data("ssh-ed25519".utf8))
        sshString(pub.rawRepresentation)
        return "ssh-ed25519 \(blob.base64EncodedString()) \(comment)"
    }

    /// Replaces the app key with a pasted, unencrypted OpenSSH ed25519 private key.
    static func importPrivateKey(_ openSSHText: String) throws {
        let key = try parseOpenSSH(openSSHText)
        try write(key.rawRepresentation, account: keyAccount)
    }

    /// Generates a fresh key (the old one is gone for good).
    static func regenerateKey() throws {
        try write(Curve25519.Signing.PrivateKey().rawRepresentation, account: keyAccount)
    }

    private static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
            throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
        }
        do {
            return try Curve25519.Signing.PrivateKey(sshEd25519: trimmed + "\n")
        } catch {
            throw KeyError.badKey("Couldn't read that key: only unencrypted ed25519 keys work (\(error))")
        }
    }

    // MARK: Passwords

    static func password(for machine: UUID) -> String? {
        (try? read(account: "pw." + machine.uuidString)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    }

    static func setPassword(_ password: String?, for machine: UUID) {
        let account = "pw." + machine.uuidString
        if let password, !password.isEmpty {
            try? write(Data(password.utf8), account: account)
        } else {
            delete(account: account)
        }
    }

    // MARK: Host keys

    static func hostKey(_ hostPort: String) -> String? {
        (try? read(account: "hostkey." + hostPort)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    }

    static func setHostKey(_ line: String?, for hostPort: String) throws {
        let account = "hostkey." + hostPort
        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
    }

    // MARK: Keychain

    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private static func read(account: String) throws -> Data? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
        return out as? Data
    }

    /// Update in place, add only when missing: a failed write never loses the existing item.
    private static func write(_ data: Data, account: String) throws {
        let attrs: [String: Any] = [kSecValueData as String: data,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var q = query(account)
            for (k, v) in attrs { q[k] = v }
            status = SecItemAdd(q as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
    }

    private static func delete(account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}
import Foundation
import HerdrKit
import Citadel
import Crypto
import NIOCore
import NIOSSH

/// `ByteTransport` over an SSH exec channel (no PTY) running
/// `herdrConnectCommand`, via Citadel.
final class CitadelTransport: ByteTransport, @unchecked Sendable {
    enum Auth {
        case key(Curve25519.Signing.PrivateKey)
        case password(String)
    }

    let host: String, port: Int, user: String
    private let auth: Auth
    private let lock = NSLock()
    private var client: SSHClient?
    private var writer: TTYStdinWriter?
    private var task: Task<Void, Never>?
    private var closed = false
    private var onClose: (@Sendable (Error?) -> Void)?

    init(host: String, port: Int, user: String, auth: Auth) {
        self.host = host; self.port = port; self.user = user; self.auth = auth
    }

    func start(onBytes: @escaping @Sendable (Data) -> Void,
               onStderr: @escaping @Sendable (Data) -> Void,
               onClose: @escaping @Sendable (Error?) -> Void) async throws {
        let method: SSHAuthenticationMethod = switch auth {
        case .key(let k): .ed25519(username: user, privateKey: k)
        case .password(let p): .passwordBased(username: user, password: p)
        }
        let client: SSHClient
        do {
            client = try await SSHClient.connect(
                host: host, port: port, authenticationMethod: method,
                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
                reconnect: .never, connectTimeout: .seconds(12))
        } catch {
            throw Self.friendly(error, host: host, user: user)
        }
        let isClosed: Bool = lock.withLock {
            self.client = client; self.onClose = onClose; return closed
        }
        if isClosed { try? await client.close(); throw HerdrError(code: -1, kind: "closed", message: "Disconnected") }

        // The exec channel lives in this task; `start` returns once stdin is writable.
        try await withCheckedThrowingContinuation { (ready: CheckedContinuation<Void, Error>) in
            let readyOnce = Once(ready)
            let t = Task.detached { [weak self] in
                var failure: Error?
                do {
                    try await client.withExec(herdrConnectCommand) { inbound, outbound in
                        self?.lock.withLock { self?.writer = outbound }
                        readyOnce.resume(.success(()))
                        for try await out in inbound {
                            switch out {
                            case .stdout(let b): onBytes(Data(b.readableBytesView))
                            case .stderr(let b): onStderr(Data(b.readableBytesView))
                            }
                        }
                    }
                } catch let e as SSHClient.CommandFailed where e.exitCode == 127 {
                    failure = HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine",
                                         hint: "install herdr-core in ~/.local/bin")
                } catch is CancellationError {
                } catch {
                    failure = error
                }
                readyOnce.resume(.failure(failure ?? HerdrError.lost))
                self?.finish(failure)
            }
            lock.withLock { task = t }
        }
    }

    func write(_ data: Data) async throws {
        guard let w = lock.withLock({ closed ? nil : writer }) else { throw HerdrError.lost }
        try await w.write(ByteBuffer(bytes: data))
    }

    func close() {
        let (t, c, cb): (Task<Void, Never>?, SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
            guard !closed else { return (nil, nil, nil) }
            closed = true
            defer { onClose = nil; writer = nil }
            return (task, client, onClose)
        }
        t?.cancel()
        if let c { Task.detached { try? await c.close() } }
        cb?(nil)
    }

    private func finish(_ err: Error?) {
        let (c, cb): (SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
            guard !closed else { return (nil, nil) }
            closed = true
            defer { onClose = nil; writer = nil }
            return (client, onClose)
        }
        if let c { Task.detached { try? await c.close() } }
        cb?(err)
    }

    /// SSH failures in words a person can act on.
    static func friendly(_ error: Error, host: String, user: String) -> Error {
        if error is HostKeys.Mismatch || error is HostKeys.Unknown { return error }
        if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
            return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
                              hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
        }
        let text = String(describing: error)
        if text.contains("connectTimeout") || text.contains("timeout") || text.contains("Timeout") {
            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "is Tailscale connected?")
        }
        if text.contains("connectionRefused") || text.contains("Connection refused") {
            return HerdrError(code: -1, kind: "unreachable", message: "\(host) refused the SSH connection", hint: "is sshd running on port 22?")
        }
        if text.contains("NIOConnectionError") || text.contains("unreachable") || text.contains("resolve") {
            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "check the address and your network")
        }
        return HerdrError(code: -1, kind: "ssh", message: "SSH to \(host) failed", hint: text)
    }
}

/// Resumes a continuation at most once.
private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var cont: CheckedContinuation<Void, Error>?
    init(_ c: CheckedContinuation<Void, Error>) { cont = c }
    func resume(_ r: Result<Void, Error>) {
        let c: CheckedContinuation<Void, Error>? = lock.withLock { defer { cont = nil }; return cont }
        c?.resume(with: r)
    }
}

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
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '120,245p' App/Sources/Store/AppStore.swift; sed -n '470,590p' App/Sources/Store/AppStore.swift; cat App/Sources/UI/RootView.swift App/Sources/UI/SettingsView.swift; sed -n '340,415p' App/Sources/UI/MainView.swift; sed -n '230,330p' App/Sources/UI/ConnectionViews.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
            if client == nil || self.phase != .connected {
                attempt = 0
                startConnect(m, reconnecting: hello != nil)
            } else {
                // The socket may have died while suspended: probe it now rather than waiting for liveness.
                let gen = generation
                Task { [weak self] in
                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
                        guard let self, gen == self.generation, self.wantConnected else { return }
                        self.connectionLost(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: "no answer after resuming"), gen: gen)
                    }
                }
            }
        case .background:
            sceneActive = false
            saveAttentionNow()
            guard client != nil, backgroundTask == nil else { return }
            // iOS kills sockets in the background: close cleanly after a short grace.
            let bgID = UIApplication.shared.beginBackgroundTask(withName: "herdr.disconnect")
            backgroundTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(8))
                if !Task.isCancelled, let self, !self.sceneActive { self.dropConnection(phase: .idle) }
                UIApplication.shared.endBackgroundTask(bgID)
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func connect(to machine: MachineConfig) {
        if !machines.contains(where: { $0.id == machine.id }) { machines.append(machine) }
        if activeMachineID != machine.id {
            dropConnection(phase: .idle)
            activeMachineID = machine.id
            clearLiveState()
            loadMachineState()
        }
        wantConnected = true
        attempt = 0
        startConnect(machine, reconnecting: false)
    }

    func reconnect() {
        guard let m = currentMachine() else { return }
        wantConnected = true
        attempt = 0
        startConnect(m, reconnecting: hello != nil)
    }

    func disconnect() {
        wantConnected = false
        dropConnection(phase: .idle)
    }

    func saveMachine(_ m: MachineConfig, password: String?) {
        let old = machines.first { $0.id == m.id }
        if let i = machines.firstIndex(where: { $0.id == m.id }) { machines[i] = m } else { machines.append(m) }
        if let password { KeyStore.setPassword(password, for: m.id) }
        if activeMachineID == nil { activeMachineID = m.id }
        // Changed where/how we connect: reconnect with the new settings.
        if m.id == activeMachineID, let old, old != m, wantConnected { connect(to: m) }
    }

    func removeMachine(_ id: UUID) {
        guard let m = machines.first(where: { $0.id == id }) else { return }
        if id == activeMachineID {
            disconnect()
            clearLiveState()
            activeMachineID = machines.first { $0.id != id }?.id
        }
        machines.removeAll { $0.id == id }
        KeyStore.setPassword(nil, for: id)
        HostKeys.forget(host: m.host, port: m.port)
        for k in ["attention.", "view.", "home."] { defaults.removeObject(forKey: k + id.uuidString) }
    }

    /// The app's own SSH public key, OpenSSH one-line form ("ssh-ed25519 AAAA... herdr-ios").
    func publicKeyLine() -> String {
        if let k = cachedPublicKey { return k }
        let k = KeyStore.publicKeyLine()
        if !k.isEmpty { cachedPublicKey = k }
        return k
    }

    /// Replace the app key with a pasted OpenSSH ed25519 private key.
    func importPrivateKey(_ text: String) throws {
        try KeyStore.importPrivateKey(text)
        cachedPublicKey = nil
    }

    /// Forget a machine's pinned host key (after a legitimate reinstall).
    func forgetHostKey(_ machine: MachineConfig) { HostKeys.forget(host: machine.host, port: machine.port) }

    /// The pinned host key fingerprint (SHA256:…), nil before the first connect.
    func hostKeyFingerprint(_ machine: MachineConfig) -> String? { HostKeys.pinnedFingerprint(host: machine.host, port: machine.port) }

    /// The last connect failed because the host key changed.
    private(set) var hostKeyMismatch = false

    /// The last connect stopped at a host seen for the first time; its key waits for approval.
    private(set) var unknownHostKey: HostKeys.Unknown?

    /// Pins the approved first-seen host key and connects again.
    func trustHostKey(_ key: HostKeys.Unknown) {
        do {
            try HostKeys.pin(key.line, host: key.host, port: key.port)
        } catch {
            phase = .failed("Couldn't save the host key: \(error.localizedDescription)")
            return
        }
        unknownHostKey = nil
        reconnect()
    }

    /// Pull-to-refresh / screens that want a step index rather than text.
    /// 0 SSH, 1 starting core, 2 hello, 3 events + layout; -1 when not connecting.
    private(set) var connectStep = -1

    // MARK: Derived views

    func spaceName(_ s: SpaceRef) -> String {
        let first = s.tabs.lazy.flatMap(\.panes).compactMap(\.terminal).first
        return Names.spaceName(s, firstTerminalCwd: first.flatMap { terminals[$0]?.cwd }.flatMap { $0.isEmpty ? nil : $0 }, home: home)
    }
        reconnectTask?.cancel(); reconnectTask = nil
        connectTask?.cancel()
        teardownClient()
        generation += 1
        let gen = generation
        // Synchronously, so no frame shows the idle/failure screen before the task runs.
        connectStep = 0
        phase = .connecting(reconnecting ? "Reconnecting to \(m.host)" : "Opening SSH to \(m.host)")
        connectTask = Task { [weak self] in await self?.runConnect(m, gen: gen, reconnecting: reconnecting) }
    }

    private func step(_ s: String, _ index: Int, _ gen: Int) -> Bool {
        guard gen == generation, !Task.isCancelled else { return false }
        connectStep = index
        phase = .connecting(s)
        return true
    }

    private func runConnect(_ m: MachineConfig, gen: Int, reconnecting: Bool) async {
        let verb = reconnecting ? "Reconnecting" : "Opening SSH"
        guard step("\(verb) to \(m.host)", 0, gen) else { return }
        let auth: CitadelTransport.Auth
        do {
            if m.usePassword, let pw = KeyStore.password(for: m.id) { auth = .password(pw) } else { auth = .key(try KeyStore.signingKey()) }
        } catch {
            fail(error, gen: gen, retry: false); return
        }
        let transport = CitadelTransport(host: m.host, port: m.port, user: m.user, auth: auth)
        let c = HerdrClient(transport: transport)
        c.onDisconnect = { [weak self] err in self?.connectionLost(err, gen: gen) }
        client = c
        do {
            _ = step("Starting herdr-core", 1, gen)
            let info = try await c.connect()
            guard gen == generation else { c.close(); return }
            hello = info
            diagnostics = ""

            guard step("Subscribing to events", 2, gen) else { return }
            let sub = try await c.subscribe()
            guard gen == generation else { return }
            wire(sub, gen: gen)
            absorbSnapshot(sub.snapshot)

            guard step("Reading the layout", 3, gen) else { return }
            let d = try await c.docGet(HerdrKit.Layout.docName)
            guard gen == generation else { return }
            applyDoc(d)

            phase = .connected
            connectStep = -1
            hostKeyMismatch = false
            unknownHostKey = nil
            attempt = 0
            Task { [weak self] in await self?.learnHome(gen: gen) }
        } catch {
            guard gen == generation else { return }
            diagnostics = c.stderrText
            fail(error, gen: gen, retry: Self.isRetryable(error))
        }
    }

    private static func isRetryable(_ error: Error) -> Bool {
        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return false }
        if let e = error as? HerdrError, ["auth", "needs_update", "not_installed"].contains(e.kind ?? "") { return false }
        return true
    }

    private func fail(_ error: Error, gen: Int, retry: Bool) {
        guard gen == generation else { return }
        teardownClient()
        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
        hostKeyMismatch = error is HostKeys.Mismatch
        unknownHostKey = error as? HostKeys.Unknown
        connectStep = -1
        phase = .failed((error as? LocalizedError)?.errorDescription ?? "\(error)")
        // Only keep trying on our own when there's a session to get back to.
        if retry, wantConnected, hello != nil { scheduleReconnect() }
    }

    private func connectionLost(_ error: HerdrError, gen: Int) {
        // Only a live session is "lost": while connecting, runConnect's catch owns the error
        // (otherwise a non-retryable failure would be replaced by an endless "Reconnecting").
        guard gen == generation, phase == .connected else { return }
        teardownClient()
        alertsArmed = false
        guard wantConnected else { phase = .idle; return }
        connectStep = 0
        phase = .connecting("Reconnecting")
        if sceneActive { scheduleReconnect(immediate: attempt == 0) }
    }

    private func scheduleReconnect(immediate: Bool = false) {
        guard wantConnected, sceneActive, let m = currentMachine() else { return }
        reconnectTask?.cancel()
        let delay = immediate ? 0.3 : min(15, pow(2, Double(min(attempt, 4))))   // 1, 2, 4, 8, 15 s
        attempt += 1
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, self.wantConnected, self.sceneActive else { return }
            self.startConnect(m, reconnecting: true)
        }
    }

    /// Closes the connection quietly (no reconnect from its callbacks).
    private func dropConnection(phase newPhase: ConnectionPhase) {
        generation += 1
        connectTask?.cancel(); connectTask = nil
        reconnectTask?.cancel(); reconnectTask = nil
        teardownClient()
        alertsArmed = false
        connectStep = -1
        phase = newPhase
    }

    private func teardownClient() {
        subscription?.onUpdate = nil; subscription?.onClose = nil; subscription?.onLost = nil
        subscription = nil
        if let c = client { c.onDisconnect = nil; c.close() }
        client = nil
    }
import SwiftUI
import HerdrKit

struct RootView: View {
    @Environment(AppStore.self) private var store
    @AppStorage("appearance") private var appearance = "system"

    private enum Stage: Equatable { case onboarding, connecting, failed, main }

    /// Once we have a live picture of the box, keep showing it through
    /// reconnects (a banner says what's happening) instead of a blank screen.
    private var stage: Stage {
        if store.machines.isEmpty && store.terminals.isEmpty { return .onboarding }
        let hadSession = store.hello != nil || !store.terminals.isEmpty
        switch store.phase {
        case .connected: return .main
        case .connecting: return hadSession ? .main : .connecting
        // A first-seen host key needs the approval card on the failure screen even mid-session.
        case .failed: return hadSession && store.unknownHostKey == nil ? .main : .failed
        // Idle with nothing to show (e.g. Cancel on the connecting screen): the
        // failure screen offers Connect and Edit machine instead of a dead spinner.
        case .idle: return hadSession ? .main : .failed
        }
    }

    var body: some View {
        ZStack {
            HC.canvas.ignoresSafeArea()
            switch stage {
            case .onboarding: OnboardingView()
            case .connecting: ConnectingView()
            case .failed: FailureView()
            case .main: MainView()
            }
        }
        .animation(.smooth(duration: 0.3), value: stage)
        .overlay(alignment: .top) { ToastOverlay() }
        .sensoryFeedback(trigger: blockedCount) { old, new in new > old ? .warning : nil }
        .tint(HC.accent)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .task {
            #if DEBUG
            if AppStore.isDemo { store.loadDemo(); return }
            #endif
            if store.phase == .idle, let m = store.activeMachine { store.connect(to: m) }
        }
    }

    /// Cheap: no names or pane index, just the attention words.
    private var blockedCount: Int {
        store.terminals.values.lazy.filter { $0.isLive && $0.parent == nil && store.attention(of: $0.address) == .blocked }.count
    }
}

// MARK: Toasts

struct ToastOverlay: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(store.toasts.suffix(3)) { toast in
                    ToastCapsule(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task {
                            try? await Task.sleep(for: .seconds(toast.duration ?? (toast.level == "error" ? 6 : 3.5)))
                            withAnimation(.smooth) { store.toasts.removeAll { $0.id == toast.id } }
                        }
                        .onTapGesture {
                            withAnimation(.smooth) { store.toasts.removeAll { $0.id == toast.id } }
                            // An agent alert opens that agent.
                            if let a = toast.address { store.pendingOpen = a }
                        }
                        .accessibilityAddTraits(toast.address != nil ? .isButton : [])
                        .accessibilityHint(toast.address != nil ? "Opens the agent" : "")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .animation(.spring(duration: 0.35), value: store.toasts)
    }
}

private struct ToastCapsule: View {
    var toast: AppStore.Toast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint).font(.system(size: 15, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title).font(HF.ui(14.5, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
                if let body = toast.body, !body.isEmpty {
                    Text(body).font(HF.ui(12.5)).foregroundStyle(HC.muted).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: 440)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch toast.level {
        case "error": "exclamationmark.triangle.fill"
        case "warning", "blocked": "hand.raised.fill"
        case "success", "done": "checkmark.circle.fill"
        default: "bell.fill"
        }
    }
    private var tint: Color {
        switch toast.level {
        case "error", "warning", "blocked": HC.blocked
        case "success", "done": HC.done
        default: HC.accent
        }
    }
}
import SwiftUI
import UIKit
import HerdrKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("terminalFontSize") private var fontSize = 13.0
    @State private var editing: MachineConfig?
    @State private var confirmForget: MachineConfig?

    var body: some View {
        NavigationStack {
            Form {
                Section("Machines") {
                    ForEach(store.machines) { m in
                        HStack(spacing: 12) {
                            Image(systemName: "server.rack").foregroundStyle(HC.muted).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.label).font(HF.ui(15.5, .medium)).foregroundStyle(HC.fg)
                                Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(11.5)).foregroundStyle(HC.dim)
                            }
                            Spacer()
                            if m.id == store.activeMachine?.id { ConnectionDot(phase: store.phase) }
                        }
                        .contentShape(.rect)
                        .onTapGesture { editing = m }
                        .swipeActions {
                            Button("Remove", role: .destructive) { store.removeMachine(m.id) }
                            if m.id != store.activeMachine?.id || store.phase != .connected {
                                Button("Connect") { store.connect(to: m) }.tint(HC.accent)
                            }
                        }
                    }
                    Button { editing = MachineConfig(label: "", host: "", user: "") } label: {
                        Label("Add machine", systemImage: "plus")
                    }
                    if store.phase == .connected {
                        Button("Disconnect", role: .destructive) { store.disconnect() }
                    } else if store.activeMachine != nil {
                        Button("Reconnect") { store.reconnect() }
                    }
                    if let m = store.activeMachine, let fp = store.hostKeyFingerprint(m) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Host key").font(HF.ui(13, .medium)).foregroundStyle(HC.muted)
                            Text(fp).font(HF.mono(11)).foregroundStyle(HC.fg).textSelection(.enabled).lineLimit(2)
                        }
                        Button("Forget host key", role: .destructive) { confirmForget = m }
                    }
                }
                .confirmationDialog("Forget the host key?", isPresented: Binding(get: { confirmForget != nil }, set: { if !$0 { confirmForget = nil } }),
                                    titleVisibility: .visible, presenting: confirmForget) { m in
                    Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
                } message: { m in
                    Text("Only after \(m.host) was reinstalled. The next key it presents will be trusted and pinned.")
                }

                NotificationSection()

                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Graphite (dark)").tag("dark")
                        Text("Paper (light)").tag("light")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Stepper(value: $fontSize, in: 9...20, step: 1) {
                            HStack {
                                Text("Terminal text")
                                Spacer()
                                Text("\(Int(fontSize)) pt").foregroundStyle(HC.muted).monospacedDigit()
                            }
                        }
                        Text("The quick brown fox → 0123 {}[]")
                            .font(HF.mono(fontSize))
                            .foregroundStyle(HC.fg)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    Text("Terminals mirror the desktop's size and scale down to fit (min 7 pt). Pinch to zoom; use Fit to phone in a terminal's menu to resize the program instead.")
                        .font(HF.ui(12.5)).foregroundStyle(HC.dim)
                }

                ModSettingsView()

                Section("About") {
                    LabeledContent("Herdr for iOS", value: appVersion)
                    if let h = store.hello {
                        LabeledContent("Core", value: h.coreName)
                        LabeledContent("herdr-core", value: h.version)
                        LabeledContent("Core id", value: String(h.coreID.prefix(12)))
                    } else {
                        LabeledContent("Core", value: "Not connected")
                    }
                    NavigationLink("Licenses") { LicensesView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HC.canvas)
            .font(HF.ui(15.5))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done", systemImage: "checkmark") { dismiss() } }
            }
            .sheet(item: $editing) { m in
                NavigationStack {
                    ScrollView { MachineForm(machine: m).padding(16) }
                        .background(HC.canvas)
                        .navigationTitle(m.host.isEmpty ? "Add machine" : m.label)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = nil } } }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}

struct LicensesView: View {
    private struct Entry: Identifiable { var id: String { title }; var title: String; var text: String }

    private var entries: [Entry] {
        func file(_ name: String, _ ext: String) -> String? {
            Bundle.main.url(forResource: name, withExtension: ext).flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        }
        func asset(_ name: String) -> String? {
            NSDataAsset(name: name).flatMap { String(data: $0.data, encoding: .utf8) }
        }
        return [
            file("OFL", "txt").map { Entry(title: "Geist (SIL OFL 1.1)", text: $0) },
            file("OFL-JetBrainsMono", "txt").map { Entry(title: "JetBrains Mono (SIL OFL 1.1)", text: $0) },
            file("LICENSE-SymbolsNerdFont", "txt").map { Entry(title: "Symbols Nerd Font (MIT)", text: $0) },
            asset("License-Lucide").map { Entry(title: "Lucide icons (ISC)", text: $0) },
            asset("License-LobeHub").map { Entry(title: "LobeHub icons (MIT)", text: $0) },
            Entry(title: "Brand marks", text: "Brand icons from Simple Icons (CC0 1.0). Agent and brand marks are trademarks of their owners."),
            Entry(title: "SwiftTerm (MIT)", text: "SwiftTerm by Miguel de Icaza. https://github.com/migueldeicaza/SwiftTerm"),
            Entry(title: "Citadel (MIT)", text: "Citadel by Orlandos. https://github.com/orlandos-nl/Citadel"),
        ].compactMap { $0 }
    }

    var body: some View {
        List(entries) { e in
            NavigationLink(e.title) {
                ScrollView {
                    Text(e.text).font(HF.mono(11.5)).foregroundStyle(HC.muted).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                }
                .background(HC.canvas)
                .navigationTitle(e.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HC.canvas)
        .navigationTitle("Licenses")
    }
}
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack").font(.system(size: 34, weight: .light)).foregroundStyle(HC.dim)
            Text(store.phase == .connected ? "No agents running" : "Waiting for \(store.machineTitle)")
                .font(HF.ui(16, .medium)).foregroundStyle(HC.muted)
            if store.phase == .connected {
                Button { nav.showNewAgent = true } label: { Label("Start an agent", systemImage: "plus") }
                    .buttonStyle(.glass).font(HF.ui(15, .medium))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// Shown above the lists while the connection isn't live.
struct ConnectionBanner: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        switch store.phase {
        case .connected:
            EmptyView()
        case .connecting(let step):
            HStack(spacing: 10) {
                Spinner(color: HC.working, size: 13)
                Text(step.isEmpty ? "Reconnecting…" : "\(step)…").font(HF.ui(14, .medium)).foregroundStyle(HC.fg)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .herdrCard()
            .padding(.top, 8)
        case .failed(let msg):
            failed(msg)
        case .idle:
            failed("Disconnected")
        }
    }

    private func failed(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.horizontal.circle").foregroundStyle(HC.blocked)
            Text(msg).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(2)
            Spacer()
            Button("Retry") { store.reconnect() }.buttonStyle(.glass).font(HF.ui(14, .semibold))
        }
        .padding(.leading, 14).padding(.trailing, 8).padding(.vertical, 8)
        .herdrCard()
        .padding(.top, 8)
    }
}

/// Floating glass bar: machine status on the left, New agent on the right.
private struct HomeBottomBar: View {
    @Environment(AppStore.self) private var store
    @Environment(Navigator.self) private var nav
    var model: HomeModel
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button { nav.showSettings = true } label: {
                    // Large text: drop the icon, then the name, then the agent count;
                    // "needs you" is the part worth keeping.
                    ViewThatFits(in: .horizontal) {
                        status(icon: true, name: true, count: true)
                        status(icon: false, name: true, count: true)
                        status(icon: false, name: false, count: true)
                        status(icon: false, name: false, count: model.blocked == 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 48)
                }
                .accessibilityLabel("\(store.machineTitle), \(summary)\(model.blocked > 0 ? ", \(model.blocked) need\(model.blocked == 1 ? "s" : "") you" : "")")
                .buttonStyle(.plain)
                .contentShape(.capsule)
struct FailureView: View {
    @Environment(AppStore.self) private var store
    @State private var editing = false
    @State private var confirmForget = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "bolt.horizontal.circle")
                    .font(.system(size: 44, weight: .light)).foregroundStyle(HC.blocked)
                    .padding(.top, 60)
                Text(store.phase == .idle ? "Not connected to \(store.machineTitle)" : "Couldn't reach \(store.machineTitle)")
                    .font(HF.ui(20, .semibold)).foregroundStyle(HC.fg)
                    .multilineTextAlignment(.center)
                if case .failed(let msg) = store.phase {
                    Text(msg).font(HF.ui(15)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
                }
                if let m = store.activeMachine {
                    Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(12.5)).foregroundStyle(HC.dim)
                }
                if !store.diagnostics.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Diagnostics").herdrSectionHeader()
                        ScrollView {
                            Text(store.diagnostics)
                                .font(HF.mono(11.5)).foregroundStyle(HC.muted)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 220)
                    }
                    .padding(14)
                    .herdrCard()
                }
                GlassEffectContainer {
                    HStack(spacing: 12) {
                        Button { editing = true } label: { Label("Edit machine", systemImage: "server.rack") }
                            .buttonStyle(.glass)
                        Button { store.reconnect() } label: {
                            Label(store.phase == .idle ? "Connect" : "Retry", systemImage: "arrow.clockwise").padding(.horizontal, 8)
                        }
                        .buttonStyle(.glassProminent)
                    }
                    .font(HF.ui(15.5, .semibold))
                    .controlSize(.large)
                }
                .padding(.top, 6)
                if let key = store.unknownHostKey {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New host key").font(HF.ui(15, .semibold))
                        Text(key.fingerprint)
                            .font(HF.mono(12.5))
                            .textSelection(.enabled)
                            .accessibilityIdentifier("hostKeyFingerprint")
                        Text("On \(key.host), compare it with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
                            .font(HF.ui(13)).foregroundStyle(HC.muted)
                        Button { store.trustHostKey(key) } label: {
                            Label("Trust and connect", systemImage: "checkmark.shield")
                        }
                        .buttonStyle(.glassProminent)
                        .font(HF.ui(15, .medium))
                    }
                    .padding(14)
                    .herdrCard()
                }
                if store.hostKeyMismatch, let m = store.activeMachine {
                    Button(role: .destructive) { confirmForget = true } label: {
                        Label("Forget host key", systemImage: "key.slash")
                    }
                    .buttonStyle(.glass)
                    .font(HF.ui(15, .medium))
                    .confirmationDialog("Forget \(m.host)'s host key?", isPresented: $confirmForget, titleVisibility: .visible) {
                        Button("Forget and reconnect", role: .destructive) {
                            store.forgetHostKey(m)
                            store.reconnect()
                        }
                    } message: {
                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; you will be asked to approve the key it presents next.")
                    }
                }
                Text("Check that the host is reachable (e.g. Tailscale is on), the key is in authorized_keys, and herdr-core is installed in ~/.local/bin.")
                    .font(HF.ui(13)).foregroundStyle(HC.dim).multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $editing) {
            NavigationStack {
                ScrollView { MachineForm(machine: store.activeMachine ?? MachineConfig()).padding(18) }
                    .background(HC.canvas)
                    .navigationTitle("Machine")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = false } } }
            }
            .presentationDetents([.large])
        }
    }
}

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "cat Herdr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; rg --files --hidden -g '*SSH*' -g '*KeyExchange*' -g '*ClientSession*' .build /Users/yosuke/Library/Developer/Xcode/DerivedData /Users/yosuke/Library/Caches/org.swift.swiftpm 2>/dev/null | head -65; rg -n 'request\\(|method:|requiredMethods|func hello' Packages/HerdrKit/Sources App/Sources; cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
{
  "originHash" : "f40fc65ed63759b13601b9712284e33271a401c8895b9ff4b27b1acb824e4f42",
  "pins" : [
    {
      "identity" : "bigint",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/attaswift/BigInt.git",
      "state" : {
        "revision" : "e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe",
        "version" : "5.7.0"
      }
    },
    {
      "identity" : "citadel",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/orlandos-nl/Citadel",
      "state" : {
        "revision" : "ae8562f895de06ccb86fdb1cbb65fd99c8976e12",
        "version" : "0.12.1"
      }
    },
    {
      "identity" : "swift-argument-parser",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-argument-parser",
      "state" : {
        "revision" : "6a52f3251125d74daf04fcbd5e6f08a75d074382",
        "version" : "1.8.2"
      }
    },
    {
      "identity" : "swift-asn1",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-asn1.git",
      "state" : {
        "revision" : "3b6410f7dee09eb33cdd26260c5fd47fda19b0e2",
        "version" : "1.7.3"
      }
    },
    {
      "identity" : "swift-atomics",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-atomics.git",
      "state" : {
        "revision" : "0442cb5a3f98ab802acb777929fdb446bda11a34",
        "version" : "1.3.1"
      }
    },
    {
      "identity" : "swift-collections",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-collections.git",
      "state" : {
        "revision" : "f96b909e1a9e469620bc5037c1e24e00153f376f",
        "version" : "1.7.5"
      }
    },
    {
      "identity" : "swift-crypto",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-crypto.git",
      "state" : {
        "revision" : "95ba0316a9b733e92bb6b071255ff46263bbe7dc",
        "version" : "3.15.1"
      }
    },
    {
      "identity" : "swift-log",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-log.git",
      "state" : {
        "revision" : "c9c6bb9d275ec0d95c3ad16391f3f045dc623104",
        "version" : "1.16.2"
      }
    },
    {
      "identity" : "swift-nio",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-nio.git",
      "state" : {
        "revision" : "6db9d9abd92ad7399b8a564cafbb87d3507245fa",
        "version" : "2.104.0"
      }
    },
    {
      "identity" : "swift-nio-ssh",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/Wellz26/swift-nio-ssh.git",
      "state" : {
        "revision" : "d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c",
        "version" : "0.3.7"
      }
    },
    {
      "identity" : "swift-system",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-system.git",
      "state" : {
        "revision" : "869129b7bf4ecc57b97d0193ad29690ca2134750",
        "version" : "1.8.1"
      }
    },
    {
      "identity" : "swiftterm",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/migueldeicaza/SwiftTerm",
      "state" : {
        "revision" : "5d14406844143538cd8f8851d2d8a67c1fe443e5",
        "version" : "1.20.0"
      }
    }
  ],
  "version" : 3
}
App/Sources/Store/AppStore.swift:435:    func call(_ method: String, _ params: JSONValue) async throws -> JSONValue {
App/Sources/Mods/ModEngine.swift:20:    var method: String
App/Sources/Mods/ModEngine.swift:197:                let req = ModFetchRequest(url: args["url"] as? String ?? "", method: args["method"] as? String ?? "GET",
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:28:    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:137:        let missing = requiredMethods.filter { !methods.contains($0) }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:166:    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:201:    public func notify(_ method: String, _ params: JSONValue = [:]) {
App/Sources/Net/CitadelTransport.swift:32:        let method: SSHAuthenticationMethod = switch auth {
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
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
MainActor 上の `resume()` と `wake = nil` の間には中断点がなく、通常の nudge で二重 resume は起きません。一方、`load()` 中の停止と再開で待機が重複する経路を確認中です。ホスト鍵については、失敗画面への遷移と SSH 依存ライブラリ内の認証開始条件を追っています。

hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg --files --hidden --no-ignore /Users/yosuke/Library/Developer/Xcode/DerivedData /Users/yosuke/Library/Caches/org.swift.swiftpm .build 2>/dev/null | rg '(Citadel|citadel|swift-nio-ssh).*(swift"'$)'"' | head -70; sed -n '345,405p' App/Sources/UI/MainView.swift; sed -n '1,75p' App/Sources/Chat/ChatView.swift; rg -n 'call\\(\"|notify\\(\"' Packages/HerdrKit/Sources App/Sources App/Resources; nl -ba App/Sources/Net/HostKeys.swift; nl -ba App/Sources/Net/KeyStore.swift | sed -n '90,165p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 2ms:
            if store.phase == .connected {
                Button { nav.showNewAgent = true } label: { Label("Start an agent", systemImage: "plus") }
                    .buttonStyle(.glass).font(HF.ui(15, .medium))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// Shown above the lists while the connection isn't live.
struct ConnectionBanner: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        switch store.phase {
        case .connected:
            EmptyView()
        case .connecting(let step):
            HStack(spacing: 10) {
                Spinner(color: HC.working, size: 13)
                Text(step.isEmpty ? "Reconnecting…" : "\(step)…").font(HF.ui(14, .medium)).foregroundStyle(HC.fg)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .herdrCard()
            .padding(.top, 8)
        case .failed(let msg):
            failed(msg)
        case .idle:
            failed("Disconnected")
        }
    }

    private func failed(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.horizontal.circle").foregroundStyle(HC.blocked)
            Text(msg).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(2)
            Spacer()
            Button("Retry") { store.reconnect() }.buttonStyle(.glass).font(HF.ui(14, .semibold))
        }
        .padding(.leading, 14).padding(.trailing, 8).padding(.vertical, 8)
        .herdrCard()
        .padding(.top, 8)
    }
}

/// Floating glass bar: machine status on the left, New agent on the right.
private struct HomeBottomBar: View {
    @Environment(AppStore.self) private var store
    @Environment(Navigator.self) private var nav
    var model: HomeModel
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button { nav.showSettings = true } label: {
                    // Large text: drop the icon, then the name, then the agent count;
                    // "needs you" is the part worth keeping.
                    ViewThatFits(in: .horizontal) {
                        status(icon: true, name: true, count: true)
import SwiftUI
import HerdrKit

/// An agent's conversation as native messages, read from its transcript.
/// Holds no terminal attach: nothing here types into or resizes the program
/// except Send, Stop and the blocked card's choices.
struct ChatView: View {
    let address: String
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ChatModel

    init(address: String) {
        self.address = address
        _model = State(initialValue: ChatModel(address: address))
    }

    var body: some View {
        let att = store.attention(of: address)
        let rec = store.terminals[address]
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                content(working: att == .working)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .scrollEdgeEffectStyle(.hard, for: .top)
        .scrollDismissesKeyboard(.interactively)
        .background(HC.canvas)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if att == .blocked { BlockedCard(address: address) }
                ChatComposer(address: address, working: att == .working)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .onAppear { model.start(store: store) }
        .onDisappear { model.stop() }
        .onChange(of: rec?.statusWord) { _, _ in model.nudge() }
        .onChange(of: rec?.turn) { _, _ in model.nudge() }
        .onChange(of: store.phase) { _, p in if p == .connected { model.nudge() } }
        .onChange(of: scenePhase) { _, p in if p == .active { model.nudge() } }
    }

    @ViewBuilder private func content(working: Bool) -> some View {
        switch model.phase {
        case .loading where model.turns.isEmpty:
            HStack(spacing: 10) { ProgressView(); Text("Reading the conversation…").foregroundStyle(HC.muted) }
                .font(HF.ui(14)).frame(maxWidth: .infinity).padding(.top, 60)
        case .unavailable(let why):
            emptyState("text.bubble", why, hint: "Switch to Terminal to see the screen.")
        case .failed(let why) where model.turns.isEmpty:
            emptyState("exclamationmark.triangle", "Couldn't read the conversation", hint: why)
        default:
            if model.hasEarlier {
                Label("Earlier messages are in the terminal's history", systemImage: "clock.arrow.circlepath")
                    .font(HF.ui(12.5)).foregroundStyle(HC.dim).frame(maxWidth: .infinity)
            }
            ForEach(model.turns) { turn in
                TurnView(turn: turn, isLast: turn.id == model.turns.last?.id, working: working)
            }
            if working { WorkingRow(since: model.turns.last?.startedAt) }
        }
    }

    private func emptyState(_ symbol: String, _ title: String, hint: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 28, weight: .light)).foregroundStyle(HC.dim)
            Text(title).font(HF.ui(15, .medium)).foregroundStyle(HC.fg).multilineTextAlignment(.center)
            Text(hint).font(HF.ui(13)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
Packages/HerdrKit/Sources/herdr-probe/main.swift:32:        let st = try await client.call("server.status")
Packages/HerdrKit/Sources/herdr-probe/main.swift:34:        let m = try await client.call("machine.list")
Packages/HerdrKit/Sources/herdr-probe/main.swift:80:        let rec = TerminalRecord(raw: try await client.call("terminal.get", ["terminal": .string(addr)]))
Packages/HerdrKit/Sources/herdr-probe/main.swift:115:        async let a = client.call("terminal.list", ["all": false])
Packages/HerdrKit/Sources/herdr-probe/main.swift:116:        async let b = client.call("server.status")
Packages/HerdrKit/Sources/herdr-probe/main.swift:120:        do { _ = try await client.call("terminal.get", ["terminal": "t99999"]) } catch let e as HerdrError {
App/Sources/Store/AppStore.swift:127:                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
App/Sources/Store/AppStore.swift:396:            _ = try await c.call("terminal.label", ["terminal": .string(terminal), "labels": ["herdr.space": "", "herdr.tab": ""]])
App/Sources/Store/AppStore.swift:397:            _ = try await c.call("terminal.keep", ["terminal": .string(terminal), "keep": false])
App/Sources/Store/AppStore.swift:401:            _ = try? await c.call("terminal.kill", ["terminal": .string(terminal)], timeout: 15)
App/Sources/Store/AppStore.swift:419:        _ = try await connectedClient().call("terminal.send", ["terminal": .string(address), "text": .string(text)], timeout: 15)
App/Sources/Store/AppStore.swift:422:        _ = try await connectedClient().call("terminal.keys", ["terminal": .string(address), "keys": .array(keys.map { .string($0) })])
App/Sources/Store/AppStore.swift:425:        _ = try await connectedClient().call("terminal.interrupt", ["terminal": .string(address), "timeout": 10], timeout: 20)
App/Sources/Store/AppStore.swift:428:        _ = try await connectedClient().call("terminal.kill", ["terminal": .string(address)], timeout: 20)
App/Sources/Store/AppStore.swift:762:        let r = try await c.call("terminal.run", [
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:195:                notify("$/cancelRequest", ["id": .number(Double(id))])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:233:        let r = try await call("doc.get", ["name": .string(name)])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:239:        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:244:        let r = try await call("terminal.list", ["all": .bool(all)])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:249:        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:261:        let r = try await call("terminal.attach", p)
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:283:        let r = try await call("events.subscribe", [:])
     1	import Foundation
     2	import Crypto
     3	import NIOCore
     4	import NIOSSH
     5	
     6	/// Host keys pinned per host:port in the Keychain, after the person approves the first one.
     7	enum HostKeys {
     8	    struct Mismatch: LocalizedError {
     9	        var host: String
    10	        var expected: String
    11	        var got: String
    12	        var errorDescription: String? {
    13	            "\(host)'s host key changed (was \(expected), now \(got)). If the machine was reinstalled, tap Forget host key; otherwise someone may be intercepting the connection."
    14	        }
    15	    }
    16	
    17	    /// A host seen for the first time. Nothing is pinned and no credentials were sent yet.
    18	    struct Unknown: LocalizedError, Equatable {
    19	        var host: String
    20	        var port: Int
    21	        var line: String
    22	        var fingerprint: String { HostKeys.fingerprint(line) }
    23	        var errorDescription: String? {
    24	            "First connection to \(host). Check its host key before trusting it: \(fingerprint)"
    25	        }
    26	    }
    27	
    28	    /// The pinned key's fingerprint, for display.
    29	    static func pinnedFingerprint(host: String, port: Int) -> String? {
    30	        pinned(host: host, port: port).map(fingerprint)
    31	    }
    32	
    33	    static func pinned(host: String, port: Int) -> String? { KeyStore.hostKey("\(host):\(port)") }
    34	
    35	    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }
    36	
    37	    static func pin(_ line: String, host: String, port: Int) throws {
    38	        try KeyStore.setHostKey(line, for: "\(host):\(port)")
    39	    }
    40	
    41	    /// `SHA256:<base64>` like ssh-keygen -l.
    42	    static func fingerprint(_ openSSHLine: String) -> String {
    43	        let parts = openSSHLine.split(separator: " ")
    44	        guard parts.count >= 2, let blob = Data(base64Encoded: String(parts[1])) else { return openSSHLine }
    45	        let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
    46	        return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
    47	    }
    48	
    49	    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
    50	    /// so the app can show the fingerprint and pin it on approval.
    51	    final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
    52	        let host: String, port: Int
    53	        init(host: String, port: Int) { self.host = host; self.port = port }
    54	
    55	        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
    56	            let line = String(openSSHPublicKey: hostKey)
    57	            if let known = HostKeys.pinned(host: host, port: port) {
    58	                if known == line {
    59	                    validationCompletePromise.succeed(())
    60	                } else {
    61	                    validationCompletePromise.fail(Mismatch(host: host, expected: HostKeys.fingerprint(known),
    62	                                                            got: HostKeys.fingerprint(line)))
    63	                }
    64	            } else {
    65	                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
    66	            }
    67	        }
    68	    }
    69	}
    90	            delete(account: account)
    91	        }
    92	    }
    93	
    94	    // MARK: Host keys
    95	
    96	    static func hostKey(_ hostPort: String) -> String? {
    97	        (try? read(account: "hostkey." + hostPort)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    98	    }
    99	
   100	    static func setHostKey(_ line: String?, for hostPort: String) throws {
   101	        let account = "hostkey." + hostPort
   102	        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
   103	    }
   104	
   105	    // MARK: Keychain
   106	
   107	    private static func query(_ account: String) -> [String: Any] {
   108	        [kSecClass as String: kSecClassGenericPassword,
   109	         kSecAttrService as String: service,
   110	         kSecAttrAccount as String: account]
   111	    }
   112	
   113	    private static func read(account: String) throws -> Data? {
   114	        var q = query(account)
   115	        q[kSecReturnData as String] = true
   116	        q[kSecMatchLimit as String] = kSecMatchLimitOne
   117	        var out: CFTypeRef?
   118	        let status = SecItemCopyMatching(q as CFDictionary, &out)
   119	        if status == errSecItemNotFound { return nil }
   120	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
   121	        return out as? Data
   122	    }
   123	
   124	    /// Update in place, add only when missing: a failed write never loses the existing item.
   125	    private static func write(_ data: Data, account: String) throws {
   126	        let attrs: [String: Any] = [kSecValueData as String: data,
   127	                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
   128	        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
   129	        if status == errSecItemNotFound {
   130	            var q = query(account)
   131	            for (k, v) in attrs { q[k] = v }
   132	            status = SecItemAdd(q as CFDictionary, nil)
   133	        }
   134	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
   135	    }
   136	
   137	    private static func delete(account: String) {
   138	        SecItemDelete(query(account) as CFDictionary)
   139	    }
   140	}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: https://raw.githubusercontent.com/orlandos-nl/Citadel/0.12.1/Sources/Citadel/SSHClient.swift
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "ls -a; ls /Users/yosuke/Library/Developer/Xcode/DerivedData; rg --files --hidden --no-ignore /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket | rg '(checkouts|Citadel|KeyExchange)' | head -35; sed -n '75,150p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; rg -n 'showSettings|sheet' App/Sources/UI/MainView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
.
..
.envrc
.git
.gitignore
.mcp.json
AGENTS.ja.md
AGENTS.md
App
Config
Herdr.xcodeproj
LICENSE
NOTICE
Packages
README.md
UITests
build
docs
nix
project.yml
scripts
CMAKE_TRY_COMPILE-apvibwssfvhlncbffpztucztzcdf
CMAKE_TRY_COMPILE-bedvsgkylcpqwreewpjpdyqlsxbv
CMAKE_TRY_COMPILE-bklavgnptpytpabtfrgdymgabsqk
CMAKE_TRY_COMPILE-bqncorfxoucuethibtrkqoeigjjp
CMAKE_TRY_COMPILE-btculpbmrqpmazexvrmhlbqfhbxg
CMAKE_TRY_COMPILE-btqkjcgwzjtzqwglbiimnfnbogpz
CMAKE_TRY_COMPILE-bxwwhcfxzmvgvleedghhgkstewoj
CMAKE_TRY_COMPILE-cvfeswdfmtaycraxhqghmlvjbmcr
CMAKE_TRY_COMPILE-cxtfxgaukuduaxggtjupppluduva
CMAKE_TRY_COMPILE-cxtmpyzntumgnhafuiehxrwksmxo
CMAKE_TRY_COMPILE-dtwiwjknunqwireygrwocmemcich
CMAKE_TRY_COMPILE-erbkmnrfaacdjxfstgjlqvjivfsn
CMAKE_TRY_COMPILE-erjnghfkkpqougbinjeafbxmoyjr
CMAKE_TRY_COMPILE-etklpdfpbayxnmdiipglcjbhklie
CMAKE_TRY_COMPILE-ffgqapqugsnflrgjjewukkidtbqu
CMAKE_TRY_COMPILE-fqwbbjuqmgiyifdptfgxuqduzinb
CMAKE_TRY_COMPILE-ftwntwzhzylkqjhlacbnpxxzsett
CMAKE_TRY_COMPILE-fuxxwvanqzootleiwnnllaifxqog
CMAKE_TRY_COMPILE-fvgfprddiulrnocmitnursycxqez
CMAKE_TRY_COMPILE-gwxckzgyvbxilqategxqljgictnq
CMAKE_TRY_COMPILE-hejsrjqlhzeuxzdfzkywuaullspk
CMAKE_TRY_COMPILE-hhbouzntyjfcdcfekksdforvwtck
CompilationCache.noindex
CompilerIdC-bitsdphztjldarfnmmvscoxvgdqv
CompilerIdC-fhreoadwagrlvlecmdjoqrkjzamr
CompilerIdCXX-ezrajrigunjchgdhsnhsqobzkqbx
CompilerIdCXX-famtxtipoggnybadlbvfbfcvxauv
Files-gjzdlalvtsxajjekynugszssfivo
ModuleCache.noindex
SymbolCache.noindex
llama.swiftui-djtdmicsuitysjcazchidxyswoqr
lmac_wasm-gtkldeigizlkobcuhokvoivdvwvi
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/CitadelTransport.swift
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/packed-refs
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/Citadel.o
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/push-to-checkout.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/update.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-push.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-applypatch.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-merge-commit.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/post-update.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/prepare-commit-msg.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-receive.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/fsmonitor-watchman.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/applypatch-msg.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-commit.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/sendemail-validate.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-rebase.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/commit-msg.sample
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/description
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/info/exclude
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/HEAD
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/objects/pack/pack-2676a512b6635e77be649b0e24649d694134cd14.pack
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/objects/pack/pack-2676a512b6635e77be649b0e24649d694134cd14.rev
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/objects/pack/pack-2676a512b6635e77be649b0e24649d694134cd14.idx
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/config
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/CCitadelBcrypt.o
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/SendsKeyExchangeMessages.o-3AR1R8E1ARYMT
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/SSHKeyExchangeStateMachine.o-U40AO2TZ70A9
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/AcceptsKeyExchangeMessages.o-3EXJOWSBYXYU0
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/CitadelTransport.o-2G77RSXKLR280
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/EllipticCurveKeyExchange.o-1H1TOVVIOPCJD
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/CCitadelBcrypt-85FM0MKBFNVQPMHRZGHB4I1DR.pcm-HUYFJ9TDWR4R
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/KeyExchangeState.o-3TZCZDA2TGIDH
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/SSHKeyExchangeResult.o-FJRY5TB9O3R7
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/Citadel.swiftmodule/arm64-apple-ios-simulator.swiftdoc
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/Citadel.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo
            guard mode == .idle else { return false }
            mode = .plain; lastReceive = Date(); return true
        }
        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }

        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
            for await chunk in outStream {
                do { try await transport.write(chunk) } catch {
                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
                    return
                }
            }
        }

        try await transport.start(
            onBytes: { [weak self] in self?.receive($0) },
            onStderr: { [weak self] d in self?.lock.withLock {
                guard let self, self.stderrBuf.count < 16_384 else { return }
                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
            } },
            onClose: { [weak self] err in self?.transportClosed(err) })

        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
            let alreadyClosed: Bool = lock.withLock {
                if mode == .closed { return true }
                helloCont = cont; return false
            }
            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
                    defer { self.helloCont = nil }; return self.helloCont
                }) else { return }
                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
                                              hint: self.stderrText.trimmed.nilIfEmpty))
                self.close()
            }
        }
        do {
            let info = try Self.check(hello: reply)
            lock.withLock { hello = info }
            startLiveness()
            return info
        } catch {
            close()
            throw error
        }
    }

    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
    public static func check(hello reply: JSONValue) throws -> HelloInfo {
        if !reply["error"].isNull { throw rpcError(reply["error"]) }
        let r = reply["result"]
        let gen = r["generation"].uint64 ?? 0
        let version = r["version"].string ?? "0"
        if gen > generation {
            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
        }
        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
        }
        let methods = r["methods"].array?.compactMap(\.string) ?? []
        let missing = requiredMethods.filter { !methods.contains($0) }
        if !missing.isEmpty {
            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
        }
        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
                         version: version, methods: methods)
    }

    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }

    static func semver(_ v: String) -> [Int] {
        var s = v.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("hc ") { s.removeFirst(3) }
        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
18:    var showSettings = false
60:        .sheet(isPresented: $nav.showNewAgent) {
65:        .sheet(isPresented: $nav.showSettings) { SettingsView() }
66:        .sheet(item: $nav.modSheet) { mod in ModFullSheet(mod: mod) }
70:            nav.showNewAgent = false; nav.showSettings = false; nav.modSheet = nil
81:    /// HERDR_DEBUG_OPEN_MOD=<mod> (full sheet of a mod)
88:            if target == "settings" { nav.showSettings = true }
214:                Button { nav.showSettings = true } label: { Image(systemName: "gearshape") }
401:                Button { nav.showSettings = true } label: {

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "ls build/dd/SourcePackages/checkouts; rg -n 'validateHostKey|validationCompletePromise|flatMap|newKeys' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key\\ Exchange/SSHKeyExchangeStateMachine.swift; rg -n 'errorCaught|connect\\(|authentication|promise|timeout' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/{Client.swift,SSHClient.swift,ClientSession.swift}" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 exited 2 in 0ms:
BigInt
Citadel
SwiftTerm
swift-argument-parser
swift-asn1
swift-atomics
swift-collections
swift-crypto
swift-log
swift-nio
swift-nio-ssh
swift-system
59:        /// We have received the remote peer's newKeys message, and are waiting to send our own.
60:        case newKeysReceived(result: KeyExchangeResult, protection: NIOSSHTransportProtection, negotiated: NegotiationResult)
62:        /// We have sent our newKeys message, and are waiting to receive the remote peer's.
63:        case newKeysSent(result: KeyExchangeResult, protection: NIOSSHTransportProtection, negotiated: NegotiationResult)
180:        case .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
203:        case .keyExchangeSent, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
231:                return SSHMultiMessage(message, .newKeys)
233:        case .idle, .keyExchangeSent, .keyExchangeReceived, .keyExchangeInitReceived, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
243:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keyExchangeInitReceived, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
296:                            validationCompletePromise: promise
299:                            SSHMultiMessage(SSHMessage.newKeys)
308:                    clientConfig.serverAuthDelegate.validateHostKey(hostKey: message.hostKey, validationCompletePromise: promise)
310:                        SSHMultiMessage(SSHMessage.newKeys)
316:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
328:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
337:            self.state = .newKeysReceived(result: result, protection: protection, negotiated: negotiated)
339:        case .newKeysSent(result: let result, protection: let protection, _):
342:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keyExchangeInitReceived, .newKeysReceived, .complete:
350:            self.state = .newKeysSent(result: result, protection: protection, negotiated: negotiated)
352:        case .newKeysReceived(result: let result, protection: let protection, _):
355:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keyExchangeInitReceived, .newKeysSent, .complete:
517:            return configuration.hostKeys.flatMap { $0.hostKeyAlgorithms }
585:             .newKeysSent(result: let result, _, _),
586:             .newKeysReceived(result: let result, _, _),
606:             .newKeysReceived(_, _, negotiated: let negotiated),
607:             .newKeysSent(_, _, negotiated: let negotiated):
rg: build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHClient.swift: No such file or directory (os error 2)
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:115:    let authenticationMethod: () -> SSHAuthenticationMethod
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:133:        authenticationMethod: @escaping @autoclosure () -> SSHAuthenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:139:        self.authenticationMethod = authenticationMethod
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:147:    public func onDisconnect(perform onDisconnect: @escaping @Sendable () -> ()) {
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:154:    public static func connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:157:        let session = try await SSHClientSession.connect(settings: settings)
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:161:            authenticationMethod: settings.authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:171:    public static func connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:190:            authenticationMethod: settings.authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:222:            authenticationMethod: settings.authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:232:    /// - authenticationMethod: The authentication method to use. See `SSHAuthenticationMethod` for more information.
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:237:    public static func connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:239:        authenticationMethod: @escaping @autoclosure () -> SSHAuthenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:247:            authenticationMethod: authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:258:            authenticationMethod: authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:269:    /// - authenticationMethod: The authentication method to use. See `SSHAuthenticationMethod` for more information.
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:278:    public static func connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:281:        authenticationMethod: SSHAuthenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:290:        let session = try await SSHClientSession.connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:293:            authenticationMethod: authenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:304:            authenticationMethod: authenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:356:        self.session = try await SSHClientSession.connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:359:            authenticationMethod: self.authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:68:    private let promise: EventLoopPromise<Void>
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:73:        promise.futureResult
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:77:        let promise = eventLoop.makePromise(of: Void.self)
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:78:        self.promise = promise
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:81:            promise.fail(ChannelError.connectTimeout(loginTimeout))
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:87:            self.promise.succeed(())
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:91:    func errorCaught(context: ChannelHandlerContext, error: any Error) {
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:92:        self.promise.fail(error)
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:97:        self.promise.fail(Disconnected())
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:104:    public var authenticationMethod: @Sendable () -> SSHAuthenticationMethod
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:115:        authenticationMethod: @Sendable @escaping () -> SSHAuthenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:120:        self.authenticationMethod = authenticationMethod
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:137:    /// - authenticationMethod: The authentication method to use, see `SSHAuthenticationMethod`.
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:144:        authenticationMethod: @escaping @Sendable @autoclosure () -> SSHAuthenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:156:                authenticationMethod: authenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:175:            userAuthDelegate: settings.authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:204:    static func connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:210:            userAuthDelegate: settings.authenticationMethod(),
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:228:        return try await bootstrap.connect(host: settings.host, port: settings.port).flatMap { channel in
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:243:    /// - authenticationMethod: The authentication method to use, see `SSHAuthenticationMethod`.
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:250:    static func connect(
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:253:        authenticationMethod: @Sendable @escaping @autoclosure () -> SSHAuthenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:264:            authenticationMethod: authenticationMethod,
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:274:        return try await connect(

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '45,78p' App/Sources/UI/MainView.swift; rg -n 'func exec|withTaskCancellation|onCancel' App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; rg --files --hidden --no-ignore build/dd/SourcePackages/checkouts/Citadel/Sources | head -40; rg -n 'validationCompletePromise|validateHostKey' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
                SplitMain()
            } else {
                NavigationStack(path: $nav.path) {
                    HomeView()
                        .navigationDestination(for: Route.self) { RouteView(route: $0) }
                }
            }
        }
        .environment(nav)
        .onChange(of: hsc, initial: true) { _, v in
            nav.split = v == .regular
            // Carry the visible screen across a size-class change.
            if nav.split, let last = nav.path.last { nav.selection = last; nav.path = [] }
            else if !nav.split, let sel = nav.selection, nav.path.isEmpty { nav.path = [sel] }
        }
        .sheet(isPresented: $nav.showNewAgent) {
            NewAgentSheet(initialSpace: nav.newAgentSpace) { addr in
                nav.openNew(terminal: addr)
            }
        }
        .sheet(isPresented: $nav.showSettings) { SettingsView() }
        .sheet(item: $nav.modSheet) { mod in ModFullSheet(mod: mod) }
        .onChange(of: store.pendingOpen, initial: true) { _, a in
            guard let a else { return }
            store.pendingOpen = nil
            nav.showNewAgent = false; nav.showSettings = false; nav.modSheet = nil
            if nav.split ? nav.selection != .terminal(a) : nav.path.last != .terminal(a) { nav.open(.terminal(a)) }
        }
        #if DEBUG
        .task(id: store.spaces.isEmpty) { debugOpen() }
        #endif
    }

    #if DEBUG
App/Sources/Store/AppStore.swift:432:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:170:        return try await withTaskCancellationHandler {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:188:        } onCancel: {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt.h
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/blf.c
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt-kdf.c
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt.c
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt-kdf.h
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/blf.h
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ChannelUnwrapper.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/OpenSSHKey.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Errors.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/BasicCommands.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/include/module.modulemap
build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/Extensions.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/Terminal.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/EchoShell.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/Server.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/HostKeyFile.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/NIOGlueHandler.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/RemotePortForward/Client/RemotePortForward+Client.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPFileFlags.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/TTY/Client/TTY.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHConnectionPoolSettings.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/BCrypt.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPSerializer.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/RemotePortForward/Server/RemotePortForward+Server.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHAuthenticationMethod.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Client/SFTPClientInboundHandler.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Client/SFTPFile.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Client/SFTPClient.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPBasicEnums.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPMessageParser.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/DirectTCPIP/Client/DirectTCPIP+Client.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Exec/Client/ExecClient.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Server/SFTPServerInboundHandler.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Server/SFTPServer.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPMessage.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Server.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ByteBufferHelpers.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHCert.swift
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHPerformanceTester/shared.swift:92:    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHPerformanceTester/shared.swift:93:        validationCompletePromise.succeed(())
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:24:    /// Invoked to validate a specific host key. Implementations should succeed the `validationCompletePromise`
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:29:    ///      - validationCompletePromise: A promise that must be succeeded or failed based on whether the host key is trusted.
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:30:    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:35:    /// The default implementation calls `validateHostKey` for backward compatibility.
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:40:    ///      - validationCompletePromise: A promise that must be succeeded or failed based on whether the certificate is trusted.
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:41:    func validateHostCertificate(hostKey: NIOSSHPublicKey, certifiedKey: NIOSSHCertifiedPublicKey, validationCompletePromise: EventLoopPromise<Void>)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:46:    func validateHostCertificate(hostKey: NIOSSHPublicKey, certifiedKey: NIOSSHCertifiedPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:48:        self.validateHostKey(hostKey: hostKey, validationCompletePromise: validationCompletePromise)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key Exchange/SSHKeyExchangeStateMachine.swift:296:                            validationCompletePromise: promise
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key Exchange/SSHKeyExchangeStateMachine.swift:308:                    clientConfig.serverAuthDelegate.validateHostKey(hostKey: message.hostKey, validationCompletePromise: promise)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHClient/main.swift:35:    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHClient/main.swift:38:        validationCompletePromise.succeed(())

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '260,320p' 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key Exchange/SSHKeyExchangeStateMachine.swift'; sed -n '60,100p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; sed -n '200,240p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; rg -n 'futureMessage|possibleFutureMessage|whenFailure|fireErrorCaught|sendNewKeys|beginAuthentication' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine'; sed -n '165,200p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; git -C build/dd/SourcePackages/checkouts/Citadel rev-parse HEAD; git -C build/dd/SourcePackages/checkouts/swift-nio-ssh rev-parse HEAD; nl -ba App/Sources/Chat/ChatModel.swift | sed -n '64,109p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 10ms:
                    serverKeyExchangeMessage: .init(
                        hostKey: message.hostKey,
                        publicKey: message.publicKey,
                        signature: message.signature
                    ),
                    initialExchangeBytes: &self.initialExchangeBytes,
                    allocator: self.allocator,
                    expectedKeySizes: negotiated.negotiatedProtection.keySizes(forMac: negotiated.negotiatedMacAlgorithm.map { String($0) })
                )

                let protection = try negotiated.negotiatedProtection.init(initialKeys: result.keys, mac: negotiated.negotiatedMacAlgorithm.map { String($0) })
                self.state = .keysExchanged(result: result, protection: protection, negotiated: negotiated)

                // Ok, we've modified the state, now we can ask the user if they like this host key.
                guard case .client(let clientConfig) = self.role else {
                    preconditionFailure("Should not be in .keyExchangeInitSent as server")
                }
                
                // Check if this is a certificate and validate it if we have trusted CAs
                if let certifiedKey = NIOSSHCertifiedPublicKey(message.hostKey),
                   !clientConfig.trustedHostCAKeys.isEmpty {
                    // This is a certificate and we have trusted CAs configured
                    do {
                        // Use the configured hostname for validation, or empty string to accept any
                        let principal = clientConfig.hostname ?? ""
                        let _ = try certifiedKey.validate(
                            principal: principal,
                            type: .host,
                            allowedAuthoritySigningKeys: clientConfig.trustedHostCAKeys,
                            acceptableCriticalOptions: [] // Host certificates typically don't have critical options
                        )
                        // Certificate is valid, now let the delegate do additional validation
                        let promise = self.loop.makePromise(of: Void.self)
                        clientConfig.serverAuthDelegate.validateHostCertificate(
                            hostKey: message.hostKey,
                            certifiedKey: certifiedKey,
                            validationCompletePromise: promise
                        )
                        return promise.futureResult.map {
                            SSHMultiMessage(SSHMessage.newKeys)
                        }
                    } catch {
                        // Certificate validation failed
                        return self.loop.makeFailedFuture(error)
                    }
                } else {
                    // Regular key validation or no trusted CAs configured
                    let promise = self.loop.makePromise(of: Void.self)
                    clientConfig.serverAuthDelegate.validateHostKey(hostKey: message.hostKey, validationCompletePromise: promise)
                    return promise.futureResult.map {
                        SSHMultiMessage(SSHMessage.newKeys)
                    }
                }
            case .server:
                preconditionFailure("Servers cannot enter key exchange init sent.")
            }
        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
            throw SSHKeyExchangeError.unexpectedMessage
        }
    }

            }
        }
    }
}

final class ClientHandshakeHandler: ChannelInboundHandler, Sendable {
    typealias InboundIn = Any

    private let promise: EventLoopPromise<Void>
    let logger = Logger(label: "nl.orlandos.citadel.handshake")

    /// A future that will be fulfilled when the handshake is complete.
    public var authenticated: EventLoopFuture<Void> {
        promise.futureResult
    }

    init(eventLoop: EventLoop, loginTimeout: TimeAmount) {
        let promise = eventLoop.makePromise(of: Void.self)
        self.promise = promise

        eventLoop.scheduleTask(deadline: .now() + loginTimeout) {
            promise.fail(ChannelError.connectTimeout(loginTimeout))
        }
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if event is UserAuthSuccessEvent {
            self.promise.succeed(())
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        self.promise.fail(error)
    }
    
    deinit {
        struct Disconnected: Error {}
        self.promise.fail(Disconnected())
    }
}

    }

    /// Creates a new SSH session on a new channel. This will connect to the given host and port.
    /// - settings: The settings to use for the SSH session.
    static func connect(
        settings: SSHClientSettings
    ) async throws -> SSHClientSession {
        let eventLoop = settings.group.any()
        let inboundChannelHandler = SSHClientInboundChannelHandler()
        var clientConfiguration = SSHClientConfiguration(
            userAuthDelegate: settings.authenticationMethod(),
            serverAuthDelegate: settings.hostKeyValidator
        )
        
        settings.algorithms.apply(to: &clientConfiguration)
        
        for option in settings.protocolOptions {
            option.apply(to: &clientConfiguration)
        }
        
        let bootstrap = ClientBootstrap(group: eventLoop).channelInitializer { channel in
            return Self.addHandlers(on: channel, inboundChannelHandler: inboundChannelHandler, settings: settings)
        }
        .connectTimeout(settings.connectTimeout)
//        .channelOption(ChannelOptions.autoRead, value: true)
        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
        
        return try await bootstrap.connect(host: settings.host, port: settings.port).flatMap { channel in
            channel.pipeline.handler(type: ClientHandshakeHandler.self).flatMap { handshakeHandler in
                handshakeHandler.authenticated
            }.flatMap {
                channel.pipeline.handler(type: NIOSSHHandler.self)
            }.map { sshHandler in
                SSHClientSession(channel: channel, inboundChannelHandler: inboundChannelHandler, sshHandler: sshHandler)
            }
        }.get()
    }
    
    /// Creates a new SSH session on a new channel. This will connect to the given host and port.
    /// - Parameters:
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:149:                context.fireErrorCaught(error)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:169:            context.fireErrorCaught(error)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:203:        case .possibleFutureMessage(let future):
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:213:                        context.fireErrorCaught(error)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:219:                    context.fireErrorCaught(error)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:377:                context.fireErrorCaught(error)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsUserAuthMessages.swift:59:            return .possibleFutureMessage(future.map(Self.transform(_:)))
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsUserAuthMessages.swift:75:            return .possibleFutureMessage(future.map { Self.transform($0, connectionAttributes: connectionAttributes, username: message.username, banner: banner) })
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsUserAuthMessages.swift:93:            return .possibleFutureMessage(future.map(Self.transform(_:)))
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsKeyExchangeMessages.swift:44:        return .possibleFutureMessage(message)
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/SendsKeyExchangeMessages.swift:40:        let result = self.keyExchangeStateMachine.sendNewKeys()
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:748:                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:783:                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:1062:        case possibleFutureMessage(EventLoopFuture<SSHMultiMessage?>)
    @discardableResult
    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
                              "params": params.isNull ? [:] : params]
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
                enum Outcome { case go, cancelled, closed }
                let outcome: Outcome = lock.withLock {
                    if cancelled.remove(id) != nil { return .cancelled }
                    if mode != .framed { return .closed }
                    pending[id] = cont; return .go
                }
                switch outcome {
                case .cancelled: cont.resume(throwing: CancellationError()); return
                case .closed: cont.resume(throwing: HerdrError.lost); return
                case .go: break
                }
                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
                }
            }
        } onCancel: {
            let wasPending = lock.withLock { () -> Bool in
                if pending[id] != nil { return true }
                cancelled.insert(id); return false
            }
            if wasPending {
                finish(id, .failure(CancellationError()))
                notify("$/cancelRequest", ["id": .number(Double(id))])
            }
        }
    }

    /// A notification (no id, no reply).
ae8562f895de06ccb86fdb1cbb65fd99c8976e12
d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c
    64	
    65	    init(address: String) { self.address = address }
    66	
    67	    func start(store: AppStore) {
    68	        self.store = store
    69	        #if DEBUG
    70	        if AppStore.isDemo { loadDemo(); return }
    71	        #endif
    72	        guard loop == nil else { return }
    73	        loop = Task { [weak self] in
    74	            while !Task.isCancelled {
    75	                guard let self else { return }
    76	                await self.load()
    77	                await self.pause()
    78	            }
    79	        }
    80	    }
    81	
    82	    func stop() {
    83	        loop?.cancel(); loop = nil
    84	        sleeper?.cancel(); sleeper = nil
    85	        wake?.resume(); wake = nil
    86	    }
    87	
    88	    /// Something changed (status, turn): read now instead of waiting.
    89	    func nudge() { wake?.resume(); wake = nil }
    90	
    91	    private func pause() async {
    92	        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
    93	        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
    94	        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
    95	            wake = c
    96	            // Cancelled so an earlier pause's timer can never end this one early.
    97	            sleeper?.cancel()
    98	            sleeper = Task { [weak self] in
    99	                try? await Task.sleep(for: delay)
   100	                guard !Task.isCancelled else { return }
   101	                self?.nudge()
   102	            }
   103	        }
   104	    }
   105	
   106	    private func load() async {
   107	        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
   108	        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
   109	        let argv = String(decoding: rec.raw["argv"].encoded(), as: UTF8.self)

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '160,205p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; sed -n '190,225p' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift; sed -n '720,795p' 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift'; sed -n '1,65p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; rg -n 'publicKeyAlgorithms|hostKeyAlgorithms' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys\\ And\\ Signatures/NIOSSHPublicKey.swift; nl -ba App/Sources/UI/SettingsView.swift | sed -n '46,63p'; rg -n 'host key|UserDefaults|Citadel|SPEC.md' README.md docs/*.md | head -45" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
    }

    /// Creates a new SSH session on the given channel. This allows you to use an existing channel for the SSH session.
    /// - channel: The channel to use for the SSH session, could be an existing TCP socket or proxy connection.
    /// - settings: The settings to use for the SSH session.
    static func addHandlers(
        on channel: Channel,
        inboundChannelHandler: SSHClientInboundChannelHandler,
        settings: SSHClientSettings
    ) -> EventLoopFuture<Void> {
        let handshakeHandler = ClientHandshakeHandler(
            eventLoop: channel.eventLoop,
            loginTimeout: .seconds(10)
        )
        var clientConfiguration = SSHClientConfiguration(
            userAuthDelegate: settings.authenticationMethod(),
            serverAuthDelegate: settings.hostKeyValidator
        )
        
        settings.algorithms.apply(to: &clientConfiguration)
        
        for option in settings.protocolOptions {
            option.apply(to: &clientConfiguration)
        }
        
        do {
            try channel.pipeline.syncOperations.addHandlers(
                NIOSSHHandler(
                    role: .client(clientConfiguration),
                    allocator: channel.allocator,
                    inboundChildChannelInitializer: { channel, channelType in
                        return inboundChannelHandler.handleChannel(channel: channel, channelType: channelType)
                    }
                ),
                handshakeHandler
            )
            return channel.eventLoop.makeSucceededVoidFuture()
        } catch {
            return channel.eventLoop.makeFailedFuture(error)
        }
    }

    /// Creates a new SSH session on a new channel. This will connect to the given host and port.
    /// - settings: The settings to use for the SSH session.
    static func connect(
        settings: SSHClientSettings
            try self.stateMachine.processOutboundMessage(message, buffer: &self.outboundFrameBuffer, allocator: context.channel.allocator, loop: context.eventLoop)
            self.pendingWrite = true
        }

        context.write(self.wrapOutboundOut(self.outboundFrameBuffer), promise: promise)
    }

    private func processInboundMessageResult(_ result: SSHConnectionStateMachine.StateMachineInboundProcessResult, context: ChannelHandlerContext) throws {
        switch result {
        case .emitMessage(let message):
            try self.writeMessage(message, context: context)
        case .noMessage:
            break
        case .possibleFutureMessage(let future):
            // TODO(cory): This is not right, but for now it's good enough.
            future.whenComplete { result in
                switch result {
                case .success(.some(let message)):
                    do {
                        try self.writeMessage(message, context: context)
                        self.pendingWrite = false
                        context.flush()
                    } catch {
                        context.fireErrorCaught(error)
                    }
                case .success(.none):
                    // Do nothing
                    break
                case .failure(let error):
                    context.fireErrorCaught(error)
                }
            }
        case .forwardToMultiplexer(let message):
            try self.multiplexer?.receiveMessage(message)
        case .globalRequest(let message):
            try self.handleGlobalRequest(message)
                self.state = .sentDisconnect(state.role)
            case .ignore, .debug, .unimplemented:
                try state.serializer.serialize(message: message, to: &buffer)
                self.state = .idle(state)
            default:
                preconditionFailure("First message sent must be version, not \(message)")
            }

        case .sentVersion:
            // We can't send anything else now.
            // TODO(cory): We could refactor the key exchange state machine to accept the delayed version from the
            // remote peer, and then we unlock the ability to remove another RTT to the remote peer.
            preconditionFailure("Cannot send other messages before receiving version.")

        case .keyExchange(var kex):
            switch message {
            case .keyExchange(let keyExchangeMessage):
                try kex.writeKeyExchangeMessage(keyExchangeMessage, into: &buffer)
                self.state = .keyExchange(kex)
            case .keyExchangeInit(let kexInit):
                try kex.writeKeyExchangeInitMessage(kexInit, into: &buffer)
                self.state = .keyExchange(kex)
            case .keyExchangeReply(let kexReply):
                try kex.writeKeyExchangeReplyMessage(kexReply, into: &buffer)
                self.state = .keyExchange(kex)
            case .newKeys:
                try kex.writeNewKeysMessage(into: &buffer)
                let newState = SentNewKeysState(keyExchangeState: kex, loop: loop)
                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
                self.state = .sentNewKeys(newState)

                // If we have a service request message, re-spin the state machine to process that too.
                if let additionalMessage = possibleMessage {
                    try self.processOutboundMessage(.serviceRequest(additionalMessage), buffer: &buffer, allocator: allocator, loop: loop)
                }

            case .disconnect:
                try kex.serializer.serialize(message: message, to: &buffer)
                self.state = .sentDisconnect(kex.role)

            case .ignore, .debug, .unimplemented:
                try kex.serializer.serialize(message: message, to: &buffer)
                self.state = .keyExchange(kex)

            default:
                throw NIOSSHError.protocolViolation(protocolName: "key exchange", violation: "Sent unexpected message type: \(message)")
            }

        case .receivedNewKeys(var kex):
            switch message {
            case .keyExchange(let keyExchangeMessage):
                try kex.writeKeyExchangeMessage(keyExchangeMessage, into: &buffer)
                self.state = .receivedNewKeys(kex)
            case .keyExchangeInit(let kexInit):
                try kex.writeKeyExchangeInitMessage(kexInit, into: &buffer)
                self.state = .receivedNewKeys(kex)
            case .keyExchangeReply(let kexReply):
                try kex.writeKeyExchangeReplyMessage(kexReply, into: &buffer)
                self.state = .receivedNewKeys(kex)
            case .newKeys:
                try kex.writeNewKeysMessage(into: &buffer)

                let newState = UserAuthenticationState(receivedNewKeysState: kex)
                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
                self.state = .userAuthentication(newState)

                // If we have a service request message, re-spin the state machine to process that too.
                if let additionalMessage = possibleMessage {
                    try self.processOutboundMessage(.serviceRequest(additionalMessage), buffer: &buffer, allocator: allocator, loop: loop)
                }

            case .disconnect:
                try kex.serializer.serialize(message: message, to: &buffer)
                self.state = .sentDisconnect(kex.role)

            case .ignore, .debug, .unimplemented:
import NIO
@preconcurrency import NIOSSH
import Logging
import NIOConcurrencyHelpers

final class SSHClientInboundChannelHandler: Sendable {
    typealias TCPIPForwardHandler = @Sendable (Channel, SSHChannelType.ForwardedTCPIP) -> EventLoopFuture<Void>
    let forwardedTCPIPHosts = NIOLockedValueBox(
        [SSHRemotePortForward: TCPIPForwardHandler]()
    )

    init() {}

    enum HandleRegistrationResult: Error {
        case success
        case alreadyRegistered
    }

    nonisolated func registerForwardedTCPIP(host: String, port: Int, handler: @escaping TCPIPForwardHandler) -> HandleRegistrationResult {
        let bound = SSHRemotePortForward(
            host: host,
            boundPort: port
        )
        return forwardedTCPIPHosts.withLockedValue { hosts in
            if hosts.keys.contains(bound) {
                return .alreadyRegistered
            }
            hosts[bound] = handler
            return .success
        }
    }

    nonisolated func unregisterForwardedTCPIP(host: String, port: Int) {
        let bound = SSHRemotePortForward(
            host: host,
            boundPort: port
        )
        forwardedTCPIPHosts.withLockedValue { hosts in
            _ = hosts.removeValue(forKey: bound)
        }
    }

    nonisolated func handleChannel(channel: Channel, channelType: SSHChannelType) -> EventLoopFuture<Void> {
        switch channelType {
        case .session:
            return channel.eventLoop.makeFailedFuture(CitadelError.unsupported)
        case .directTCPIP:
            return channel.eventLoop.makeFailedFuture(CitadelError.unsupported)
        case .forwardedTCPIP(let forwardedTCPIP):
            return forwardedTCPIPHosts.withLockedValue { hosts in
                let bound = SSHRemotePortForward(
                    host: forwardedTCPIP.listeningHost,
                    boundPort: forwardedTCPIP.listeningPort
                )
                guard let host = hosts[bound] else {
                    return channel.eventLoop.makeFailedFuture(CitadelError.channelCreationFailed)
                }

                return host(channel, forwardedTCPIP)
            }
        }
    }
}

final class ClientHandshakeHandler: ChannelInboundHandler, Sendable {
211:        _CustomAlgorithms.publicKeyAlgorithmsLock.withLock {
212:            _CustomAlgorithms.publicKeyAlgorithms
248:        _CustomAlgorithms.publicKeyAlgorithmsLock.withLockVoid {
249:            if !_CustomAlgorithms.publicKeyAlgorithms.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(type) }) {
250:                _CustomAlgorithms.publicKeyAlgorithms.append(type)
261:        _CustomAlgorithms.publicKeyAlgorithmsLock.withLockVoid {
262:            _CustomAlgorithms.publicKeyAlgorithms = []
290:    static var publicKeyAlgorithmsLock = NIOLock()
291:    static var publicKeyAlgorithms: [NIOSSHPublicKeyProtocol.Type] = []
    46	                            Text("Host key").font(HF.ui(13, .medium)).foregroundStyle(HC.muted)
    47	                            Text(fp).font(HF.mono(11)).foregroundStyle(HC.fg).textSelection(.enabled).lineLimit(2)
    48	                        }
    49	                        Button("Forget host key", role: .destructive) { confirmForget = m }
    50	                    }
    51	                }
    52	                .confirmationDialog("Forget the host key?", isPresented: Binding(get: { confirmForget != nil }, set: { if !$0 { confirmForget = nil } }),
    53	                                    titleVisibility: .visible, presenting: confirmForget) { m in
    54	                    Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
    55	                } message: { m in
    56	                    Text("Only after \(m.host) was reinstalled. The next key it presents will be trusted and pinned.")
    57	                }
    58	
    59	                NotificationSection()
    60	
    61	                Section("Appearance") {
    62	                    Picker("Theme", selection: $appearance) {
    63	                        Text("System").tag("system")
docs/2026-11-01_herdr-ios-code-review.md:24:| `App/Sources` | Net (Citadel SSH, Keychain, host key), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore mod host), Notify |
docs/2026-11-01_herdr-ios-code-review.md:25:| External dependencies | Citadel `from: 0.12.1`, SwiftTerm `exactVersion: 1.20.0` |
docs/2026-11-01_herdr-ios-code-review.md:33:| High (confirmed in source) | `App/Sources/Net/HostKeys.swift:58-60` | On the first connection, the host key is pinned without confirmation, and the fingerprint is shown only after pinning. With a man-in-the-middle attack on the first connection, password authentication hands over the password as is. Storage is UserDefaults, not Keychain | On the first connection, show the fingerprint and require approval. Store in Keychain |
docs/2026-11-01_herdr-ios-code-review.md:37:| Medium | `project.yml:14-19` | The Citadel version is not pinned, and `Package.resolved` is gitignored. `__pycache__/*.pyc` is tracked and bundled into the app | Use `exactVersion` and commit resolved. Delete the pyc files |
docs/2026-11-01_herdr-ios-code-review.md:54:- Code comments refer to `SPEC.md`, but `SPEC.md` is not in the repo.
docs/HANDOVER.md:16:   - The host key is shown and approved before it is pinned, and pins live in the Keychain.
docs/HANDOVER.md:17:   - Citadel is pinned to an exact version; the tracked `.pyc` is gone.
docs/HANDOVER.md:21:   question about Citadel keeping the `hc connect` stdio alive (on the simulator, not a device).
docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:94:| 規模・構成 | Swift のコードが多く、relay・plugin・docs-site を含む | Swift のファイルが 49 個。`HerdrKit`（protocol と model、SwiftPM、テストあり）と `App`（Citadel の SSH、SwiftTerm）に分かれる |
docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:92:| Size and structure | Large amount of Swift code, includes relay, plugin and docs-site | 49 Swift files. Split into `HerdrKit` (protocol and model, SwiftPM, with tests) and `App` (Citadel SSH, SwiftTerm) |
docs/2026-11-01_herdr-ios-code-review.ja.md:26:| `App/Sources` | Net（Citadel の SSH、Keychain、host key）、Store（`AppStore`）、UI、Chat、Mods（JavaScriptCore の mod host）、Notify |
docs/2026-11-01_herdr-ios-code-review.ja.md:27:| 外部の依存 | Citadel `from: 0.12.1`、SwiftTerm `exactVersion: 1.20.0` |
docs/2026-11-01_herdr-ios-code-review.ja.md:35:| 高（原文で確認） | `App/Sources/Net/HostKeys.swift:58-60` | 初回の接続で host key を確認なしに固定し、fingerprint は固定した後にしか見せない。初回に中間者攻撃を受けると、password 認証では password がそのまま渡る。保存先は Keychain ではなく UserDefaults である | 初回は fingerprint を見せて承認させる。保存先を Keychain にする |
docs/2026-11-01_herdr-ios-code-review.ja.md:39:| 中 | `project.yml:14-19` | Citadel の版が固定されておらず、`Package.resolved` も gitignore されている。`__pycache__/*.pyc` が追跡され、アプリに同梱される | `exactVersion` にし、resolved を commit する。pyc を消す |
docs/2026-11-01_herdr-ios-code-review.ja.md:56:- コードのコメントが `SPEC.md` を参照しているが、`SPEC.md` は repo に無い。
README.md:41:- **Host key:** the box's host key is pinned on first connect.
README.md:103:  Net                 Citadel SSH transport, Keychain key store, host-key pinning

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
Citadel 0.12.1 と解決済みの NIOSSH ソースで、ホスト鍵の検証成功前には認証を開始せず、`Unknown` がそのままアプリへ返ることを確認しました。初回鍵の承認は RootView 経由で到達可能です。残る確認対象は、接続拒否後のソケット解放と、Keychain 読み取り失敗を「未登録」と扱う経路です。

hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '200,225p' 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/NIOSSHPublicKey.swift'; sed -n '275,313p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift; rg -n 'deinit|func errorCaught|close\\(' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift; nl -ba App/Sources/Net/CitadelTransport.swift | sed -n '30,52p'; nl -ba App/Sources/UI/ConnectionViews.swift | sed -n '276,293p'; git log -5 --oneline; rg -n 'missing|methods|compat' Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift; cat project.yml | head -30" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
    }

    private static let bundledAlgorithms: [String.UTF8View] = [
        Self.ed25519PublicKeyPrefix, Self.ecdsaP384PublicKeyPrefix, Self.ecdsaP256PublicKeyPrefix, Self.ecdsaP521PublicKeyPrefix,
    ]

    static var knownAlgorithms: [String.UTF8View] {
        bundledAlgorithms + customPublicKeyAlgorithms.map { $0.publicKeyPrefix.utf8 }
    }

    static var customPublicKeyAlgorithms: [NIOSSHPublicKeyProtocol.Type] {
        _CustomAlgorithms.publicKeyAlgorithmsLock.withLock {
            _CustomAlgorithms.publicKeyAlgorithms
        }
    }

    static var customSignatures: [NIOSSHSignatureProtocol.Type] {
        _CustomAlgorithms.signaturesLock.withLock {
            _CustomAlgorithms.signatures
        }
    }
}

public enum NIOSSHAlgorithms {
    public static func register(keyExchangeAlgorithm type: NIOSSHKeyExchangeAlgorithmProtocol.Type) {
        _CustomAlgorithms.keyExchangeAlgorithmsLock.withLockVoid {
    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
    /// - connectTimeout: Pass in the time before the connection times out. Default 30 seconds.
    /// - Returns: An SSH client.
    public static func connect(
        host: String,
        port: Int = 22,
        authenticationMethod: SSHAuthenticationMethod,
        hostKeyValidator: SSHHostKeyValidator,
        reconnect: SSHReconnectMode,
        algorithms: SSHAlgorithms = SSHAlgorithms(),
        protocolOptions: Set<SSHProtocolOption> = [],
        group: MultiThreadedEventLoopGroup = .singleton,
        channelHandlers: [ChannelHandler] = [],
        connectTimeout:TimeAmount = .seconds(30)
    ) async throws -> SSHClient {
        let session = try await SSHClientSession.connect(
            host: host,
            port: port,
            authenticationMethod: authenticationMethod,
            hostKeyValidator: hostKeyValidator,
            algorithms: algorithms,
            protocolOptions: protocolOptions,
            group: group,
            channelHandlers: channelHandlers,
            connectTimeout: connectTimeout
        )
        
        let client = SSHClient(
            session: session,
            authenticationMethod: authenticationMethod,
            hostKeyValidator: hostKeyValidator,
            algorithms: algorithms,
            protocolOptions: protocolOptions
        )
        
        switch reconnect.mode {
        case .always:
            client.connectionSettings.reconnect = .always(to: host, port: port)
        case .once:
230:            context.close(promise: nil)
    30	               onStderr: @escaping @Sendable (Data) -> Void,
    31	               onClose: @escaping @Sendable (Error?) -> Void) async throws {
    32	        let method: SSHAuthenticationMethod = switch auth {
    33	        case .key(let k): .ed25519(username: user, privateKey: k)
    34	        case .password(let p): .passwordBased(username: user, password: p)
    35	        }
    36	        let client: SSHClient
    37	        do {
    38	            client = try await SSHClient.connect(
    39	                host: host, port: port, authenticationMethod: method,
    40	                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
    41	                reconnect: .never, connectTimeout: .seconds(12))
    42	        } catch {
    43	            throw Self.friendly(error, host: host, user: user)
    44	        }
    45	        let isClosed: Bool = lock.withLock {
    46	            self.client = client; self.onClose = onClose; return closed
    47	        }
    48	        if isClosed { try? await client.close(); throw HerdrError(code: -1, kind: "closed", message: "Disconnected") }
    49	
    50	        // The exec channel lives in this task; `start` returns once stdin is writable.
    51	        try await withCheckedThrowingContinuation { (ready: CheckedContinuation<Void, Error>) in
    52	            let readyOnce = Once(ready)
   276	                .padding(.top, 6)
   277	                if let key = store.unknownHostKey {
   278	                    VStack(alignment: .leading, spacing: 8) {
   279	                        Text("New host key").font(HF.ui(15, .semibold))
   280	                        Text(key.fingerprint)
   281	                            .font(HF.mono(12.5))
   282	                            .textSelection(.enabled)
   283	                            .accessibilityIdentifier("hostKeyFingerprint")
   284	                        Text("On \(key.host), compare it with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
   285	                            .font(HF.ui(13)).foregroundStyle(HC.muted)
   286	                        Button { store.trustHostKey(key) } label: {
   287	                            Label("Trust and connect", systemImage: "checkmark.shield")
   288	                        }
   289	                        .buttonStyle(.glassProminent)
   290	                        .font(HF.ui(15, .medium))
   291	                    }
   292	                    .padding(14)
   293	                    .herdrCard()
1b740be List every core method the app calls in requiredMethods
362b8bc Ask before pinning a new host key, and keep pins in the Keychain
407eccd Stop re-reading the transcript on every terminal title change
2357d77 Pin Citadel and commit the resolved package versions
4d7576a Add agent instructions, devshell and the fork's founding research
43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
61:        XCTAssertThrowsError(try HerdrClient.check(hello: ["result": ["generation": 1, "version": "0.1.9", "methods": []]]))
62:        XCTAssertThrowsError(try HerdrClient.check(hello: ["result": ["generation": 2, "version": "0.2.0", "methods": []]]))
name: Herdr
options:
  bundleIdPrefix: dev.herdr
  deploymentTarget:
    iOS: "26.0"
  createIntermediateGroups: true
settings:
  base:
    CODE_SIGN_STYLE: Automatic
    SWIFT_VERSION: "5.0"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
packages:
  HerdrKit:
    path: Packages/HerdrKit
  Citadel:
    url: https://github.com/orlandos-nl/Citadel
    exactVersion: 0.12.1
  SwiftTerm:
    url: https://github.com/migueldeicaza/SwiftTerm
    exactVersion: 1.20.0
targets:
  Herdr:
    type: application
    platform: iOS
    configFiles:
      Debug: Config/Base.xcconfig
      Release: Config/Base.xcconfig
    sources:
      - path: App/Sources

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '245,288p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; rg -n 'channelHandlers' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/{ClientSession,Client}.swift; sed -n '225,245p' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift; rg -n 'func errorCaught|unhandledError' build/dd/SourcePackages/checkouts/swift-nio/Sources/NIOCore/ChannelPipeline.swift | tail -10" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
    /// - algorithms: The algorithms to use, will use the default algorithms if not specified.
    /// - protocolOptions: The protocol options to use, will use the default options if not specified.
    /// - group: The event loop group to use, will use a new group with one thread if not specified.
    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
    /// - connectTimeout: Pass in the time before the connection times out. Default 30 seconds.
    static func connect(
        host: String,
        port: Int = 22,
        authenticationMethod: @Sendable @escaping @autoclosure () -> SSHAuthenticationMethod,
        hostKeyValidator: SSHHostKeyValidator,
        algorithms: SSHAlgorithms = SSHAlgorithms(),
        protocolOptions: Set<SSHProtocolOption> = [],
        group: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        channelHandlers: [ChannelHandler] = [],
        connectTimeout: TimeAmount = .seconds(30)
    ) async throws -> SSHClientSession {
        var settings = SSHClientSettings(
            host: host,
            port: port,
            authenticationMethod: authenticationMethod,
            hostKeyValidator: hostKeyValidator
        )

        settings.algorithms = algorithms
        settings.protocolOptions = protocolOptions
        settings.group = group
        settings.channelHandlers = channelHandlers
        settings.connectTimeout = connectTimeout
        
        return try await connect(
            settings: settings
        )
    }
}

public struct InvalidHostKey: Error, Equatable {}

/// A host key validator that can be used to validate an SSH host key. This can be used to validate the host key against a set of trusted keys, or to accept any key.
public struct SSHHostKeyValidator: NIOSSHClientServerAuthenticationDelegate, Sendable {
    private enum Method {
        case trustedKeys(Set<NIOSSHPublicKey>)
        case acceptAnything
        case custom(NIOSSHClientServerAuthenticationDelegate)
    }
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:109:    internal var channelHandlers: [ChannelHandler & Sendable] = []
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:248:    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:258:        channelHandlers: [ChannelHandler] = [],
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:271:        settings.channelHandlers = channelHandlers
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:275:    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:287:        channelHandlers: [ChannelHandler] = [],
build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:298:            channelHandlers: channelHandlers,
            try self.handleGlobalRequest(message)
        case .globalRequestResponse(let response):
            try self.handleGlobalRequestResponse(response)
        case .disconnect:
            // Welp, we immediately have to close.
            context.close(promise: nil)
        case .event(let event):
            context.fireUserInboundEventTriggered(event)
        }
    }
}

// MARK: Create a child channel

extension NIOSSHHandler {
    /// Creates an SSH channel.
    ///
    /// This function is **not** thread-safe: it may only be called from on the channel.
    ///
    /// - parameters:
    ///     - promise: An `EventLoopPromise` that will be fulfilled with the channel when it becomes active.
1832:    func errorCaught(context: ChannelHandlerContext, error: Error) {

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
指摘は4件です。

1. **medium — [ChatModel.swift:95](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/ChatModel.swift:95)**  
   `load()` 中に `stop()` → `start()` すると、停止済みループも `pause()` に進みます。新旧ループが `wake` を上書きし、片方の continuation が未解放になります。**修正:** `load()` の直後、キャンセル済みなら `pause()` に進まず終了する。通常の nudge による二重 resume は **no findings**。MainActor 上で resume と nil 代入は分断されません。

2. **medium — [HostKeys.swift:65](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/HostKeys.swift:65)**  
   `Unknown` で接続を拒否しても、Citadel 0.12.1 は handshake の promise を失敗させるだけで TCP channel を閉じません。アプリも `SSHClient` を受け取れず、解放できません。初回接続の再試行で未認証接続が蓄積し、sshd の接続制限に達し得ます。**修正:** handshake 失敗時に channel を閉じてからエラーを返すよう Citadel の接続処理を修正する。

3. **medium — [KeyStore.swift:97](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/KeyStore.swift:97)**  
   Keychain の読み取りエラーを `nil` に変換するため、一時的な Keychain 障害でも登録済みホストを「初回」と表示します。その後の保存が成功すると、既存 pin を別の鍵で上書きできます。**修正:** 未登録と読み取り失敗を区別し、失敗は validator から接続エラーとして返す。

4. **low — [ConnectionViews.swift:284](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ConnectionViews.swift:284)**  
   ECDSA のみを提供するホストでも、照合コマンドは ed25519 固定です。表示された fingerprint を指定の手順で確認できません。**修正:** 提示された鍵種別に対応するファイルを案内するか、全ホスト公開鍵の fingerprint を表示するコマンドにする。

認証情報送信前の停止は **no findings**。解決済み NIOSSH は検証成功後にのみ `NEWKEYS` を送信し、認証へ進みます。[NIOSSH ソース](https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Key%20Exchange/SSHKeyExchangeStateMachine.swift#L308)

承認への到達性も **no findings**。`Unknown` は既存セッションの有無にかかわらず RootView が FailureView に振り分けます。MainView の mismatch は Settings の Forget → 再接続 → 承認へ進めます。ただし [SettingsView.swift:56](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/SettingsView.swift:56) の「次の鍵を自動で信頼・保存する」という説明は実装と不一致です。

`requiredMethods` の追加は **no findings**。

ファイル変更、テスト実行、実機確認はしていません。指摘はアプリと解決済み依存ライブラリのソース追跡に基づきます。
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
80,714
指摘は4件です。

1. **medium — [ChatModel.swift:95](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/ChatModel.swift:95)**  
   `load()` 中に `stop()` → `start()` すると、停止済みループも `pause()` に進みます。新旧ループが `wake` を上書きし、片方の continuation が未解放になります。**修正:** `load()` の直後、キャンセル済みなら `pause()` に進まず終了する。通常の nudge による二重 resume は **no findings**。MainActor 上で resume と nil 代入は分断されません。

2. **medium — [HostKeys.swift:65](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/HostKeys.swift:65)**  
   `Unknown` で接続を拒否しても、Citadel 0.12.1 は handshake の promise を失敗させるだけで TCP channel を閉じません。アプリも `SSHClient` を受け取れず、解放できません。初回接続の再試行で未認証接続が蓄積し、sshd の接続制限に達し得ます。**修正:** handshake 失敗時に channel を閉じてからエラーを返すよう Citadel の接続処理を修正する。

3. **medium — [KeyStore.swift:97](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/KeyStore.swift:97)**  
   Keychain の読み取りエラーを `nil` に変換するため、一時的な Keychain 障害でも登録済みホストを「初回」と表示します。その後の保存が成功すると、既存 pin を別の鍵で上書きできます。**修正:** 未登録と読み取り失敗を区別し、失敗は validator から接続エラーとして返す。

4. **low — [ConnectionViews.swift:284](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ConnectionViews.swift:284)**  
   ECDSA のみを提供するホストでも、照合コマンドは ed25519 固定です。表示された fingerprint を指定の手順で確認できません。**修正:** 提示された鍵種別に対応するファイルを案内するか、全ホスト公開鍵の fingerprint を表示するコマンドにする。

認証情報送信前の停止は **no findings**。解決済み NIOSSH は検証成功後にのみ `NEWKEYS` を送信し、認証へ進みます。[NIOSSH ソース](https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Key%20Exchange/SSHKeyExchangeStateMachine.swift#L308)

承認への到達性も **no findings**。`Unknown` は既存セッションの有無にかかわらず RootView が FailureView に振り分けます。MainView の mismatch は Settings の Forget → 再接続 → 承認へ進めます。ただし [SettingsView.swift:56](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/SettingsView.swift:56) の「次の鍵を自動で信頼・保存する」という説明は実装と不一致です。

`requiredMethods` の追加は **no findings**。

ファイル変更、テスト実行、実機確認はしていません。指摘はアプリと解決済み依存ライブラリのソース追跡に基づきます。
