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
session id: 01a19355-2398-7921-b416-82f5b67514a0
--------
user
Review commits 8f48ed6 and 95acd13 in this repo (git show 8f48ed6 95acd13). They act on earlier reviews recorded in docs/reviews/2026-11-01-fixes-judgement.md and docs/reviews/2026-11-01-files-judgement.md. Review only; do not edit files. Check that each fix does what its judgement row says and introduces no new defect. In particular: the python3 read script in App/Sources/UI/FilesView.swift (limit, O_NONBLOCK on regular files, exit codes, stdout buffering), task cancellation and the 'opening' state in FilesView, preview folder deletion timing, and the throwing Keychain read in HostKeys/KeyStore. For each finding: severity, file:line, concrete failure scenario, suggested fix. Say 'no findings' if none. Be concise.
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
指定の2コミットと判断表を照合し、関連する呼び出し元まで確認します。`ponytail-review` スキルを使い、ファイルは変更しません。
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
/bin/zsh -lc 'git show 8f48ed6 95acd13' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 8f48ed6eb86f9af6b9cffc57759f1515efa2c777
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:45:03 2026 +0900

    Act on the review of the pre-use fixes and test first-connect approval
    
    A Keychain read failure made a pinned host look new, so its pin could be
    replaced; it now fails the connection. A Chat loop stopped during a load
    could leave a continuation hanging. The approval card names the host key
    file for the presented key type, and the failure title says what is being
    asked. A UI test drives a fresh install through approval against a real
    herdr-core and checks the fingerprint against the host's key.

diff --git a/App/Sources/Chat/ChatModel.swift b/App/Sources/Chat/ChatModel.swift
index 1f97a61..4523b0c 100644
--- a/App/Sources/Chat/ChatModel.swift
+++ b/App/Sources/Chat/ChatModel.swift
@@ -74,6 +74,7 @@ final class ChatModel {
             while !Task.isCancelled {
                 guard let self else { return }
                 await self.load()
+                guard !Task.isCancelled else { return }
                 await self.pause()
             }
         }
diff --git a/App/Sources/Net/CitadelTransport.swift b/App/Sources/Net/CitadelTransport.swift
index 3ed1107..386c106 100644
--- a/App/Sources/Net/CitadelTransport.swift
+++ b/App/Sources/Net/CitadelTransport.swift
@@ -107,7 +107,7 @@ final class CitadelTransport: ByteTransport, @unchecked Sendable {
 
     /// SSH failures in words a person can act on.
     static func friendly(_ error: Error, host: String, user: String) -> Error {
-        if error is HostKeys.Mismatch || error is HostKeys.Unknown { return error }
+        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return error }
         if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
             return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
                               hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
diff --git a/App/Sources/Net/HostKeys.swift b/App/Sources/Net/HostKeys.swift
index 2d3f96f..82303de 100644
--- a/App/Sources/Net/HostKeys.swift
+++ b/App/Sources/Net/HostKeys.swift
@@ -20,17 +20,22 @@ enum HostKeys {
         var port: Int
         var line: String
         var fingerprint: String { HostKeys.fingerprint(line) }
+        /// The command that prints this key's fingerprint on the machine itself.
+        var checkCommand: String {
+            let type = line.hasPrefix("ssh-ed25519") ? "ed25519" : line.hasPrefix("ecdsa-") ? "ecdsa" : "rsa"
+            return "ssh-keygen -lf /etc/ssh/ssh_host_\(type)_key.pub"
+        }
         var errorDescription: String? {
-            "First connection to \(host). Check its host key before trusting it: \(fingerprint)"
+            "First connection to \(host). Compare its host key with the machine before trusting it."
         }
     }
 
     /// The pinned key's fingerprint, for display.
     static func pinnedFingerprint(host: String, port: Int) -> String? {
-        pinned(host: host, port: port).map(fingerprint)
+        (try? pinned(host: host, port: port))?.map(fingerprint)
     }
 
-    static func pinned(host: String, port: Int) -> String? { KeyStore.hostKey("\(host):\(port)") }
+    static func pinned(host: String, port: Int) throws -> String? { try KeyStore.hostKey("\(host):\(port)") }
 
     static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }
 
@@ -54,7 +59,11 @@ enum HostKeys {
 
         func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
             let line = String(openSSHPublicKey: hostKey)
-            if let known = HostKeys.pinned(host: host, port: port) {
+            let known: String?
+            do { known = try HostKeys.pinned(host: host, port: port) } catch {
+                validationCompletePromise.fail(error); return
+            }
+            if let known {
                 if known == line {
                     validationCompletePromise.succeed(())
                 } else {
diff --git a/App/Sources/Net/KeyStore.swift b/App/Sources/Net/KeyStore.swift
index b7dd639..6c7a198 100644
--- a/App/Sources/Net/KeyStore.swift
+++ b/App/Sources/Net/KeyStore.swift
@@ -93,8 +93,9 @@ enum KeyStore {
 
     // MARK: Host keys
 
-    static func hostKey(_ hostPort: String) -> String? {
-        (try? read(account: "hostkey." + hostPort)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
+    /// nil only when nothing is pinned; a Keychain failure throws so it is never taken for a first connection.
+    static func hostKey(_ hostPort: String) throws -> String? {
+        try read(account: "hostkey." + hostPort).flatMap { String(data: $0, encoding: .utf8) }
     }
 
     static func setHostKey(_ line: String?, for hostPort: String) throws {
diff --git a/App/Sources/UI/ConnectionViews.swift b/App/Sources/UI/ConnectionViews.swift
index 4cda07e..7a56291 100644
--- a/App/Sources/UI/ConnectionViews.swift
+++ b/App/Sources/UI/ConnectionViews.swift
@@ -238,7 +238,7 @@ struct FailureView: View {
                 Image(systemName: "bolt.horizontal.circle")
                     .font(.system(size: 44, weight: .light)).foregroundStyle(HC.blocked)
                     .padding(.top, 60)
-                Text(store.phase == .idle ? "Not connected to \(store.machineTitle)" : "Couldn't reach \(store.machineTitle)")
+                Text(store.unknownHostKey != nil ? "Check \(store.machineTitle)'s host key" : store.phase == .idle ? "Not connected to \(store.machineTitle)" : "Couldn't reach \(store.machineTitle)")
                     .font(HF.ui(20, .semibold)).foregroundStyle(HC.fg)
                     .multilineTextAlignment(.center)
                 if case .failed(let msg) = store.phase {
@@ -281,7 +281,7 @@ struct FailureView: View {
                             .font(HF.mono(12.5))
                             .textSelection(.enabled)
                             .accessibilityIdentifier("hostKeyFingerprint")
-                        Text("On \(key.host), compare it with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
+                        Text("On \(key.host), compare it with: \(key.checkCommand)")
                             .font(HF.ui(13)).foregroundStyle(HC.muted)
                         Button { store.trustHostKey(key) } label: {
                             Label("Trust and connect", systemImage: "checkmark.shield")
diff --git a/App/Sources/UI/SettingsView.swift b/App/Sources/UI/SettingsView.swift
index 13f8bd8..f480b75 100644
--- a/App/Sources/UI/SettingsView.swift
+++ b/App/Sources/UI/SettingsView.swift
@@ -53,7 +53,7 @@ struct SettingsView: View {
                                     titleVisibility: .visible, presenting: confirmForget) { m in
                     Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
                 } message: { m in
-                    Text("Only after \(m.host) was reinstalled. The next key it presents will be trusted and pinned.")
+                    Text("Only after \(m.host) was reinstalled. You will be asked to approve the next key it presents.")
                 }
 
                 NotificationSection()
diff --git a/UITests/HerdrUITests.swift b/UITests/HerdrUITests.swift
index b94bc2f..5f9cfea 100644
--- a/UITests/HerdrUITests.swift
+++ b/UITests/HerdrUITests.swift
@@ -32,6 +32,35 @@ final class HerdrUITests: XCTestCase {
         XCTAssertTrue(start.isEnabled, "Start disabled with a space selected")
     }
 
+    /// A fresh install connecting for the first time stops at the host key, shows the
+    /// fingerprint the box really has, and reaches home only after approval.
+    /// Needs HERDR_TEST_HOST, HERDR_TEST_USER and HERDR_TEST_HOST_FP (ssh-keygen -lf of the
+    /// box's ed25519 host key); run after uninstalling the app and resetting the simulator keychain.
+    func testFirstConnectAsksForHostKey() throws {
+        let env = ProcessInfo.processInfo.environment
+        let host = try XCTUnwrap(env["HERDR_TEST_HOST"]), user = try XCTUnwrap(env["HERDR_TEST_USER"])
+        let app = XCUIApplication()
+        app.launchEnvironment["HERDR_DEBUG_KEY_PATH"] = env["HERDR_DEBUG_KEY_PATH"] ?? ""
+        app.launchEnvironment["HERDR_DEBUG_OBSERVE"] = "1"
+        app.launch()
+        let hostField = app.textFields["100.x.y.z or my-box.local"]
+        XCTAssertTrue(hostField.waitForExistence(timeout: 15), "no onboarding form")
+        hostField.tap(); hostField.typeText(host)
+        let userField = app.textFields["username"]
+        userField.tap(); userField.typeText(user)
+        app.buttons["Connect"].tap()
+
+        let fp = app.staticTexts["hostKeyFingerprint"]
+        XCTAssertTrue(fp.waitForExistence(timeout: 30), "no host key approval")
+        shot(app, "host-key-approval")
+        XCTAssertEqual(fp.label, env["HERDR_TEST_HOST_FP"], "fingerprint differs from the box's host key")
+        XCTAssertFalse(app.buttons["New agent"].exists, "reached home before approval")
+
+        app.buttons["Trust and connect"].tap()
+        XCTAssertTrue(app.buttons["New agent"].waitForExistence(timeout: 30), "did not reach home after approval")
+        shot(app, "home-after-approval")
+    }
+
     /// Chat reads a Claude agent's transcript ($HERDR_TEST_TERMINAL); folds open on tap. Never sends anything.
     func testChatRendersAndFolds() throws {
         let app = launch(["HERDR_DEBUG_OPEN": ProcessInfo.processInfo.environment["HERDR_TEST_TERMINAL"] ?? "t1"])
diff --git a/docs/reviews/2026-11-01-fixes-codex.md b/docs/reviews/2026-11-01-fixes-codex.md
new file mode 100644
index 0000000..8e82d57
--- /dev/null
+++ b/docs/reviews/2026-11-01-fixes-codex.md
@@ -0,0 +1,3527 @@
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
+session id: 01a19342-1792-7dd3-b335-9974e0c19af6
+--------
+user
+You are reviewing commits 407eccd, 362b8bc and 1b740be in this repo (run: git show 407eccd 362b8bc 1b740be). Context: docs/2026-11-01_herdr-ios-code-review.md lists the problems they fix (Chat nudge on title, host key trust on first use stored in UserDefaults, requiredMethods). Review only; do not edit files. For each finding give: severity (high/medium/low), file:line, the concrete failure scenario, and a suggested fix. Check in particular: (1) whether ChatModel's pause/nudge can still resume a continuation twice or leak one, given everything runs on the MainActor; (2) whether HostKeys.Unknown really stops before any credential is sent with Citadel 0.12.1 / NIOSSH, and every path that shows a failure lets the user approve (RootView, MainView banner, Settings); (3) anything else broken by moving pins to the Keychain. Say 'no findings' for a point if there are none. Be concise.
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
+指定の3コミットと関連コード、Citadel／NIOSSH の認証順序を読み取り専用で確認します。レビュー用の Ponytail スキルを適用し、再現条件が確認できた指摘に絞ります。
+
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'git show 407eccd 362b8bc 1b740be' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+commit 407eccdb208fbc4b9b8612dcd6e2a4734b230b16
+Author: i2 <95607264+YosukeIida@users.noreply.github.com>
+Date:   Sun Nov 1 03:38:45 2026 +0900
+
+    Stop re-reading the transcript on every terminal title change
+    
+    While an agent works its title changes about every 0.1 s (the spinner), and
+    each change woke Chat, so the box ran the transcript script almost back to
+    back. Status and turn changes are enough to notice new output. An earlier
+    pause's timer could also end the next pause early; it is now cancelled.
+
+diff --git a/App/Sources/Chat/ChatModel.swift b/App/Sources/Chat/ChatModel.swift
+index 584bcb3..1f97a61 100644
+--- a/App/Sources/Chat/ChatModel.swift
++++ b/App/Sources/Chat/ChatModel.swift
+@@ -59,6 +59,7 @@ final class ChatModel {
+     private var offset: Int64 = -1
+     private var loop: Task<Void, Never>?
+     private var wake: CheckedContinuation<Void, Never>?
++    private var sleeper: Task<Void, Never>?
+     private weak var store: AppStore?
+ 
+     init(address: String) { self.address = address }
+@@ -80,10 +81,11 @@ final class ChatModel {
+ 
+     func stop() {
+         loop?.cancel(); loop = nil
++        sleeper?.cancel(); sleeper = nil
+         wake?.resume(); wake = nil
+     }
+ 
+-    /// Something changed (status, turn, title): read now instead of waiting.
++    /// Something changed (status, turn): read now instead of waiting.
+     func nudge() { wake?.resume(); wake = nil }
+ 
+     private func pause() async {
+@@ -91,9 +93,12 @@ final class ChatModel {
+         let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
+         await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
+             wake = c
+-            Task { [weak self] in
++            // Cancelled so an earlier pause's timer can never end this one early.
++            sleeper?.cancel()
++            sleeper = Task { [weak self] in
+                 try? await Task.sleep(for: delay)
+-                self?.wake?.resume(); self?.wake = nil
++                guard !Task.isCancelled else { return }
++                self?.nudge()
+             }
+         }
+     }
+diff --git a/App/Sources/Chat/ChatView.swift b/App/Sources/Chat/ChatView.swift
+index dd11409..3d05359 100644
+--- a/App/Sources/Chat/ChatView.swift
++++ b/App/Sources/Chat/ChatView.swift
+@@ -43,7 +43,6 @@ struct ChatView: View {
+         .onDisappear { model.stop() }
+         .onChange(of: rec?.statusWord) { _, _ in model.nudge() }
+         .onChange(of: rec?.turn) { _, _ in model.nudge() }
+-        .onChange(of: rec?.title) { _, _ in model.nudge() }
+         .onChange(of: store.phase) { _, p in if p == .connected { model.nudge() } }
+         .onChange(of: scenePhase) { _, p in if p == .active { model.nudge() } }
+     }
+
+commit 362b8bcbaefe944c287fea45317f6e29debbebb3
+Author: i2 <95607264+YosukeIida@users.noreply.github.com>
+Date:   Sun Nov 1 03:38:46 2026 +0900
+
+    Ask before pinning a new host key, and keep pins in the Keychain
+    
+    The first connection pinned whatever key it saw and showed the fingerprint
+    only afterwards, so a man in the middle on that first connection would be
+    trusted, and with password login would receive the password. Now an unknown
+    host stops the connection before authentication and the failure screen shows
+    the fingerprint to approve. Pins move from UserDefaults to the Keychain;
+    existing pins are not migrated, so each host is approved once more.
+
+diff --git a/App/Sources/Net/CitadelTransport.swift b/App/Sources/Net/CitadelTransport.swift
+index ea6f558..3ed1107 100644
+--- a/App/Sources/Net/CitadelTransport.swift
++++ b/App/Sources/Net/CitadelTransport.swift
+@@ -107,7 +107,7 @@ final class CitadelTransport: ByteTransport, @unchecked Sendable {
+ 
+     /// SSH failures in words a person can act on.
+     static func friendly(_ error: Error, host: String, user: String) -> Error {
+-        if error is HostKeys.Mismatch { return error }
++        if error is HostKeys.Mismatch || error is HostKeys.Unknown { return error }
+         if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
+             return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
+                               hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
+diff --git a/App/Sources/Net/HostKeys.swift b/App/Sources/Net/HostKeys.swift
+index d2000c1..2d3f96f 100644
+--- a/App/Sources/Net/HostKeys.swift
++++ b/App/Sources/Net/HostKeys.swift
+@@ -3,10 +3,8 @@ import Crypto
+ import NIOCore
+ import NIOSSH
+ 
+-/// Trust-on-first-use host keys, pinned per host:port in UserDefaults.
++/// Host keys pinned per host:port in the Keychain, after the person approves the first one.
+ enum HostKeys {
+-    private static let prefix = "hostkey."
+-
+     struct Mismatch: LocalizedError {
+         var host: String
+         var expected: String
+@@ -16,21 +14,28 @@ enum HostKeys {
+         }
+     }
+ 
++    /// A host seen for the first time. Nothing is pinned and no credentials were sent yet.
++    struct Unknown: LocalizedError, Equatable {
++        var host: String
++        var port: Int
++        var line: String
++        var fingerprint: String { HostKeys.fingerprint(line) }
++        var errorDescription: String? {
++            "First connection to \(host). Check its host key before trusting it: \(fingerprint)"
++        }
++    }
++
+     /// The pinned key's fingerprint, for display.
+     static func pinnedFingerprint(host: String, port: Int) -> String? {
+         pinned(host: host, port: port).map(fingerprint)
+     }
+ 
+-    static func pinned(host: String, port: Int) -> String? {
+-        UserDefaults.standard.string(forKey: prefix + "\(host):\(port)")
+-    }
++    static func pinned(host: String, port: Int) -> String? { KeyStore.hostKey("\(host):\(port)") }
+ 
+-    static func forget(host: String, port: Int) {
+-        UserDefaults.standard.removeObject(forKey: prefix + "\(host):\(port)")
+-    }
++    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }
+ 
+-    static func pin(_ line: String, host: String, port: Int) {
+-        UserDefaults.standard.set(line, forKey: prefix + "\(host):\(port)")
++    static func pin(_ line: String, host: String, port: Int) throws {
++        try KeyStore.setHostKey(line, for: "\(host):\(port)")
+     }
+ 
+     /// `SHA256:<base64>` like ssh-keygen -l.
+@@ -41,7 +46,8 @@ enum HostKeys {
+         return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
+     }
+ 
+-    /// Validator for Citadel: pins on first sight, fails on change.
++    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
++    /// so the app can show the fingerprint and pin it on approval.
+     final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
+         let host: String, port: Int
+         init(host: String, port: Int) { self.host = host; self.port = port }
+@@ -56,8 +62,7 @@ enum HostKeys {
+                                                             got: HostKeys.fingerprint(line)))
+                 }
+             } else {
+-                HostKeys.pin(line, host: host, port: port)
+-                validationCompletePromise.succeed(())
++                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
+             }
+         }
+     }
+diff --git a/App/Sources/Net/KeyStore.swift b/App/Sources/Net/KeyStore.swift
+index 0902806..b7dd639 100644
+--- a/App/Sources/Net/KeyStore.swift
++++ b/App/Sources/Net/KeyStore.swift
+@@ -91,6 +91,17 @@ enum KeyStore {
+         }
+     }
+ 
++    // MARK: Host keys
++
++    static func hostKey(_ hostPort: String) -> String? {
++        (try? read(account: "hostkey." + hostPort)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
++    }
++
++    static func setHostKey(_ line: String?, for hostPort: String) throws {
++        let account = "hostkey." + hostPort
++        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
++    }
++
+     // MARK: Keychain
+ 
+     private static func query(_ account: String) -> [String: Any] {
+diff --git a/App/Sources/Store/AppStore.swift b/App/Sources/Store/AppStore.swift
+index 3dd1dff..5d529ee 100644
+--- a/App/Sources/Store/AppStore.swift
++++ b/App/Sources/Store/AppStore.swift
+@@ -218,6 +218,21 @@ final class AppStore {
+     /// The last connect failed because the host key changed.
+     private(set) var hostKeyMismatch = false
+ 
++    /// The last connect stopped at a host seen for the first time; its key waits for approval.
++    private(set) var unknownHostKey: HostKeys.Unknown?
++
++    /// Pins the approved first-seen host key and connects again.
++    func trustHostKey(_ key: HostKeys.Unknown) {
++        do {
++            try HostKeys.pin(key.line, host: key.host, port: key.port)
++        } catch {
++            phase = .failed("Couldn't save the host key: \(error.localizedDescription)")
++            return
++        }
++        unknownHostKey = nil
++        reconnect()
++    }
++
+     /// Pull-to-refresh / screens that want a step index rather than text.
+     /// 0 SSH, 1 starting core, 2 hello, 3 events + layout; -1 when not connecting.
+     private(set) var connectStep = -1
+@@ -504,6 +519,7 @@ final class AppStore {
+             phase = .connected
+             connectStep = -1
+             hostKeyMismatch = false
++            unknownHostKey = nil
+             attempt = 0
+             Task { [weak self] in await self?.learnHome(gen: gen) }
+         } catch {
+@@ -514,7 +530,7 @@ final class AppStore {
+     }
+ 
+     private static func isRetryable(_ error: Error) -> Bool {
+-        if error is HostKeys.Mismatch || error is KeyStore.KeyError { return false }
++        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return false }
+         if let e = error as? HerdrError, ["auth", "needs_update", "not_installed"].contains(e.kind ?? "") { return false }
+         return true
+     }
+@@ -524,6 +540,7 @@ final class AppStore {
+         teardownClient()
+         if !retry { reconnectTask?.cancel(); reconnectTask = nil }
+         hostKeyMismatch = error is HostKeys.Mismatch
++        unknownHostKey = error as? HostKeys.Unknown
+         connectStep = -1
+         phase = .failed((error as? LocalizedError)?.errorDescription ?? "\(error)")
+         // Only keep trying on our own when there's a session to get back to.
+diff --git a/App/Sources/UI/ConnectionViews.swift b/App/Sources/UI/ConnectionViews.swift
+index ec20878..4cda07e 100644
+--- a/App/Sources/UI/ConnectionViews.swift
++++ b/App/Sources/UI/ConnectionViews.swift
+@@ -274,6 +274,24 @@ struct FailureView: View {
+                     .controlSize(.large)
+                 }
+                 .padding(.top, 6)
++                if let key = store.unknownHostKey {
++                    VStack(alignment: .leading, spacing: 8) {
++                        Text("New host key").font(HF.ui(15, .semibold))
++                        Text(key.fingerprint)
++                            .font(HF.mono(12.5))
++                            .textSelection(.enabled)
++                            .accessibilityIdentifier("hostKeyFingerprint")
++                        Text("On \(key.host), compare it with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
++                            .font(HF.ui(13)).foregroundStyle(HC.muted)
++                        Button { store.trustHostKey(key) } label: {
++                            Label("Trust and connect", systemImage: "checkmark.shield")
++                        }
++                        .buttonStyle(.glassProminent)
++                        .font(HF.ui(15, .medium))
++                    }
++                    .padding(14)
++                    .herdrCard()
++                }
+                 if store.hostKeyMismatch, let m = store.activeMachine {
+                     Button(role: .destructive) { confirmForget = true } label: {
+                         Label("Forget host key", systemImage: "key.slash")
+@@ -286,7 +304,7 @@ struct FailureView: View {
+                             store.reconnect()
+                         }
+                     } message: {
+-                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; the next key it presents will be trusted.")
++                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; you will be asked to approve the key it presents next.")
+                     }
+                 }
+                 Text("Check that the host is reachable (e.g. Tailscale is on), the key is in authorized_keys, and herdr-core is installed in ~/.local/bin.")
+diff --git a/App/Sources/UI/RootView.swift b/App/Sources/UI/RootView.swift
+index 57156ff..b5bc68c 100644
+--- a/App/Sources/UI/RootView.swift
++++ b/App/Sources/UI/RootView.swift
+@@ -15,7 +15,8 @@ struct RootView: View {
+         switch store.phase {
+         case .connected: return .main
+         case .connecting: return hadSession ? .main : .connecting
+-        case .failed: return hadSession ? .main : .failed
++        // A first-seen host key needs the approval card on the failure screen even mid-session.
++        case .failed: return hadSession && store.unknownHostKey == nil ? .main : .failed
+         // Idle with nothing to show (e.g. Cancel on the connecting screen): the
+         // failure screen offers Connect and Edit machine instead of a dead spinner.
+         case .idle: return hadSession ? .main : .failed
+
+commit 1b740be0f3661954c95ec02bba3cd180f0de64bf
+Author: i2 <95607264+YosukeIida@users.noreply.github.com>
+Date:   Sun Nov 1 03:38:46 2026 +0900
+
+    List every core method the app calls in requiredMethods
+    
+    The hello check missed terminal.get/read/send/keys/interrupt, machine.list
+    and server.status, so a core lacking them connected and failed later on the
+    screen that needed them.
+
+diff --git a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
+index 1fdb6b3..3c3f88a 100644
+--- a/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
++++ b/Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift
+@@ -25,8 +25,10 @@ public final class HerdrClient: @unchecked Sendable {
+     public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }
+ 
+     /// Methods the app calls; a core lacking one can't serve it.
+-    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.kill", "terminal.label", "terminal.attach",
+-                                         "terminal.keep", "doc.get", "doc.set", "events.subscribe", "machine.exec"]
++    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
++                                         "terminal.attach", "terminal.keep", "terminal.read", "terminal.send", "terminal.keys",
++                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
++                                         "machine.list", "server.status"]
+     public static let minCoreVersion = "0.1.11"
+     public static let generation: UInt64 = 1
+ 
+diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
+index 2e7a840..ae09bc1 100644
+--- a/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
++++ b/Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift
+@@ -40,7 +40,7 @@ final class FakeTransport: ByteTransport, @unchecked Sendable {
+ }
+ 
+ final class ClientTests: XCTestCase {
+-    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec"]}}"# + "\n").utf8)
++    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
+ 
+     func connected() async throws -> (HerdrClient, FakeTransport) {
+         let t = FakeTransport()
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
+/bin/zsh -lc "git status --short; rg --files -g '*resolved' -g '*ChatModel*' -g '*HostKeys*' -g '*AGENTS*'; cat App/Sources/Chat/ChatModel.swift App/Sources/Net/KeyStore.swift App/Sources/Net/CitadelTransport.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+?? docs/reviews/
+Herdr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
+AGENTS.md
+AGENTS.ja.md
+App/Sources/Chat/ChatModel.swift
+App/Sources/Net/HostKeys.swift
+import SwiftUI
+import HerdrKit
+
+/// One entry the box-side script emitted (TranscriptScript).
+enum ChatEntry {
+    case user(String, Date?)
+    case note(String)
+    case command(String)
+    case compact
+    case text(String)
+    case tool(id: String, name: String, summary: String, detail: String, at: Date?)
+    case result(id: String, isError: Bool, output: String)
+    case duration(ms: Int)
+}
+
+struct ToolCall: Identifiable, Equatable {
+    var id: String
+    var name: String
+    var summary: String
+    var detail: String
+    var output: String?
+    var isError = false
+}
+
+enum ChatStep: Identifiable, Equatable {
+    case text(Int, String)
+    case tools(Int, [ToolCall])
+    var id: Int { switch self { case .text(let i, _), .tools(let i, _): i } }
+    var toolCount: Int { if case .tools(_, let c) = self { c.count } else { 0 } }
+}
+
+/// One prompt and everything the agent did in answer.
+struct ChatTurn: Identifiable, Equatable {
+    enum Prompt: Equatable { case user(String), note(String), command(String) }
+    var id: Int
+    var prompt: Prompt?
+    var compacted = false
+    var steps: [ChatStep] = []
+    var durationMs: Int?
+    var startedAt: Date?
+}
+
+/// Reads an agent's Claude Code transcript from the box and folds it into
+/// turns. Polls quickly while the agent works, slowly otherwise; never
+/// attaches to (or resizes) the terminal.
+@MainActor @Observable
+final class ChatModel {
+    enum Phase: Equatable { case loading, ready, unavailable(String), failed(String) }
+
+    let address: String
+    private(set) var phase: Phase = .loading
+    private(set) var turns: [ChatTurn] = []
+    /// The transcript continues above what was loaded (we only read its tail).
+    private(set) var hasEarlier = false
+    private(set) var revision = 0
+
+    private var entries: [ChatEntry] = []
+    private var session = ""
+    private var offset: Int64 = -1
+    private var loop: Task<Void, Never>?
+    private var wake: CheckedContinuation<Void, Never>?
+    private var sleeper: Task<Void, Never>?
+    private weak var store: AppStore?
+
+    init(address: String) { self.address = address }
+
+    func start(store: AppStore) {
+        self.store = store
+        #if DEBUG
+        if AppStore.isDemo { loadDemo(); return }
+        #endif
+        guard loop == nil else { return }
+        loop = Task { [weak self] in
+            while !Task.isCancelled {
+                guard let self else { return }
+                await self.load()
+                await self.pause()
+            }
+        }
+    }
+
+    func stop() {
+        loop?.cancel(); loop = nil
+        sleeper?.cancel(); sleeper = nil
+        wake?.resume(); wake = nil
+    }
+
+    /// Something changed (status, turn): read now instead of waiting.
+    func nudge() { wake?.resume(); wake = nil }
+
+    private func pause() async {
+        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
+        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
+        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
+            wake = c
+            // Cancelled so an earlier pause's timer can never end this one early.
+            sleeper?.cancel()
+            sleeper = Task { [weak self] in
+                try? await Task.sleep(for: delay)
+                guard !Task.isCancelled else { return }
+                self?.nudge()
+            }
+        }
+    }
+
+    private func load() async {
+        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
+        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
+        let argv = String(decoding: rec.raw["argv"].encoded(), as: UTF8.self)
+        for _ in 0..<4 {   // follow "more" a few times on a big backlog
+            do {
+                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
+                                             cwd: nil, on: nil, timeout: 20, input: nil)
+                guard r.code == 0 else {
+                    let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+                    phase = .failed(err.isEmpty ? "Couldn't read the conversation." : String(err.suffix(300)))
+                    return
+                }
+                if !apply(r.stdout) { return }
+            } catch {
+                if case .ready = phase {} else { phase = .failed(error.localizedDescription) }
+                return
+            }
+        }
+    }
+
+    /// Returns true when the box has more to send right away.
+    private func apply(_ data: Data) -> Bool {
+        var lines = data.split(separator: UInt8(ascii: "\n"))
+        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())) else { return false }
+        if let why = head["why"].string {
+            phase = .unavailable(why == "no-session"
+                ? "No Claude Code conversation found for this terminal yet."
+                : "Claude Code's transcript for this session isn't on disk yet.")
+            return false
+        }
+        let fresh = head["fresh"].bool ?? false
+        if fresh {
+            entries = []
+            session = head["session"].string ?? ""
+            hasEarlier = (head["start"].int ?? 0) > 0
+        }
+        offset = Int64(head["next"].double ?? Double(offset))
+        var added = false
+        for line in lines {
+            guard let e = try? JSONValue.parse(Data(line)), let entry = Self.entry(e) else { continue }
+            entries.append(entry); added = true
+        }
+        if fresh || added { rebuild() }
+        phase = .ready
+        return head["more"].bool ?? false
+    }
+
+    private static let iso: ISO8601DateFormatter = {
+        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
+    }()
+
+    private static func entry(_ e: JSONValue) -> ChatEntry? {
+        let t = e["t"].string ?? ""
+        let ts = e["ts"].string.flatMap { iso.date(from: $0) }
+        switch e["k"].string {
+        case "user": return .user(t, ts)
+        case "note": return .note(t)
+        case "cmd": return .command(t)
+        case "compact": return .compact
+        case "text": return .text(t)
+        case "tool": return .tool(id: e["id"].string ?? "", name: e["name"].string ?? "Tool",
+                                  summary: e["sum"].string ?? "", detail: e["detail"].string ?? "", at: ts)
+        case "result": return .result(id: e["id"].string ?? "", isError: e["err"].bool ?? false, output: e["out"].string ?? "")
+        case "dur": return .duration(ms: e["ms"].int ?? 0)
+        default: return nil
+        }
+    }
+
+    /// Folds entries into turns: a prompt starts one; texts and tool calls
+    /// follow; consecutive tool calls share a group; results attach by id.
+    private func rebuild() {
+        var out: [ChatTurn] = []
+        var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
+        var n = 0
+        func next() -> Int { n += 1; return n }
+        func current() -> Int {
+            if out.isEmpty { out.append(ChatTurn(id: next())) }
+            return out.count - 1
+        }
+        for e in entries {
+            switch e {
+            case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
+            case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
+            case .command(let s): out.append(ChatTurn(id: next(), prompt: .command(s)))
+            case .compact:
+                // A boundary and its "continued from" summary arrive together: one marker.
+                if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
+                out.append(ChatTurn(id: next(), compacted: true))
+            case .text(let s):
+                let i = current(); out[i].steps.append(.text(next(), s))
+            case .tool(let id, let name, let sum, let detail, let at):
+                let i = current()
+                if out[i].startedAt == nil { out[i].startedAt = at }
+                let call = ToolCall(id: id, name: name, summary: sum, detail: detail)
+                if case .tools(let sid, var calls)? = out[i].steps.last {
+                    calls.append(call)
+                    out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
+                    where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
+                } else {
+                    out[i].steps.append(.tools(next(), [call]))
+                    where_[id] = (i, out[i].steps.count - 1, 0)
+                }
+            case .result(let id, let err, let output):
+                guard let w = where_[id], case .tools(let sid, var calls) = out[w.turn].steps[w.step] else { continue }
+                calls[w.call].output = output
+                calls[w.call].isError = err
+                out[w.turn].steps[w.step] = .tools(sid, calls)
+            case .duration(let ms):
+                if !out.isEmpty { out[out.count - 1].durationMs = ms }
+            }
+        }
+        // A trailing "continued from earlier" marker with nothing after it reads oddly; keep it, it's honest.
+        turns = out
+        revision += 1
+    }
+}
+
+// MARK: Display helpers
+
+enum ToolStyle {
+    static func symbol(_ name: String) -> String {
+        switch name {
+        case "Bash", "BashOutput", "KillShell": "terminal"
+        case "Read": "doc.text"
+        case "Edit", "MultiEdit": "pencil"
+        case "Write", "NotebookEdit": "square.and.pencil"
+        case "Grep", "Glob", "ToolSearch": "magnifyingglass"
+        case "WebSearch", "WebFetch": "globe"
+        case "Agent", "Task", "SendMessage": "person.2"
+        case "TodoWrite": "checklist"
+        case "Skill": "sparkles"
+        case "Workflow": "point.3.connected.trianglepath.dotted"
+        default: name.hasPrefix("mcp__") ? "puzzlepiece.extension" : "wrench.and.screwdriver"
+        }
+    }
+
+    /// "mcp__claude-artifacts__get_artifact" -> "claude-artifacts · get_artifact"
+    static func title(_ name: String) -> String {
+        guard name.hasPrefix("mcp__") else { return name }
+        let parts = name.dropFirst(5).components(separatedBy: "__")
+        return parts.count >= 2 ? "\(parts[0]) · \(parts.dropFirst().joined(separator: "__"))" : String(name.dropFirst(5))
+    }
+
+    static func duration(ms: Int) -> String {
+        let s = ms / 1000
+        if s < 60 { return "\(max(s, 1))s" }
+        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
+        return "\(s / 3600)h \((s % 3600) / 60)m"
+    }
+}
+
+#if DEBUG
+// A canned conversation for screenshots (HERDR_DEMO=1).
+extension ChatModel {
+    fileprivate func loadDemo() {
+        let now = Date()
+        entries = [
+            .user("Add a global time slider to the analytics dashboard so every chart shares one range", now.addingTimeInterval(-900)),
+            .text("I'll start by looking at how the dashboard wires its charts together."),
+            .tool(id: "a", name: "Read", summary: "~/projects/webapp/src/dashboard/Dashboard.tsx", detail: "", at: nil),
+            .result(id: "a", isError: false, output: "214 lines"),
+            .tool(id: "b", name: "Grep", summary: "useTimeRange", detail: "", at: nil),
+            .result(id: "b", isError: false, output: "Found 7 files"),
+            .tool(id: "c", name: "Edit", summary: "~/projects/webapp/src/dashboard/TimeSlider.tsx", detail: "+ export function TimeSlider({ range, onChange }: TimeSliderProps) {\n+   const [draft, setDraft] = useState(range);", at: nil),
+            .result(id: "c", isError: false, output: "Updated with 48 additions and 3 removals"),
+            .tool(id: "d", name: "Bash", summary: "Run the dashboard tests", detail: "npm test -- dashboard", at: nil),
+            .result(id: "d", isError: false, output: "Tests: 42 passed, 42 total"),
+            .text("""
+            Every chart on the dashboard now follows **one shared time range**.
+
+            **What changed**
+            - A new `TimeSlider` sits in the dashboard header; dragging it updates every chart after a short debounce.
+            - Charts read the range from `useTimeRange()` instead of keeping their own.
+
+            | Chart | Before | After |
+            |---|---|---|
+            | Net flow | own range | shared |
+            | Volume | own range | shared |
+            | Latency | fixed 24h | shared |
+
+            Tests pass (42/42). Want me to persist the range in the URL so links keep it?
+            """),
+            .duration(ms: 318_000),
+            .user("Yes, put it in the URL", now.addingTimeInterval(-95)),
+            .text("Adding a `range` query parameter and reading it on load."),
+            .tool(id: "e", name: "Edit", summary: "~/projects/webapp/src/dashboard/useTimeRange.ts", detail: "", at: nil),
+            .result(id: "e", isError: false, output: "Updated"),
+            .tool(id: "f", name: "Bash", summary: "Type-check the project", detail: "npx tsc --noEmit", at: nil),
+        ]
+        rebuild()
+        phase = .ready
+    }
+}
+#endif
+import Foundation
+import Security
+import Crypto
+import Citadel
+
+/// The app's SSH identity and saved passwords, in the Keychain
+/// (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: never synced or backed up).
+enum KeyStore {
+    private static let service = "com.zzulanas.herdr.ssh"
+    private static let keyAccount = "ed25519"
+
+    enum KeyError: LocalizedError {
+        case keychain(OSStatus)
+        case badKey(String)
+        var errorDescription: String? {
+            switch self {
+            case .keychain(let s): "Keychain error \(s)"
+            case .badKey(let why): why
+            }
+        }
+    }
+
+    /// The signing key: a DEBUG override file, else the Keychain, else a new one (saved).
+    static func signingKey() throws -> Curve25519.Signing.PrivateKey {
+        #if DEBUG
+        if let path = ProcessInfo.processInfo.environment["HERDR_DEBUG_KEY_PATH"], !path.isEmpty {
+            let text = try String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8)
+            return try parseOpenSSH(text)
+        }
+        #endif
+        if let raw = try read(account: keyAccount) {
+            return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
+        }
+        let key = Curve25519.Signing.PrivateKey()
+        try write(key.rawRepresentation, account: keyAccount)
+        return key
+    }
+
+    /// OpenSSH one-line public key: `ssh-ed25519 AAAA… herdr-ios`.
+    static func publicKeyLine() -> String {
+        guard let key = try? signingKey() else { return "" }
+        return publicKeyLine(for: key.publicKey)
+    }
+
+    static func publicKeyLine(for pub: Curve25519.Signing.PublicKey, comment: String = "herdr-ios") -> String {
+        var blob = Data()
+        func sshString(_ d: Data) {
+            withUnsafeBytes(of: UInt32(d.count).bigEndian) { blob.append(contentsOf: $0) }
+            blob.append(d)
+        }
+        sshString(Data("ssh-ed25519".utf8))
+        sshString(pub.rawRepresentation)
+        return "ssh-ed25519 \(blob.base64EncodedString()) \(comment)"
+    }
+
+    /// Replaces the app key with a pasted, unencrypted OpenSSH ed25519 private key.
+    static func importPrivateKey(_ openSSHText: String) throws {
+        let key = try parseOpenSSH(openSSHText)
+        try write(key.rawRepresentation, account: keyAccount)
+    }
+
+    /// Generates a fresh key (the old one is gone for good).
+    static func regenerateKey() throws {
+        try write(Curve25519.Signing.PrivateKey().rawRepresentation, account: keyAccount)
+    }
+
+    private static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
+        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
+        guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
+            throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
+        }
+        do {
+            return try Curve25519.Signing.PrivateKey(sshEd25519: trimmed + "\n")
+        } catch {
+            throw KeyError.badKey("Couldn't read that key: only unencrypted ed25519 keys work (\(error))")
+        }
+    }
+
+    // MARK: Passwords
+
+    static func password(for machine: UUID) -> String? {
+        (try? read(account: "pw." + machine.uuidString)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
+    }
+
+    static func setPassword(_ password: String?, for machine: UUID) {
+        let account = "pw." + machine.uuidString
+        if let password, !password.isEmpty {
+            try? write(Data(password.utf8), account: account)
+        } else {
+            delete(account: account)
+        }
+    }
+
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
+    // MARK: Keychain
+
+    private static func query(_ account: String) -> [String: Any] {
+        [kSecClass as String: kSecClassGenericPassword,
+         kSecAttrService as String: service,
+         kSecAttrAccount as String: account]
+    }
+
+    private static func read(account: String) throws -> Data? {
+        var q = query(account)
+        q[kSecReturnData as String] = true
+        q[kSecMatchLimit as String] = kSecMatchLimitOne
+        var out: CFTypeRef?
+        let status = SecItemCopyMatching(q as CFDictionary, &out)
+        if status == errSecItemNotFound { return nil }
+        guard status == errSecSuccess else { throw KeyError.keychain(status) }
+        return out as? Data
+    }
+
+    /// Update in place, add only when missing: a failed write never loses the existing item.
+    private static func write(_ data: Data, account: String) throws {
+        let attrs: [String: Any] = [kSecValueData as String: data,
+                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
+        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
+        if status == errSecItemNotFound {
+            var q = query(account)
+            for (k, v) in attrs { q[k] = v }
+            status = SecItemAdd(q as CFDictionary, nil)
+        }
+        guard status == errSecSuccess else { throw KeyError.keychain(status) }
+    }
+
+    private static func delete(account: String) {
+        SecItemDelete(query(account) as CFDictionary)
+    }
+}
+import Foundation
+import HerdrKit
+import Citadel
+import Crypto
+import NIOCore
+import NIOSSH
+
+/// `ByteTransport` over an SSH exec channel (no PTY) running
+/// `herdrConnectCommand`, via Citadel.
+final class CitadelTransport: ByteTransport, @unchecked Sendable {
+    enum Auth {
+        case key(Curve25519.Signing.PrivateKey)
+        case password(String)
+    }
+
+    let host: String, port: Int, user: String
+    private let auth: Auth
+    private let lock = NSLock()
+    private var client: SSHClient?
+    private var writer: TTYStdinWriter?
+    private var task: Task<Void, Never>?
+    private var closed = false
+    private var onClose: (@Sendable (Error?) -> Void)?
+
+    init(host: String, port: Int, user: String, auth: Auth) {
+        self.host = host; self.port = port; self.user = user; self.auth = auth
+    }
+
+    func start(onBytes: @escaping @Sendable (Data) -> Void,
+               onStderr: @escaping @Sendable (Data) -> Void,
+               onClose: @escaping @Sendable (Error?) -> Void) async throws {
+        let method: SSHAuthenticationMethod = switch auth {
+        case .key(let k): .ed25519(username: user, privateKey: k)
+        case .password(let p): .passwordBased(username: user, password: p)
+        }
+        let client: SSHClient
+        do {
+            client = try await SSHClient.connect(
+                host: host, port: port, authenticationMethod: method,
+                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
+                reconnect: .never, connectTimeout: .seconds(12))
+        } catch {
+            throw Self.friendly(error, host: host, user: user)
+        }
+        let isClosed: Bool = lock.withLock {
+            self.client = client; self.onClose = onClose; return closed
+        }
+        if isClosed { try? await client.close(); throw HerdrError(code: -1, kind: "closed", message: "Disconnected") }
+
+        // The exec channel lives in this task; `start` returns once stdin is writable.
+        try await withCheckedThrowingContinuation { (ready: CheckedContinuation<Void, Error>) in
+            let readyOnce = Once(ready)
+            let t = Task.detached { [weak self] in
+                var failure: Error?
+                do {
+                    try await client.withExec(herdrConnectCommand) { inbound, outbound in
+                        self?.lock.withLock { self?.writer = outbound }
+                        readyOnce.resume(.success(()))
+                        for try await out in inbound {
+                            switch out {
+                            case .stdout(let b): onBytes(Data(b.readableBytesView))
+                            case .stderr(let b): onStderr(Data(b.readableBytesView))
+                            }
+                        }
+                    }
+                } catch let e as SSHClient.CommandFailed where e.exitCode == 127 {
+                    failure = HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine",
+                                         hint: "install herdr-core in ~/.local/bin")
+                } catch is CancellationError {
+                } catch {
+                    failure = error
+                }
+                readyOnce.resume(.failure(failure ?? HerdrError.lost))
+                self?.finish(failure)
+            }
+            lock.withLock { task = t }
+        }
+    }
+
+    func write(_ data: Data) async throws {
+        guard let w = lock.withLock({ closed ? nil : writer }) else { throw HerdrError.lost }
+        try await w.write(ByteBuffer(bytes: data))
+    }
+
+    func close() {
+        let (t, c, cb): (Task<Void, Never>?, SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
+            guard !closed else { return (nil, nil, nil) }
+            closed = true
+            defer { onClose = nil; writer = nil }
+            return (task, client, onClose)
+        }
+        t?.cancel()
+        if let c { Task.detached { try? await c.close() } }
+        cb?(nil)
+    }
+
+    private func finish(_ err: Error?) {
+        let (c, cb): (SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
+            guard !closed else { return (nil, nil) }
+            closed = true
+            defer { onClose = nil; writer = nil }
+            return (client, onClose)
+        }
+        if let c { Task.detached { try? await c.close() } }
+        cb?(err)
+    }
+
+    /// SSH failures in words a person can act on.
+    static func friendly(_ error: Error, host: String, user: String) -> Error {
+        if error is HostKeys.Mismatch || error is HostKeys.Unknown { return error }
+        if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
+            return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
+                              hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
+        }
+        let text = String(describing: error)
+        if text.contains("connectTimeout") || text.contains("timeout") || text.contains("Timeout") {
+            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "is Tailscale connected?")
+        }
+        if text.contains("connectionRefused") || text.contains("Connection refused") {
+            return HerdrError(code: -1, kind: "unreachable", message: "\(host) refused the SSH connection", hint: "is sshd running on port 22?")
+        }
+        if text.contains("NIOConnectionError") || text.contains("unreachable") || text.contains("resolve") {
+            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "check the address and your network")
+        }
+        return HerdrError(code: -1, kind: "ssh", message: "SSH to \(host) failed", hint: text)
+    }
+}
+
+/// Resumes a continuation at most once.
+private final class Once: @unchecked Sendable {
+    private let lock = NSLock()
+    private var cont: CheckedContinuation<Void, Error>?
+    init(_ c: CheckedContinuation<Void, Error>) { cont = c }
+    func resume(_ r: Result<Void, Error>) {
+        let c: CheckedContinuation<Void, Error>? = lock.withLock { defer { cont = nil }; return cont }
+        c?.resume(with: r)
+    }
+}
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '120,245p' App/Sources/Store/AppStore.swift; sed -n '470,590p' App/Sources/Store/AppStore.swift; cat App/Sources/UI/RootView.swift App/Sources/UI/SettingsView.swift; sed -n '340,415p' App/Sources/UI/MainView.swift; sed -n '230,330p' App/Sources/UI/ConnectionViews.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+            if client == nil || self.phase != .connected {
+                attempt = 0
+                startConnect(m, reconnecting: hello != nil)
+            } else {
+                // The socket may have died while suspended: probe it now rather than waiting for liveness.
+                let gen = generation
+                Task { [weak self] in
+                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
+                        guard let self, gen == self.generation, self.wantConnected else { return }
+                        self.connectionLost(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: "no answer after resuming"), gen: gen)
+                    }
+                }
+            }
+        case .background:
+            sceneActive = false
+            saveAttentionNow()
+            guard client != nil, backgroundTask == nil else { return }
+            // iOS kills sockets in the background: close cleanly after a short grace.
+            let bgID = UIApplication.shared.beginBackgroundTask(withName: "herdr.disconnect")
+            backgroundTask = Task { [weak self] in
+                try? await Task.sleep(for: .seconds(8))
+                if !Task.isCancelled, let self, !self.sceneActive { self.dropConnection(phase: .idle) }
+                UIApplication.shared.endBackgroundTask(bgID)
+            }
+        case .inactive:
+            break
+        @unknown default:
+            break
+        }
+    }
+
+    func connect(to machine: MachineConfig) {
+        if !machines.contains(where: { $0.id == machine.id }) { machines.append(machine) }
+        if activeMachineID != machine.id {
+            dropConnection(phase: .idle)
+            activeMachineID = machine.id
+            clearLiveState()
+            loadMachineState()
+        }
+        wantConnected = true
+        attempt = 0
+        startConnect(machine, reconnecting: false)
+    }
+
+    func reconnect() {
+        guard let m = currentMachine() else { return }
+        wantConnected = true
+        attempt = 0
+        startConnect(m, reconnecting: hello != nil)
+    }
+
+    func disconnect() {
+        wantConnected = false
+        dropConnection(phase: .idle)
+    }
+
+    func saveMachine(_ m: MachineConfig, password: String?) {
+        let old = machines.first { $0.id == m.id }
+        if let i = machines.firstIndex(where: { $0.id == m.id }) { machines[i] = m } else { machines.append(m) }
+        if let password { KeyStore.setPassword(password, for: m.id) }
+        if activeMachineID == nil { activeMachineID = m.id }
+        // Changed where/how we connect: reconnect with the new settings.
+        if m.id == activeMachineID, let old, old != m, wantConnected { connect(to: m) }
+    }
+
+    func removeMachine(_ id: UUID) {
+        guard let m = machines.first(where: { $0.id == id }) else { return }
+        if id == activeMachineID {
+            disconnect()
+            clearLiveState()
+            activeMachineID = machines.first { $0.id != id }?.id
+        }
+        machines.removeAll { $0.id == id }
+        KeyStore.setPassword(nil, for: id)
+        HostKeys.forget(host: m.host, port: m.port)
+        for k in ["attention.", "view.", "home."] { defaults.removeObject(forKey: k + id.uuidString) }
+    }
+
+    /// The app's own SSH public key, OpenSSH one-line form ("ssh-ed25519 AAAA... herdr-ios").
+    func publicKeyLine() -> String {
+        if let k = cachedPublicKey { return k }
+        let k = KeyStore.publicKeyLine()
+        if !k.isEmpty { cachedPublicKey = k }
+        return k
+    }
+
+    /// Replace the app key with a pasted OpenSSH ed25519 private key.
+    func importPrivateKey(_ text: String) throws {
+        try KeyStore.importPrivateKey(text)
+        cachedPublicKey = nil
+    }
+
+    /// Forget a machine's pinned host key (after a legitimate reinstall).
+    func forgetHostKey(_ machine: MachineConfig) { HostKeys.forget(host: machine.host, port: machine.port) }
+
+    /// The pinned host key fingerprint (SHA256:…), nil before the first connect.
+    func hostKeyFingerprint(_ machine: MachineConfig) -> String? { HostKeys.pinnedFingerprint(host: machine.host, port: machine.port) }
+
+    /// The last connect failed because the host key changed.
+    private(set) var hostKeyMismatch = false
+
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
+    /// Pull-to-refresh / screens that want a step index rather than text.
+    /// 0 SSH, 1 starting core, 2 hello, 3 events + layout; -1 when not connecting.
+    private(set) var connectStep = -1
+
+    // MARK: Derived views
+
+    func spaceName(_ s: SpaceRef) -> String {
+        let first = s.tabs.lazy.flatMap(\.panes).compactMap(\.terminal).first
+        return Names.spaceName(s, firstTerminalCwd: first.flatMap { terminals[$0]?.cwd }.flatMap { $0.isEmpty ? nil : $0 }, home: home)
+    }
+        reconnectTask?.cancel(); reconnectTask = nil
+        connectTask?.cancel()
+        teardownClient()
+        generation += 1
+        let gen = generation
+        // Synchronously, so no frame shows the idle/failure screen before the task runs.
+        connectStep = 0
+        phase = .connecting(reconnecting ? "Reconnecting to \(m.host)" : "Opening SSH to \(m.host)")
+        connectTask = Task { [weak self] in await self?.runConnect(m, gen: gen, reconnecting: reconnecting) }
+    }
+
+    private func step(_ s: String, _ index: Int, _ gen: Int) -> Bool {
+        guard gen == generation, !Task.isCancelled else { return false }
+        connectStep = index
+        phase = .connecting(s)
+        return true
+    }
+
+    private func runConnect(_ m: MachineConfig, gen: Int, reconnecting: Bool) async {
+        let verb = reconnecting ? "Reconnecting" : "Opening SSH"
+        guard step("\(verb) to \(m.host)", 0, gen) else { return }
+        let auth: CitadelTransport.Auth
+        do {
+            if m.usePassword, let pw = KeyStore.password(for: m.id) { auth = .password(pw) } else { auth = .key(try KeyStore.signingKey()) }
+        } catch {
+            fail(error, gen: gen, retry: false); return
+        }
+        let transport = CitadelTransport(host: m.host, port: m.port, user: m.user, auth: auth)
+        let c = HerdrClient(transport: transport)
+        c.onDisconnect = { [weak self] err in self?.connectionLost(err, gen: gen) }
+        client = c
+        do {
+            _ = step("Starting herdr-core", 1, gen)
+            let info = try await c.connect()
+            guard gen == generation else { c.close(); return }
+            hello = info
+            diagnostics = ""
+
+            guard step("Subscribing to events", 2, gen) else { return }
+            let sub = try await c.subscribe()
+            guard gen == generation else { return }
+            wire(sub, gen: gen)
+            absorbSnapshot(sub.snapshot)
+
+            guard step("Reading the layout", 3, gen) else { return }
+            let d = try await c.docGet(HerdrKit.Layout.docName)
+            guard gen == generation else { return }
+            applyDoc(d)
+
+            phase = .connected
+            connectStep = -1
+            hostKeyMismatch = false
+            unknownHostKey = nil
+            attempt = 0
+            Task { [weak self] in await self?.learnHome(gen: gen) }
+        } catch {
+            guard gen == generation else { return }
+            diagnostics = c.stderrText
+            fail(error, gen: gen, retry: Self.isRetryable(error))
+        }
+    }
+
+    private static func isRetryable(_ error: Error) -> Bool {
+        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return false }
+        if let e = error as? HerdrError, ["auth", "needs_update", "not_installed"].contains(e.kind ?? "") { return false }
+        return true
+    }
+
+    private func fail(_ error: Error, gen: Int, retry: Bool) {
+        guard gen == generation else { return }
+        teardownClient()
+        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
+        hostKeyMismatch = error is HostKeys.Mismatch
+        unknownHostKey = error as? HostKeys.Unknown
+        connectStep = -1
+        phase = .failed((error as? LocalizedError)?.errorDescription ?? "\(error)")
+        // Only keep trying on our own when there's a session to get back to.
+        if retry, wantConnected, hello != nil { scheduleReconnect() }
+    }
+
+    private func connectionLost(_ error: HerdrError, gen: Int) {
+        // Only a live session is "lost": while connecting, runConnect's catch owns the error
+        // (otherwise a non-retryable failure would be replaced by an endless "Reconnecting").
+        guard gen == generation, phase == .connected else { return }
+        teardownClient()
+        alertsArmed = false
+        guard wantConnected else { phase = .idle; return }
+        connectStep = 0
+        phase = .connecting("Reconnecting")
+        if sceneActive { scheduleReconnect(immediate: attempt == 0) }
+    }
+
+    private func scheduleReconnect(immediate: Bool = false) {
+        guard wantConnected, sceneActive, let m = currentMachine() else { return }
+        reconnectTask?.cancel()
+        let delay = immediate ? 0.3 : min(15, pow(2, Double(min(attempt, 4))))   // 1, 2, 4, 8, 15 s
+        attempt += 1
+        reconnectTask = Task { [weak self] in
+            try? await Task.sleep(for: .seconds(delay))
+            guard !Task.isCancelled, let self, self.wantConnected, self.sceneActive else { return }
+            self.startConnect(m, reconnecting: true)
+        }
+    }
+
+    /// Closes the connection quietly (no reconnect from its callbacks).
+    private func dropConnection(phase newPhase: ConnectionPhase) {
+        generation += 1
+        connectTask?.cancel(); connectTask = nil
+        reconnectTask?.cancel(); reconnectTask = nil
+        teardownClient()
+        alertsArmed = false
+        connectStep = -1
+        phase = newPhase
+    }
+
+    private func teardownClient() {
+        subscription?.onUpdate = nil; subscription?.onClose = nil; subscription?.onLost = nil
+        subscription = nil
+        if let c = client { c.onDisconnect = nil; c.close() }
+        client = nil
+    }
+import SwiftUI
+import HerdrKit
+
+struct RootView: View {
+    @Environment(AppStore.self) private var store
+    @AppStorage("appearance") private var appearance = "system"
+
+    private enum Stage: Equatable { case onboarding, connecting, failed, main }
+
+    /// Once we have a live picture of the box, keep showing it through
+    /// reconnects (a banner says what's happening) instead of a blank screen.
+    private var stage: Stage {
+        if store.machines.isEmpty && store.terminals.isEmpty { return .onboarding }
+        let hadSession = store.hello != nil || !store.terminals.isEmpty
+        switch store.phase {
+        case .connected: return .main
+        case .connecting: return hadSession ? .main : .connecting
+        // A first-seen host key needs the approval card on the failure screen even mid-session.
+        case .failed: return hadSession && store.unknownHostKey == nil ? .main : .failed
+        // Idle with nothing to show (e.g. Cancel on the connecting screen): the
+        // failure screen offers Connect and Edit machine instead of a dead spinner.
+        case .idle: return hadSession ? .main : .failed
+        }
+    }
+
+    var body: some View {
+        ZStack {
+            HC.canvas.ignoresSafeArea()
+            switch stage {
+            case .onboarding: OnboardingView()
+            case .connecting: ConnectingView()
+            case .failed: FailureView()
+            case .main: MainView()
+            }
+        }
+        .animation(.smooth(duration: 0.3), value: stage)
+        .overlay(alignment: .top) { ToastOverlay() }
+        .sensoryFeedback(trigger: blockedCount) { old, new in new > old ? .warning : nil }
+        .tint(HC.accent)
+        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
+        .task {
+            #if DEBUG
+            if AppStore.isDemo { store.loadDemo(); return }
+            #endif
+            if store.phase == .idle, let m = store.activeMachine { store.connect(to: m) }
+        }
+    }
+
+    /// Cheap: no names or pane index, just the attention words.
+    private var blockedCount: Int {
+        store.terminals.values.lazy.filter { $0.isLive && $0.parent == nil && store.attention(of: $0.address) == .blocked }.count
+    }
+}
+
+// MARK: Toasts
+
+struct ToastOverlay: View {
+    @Environment(AppStore.self) private var store
+
+    var body: some View {
+        GlassEffectContainer(spacing: 8) {
+            VStack(spacing: 8) {
+                ForEach(store.toasts.suffix(3)) { toast in
+                    ToastCapsule(toast: toast)
+                        .transition(.move(edge: .top).combined(with: .opacity))
+                        .task {
+                            try? await Task.sleep(for: .seconds(toast.duration ?? (toast.level == "error" ? 6 : 3.5)))
+                            withAnimation(.smooth) { store.toasts.removeAll { $0.id == toast.id } }
+                        }
+                        .onTapGesture {
+                            withAnimation(.smooth) { store.toasts.removeAll { $0.id == toast.id } }
+                            // An agent alert opens that agent.
+                            if let a = toast.address { store.pendingOpen = a }
+                        }
+                        .accessibilityAddTraits(toast.address != nil ? .isButton : [])
+                        .accessibilityHint(toast.address != nil ? "Opens the agent" : "")
+                }
+            }
+        }
+        .padding(.horizontal, 16)
+        .padding(.top, 4)
+        .animation(.spring(duration: 0.35), value: store.toasts)
+    }
+}
+
+private struct ToastCapsule: View {
+    var toast: AppStore.Toast
+
+    var body: some View {
+        HStack(spacing: 10) {
+            Image(systemName: icon).foregroundStyle(tint).font(.system(size: 15, weight: .semibold))
+            VStack(alignment: .leading, spacing: 1) {
+                Text(toast.title).font(HF.ui(14.5, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
+                if let body = toast.body, !body.isEmpty {
+                    Text(body).font(HF.ui(12.5)).foregroundStyle(HC.muted).lineLimit(2)
+                }
+            }
+            Spacer(minLength: 0)
+        }
+        .padding(.horizontal, 16)
+        .padding(.vertical, 11)
+        .frame(maxWidth: 440)
+        .glassEffect(.regular, in: .capsule)
+        .accessibilityElement(children: .combine)
+    }
+
+    private var icon: String {
+        switch toast.level {
+        case "error": "exclamationmark.triangle.fill"
+        case "warning", "blocked": "hand.raised.fill"
+        case "success", "done": "checkmark.circle.fill"
+        default: "bell.fill"
+        }
+    }
+    private var tint: Color {
+        switch toast.level {
+        case "error", "warning", "blocked": HC.blocked
+        case "success", "done": HC.done
+        default: HC.accent
+        }
+    }
+}
+import SwiftUI
+import UIKit
+import HerdrKit
+
+struct SettingsView: View {
+    @Environment(AppStore.self) private var store
+    @Environment(\.dismiss) private var dismiss
+    @AppStorage("appearance") private var appearance = "system"
+    @AppStorage("terminalFontSize") private var fontSize = 13.0
+    @State private var editing: MachineConfig?
+    @State private var confirmForget: MachineConfig?
+
+    var body: some View {
+        NavigationStack {
+            Form {
+                Section("Machines") {
+                    ForEach(store.machines) { m in
+                        HStack(spacing: 12) {
+                            Image(systemName: "server.rack").foregroundStyle(HC.muted).frame(width: 22)
+                            VStack(alignment: .leading, spacing: 2) {
+                                Text(m.label).font(HF.ui(15.5, .medium)).foregroundStyle(HC.fg)
+                                Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(11.5)).foregroundStyle(HC.dim)
+                            }
+                            Spacer()
+                            if m.id == store.activeMachine?.id { ConnectionDot(phase: store.phase) }
+                        }
+                        .contentShape(.rect)
+                        .onTapGesture { editing = m }
+                        .swipeActions {
+                            Button("Remove", role: .destructive) { store.removeMachine(m.id) }
+                            if m.id != store.activeMachine?.id || store.phase != .connected {
+                                Button("Connect") { store.connect(to: m) }.tint(HC.accent)
+                            }
+                        }
+                    }
+                    Button { editing = MachineConfig(label: "", host: "", user: "") } label: {
+                        Label("Add machine", systemImage: "plus")
+                    }
+                    if store.phase == .connected {
+                        Button("Disconnect", role: .destructive) { store.disconnect() }
+                    } else if store.activeMachine != nil {
+                        Button("Reconnect") { store.reconnect() }
+                    }
+                    if let m = store.activeMachine, let fp = store.hostKeyFingerprint(m) {
+                        VStack(alignment: .leading, spacing: 4) {
+                            Text("Host key").font(HF.ui(13, .medium)).foregroundStyle(HC.muted)
+                            Text(fp).font(HF.mono(11)).foregroundStyle(HC.fg).textSelection(.enabled).lineLimit(2)
+                        }
+                        Button("Forget host key", role: .destructive) { confirmForget = m }
+                    }
+                }
+                .confirmationDialog("Forget the host key?", isPresented: Binding(get: { confirmForget != nil }, set: { if !$0 { confirmForget = nil } }),
+                                    titleVisibility: .visible, presenting: confirmForget) { m in
+                    Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
+                } message: { m in
+                    Text("Only after \(m.host) was reinstalled. The next key it presents will be trusted and pinned.")
+                }
+
+                NotificationSection()
+
+                Section("Appearance") {
+                    Picker("Theme", selection: $appearance) {
+                        Text("System").tag("system")
+                        Text("Graphite (dark)").tag("dark")
+                        Text("Paper (light)").tag("light")
+                    }
+                    VStack(alignment: .leading, spacing: 10) {
+                        Stepper(value: $fontSize, in: 9...20, step: 1) {
+                            HStack {
+                                Text("Terminal text")
+                                Spacer()
+                                Text("\(Int(fontSize)) pt").foregroundStyle(HC.muted).monospacedDigit()
+                            }
+                        }
+                        Text("The quick brown fox → 0123 {}[]")
+                            .font(HF.mono(fontSize))
+                            .foregroundStyle(HC.fg)
+                            .lineLimit(1)
+                            .minimumScaleFactor(0.5)
+                    }
+                    Text("Terminals mirror the desktop's size and scale down to fit (min 7 pt). Pinch to zoom; use Fit to phone in a terminal's menu to resize the program instead.")
+                        .font(HF.ui(12.5)).foregroundStyle(HC.dim)
+                }
+
+                ModSettingsView()
+
+                Section("About") {
+                    LabeledContent("Herdr for iOS", value: appVersion)
+                    if let h = store.hello {
+                        LabeledContent("Core", value: h.coreName)
+                        LabeledContent("herdr-core", value: h.version)
+                        LabeledContent("Core id", value: String(h.coreID.prefix(12)))
+                    } else {
+                        LabeledContent("Core", value: "Not connected")
+                    }
+                    NavigationLink("Licenses") { LicensesView() }
+                }
+            }
+            .scrollContentBackground(.hidden)
+            .background(HC.canvas)
+            .font(HF.ui(15.5))
+            .navigationTitle("Settings")
+            .navigationBarTitleDisplayMode(.inline)
+            .toolbar {
+                ToolbarItem(placement: .confirmationAction) { Button("Done", systemImage: "checkmark") { dismiss() } }
+            }
+            .sheet(item: $editing) { m in
+                NavigationStack {
+                    ScrollView { MachineForm(machine: m).padding(16) }
+                        .background(HC.canvas)
+                        .navigationTitle(m.host.isEmpty ? "Add machine" : m.label)
+                        .navigationBarTitleDisplayMode(.inline)
+                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = nil } } }
+                }
+            }
+        }
+        .presentationDragIndicator(.visible)
+    }
+
+    private var appVersion: String {
+        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
+        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
+        return "\(v) (\(b))"
+    }
+}
+
+struct LicensesView: View {
+    private struct Entry: Identifiable { var id: String { title }; var title: String; var text: String }
+
+    private var entries: [Entry] {
+        func file(_ name: String, _ ext: String) -> String? {
+            Bundle.main.url(forResource: name, withExtension: ext).flatMap { try? String(contentsOf: $0, encoding: .utf8) }
+        }
+        func asset(_ name: String) -> String? {
+            NSDataAsset(name: name).flatMap { String(data: $0.data, encoding: .utf8) }
+        }
+        return [
+            file("OFL", "txt").map { Entry(title: "Geist (SIL OFL 1.1)", text: $0) },
+            file("OFL-JetBrainsMono", "txt").map { Entry(title: "JetBrains Mono (SIL OFL 1.1)", text: $0) },
+            file("LICENSE-SymbolsNerdFont", "txt").map { Entry(title: "Symbols Nerd Font (MIT)", text: $0) },
+            asset("License-Lucide").map { Entry(title: "Lucide icons (ISC)", text: $0) },
+            asset("License-LobeHub").map { Entry(title: "LobeHub icons (MIT)", text: $0) },
+            Entry(title: "Brand marks", text: "Brand icons from Simple Icons (CC0 1.0). Agent and brand marks are trademarks of their owners."),
+            Entry(title: "SwiftTerm (MIT)", text: "SwiftTerm by Miguel de Icaza. https://github.com/migueldeicaza/SwiftTerm"),
+            Entry(title: "Citadel (MIT)", text: "Citadel by Orlandos. https://github.com/orlandos-nl/Citadel"),
+        ].compactMap { $0 }
+    }
+
+    var body: some View {
+        List(entries) { e in
+            NavigationLink(e.title) {
+                ScrollView {
+                    Text(e.text).font(HF.mono(11.5)).foregroundStyle(HC.muted).textSelection(.enabled)
+                        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
+                }
+                .background(HC.canvas)
+                .navigationTitle(e.title)
+                .navigationBarTitleDisplayMode(.inline)
+            }
+        }
+        .scrollContentBackground(.hidden)
+        .background(HC.canvas)
+        .navigationTitle("Licenses")
+    }
+}
+    var body: some View {
+        VStack(spacing: 12) {
+            Image(systemName: "sparkles.rectangle.stack").font(.system(size: 34, weight: .light)).foregroundStyle(HC.dim)
+            Text(store.phase == .connected ? "No agents running" : "Waiting for \(store.machineTitle)")
+                .font(HF.ui(16, .medium)).foregroundStyle(HC.muted)
+            if store.phase == .connected {
+                Button { nav.showNewAgent = true } label: { Label("Start an agent", systemImage: "plus") }
+                    .buttonStyle(.glass).font(HF.ui(15, .medium))
+            }
+        }
+        .frame(maxWidth: .infinity)
+        .padding(.vertical, 60)
+    }
+}
+
+/// Shown above the lists while the connection isn't live.
+struct ConnectionBanner: View {
+    @Environment(AppStore.self) private var store
+    var body: some View {
+        switch store.phase {
+        case .connected:
+            EmptyView()
+        case .connecting(let step):
+            HStack(spacing: 10) {
+                Spinner(color: HC.working, size: 13)
+                Text(step.isEmpty ? "Reconnecting…" : "\(step)…").font(HF.ui(14, .medium)).foregroundStyle(HC.fg)
+                Spacer()
+            }
+            .padding(.horizontal, 14).padding(.vertical, 10)
+            .herdrCard()
+            .padding(.top, 8)
+        case .failed(let msg):
+            failed(msg)
+        case .idle:
+            failed("Disconnected")
+        }
+    }
+
+    private func failed(_ msg: String) -> some View {
+        HStack(spacing: 10) {
+            Image(systemName: "bolt.horizontal.circle").foregroundStyle(HC.blocked)
+            Text(msg).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(2)
+            Spacer()
+            Button("Retry") { store.reconnect() }.buttonStyle(.glass).font(HF.ui(14, .semibold))
+        }
+        .padding(.leading, 14).padding(.trailing, 8).padding(.vertical, 8)
+        .herdrCard()
+        .padding(.top, 8)
+    }
+}
+
+/// Floating glass bar: machine status on the left, New agent on the right.
+private struct HomeBottomBar: View {
+    @Environment(AppStore.self) private var store
+    @Environment(Navigator.self) private var nav
+    var model: HomeModel
+    @Namespace private var ns
+
+    var body: some View {
+        GlassEffectContainer(spacing: 12) {
+            HStack(spacing: 12) {
+                Button { nav.showSettings = true } label: {
+                    // Large text: drop the icon, then the name, then the agent count;
+                    // "needs you" is the part worth keeping.
+                    ViewThatFits(in: .horizontal) {
+                        status(icon: true, name: true, count: true)
+                        status(icon: false, name: true, count: true)
+                        status(icon: false, name: false, count: true)
+                        status(icon: false, name: false, count: model.blocked == 0)
+                    }
+                    .padding(.horizontal, 16)
+                    .frame(minHeight: 48)
+                }
+                .accessibilityLabel("\(store.machineTitle), \(summary)\(model.blocked > 0 ? ", \(model.blocked) need\(model.blocked == 1 ? "s" : "") you" : "")")
+                .buttonStyle(.plain)
+                .contentShape(.capsule)
+struct FailureView: View {
+    @Environment(AppStore.self) private var store
+    @State private var editing = false
+    @State private var confirmForget = false
+
+    var body: some View {
+        ScrollView {
+            VStack(spacing: 18) {
+                Image(systemName: "bolt.horizontal.circle")
+                    .font(.system(size: 44, weight: .light)).foregroundStyle(HC.blocked)
+                    .padding(.top, 60)
+                Text(store.phase == .idle ? "Not connected to \(store.machineTitle)" : "Couldn't reach \(store.machineTitle)")
+                    .font(HF.ui(20, .semibold)).foregroundStyle(HC.fg)
+                    .multilineTextAlignment(.center)
+                if case .failed(let msg) = store.phase {
+                    Text(msg).font(HF.ui(15)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
+                }
+                if let m = store.activeMachine {
+                    Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(12.5)).foregroundStyle(HC.dim)
+                }
+                if !store.diagnostics.isEmpty {
+                    VStack(alignment: .leading, spacing: 6) {
+                        Text("Diagnostics").herdrSectionHeader()
+                        ScrollView {
+                            Text(store.diagnostics)
+                                .font(HF.mono(11.5)).foregroundStyle(HC.muted)
+                                .textSelection(.enabled)
+                                .frame(maxWidth: .infinity, alignment: .leading)
+                        }
+                        .frame(maxHeight: 220)
+                    }
+                    .padding(14)
+                    .herdrCard()
+                }
+                GlassEffectContainer {
+                    HStack(spacing: 12) {
+                        Button { editing = true } label: { Label("Edit machine", systemImage: "server.rack") }
+                            .buttonStyle(.glass)
+                        Button { store.reconnect() } label: {
+                            Label(store.phase == .idle ? "Connect" : "Retry", systemImage: "arrow.clockwise").padding(.horizontal, 8)
+                        }
+                        .buttonStyle(.glassProminent)
+                    }
+                    .font(HF.ui(15.5, .semibold))
+                    .controlSize(.large)
+                }
+                .padding(.top, 6)
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
+                if store.hostKeyMismatch, let m = store.activeMachine {
+                    Button(role: .destructive) { confirmForget = true } label: {
+                        Label("Forget host key", systemImage: "key.slash")
+                    }
+                    .buttonStyle(.glass)
+                    .font(HF.ui(15, .medium))
+                    .confirmationDialog("Forget \(m.host)'s host key?", isPresented: $confirmForget, titleVisibility: .visible) {
+                        Button("Forget and reconnect", role: .destructive) {
+                            store.forgetHostKey(m)
+                            store.reconnect()
+                        }
+                    } message: {
+                        Text("Pinned: \(store.hostKeyFingerprint(m) ?? "none"). Only do this if \(m.host) was reinstalled; you will be asked to approve the key it presents next.")
+                    }
+                }
+                Text("Check that the host is reachable (e.g. Tailscale is on), the key is in authorized_keys, and herdr-core is installed in ~/.local/bin.")
+                    .font(HF.ui(13)).foregroundStyle(HC.dim).multilineTextAlignment(.center)
+                    .padding(.top, 6)
+            }
+            .padding(.horizontal, 24)
+            .frame(maxWidth: 560)
+            .frame(maxWidth: .infinity)
+        }
+        .sheet(isPresented: $editing) {
+            NavigationStack {
+                ScrollView { MachineForm(machine: store.activeMachine ?? MachineConfig()).padding(18) }
+                    .background(HC.canvas)
+                    .navigationTitle("Machine")
+                    .navigationBarTitleDisplayMode(.inline)
+                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = false } } }
+            }
+            .presentationDetents([.large])
+        }
+    }
+}
+
+hook: PostToolUse
+hook: PostToolUse
+exec
+/bin/zsh -lc "cat Herdr.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved; rg --files --hidden -g '*SSH*' -g '*KeyExchange*' -g '*ClientSession*' .build /Users/yosuke/Library/Developer/Xcode/DerivedData /Users/yosuke/Library/Caches/org.swift.swiftpm 2>/dev/null | head -65; rg -n 'request\\(|method:|requiredMethods|func hello' Packages/HerdrKit/Sources App/Sources; cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+{
+  "originHash" : "f40fc65ed63759b13601b9712284e33271a401c8895b9ff4b27b1acb824e4f42",
+  "pins" : [
+    {
+      "identity" : "bigint",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/attaswift/BigInt.git",
+      "state" : {
+        "revision" : "e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe",
+        "version" : "5.7.0"
+      }
+    },
+    {
+      "identity" : "citadel",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/orlandos-nl/Citadel",
+      "state" : {
+        "revision" : "ae8562f895de06ccb86fdb1cbb65fd99c8976e12",
+        "version" : "0.12.1"
+      }
+    },
+    {
+      "identity" : "swift-argument-parser",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-argument-parser",
+      "state" : {
+        "revision" : "6a52f3251125d74daf04fcbd5e6f08a75d074382",
+        "version" : "1.8.2"
+      }
+    },
+    {
+      "identity" : "swift-asn1",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-asn1.git",
+      "state" : {
+        "revision" : "3b6410f7dee09eb33cdd26260c5fd47fda19b0e2",
+        "version" : "1.7.3"
+      }
+    },
+    {
+      "identity" : "swift-atomics",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-atomics.git",
+      "state" : {
+        "revision" : "0442cb5a3f98ab802acb777929fdb446bda11a34",
+        "version" : "1.3.1"
+      }
+    },
+    {
+      "identity" : "swift-collections",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-collections.git",
+      "state" : {
+        "revision" : "f96b909e1a9e469620bc5037c1e24e00153f376f",
+        "version" : "1.7.5"
+      }
+    },
+    {
+      "identity" : "swift-crypto",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-crypto.git",
+      "state" : {
+        "revision" : "95ba0316a9b733e92bb6b071255ff46263bbe7dc",
+        "version" : "3.15.1"
+      }
+    },
+    {
+      "identity" : "swift-log",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-log.git",
+      "state" : {
+        "revision" : "c9c6bb9d275ec0d95c3ad16391f3f045dc623104",
+        "version" : "1.16.2"
+      }
+    },
+    {
+      "identity" : "swift-nio",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-nio.git",
+      "state" : {
+        "revision" : "6db9d9abd92ad7399b8a564cafbb87d3507245fa",
+        "version" : "2.104.0"
+      }
+    },
+    {
+      "identity" : "swift-nio-ssh",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/Wellz26/swift-nio-ssh.git",
+      "state" : {
+        "revision" : "d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c",
+        "version" : "0.3.7"
+      }
+    },
+    {
+      "identity" : "swift-system",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/apple/swift-system.git",
+      "state" : {
+        "revision" : "869129b7bf4ecc57b97d0193ad29690ca2134750",
+        "version" : "1.8.1"
+      }
+    },
+    {
+      "identity" : "swiftterm",
+      "kind" : "remoteSourceControl",
+      "location" : "https://github.com/migueldeicaza/SwiftTerm",
+      "state" : {
+        "revision" : "5d14406844143538cd8f8851d2d8a67c1fe443e5",
+        "version" : "1.20.0"
+      }
+    }
+  ],
+  "version" : 3
+}
+App/Sources/Store/AppStore.swift:435:    func call(_ method: String, _ params: JSONValue) async throws -> JSONValue {
+App/Sources/Mods/ModEngine.swift:20:    var method: String
+App/Sources/Mods/ModEngine.swift:197:                let req = ModFetchRequest(url: args["url"] as? String ?? "", method: args["method"] as? String ?? "GET",
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:28:    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:137:        let missing = requiredMethods.filter { !methods.contains($0) }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:166:    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:201:    public func notify(_ method: String, _ params: JSONValue = [:]) {
+App/Sources/Net/CitadelTransport.swift:32:        let method: SSHAuthenticationMethod = switch auth {
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
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+codex
+MainActor 上の `resume()` と `wake = nil` の間には中断点がなく、通常の nudge で二重 resume は起きません。一方、`load()` 中の停止と再開で待機が重複する経路を確認中です。ホスト鍵については、失敗画面への遷移と SSH 依存ライブラリ内の認証開始条件を追っています。
+
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "rg --files --hidden --no-ignore /Users/yosuke/Library/Developer/Xcode/DerivedData /Users/yosuke/Library/Caches/org.swift.swiftpm .build 2>/dev/null | rg '(Citadel|citadel|swift-nio-ssh).*(swift"'$)'"' | head -70; sed -n '345,405p' App/Sources/UI/MainView.swift; sed -n '1,75p' App/Sources/Chat/ChatView.swift; rg -n 'call\\(\"|notify\\(\"' Packages/HerdrKit/Sources App/Sources App/Resources; nl -ba App/Sources/Net/HostKeys.swift; nl -ba App/Sources/Net/KeyStore.swift | sed -n '90,165p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 2ms:
+            if store.phase == .connected {
+                Button { nav.showNewAgent = true } label: { Label("Start an agent", systemImage: "plus") }
+                    .buttonStyle(.glass).font(HF.ui(15, .medium))
+            }
+        }
+        .frame(maxWidth: .infinity)
+        .padding(.vertical, 60)
+    }
+}
+
+/// Shown above the lists while the connection isn't live.
+struct ConnectionBanner: View {
+    @Environment(AppStore.self) private var store
+    var body: some View {
+        switch store.phase {
+        case .connected:
+            EmptyView()
+        case .connecting(let step):
+            HStack(spacing: 10) {
+                Spinner(color: HC.working, size: 13)
+                Text(step.isEmpty ? "Reconnecting…" : "\(step)…").font(HF.ui(14, .medium)).foregroundStyle(HC.fg)
+                Spacer()
+            }
+            .padding(.horizontal, 14).padding(.vertical, 10)
+            .herdrCard()
+            .padding(.top, 8)
+        case .failed(let msg):
+            failed(msg)
+        case .idle:
+            failed("Disconnected")
+        }
+    }
+
+    private func failed(_ msg: String) -> some View {
+        HStack(spacing: 10) {
+            Image(systemName: "bolt.horizontal.circle").foregroundStyle(HC.blocked)
+            Text(msg).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(2)
+            Spacer()
+            Button("Retry") { store.reconnect() }.buttonStyle(.glass).font(HF.ui(14, .semibold))
+        }
+        .padding(.leading, 14).padding(.trailing, 8).padding(.vertical, 8)
+        .herdrCard()
+        .padding(.top, 8)
+    }
+}
+
+/// Floating glass bar: machine status on the left, New agent on the right.
+private struct HomeBottomBar: View {
+    @Environment(AppStore.self) private var store
+    @Environment(Navigator.self) private var nav
+    var model: HomeModel
+    @Namespace private var ns
+
+    var body: some View {
+        GlassEffectContainer(spacing: 12) {
+            HStack(spacing: 12) {
+                Button { nav.showSettings = true } label: {
+                    // Large text: drop the icon, then the name, then the agent count;
+                    // "needs you" is the part worth keeping.
+                    ViewThatFits(in: .horizontal) {
+                        status(icon: true, name: true, count: true)
+import SwiftUI
+import HerdrKit
+
+/// An agent's conversation as native messages, read from its transcript.
+/// Holds no terminal attach: nothing here types into or resizes the program
+/// except Send, Stop and the blocked card's choices.
+struct ChatView: View {
+    let address: String
+    @Environment(AppStore.self) private var store
+    @Environment(\.scenePhase) private var scenePhase
+    @State private var model: ChatModel
+
+    init(address: String) {
+        self.address = address
+        _model = State(initialValue: ChatModel(address: address))
+    }
+
+    var body: some View {
+        let att = store.attention(of: address)
+        let rec = store.terminals[address]
+        ScrollView {
+            LazyVStack(alignment: .leading, spacing: 18) {
+                content(working: att == .working)
+            }
+            .padding(.horizontal, 16)
+            .padding(.top, 8)
+            .padding(.bottom, 12)
+        }
+        .defaultScrollAnchor(.bottom)
+        .defaultScrollAnchor(.bottom, for: .sizeChanges)
+        .scrollEdgeEffectStyle(.hard, for: .top)
+        .scrollDismissesKeyboard(.interactively)
+        .background(HC.canvas)
+        .safeAreaInset(edge: .bottom, spacing: 0) {
+            VStack(spacing: 8) {
+                if att == .blocked { BlockedCard(address: address) }
+                ChatComposer(address: address, working: att == .working)
+            }
+            .padding(.horizontal, 10)
+            .padding(.bottom, 6)
+        }
+        .onAppear { model.start(store: store) }
+        .onDisappear { model.stop() }
+        .onChange(of: rec?.statusWord) { _, _ in model.nudge() }
+        .onChange(of: rec?.turn) { _, _ in model.nudge() }
+        .onChange(of: store.phase) { _, p in if p == .connected { model.nudge() } }
+        .onChange(of: scenePhase) { _, p in if p == .active { model.nudge() } }
+    }
+
+    @ViewBuilder private func content(working: Bool) -> some View {
+        switch model.phase {
+        case .loading where model.turns.isEmpty:
+            HStack(spacing: 10) { ProgressView(); Text("Reading the conversation…").foregroundStyle(HC.muted) }
+                .font(HF.ui(14)).frame(maxWidth: .infinity).padding(.top, 60)
+        case .unavailable(let why):
+            emptyState("text.bubble", why, hint: "Switch to Terminal to see the screen.")
+        case .failed(let why) where model.turns.isEmpty:
+            emptyState("exclamationmark.triangle", "Couldn't read the conversation", hint: why)
+        default:
+            if model.hasEarlier {
+                Label("Earlier messages are in the terminal's history", systemImage: "clock.arrow.circlepath")
+                    .font(HF.ui(12.5)).foregroundStyle(HC.dim).frame(maxWidth: .infinity)
+            }
+            ForEach(model.turns) { turn in
+                TurnView(turn: turn, isLast: turn.id == model.turns.last?.id, working: working)
+            }
+            if working { WorkingRow(since: model.turns.last?.startedAt) }
+        }
+    }
+
+    private func emptyState(_ symbol: String, _ title: String, hint: String) -> some View {
+        VStack(spacing: 10) {
+            Image(systemName: symbol).font(.system(size: 28, weight: .light)).foregroundStyle(HC.dim)
+            Text(title).font(HF.ui(15, .medium)).foregroundStyle(HC.fg).multilineTextAlignment(.center)
+            Text(hint).font(HF.ui(13)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
+Packages/HerdrKit/Sources/herdr-probe/main.swift:32:        let st = try await client.call("server.status")
+Packages/HerdrKit/Sources/herdr-probe/main.swift:34:        let m = try await client.call("machine.list")
+Packages/HerdrKit/Sources/herdr-probe/main.swift:80:        let rec = TerminalRecord(raw: try await client.call("terminal.get", ["terminal": .string(addr)]))
+Packages/HerdrKit/Sources/herdr-probe/main.swift:115:        async let a = client.call("terminal.list", ["all": false])
+Packages/HerdrKit/Sources/herdr-probe/main.swift:116:        async let b = client.call("server.status")
+Packages/HerdrKit/Sources/herdr-probe/main.swift:120:        do { _ = try await client.call("terminal.get", ["terminal": "t99999"]) } catch let e as HerdrError {
+App/Sources/Store/AppStore.swift:127:                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
+App/Sources/Store/AppStore.swift:396:            _ = try await c.call("terminal.label", ["terminal": .string(terminal), "labels": ["herdr.space": "", "herdr.tab": ""]])
+App/Sources/Store/AppStore.swift:397:            _ = try await c.call("terminal.keep", ["terminal": .string(terminal), "keep": false])
+App/Sources/Store/AppStore.swift:401:            _ = try? await c.call("terminal.kill", ["terminal": .string(terminal)], timeout: 15)
+App/Sources/Store/AppStore.swift:419:        _ = try await connectedClient().call("terminal.send", ["terminal": .string(address), "text": .string(text)], timeout: 15)
+App/Sources/Store/AppStore.swift:422:        _ = try await connectedClient().call("terminal.keys", ["terminal": .string(address), "keys": .array(keys.map { .string($0) })])
+App/Sources/Store/AppStore.swift:425:        _ = try await connectedClient().call("terminal.interrupt", ["terminal": .string(address), "timeout": 10], timeout: 20)
+App/Sources/Store/AppStore.swift:428:        _ = try await connectedClient().call("terminal.kill", ["terminal": .string(address)], timeout: 20)
+App/Sources/Store/AppStore.swift:762:        let r = try await c.call("terminal.run", [
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:195:                notify("$/cancelRequest", ["id": .number(Double(id))])
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:233:        let r = try await call("doc.get", ["name": .string(name)])
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:239:        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:244:        let r = try await call("terminal.list", ["all": .bool(all)])
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:249:        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:261:        let r = try await call("terminal.attach", p)
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:283:        let r = try await call("events.subscribe", [:])
+     1	import Foundation
+     2	import Crypto
+     3	import NIOCore
+     4	import NIOSSH
+     5	
+     6	/// Host keys pinned per host:port in the Keychain, after the person approves the first one.
+     7	enum HostKeys {
+     8	    struct Mismatch: LocalizedError {
+     9	        var host: String
+    10	        var expected: String
+    11	        var got: String
+    12	        var errorDescription: String? {
+    13	            "\(host)'s host key changed (was \(expected), now \(got)). If the machine was reinstalled, tap Forget host key; otherwise someone may be intercepting the connection."
+    14	        }
+    15	    }
+    16	
+    17	    /// A host seen for the first time. Nothing is pinned and no credentials were sent yet.
+    18	    struct Unknown: LocalizedError, Equatable {
+    19	        var host: String
+    20	        var port: Int
+    21	        var line: String
+    22	        var fingerprint: String { HostKeys.fingerprint(line) }
+    23	        var errorDescription: String? {
+    24	            "First connection to \(host). Check its host key before trusting it: \(fingerprint)"
+    25	        }
+    26	    }
+    27	
+    28	    /// The pinned key's fingerprint, for display.
+    29	    static func pinnedFingerprint(host: String, port: Int) -> String? {
+    30	        pinned(host: host, port: port).map(fingerprint)
+    31	    }
+    32	
+    33	    static func pinned(host: String, port: Int) -> String? { KeyStore.hostKey("\(host):\(port)") }
+    34	
+    35	    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }
+    36	
+    37	    static func pin(_ line: String, host: String, port: Int) throws {
+    38	        try KeyStore.setHostKey(line, for: "\(host):\(port)")
+    39	    }
+    40	
+    41	    /// `SHA256:<base64>` like ssh-keygen -l.
+    42	    static func fingerprint(_ openSSHLine: String) -> String {
+    43	        let parts = openSSHLine.split(separator: " ")
+    44	        guard parts.count >= 2, let blob = Data(base64Encoded: String(parts[1])) else { return openSSHLine }
+    45	        let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
+    46	        return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
+    47	    }
+    48	
+    49	    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
+    50	    /// so the app can show the fingerprint and pin it on approval.
+    51	    final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
+    52	        let host: String, port: Int
+    53	        init(host: String, port: Int) { self.host = host; self.port = port }
+    54	
+    55	        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
+    56	            let line = String(openSSHPublicKey: hostKey)
+    57	            if let known = HostKeys.pinned(host: host, port: port) {
+    58	                if known == line {
+    59	                    validationCompletePromise.succeed(())
+    60	                } else {
+    61	                    validationCompletePromise.fail(Mismatch(host: host, expected: HostKeys.fingerprint(known),
+    62	                                                            got: HostKeys.fingerprint(line)))
+    63	                }
+    64	            } else {
+    65	                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
+    66	            }
+    67	        }
+    68	    }
+    69	}
+    90	            delete(account: account)
+    91	        }
+    92	    }
+    93	
+    94	    // MARK: Host keys
+    95	
+    96	    static func hostKey(_ hostPort: String) -> String? {
+    97	        (try? read(account: "hostkey." + hostPort)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
+    98	    }
+    99	
+   100	    static func setHostKey(_ line: String?, for hostPort: String) throws {
+   101	        let account = "hostkey." + hostPort
+   102	        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
+   103	    }
+   104	
+   105	    // MARK: Keychain
+   106	
+   107	    private static func query(_ account: String) -> [String: Any] {
+   108	        [kSecClass as String: kSecClassGenericPassword,
+   109	         kSecAttrService as String: service,
+   110	         kSecAttrAccount as String: account]
+   111	    }
+   112	
+   113	    private static func read(account: String) throws -> Data? {
+   114	        var q = query(account)
+   115	        q[kSecReturnData as String] = true
+   116	        q[kSecMatchLimit as String] = kSecMatchLimitOne
+   117	        var out: CFTypeRef?
+   118	        let status = SecItemCopyMatching(q as CFDictionary, &out)
+   119	        if status == errSecItemNotFound { return nil }
+   120	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
+   121	        return out as? Data
+   122	    }
+   123	
+   124	    /// Update in place, add only when missing: a failed write never loses the existing item.
+   125	    private static func write(_ data: Data, account: String) throws {
+   126	        let attrs: [String: Any] = [kSecValueData as String: data,
+   127	                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
+   128	        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
+   129	        if status == errSecItemNotFound {
+   130	            var q = query(account)
+   131	            for (k, v) in attrs { q[k] = v }
+   132	            status = SecItemAdd(q as CFDictionary, nil)
+   133	        }
+   134	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
+   135	    }
+   136	
+   137	    private static func delete(account: String) {
+   138	        SecItemDelete(query(account) as CFDictionary)
+   139	    }
+   140	}
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+web search: 
+web search: https://raw.githubusercontent.com/orlandos-nl/Citadel/0.12.1/Sources/Citadel/SSHClient.swift
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "ls -a; ls /Users/yosuke/Library/Developer/Xcode/DerivedData; rg --files --hidden --no-ignore /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket | rg '(checkouts|Citadel|KeyExchange)' | head -35; sed -n '75,150p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; rg -n 'showSettings|sheet' App/Sources/UI/MainView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+.
+..
+.envrc
+.git
+.gitignore
+.mcp.json
+AGENTS.ja.md
+AGENTS.md
+App
+Config
+Herdr.xcodeproj
+LICENSE
+NOTICE
+Packages
+README.md
+UITests
+build
+docs
+nix
+project.yml
+scripts
+CMAKE_TRY_COMPILE-apvibwssfvhlncbffpztucztzcdf
+CMAKE_TRY_COMPILE-bedvsgkylcpqwreewpjpdyqlsxbv
+CMAKE_TRY_COMPILE-bklavgnptpytpabtfrgdymgabsqk
+CMAKE_TRY_COMPILE-bqncorfxoucuethibtrkqoeigjjp
+CMAKE_TRY_COMPILE-btculpbmrqpmazexvrmhlbqfhbxg
+CMAKE_TRY_COMPILE-btqkjcgwzjtzqwglbiimnfnbogpz
+CMAKE_TRY_COMPILE-bxwwhcfxzmvgvleedghhgkstewoj
+CMAKE_TRY_COMPILE-cvfeswdfmtaycraxhqghmlvjbmcr
+CMAKE_TRY_COMPILE-cxtfxgaukuduaxggtjupppluduva
+CMAKE_TRY_COMPILE-cxtmpyzntumgnhafuiehxrwksmxo
+CMAKE_TRY_COMPILE-dtwiwjknunqwireygrwocmemcich
+CMAKE_TRY_COMPILE-erbkmnrfaacdjxfstgjlqvjivfsn
+CMAKE_TRY_COMPILE-erjnghfkkpqougbinjeafbxmoyjr
+CMAKE_TRY_COMPILE-etklpdfpbayxnmdiipglcjbhklie
+CMAKE_TRY_COMPILE-ffgqapqugsnflrgjjewukkidtbqu
+CMAKE_TRY_COMPILE-fqwbbjuqmgiyifdptfgxuqduzinb
+CMAKE_TRY_COMPILE-ftwntwzhzylkqjhlacbnpxxzsett
+CMAKE_TRY_COMPILE-fuxxwvanqzootleiwnnllaifxqog
+CMAKE_TRY_COMPILE-fvgfprddiulrnocmitnursycxqez
+CMAKE_TRY_COMPILE-gwxckzgyvbxilqategxqljgictnq
+CMAKE_TRY_COMPILE-hejsrjqlhzeuxzdfzkywuaullspk
+CMAKE_TRY_COMPILE-hhbouzntyjfcdcfekksdforvwtck
+CompilationCache.noindex
+CompilerIdC-bitsdphztjldarfnmmvscoxvgdqv
+CompilerIdC-fhreoadwagrlvlecmdjoqrkjzamr
+CompilerIdCXX-ezrajrigunjchgdhsnhsqobzkqbx
+CompilerIdCXX-famtxtipoggnybadlbvfbfcvxauv
+Files-gjzdlalvtsxajjekynugszssfivo
+ModuleCache.noindex
+SymbolCache.noindex
+llama.swiftui-djtdmicsuitysjcazchidxyswoqr
+lmac_wasm-gtkldeigizlkobcuhokvoivdvwvi
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/CitadelTransport.swift
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/packed-refs
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/Citadel.o
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/push-to-checkout.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/update.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-push.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-applypatch.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-merge-commit.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/post-update.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/prepare-commit-msg.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-receive.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/fsmonitor-watchman.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/applypatch-msg.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-commit.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/sendemail-validate.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/pre-rebase.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/hooks/commit-msg.sample
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/description
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/info/exclude
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/HEAD
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/objects/pack/pack-2676a512b6635e77be649b0e24649d694134cd14.pack
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/objects/pack/pack-2676a512b6635e77be649b0e24649d694134cd14.rev
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/objects/pack/pack-2676a512b6635e77be649b0e24649d694134cd14.idx
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/SourcePackages/repositories/Citadel-0bda25d9/config
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/CCitadelBcrypt.o
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/SendsKeyExchangeMessages.o-3AR1R8E1ARYMT
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/SSHKeyExchangeStateMachine.o-U40AO2TZ70A9
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/AcceptsKeyExchangeMessages.o-3EXJOWSBYXYU0
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/CitadelTransport.o-2G77RSXKLR280
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/EllipticCurveKeyExchange.o-1H1TOVVIOPCJD
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/CCitadelBcrypt-85FM0MKBFNVQPMHRZGHB4I1DR.pcm-HUYFJ9TDWR4R
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/KeyExchangeState.o-3TZCZDA2TGIDH
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Index.noindex/DataStore/v5/units/SSHKeyExchangeResult.o-FJRY5TB9O3R7
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/Citadel.swiftmodule/arm64-apple-ios-simulator.swiftdoc
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/build/dd/Build/Products/Debug-iphonesimulator/Citadel.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo
+            guard mode == .idle else { return false }
+            mode = .plain; lastReceive = Date(); return true
+        }
+        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }
+
+        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
+            for await chunk in outStream {
+                do { try await transport.write(chunk) } catch {
+                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
+                    return
+                }
+            }
+        }
+
+        try await transport.start(
+            onBytes: { [weak self] in self?.receive($0) },
+            onStderr: { [weak self] d in self?.lock.withLock {
+                guard let self, self.stderrBuf.count < 16_384 else { return }
+                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
+            } },
+            onClose: { [weak self] err in self?.transportClosed(err) })
+
+        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
+            let alreadyClosed: Bool = lock.withLock {
+                if mode == .closed { return true }
+                helloCont = cont; return false
+            }
+            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
+            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
+            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
+                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
+                    defer { self.helloCont = nil }; return self.helloCont
+                }) else { return }
+                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
+                                              hint: self.stderrText.trimmed.nilIfEmpty))
+                self.close()
+            }
+        }
+        do {
+            let info = try Self.check(hello: reply)
+            lock.withLock { hello = info }
+            startLiveness()
+            return info
+        } catch {
+            close()
+            throw error
+        }
+    }
+
+    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
+    public static func check(hello reply: JSONValue) throws -> HelloInfo {
+        if !reply["error"].isNull { throw rpcError(reply["error"]) }
+        let r = reply["result"]
+        let gen = r["generation"].uint64 ?? 0
+        let version = r["version"].string ?? "0"
+        if gen > generation {
+            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
+        }
+        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
+            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
+        }
+        let methods = r["methods"].array?.compactMap(\.string) ?? []
+        let missing = requiredMethods.filter { !methods.contains($0) }
+        if !missing.isEmpty {
+            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
+        }
+        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
+                         version: version, methods: methods)
+    }
+
+    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }
+
+    static func semver(_ v: String) -> [Int] {
+        var s = v.trimmingCharacters(in: .whitespaces)
+        if s.hasPrefix("hc ") { s.removeFirst(3) }
+        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
+18:    var showSettings = false
+60:        .sheet(isPresented: $nav.showNewAgent) {
+65:        .sheet(isPresented: $nav.showSettings) { SettingsView() }
+66:        .sheet(item: $nav.modSheet) { mod in ModFullSheet(mod: mod) }
+70:            nav.showNewAgent = false; nav.showSettings = false; nav.modSheet = nil
+81:    /// HERDR_DEBUG_OPEN_MOD=<mod> (full sheet of a mod)
+88:            if target == "settings" { nav.showSettings = true }
+214:                Button { nav.showSettings = true } label: { Image(systemName: "gearshape") }
+401:                Button { nav.showSettings = true } label: {
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "ls build/dd/SourcePackages/checkouts; rg -n 'validateHostKey|validationCompletePromise|flatMap|newKeys' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key\\ Exchange/SSHKeyExchangeStateMachine.swift; rg -n 'errorCaught|connect\\(|authentication|promise|timeout' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/{Client.swift,SSHClient.swift,ClientSession.swift}" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ exited 2 in 0ms:
+BigInt
+Citadel
+SwiftTerm
+swift-argument-parser
+swift-asn1
+swift-atomics
+swift-collections
+swift-crypto
+swift-log
+swift-nio
+swift-nio-ssh
+swift-system
+59:        /// We have received the remote peer's newKeys message, and are waiting to send our own.
+60:        case newKeysReceived(result: KeyExchangeResult, protection: NIOSSHTransportProtection, negotiated: NegotiationResult)
+62:        /// We have sent our newKeys message, and are waiting to receive the remote peer's.
+63:        case newKeysSent(result: KeyExchangeResult, protection: NIOSSHTransportProtection, negotiated: NegotiationResult)
+180:        case .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+203:        case .keyExchangeSent, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+231:                return SSHMultiMessage(message, .newKeys)
+233:        case .idle, .keyExchangeSent, .keyExchangeReceived, .keyExchangeInitReceived, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+243:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keyExchangeInitReceived, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+296:                            validationCompletePromise: promise
+299:                            SSHMultiMessage(SSHMessage.newKeys)
+308:                    clientConfig.serverAuthDelegate.validateHostKey(hostKey: message.hostKey, validationCompletePromise: promise)
+310:                        SSHMultiMessage(SSHMessage.newKeys)
+316:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+328:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+337:            self.state = .newKeysReceived(result: result, protection: protection, negotiated: negotiated)
+339:        case .newKeysSent(result: let result, protection: let protection, _):
+342:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keyExchangeInitReceived, .newKeysReceived, .complete:
+350:            self.state = .newKeysSent(result: result, protection: protection, negotiated: negotiated)
+352:        case .newKeysReceived(result: let result, protection: let protection, _):
+355:        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitSent, .keyExchangeInitReceived, .newKeysSent, .complete:
+517:            return configuration.hostKeys.flatMap { $0.hostKeyAlgorithms }
+585:             .newKeysSent(result: let result, _, _),
+586:             .newKeysReceived(result: let result, _, _),
+606:             .newKeysReceived(_, _, negotiated: let negotiated),
+607:             .newKeysSent(_, _, negotiated: let negotiated):
+rg: build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHClient.swift: No such file or directory (os error 2)
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:115:    let authenticationMethod: () -> SSHAuthenticationMethod
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:133:        authenticationMethod: @escaping @autoclosure () -> SSHAuthenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:139:        self.authenticationMethod = authenticationMethod
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:147:    public func onDisconnect(perform onDisconnect: @escaping @Sendable () -> ()) {
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:154:    public static func connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:157:        let session = try await SSHClientSession.connect(settings: settings)
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:161:            authenticationMethod: settings.authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:171:    public static func connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:190:            authenticationMethod: settings.authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:222:            authenticationMethod: settings.authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:232:    /// - authenticationMethod: The authentication method to use. See `SSHAuthenticationMethod` for more information.
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:237:    public static func connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:239:        authenticationMethod: @escaping @autoclosure () -> SSHAuthenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:247:            authenticationMethod: authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:258:            authenticationMethod: authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:269:    /// - authenticationMethod: The authentication method to use. See `SSHAuthenticationMethod` for more information.
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:278:    public static func connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:281:        authenticationMethod: SSHAuthenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:290:        let session = try await SSHClientSession.connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:293:            authenticationMethod: authenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:304:            authenticationMethod: authenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:356:        self.session = try await SSHClientSession.connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:359:            authenticationMethod: self.authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:68:    private let promise: EventLoopPromise<Void>
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:73:        promise.futureResult
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:77:        let promise = eventLoop.makePromise(of: Void.self)
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:78:        self.promise = promise
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:81:            promise.fail(ChannelError.connectTimeout(loginTimeout))
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:87:            self.promise.succeed(())
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:91:    func errorCaught(context: ChannelHandlerContext, error: any Error) {
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:92:        self.promise.fail(error)
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:97:        self.promise.fail(Disconnected())
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:104:    public var authenticationMethod: @Sendable () -> SSHAuthenticationMethod
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:115:        authenticationMethod: @Sendable @escaping () -> SSHAuthenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:120:        self.authenticationMethod = authenticationMethod
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:137:    /// - authenticationMethod: The authentication method to use, see `SSHAuthenticationMethod`.
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:144:        authenticationMethod: @escaping @Sendable @autoclosure () -> SSHAuthenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:156:                authenticationMethod: authenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:175:            userAuthDelegate: settings.authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:204:    static func connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:210:            userAuthDelegate: settings.authenticationMethod(),
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:228:        return try await bootstrap.connect(host: settings.host, port: settings.port).flatMap { channel in
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:243:    /// - authenticationMethod: The authentication method to use, see `SSHAuthenticationMethod`.
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:250:    static func connect(
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:253:        authenticationMethod: @Sendable @escaping @autoclosure () -> SSHAuthenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:264:            authenticationMethod: authenticationMethod,
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:274:        return try await connect(
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '45,78p' App/Sources/UI/MainView.swift; rg -n 'func exec|withTaskCancellation|onCancel' App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; rg --files --hidden --no-ignore build/dd/SourcePackages/checkouts/Citadel/Sources | head -40; rg -n 'validationCompletePromise|validateHostKey' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+                SplitMain()
+            } else {
+                NavigationStack(path: $nav.path) {
+                    HomeView()
+                        .navigationDestination(for: Route.self) { RouteView(route: $0) }
+                }
+            }
+        }
+        .environment(nav)
+        .onChange(of: hsc, initial: true) { _, v in
+            nav.split = v == .regular
+            // Carry the visible screen across a size-class change.
+            if nav.split, let last = nav.path.last { nav.selection = last; nav.path = [] }
+            else if !nav.split, let sel = nav.selection, nav.path.isEmpty { nav.path = [sel] }
+        }
+        .sheet(isPresented: $nav.showNewAgent) {
+            NewAgentSheet(initialSpace: nav.newAgentSpace) { addr in
+                nav.openNew(terminal: addr)
+            }
+        }
+        .sheet(isPresented: $nav.showSettings) { SettingsView() }
+        .sheet(item: $nav.modSheet) { mod in ModFullSheet(mod: mod) }
+        .onChange(of: store.pendingOpen, initial: true) { _, a in
+            guard let a else { return }
+            store.pendingOpen = nil
+            nav.showNewAgent = false; nav.showSettings = false; nav.modSheet = nil
+            if nav.split ? nav.selection != .terminal(a) : nav.path.last != .terminal(a) { nav.open(.terminal(a)) }
+        }
+        #if DEBUG
+        .task(id: store.spaces.isEmpty) { debugOpen() }
+        #endif
+    }
+
+    #if DEBUG
+App/Sources/Store/AppStore.swift:432:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:170:        return try await withTaskCancellationHandler {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:188:        } onCancel: {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt.h
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/blf.c
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt-kdf.c
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt.c
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/bcrypt-kdf.h
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/blf.h
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ChannelUnwrapper.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/OpenSSHKey.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Errors.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/BasicCommands.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/CCitadelBcrypt/include/module.modulemap
+build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/Extensions.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/Terminal.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/EchoShell/EchoShell.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/Server.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/CitadelServerExample/HostKeyFile.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/NIOGlueHandler.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/RemotePortForward/Client/RemotePortForward+Client.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPFileFlags.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/TTY/Client/TTY.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHConnectionPoolSettings.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/BCrypt.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPSerializer.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/RemotePortForward/Server/RemotePortForward+Server.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHAuthenticationMethod.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Client/SFTPClientInboundHandler.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Client/SFTPFile.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Client/SFTPClient.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPBasicEnums.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPMessageParser.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/DirectTCPIP/Client/DirectTCPIP+Client.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Exec/Client/ExecClient.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Server/SFTPServerInboundHandler.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/Server/SFTPServer.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SFTP/SFTPMessage.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Server.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ByteBufferHelpers.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/SSHCert.swift
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHPerformanceTester/shared.swift:92:    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHPerformanceTester/shared.swift:93:        validationCompletePromise.succeed(())
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:24:    /// Invoked to validate a specific host key. Implementations should succeed the `validationCompletePromise`
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:29:    ///      - validationCompletePromise: A promise that must be succeeded or failed based on whether the host key is trusted.
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:30:    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:35:    /// The default implementation calls `validateHostKey` for backward compatibility.
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:40:    ///      - validationCompletePromise: A promise that must be succeeded or failed based on whether the certificate is trusted.
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:41:    func validateHostCertificate(hostKey: NIOSSHPublicKey, certifiedKey: NIOSSHCertifiedPublicKey, validationCompletePromise: EventLoopPromise<Void>)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:46:    func validateHostCertificate(hostKey: NIOSSHPublicKey, certifiedKey: NIOSSHCertifiedPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/ClientServerAuthenticationDelegate.swift:48:        self.validateHostKey(hostKey: hostKey, validationCompletePromise: validationCompletePromise)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key Exchange/SSHKeyExchangeStateMachine.swift:296:                            validationCompletePromise: promise
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key Exchange/SSHKeyExchangeStateMachine.swift:308:                    clientConfig.serverAuthDelegate.validateHostKey(hostKey: message.hostKey, validationCompletePromise: promise)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHClient/main.swift:35:    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSHClient/main.swift:38:        validationCompletePromise.succeed(())
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '260,320p' 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Key Exchange/SSHKeyExchangeStateMachine.swift'; sed -n '60,100p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; sed -n '200,240p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; rg -n 'futureMessage|possibleFutureMessage|whenFailure|fireErrorCaught|sendNewKeys|beginAuthentication' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine'; sed -n '165,200p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; git -C build/dd/SourcePackages/checkouts/Citadel rev-parse HEAD; git -C build/dd/SourcePackages/checkouts/swift-nio-ssh rev-parse HEAD; nl -ba App/Sources/Chat/ChatModel.swift | sed -n '64,109p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 10ms:
+                    serverKeyExchangeMessage: .init(
+                        hostKey: message.hostKey,
+                        publicKey: message.publicKey,
+                        signature: message.signature
+                    ),
+                    initialExchangeBytes: &self.initialExchangeBytes,
+                    allocator: self.allocator,
+                    expectedKeySizes: negotiated.negotiatedProtection.keySizes(forMac: negotiated.negotiatedMacAlgorithm.map { String($0) })
+                )
+
+                let protection = try negotiated.negotiatedProtection.init(initialKeys: result.keys, mac: negotiated.negotiatedMacAlgorithm.map { String($0) })
+                self.state = .keysExchanged(result: result, protection: protection, negotiated: negotiated)
+
+                // Ok, we've modified the state, now we can ask the user if they like this host key.
+                guard case .client(let clientConfig) = self.role else {
+                    preconditionFailure("Should not be in .keyExchangeInitSent as server")
+                }
+                
+                // Check if this is a certificate and validate it if we have trusted CAs
+                if let certifiedKey = NIOSSHCertifiedPublicKey(message.hostKey),
+                   !clientConfig.trustedHostCAKeys.isEmpty {
+                    // This is a certificate and we have trusted CAs configured
+                    do {
+                        // Use the configured hostname for validation, or empty string to accept any
+                        let principal = clientConfig.hostname ?? ""
+                        let _ = try certifiedKey.validate(
+                            principal: principal,
+                            type: .host,
+                            allowedAuthoritySigningKeys: clientConfig.trustedHostCAKeys,
+                            acceptableCriticalOptions: [] // Host certificates typically don't have critical options
+                        )
+                        // Certificate is valid, now let the delegate do additional validation
+                        let promise = self.loop.makePromise(of: Void.self)
+                        clientConfig.serverAuthDelegate.validateHostCertificate(
+                            hostKey: message.hostKey,
+                            certifiedKey: certifiedKey,
+                            validationCompletePromise: promise
+                        )
+                        return promise.futureResult.map {
+                            SSHMultiMessage(SSHMessage.newKeys)
+                        }
+                    } catch {
+                        // Certificate validation failed
+                        return self.loop.makeFailedFuture(error)
+                    }
+                } else {
+                    // Regular key validation or no trusted CAs configured
+                    let promise = self.loop.makePromise(of: Void.self)
+                    clientConfig.serverAuthDelegate.validateHostKey(hostKey: message.hostKey, validationCompletePromise: promise)
+                    return promise.futureResult.map {
+                        SSHMultiMessage(SSHMessage.newKeys)
+                    }
+                }
+            case .server:
+                preconditionFailure("Servers cannot enter key exchange init sent.")
+            }
+        case .idle, .keyExchangeSent, .keyExchangeReceived, .awaitingKeyExchangeInit, .awaitingKeyExchangeInitInvalidGuess, .keyExchangeInitReceived, .keysExchanged, .newKeysSent, .newKeysReceived, .complete:
+            throw SSHKeyExchangeError.unexpectedMessage
+        }
+    }
+
+            }
+        }
+    }
+}
+
+final class ClientHandshakeHandler: ChannelInboundHandler, Sendable {
+    typealias InboundIn = Any
+
+    private let promise: EventLoopPromise<Void>
+    let logger = Logger(label: "nl.orlandos.citadel.handshake")
+
+    /// A future that will be fulfilled when the handshake is complete.
+    public var authenticated: EventLoopFuture<Void> {
+        promise.futureResult
+    }
+
+    init(eventLoop: EventLoop, loginTimeout: TimeAmount) {
+        let promise = eventLoop.makePromise(of: Void.self)
+        self.promise = promise
+
+        eventLoop.scheduleTask(deadline: .now() + loginTimeout) {
+            promise.fail(ChannelError.connectTimeout(loginTimeout))
+        }
+    }
+
+    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
+        if event is UserAuthSuccessEvent {
+            self.promise.succeed(())
+        }
+    }
+
+    func errorCaught(context: ChannelHandlerContext, error: any Error) {
+        self.promise.fail(error)
+    }
+    
+    deinit {
+        struct Disconnected: Error {}
+        self.promise.fail(Disconnected())
+    }
+}
+
+    }
+
+    /// Creates a new SSH session on a new channel. This will connect to the given host and port.
+    /// - settings: The settings to use for the SSH session.
+    static func connect(
+        settings: SSHClientSettings
+    ) async throws -> SSHClientSession {
+        let eventLoop = settings.group.any()
+        let inboundChannelHandler = SSHClientInboundChannelHandler()
+        var clientConfiguration = SSHClientConfiguration(
+            userAuthDelegate: settings.authenticationMethod(),
+            serverAuthDelegate: settings.hostKeyValidator
+        )
+        
+        settings.algorithms.apply(to: &clientConfiguration)
+        
+        for option in settings.protocolOptions {
+            option.apply(to: &clientConfiguration)
+        }
+        
+        let bootstrap = ClientBootstrap(group: eventLoop).channelInitializer { channel in
+            return Self.addHandlers(on: channel, inboundChannelHandler: inboundChannelHandler, settings: settings)
+        }
+        .connectTimeout(settings.connectTimeout)
+//        .channelOption(ChannelOptions.autoRead, value: true)
+        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
+        .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)
+        
+        return try await bootstrap.connect(host: settings.host, port: settings.port).flatMap { channel in
+            channel.pipeline.handler(type: ClientHandshakeHandler.self).flatMap { handshakeHandler in
+                handshakeHandler.authenticated
+            }.flatMap {
+                channel.pipeline.handler(type: NIOSSHHandler.self)
+            }.map { sshHandler in
+                SSHClientSession(channel: channel, inboundChannelHandler: inboundChannelHandler, sshHandler: sshHandler)
+            }
+        }.get()
+    }
+    
+    /// Creates a new SSH session on a new channel. This will connect to the given host and port.
+    /// - Parameters:
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:149:                context.fireErrorCaught(error)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:169:            context.fireErrorCaught(error)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:203:        case .possibleFutureMessage(let future):
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:213:                        context.fireErrorCaught(error)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:219:                    context.fireErrorCaught(error)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift:377:                context.fireErrorCaught(error)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsUserAuthMessages.swift:59:            return .possibleFutureMessage(future.map(Self.transform(_:)))
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsUserAuthMessages.swift:75:            return .possibleFutureMessage(future.map { Self.transform($0, connectionAttributes: connectionAttributes, username: message.username, banner: banner) })
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsUserAuthMessages.swift:93:            return .possibleFutureMessage(future.map(Self.transform(_:)))
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/AcceptsKeyExchangeMessages.swift:44:        return .possibleFutureMessage(message)
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/Operations/SendsKeyExchangeMessages.swift:40:        let result = self.keyExchangeStateMachine.sendNewKeys()
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:748:                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:783:                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
+build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:1062:        case possibleFutureMessage(EventLoopFuture<SSHMultiMessage?>)
+    @discardableResult
+    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
+        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
+        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
+                              "params": params.isNull ? [:] : params]
+        return try await withTaskCancellationHandler {
+            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
+                enum Outcome { case go, cancelled, closed }
+                let outcome: Outcome = lock.withLock {
+                    if cancelled.remove(id) != nil { return .cancelled }
+                    if mode != .framed { return .closed }
+                    pending[id] = cont; return .go
+                }
+                switch outcome {
+                case .cancelled: cont.resume(throwing: CancellationError()); return
+                case .closed: cont.resume(throwing: HerdrError.lost); return
+                case .go: break
+                }
+                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
+                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
+                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
+                }
+            }
+        } onCancel: {
+            let wasPending = lock.withLock { () -> Bool in
+                if pending[id] != nil { return true }
+                cancelled.insert(id); return false
+            }
+            if wasPending {
+                finish(id, .failure(CancellationError()))
+                notify("$/cancelRequest", ["id": .number(Double(id))])
+            }
+        }
+    }
+
+    /// A notification (no id, no reply).
+ae8562f895de06ccb86fdb1cbb65fd99c8976e12
+d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c
+    64	
+    65	    init(address: String) { self.address = address }
+    66	
+    67	    func start(store: AppStore) {
+    68	        self.store = store
+    69	        #if DEBUG
+    70	        if AppStore.isDemo { loadDemo(); return }
+    71	        #endif
+    72	        guard loop == nil else { return }
+    73	        loop = Task { [weak self] in
+    74	            while !Task.isCancelled {
+    75	                guard let self else { return }
+    76	                await self.load()
+    77	                await self.pause()
+    78	            }
+    79	        }
+    80	    }
+    81	
+    82	    func stop() {
+    83	        loop?.cancel(); loop = nil
+    84	        sleeper?.cancel(); sleeper = nil
+    85	        wake?.resume(); wake = nil
+    86	    }
+    87	
+    88	    /// Something changed (status, turn): read now instead of waiting.
+    89	    func nudge() { wake?.resume(); wake = nil }
+    90	
+    91	    private func pause() async {
+    92	        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
+    93	        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
+    94	        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
+    95	            wake = c
+    96	            // Cancelled so an earlier pause's timer can never end this one early.
+    97	            sleeper?.cancel()
+    98	            sleeper = Task { [weak self] in
+    99	                try? await Task.sleep(for: delay)
+   100	                guard !Task.isCancelled else { return }
+   101	                self?.nudge()
+   102	            }
+   103	        }
+   104	    }
+   105	
+   106	    private func load() async {
+   107	        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
+   108	        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
+   109	        let argv = String(decoding: rec.raw["argv"].encoded(), as: UTF8.self)
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '160,205p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; sed -n '190,225p' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift; sed -n '720,795p' 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift'; sed -n '1,65p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; rg -n 'publicKeyAlgorithms|hostKeyAlgorithms' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys\\ And\\ Signatures/NIOSSHPublicKey.swift; nl -ba App/Sources/UI/SettingsView.swift | sed -n '46,63p'; rg -n 'host key|UserDefaults|Citadel|SPEC.md' README.md docs/*.md | head -45" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+    }
+
+    /// Creates a new SSH session on the given channel. This allows you to use an existing channel for the SSH session.
+    /// - channel: The channel to use for the SSH session, could be an existing TCP socket or proxy connection.
+    /// - settings: The settings to use for the SSH session.
+    static func addHandlers(
+        on channel: Channel,
+        inboundChannelHandler: SSHClientInboundChannelHandler,
+        settings: SSHClientSettings
+    ) -> EventLoopFuture<Void> {
+        let handshakeHandler = ClientHandshakeHandler(
+            eventLoop: channel.eventLoop,
+            loginTimeout: .seconds(10)
+        )
+        var clientConfiguration = SSHClientConfiguration(
+            userAuthDelegate: settings.authenticationMethod(),
+            serverAuthDelegate: settings.hostKeyValidator
+        )
+        
+        settings.algorithms.apply(to: &clientConfiguration)
+        
+        for option in settings.protocolOptions {
+            option.apply(to: &clientConfiguration)
+        }
+        
+        do {
+            try channel.pipeline.syncOperations.addHandlers(
+                NIOSSHHandler(
+                    role: .client(clientConfiguration),
+                    allocator: channel.allocator,
+                    inboundChildChannelInitializer: { channel, channelType in
+                        return inboundChannelHandler.handleChannel(channel: channel, channelType: channelType)
+                    }
+                ),
+                handshakeHandler
+            )
+            return channel.eventLoop.makeSucceededVoidFuture()
+        } catch {
+            return channel.eventLoop.makeFailedFuture(error)
+        }
+    }
+
+    /// Creates a new SSH session on a new channel. This will connect to the given host and port.
+    /// - settings: The settings to use for the SSH session.
+    static func connect(
+        settings: SSHClientSettings
+            try self.stateMachine.processOutboundMessage(message, buffer: &self.outboundFrameBuffer, allocator: context.channel.allocator, loop: context.eventLoop)
+            self.pendingWrite = true
+        }
+
+        context.write(self.wrapOutboundOut(self.outboundFrameBuffer), promise: promise)
+    }
+
+    private func processInboundMessageResult(_ result: SSHConnectionStateMachine.StateMachineInboundProcessResult, context: ChannelHandlerContext) throws {
+        switch result {
+        case .emitMessage(let message):
+            try self.writeMessage(message, context: context)
+        case .noMessage:
+            break
+        case .possibleFutureMessage(let future):
+            // TODO(cory): This is not right, but for now it's good enough.
+            future.whenComplete { result in
+                switch result {
+                case .success(.some(let message)):
+                    do {
+                        try self.writeMessage(message, context: context)
+                        self.pendingWrite = false
+                        context.flush()
+                    } catch {
+                        context.fireErrorCaught(error)
+                    }
+                case .success(.none):
+                    // Do nothing
+                    break
+                case .failure(let error):
+                    context.fireErrorCaught(error)
+                }
+            }
+        case .forwardToMultiplexer(let message):
+            try self.multiplexer?.receiveMessage(message)
+        case .globalRequest(let message):
+            try self.handleGlobalRequest(message)
+                self.state = .sentDisconnect(state.role)
+            case .ignore, .debug, .unimplemented:
+                try state.serializer.serialize(message: message, to: &buffer)
+                self.state = .idle(state)
+            default:
+                preconditionFailure("First message sent must be version, not \(message)")
+            }
+
+        case .sentVersion:
+            // We can't send anything else now.
+            // TODO(cory): We could refactor the key exchange state machine to accept the delayed version from the
+            // remote peer, and then we unlock the ability to remove another RTT to the remote peer.
+            preconditionFailure("Cannot send other messages before receiving version.")
+
+        case .keyExchange(var kex):
+            switch message {
+            case .keyExchange(let keyExchangeMessage):
+                try kex.writeKeyExchangeMessage(keyExchangeMessage, into: &buffer)
+                self.state = .keyExchange(kex)
+            case .keyExchangeInit(let kexInit):
+                try kex.writeKeyExchangeInitMessage(kexInit, into: &buffer)
+                self.state = .keyExchange(kex)
+            case .keyExchangeReply(let kexReply):
+                try kex.writeKeyExchangeReplyMessage(kexReply, into: &buffer)
+                self.state = .keyExchange(kex)
+            case .newKeys:
+                try kex.writeNewKeysMessage(into: &buffer)
+                let newState = SentNewKeysState(keyExchangeState: kex, loop: loop)
+                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
+                self.state = .sentNewKeys(newState)
+
+                // If we have a service request message, re-spin the state machine to process that too.
+                if let additionalMessage = possibleMessage {
+                    try self.processOutboundMessage(.serviceRequest(additionalMessage), buffer: &buffer, allocator: allocator, loop: loop)
+                }
+
+            case .disconnect:
+                try kex.serializer.serialize(message: message, to: &buffer)
+                self.state = .sentDisconnect(kex.role)
+
+            case .ignore, .debug, .unimplemented:
+                try kex.serializer.serialize(message: message, to: &buffer)
+                self.state = .keyExchange(kex)
+
+            default:
+                throw NIOSSHError.protocolViolation(protocolName: "key exchange", violation: "Sent unexpected message type: \(message)")
+            }
+
+        case .receivedNewKeys(var kex):
+            switch message {
+            case .keyExchange(let keyExchangeMessage):
+                try kex.writeKeyExchangeMessage(keyExchangeMessage, into: &buffer)
+                self.state = .receivedNewKeys(kex)
+            case .keyExchangeInit(let kexInit):
+                try kex.writeKeyExchangeInitMessage(kexInit, into: &buffer)
+                self.state = .receivedNewKeys(kex)
+            case .keyExchangeReply(let kexReply):
+                try kex.writeKeyExchangeReplyMessage(kexReply, into: &buffer)
+                self.state = .receivedNewKeys(kex)
+            case .newKeys:
+                try kex.writeNewKeysMessage(into: &buffer)
+
+                let newState = UserAuthenticationState(receivedNewKeysState: kex)
+                let possibleMessage = newState.userAuthStateMachine.beginAuthentication()
+                self.state = .userAuthentication(newState)
+
+                // If we have a service request message, re-spin the state machine to process that too.
+                if let additionalMessage = possibleMessage {
+                    try self.processOutboundMessage(.serviceRequest(additionalMessage), buffer: &buffer, allocator: allocator, loop: loop)
+                }
+
+            case .disconnect:
+                try kex.serializer.serialize(message: message, to: &buffer)
+                self.state = .sentDisconnect(kex.role)
+
+            case .ignore, .debug, .unimplemented:
+import NIO
+@preconcurrency import NIOSSH
+import Logging
+import NIOConcurrencyHelpers
+
+final class SSHClientInboundChannelHandler: Sendable {
+    typealias TCPIPForwardHandler = @Sendable (Channel, SSHChannelType.ForwardedTCPIP) -> EventLoopFuture<Void>
+    let forwardedTCPIPHosts = NIOLockedValueBox(
+        [SSHRemotePortForward: TCPIPForwardHandler]()
+    )
+
+    init() {}
+
+    enum HandleRegistrationResult: Error {
+        case success
+        case alreadyRegistered
+    }
+
+    nonisolated func registerForwardedTCPIP(host: String, port: Int, handler: @escaping TCPIPForwardHandler) -> HandleRegistrationResult {
+        let bound = SSHRemotePortForward(
+            host: host,
+            boundPort: port
+        )
+        return forwardedTCPIPHosts.withLockedValue { hosts in
+            if hosts.keys.contains(bound) {
+                return .alreadyRegistered
+            }
+            hosts[bound] = handler
+            return .success
+        }
+    }
+
+    nonisolated func unregisterForwardedTCPIP(host: String, port: Int) {
+        let bound = SSHRemotePortForward(
+            host: host,
+            boundPort: port
+        )
+        forwardedTCPIPHosts.withLockedValue { hosts in
+            _ = hosts.removeValue(forKey: bound)
+        }
+    }
+
+    nonisolated func handleChannel(channel: Channel, channelType: SSHChannelType) -> EventLoopFuture<Void> {
+        switch channelType {
+        case .session:
+            return channel.eventLoop.makeFailedFuture(CitadelError.unsupported)
+        case .directTCPIP:
+            return channel.eventLoop.makeFailedFuture(CitadelError.unsupported)
+        case .forwardedTCPIP(let forwardedTCPIP):
+            return forwardedTCPIPHosts.withLockedValue { hosts in
+                let bound = SSHRemotePortForward(
+                    host: forwardedTCPIP.listeningHost,
+                    boundPort: forwardedTCPIP.listeningPort
+                )
+                guard let host = hosts[bound] else {
+                    return channel.eventLoop.makeFailedFuture(CitadelError.channelCreationFailed)
+                }
+
+                return host(channel, forwardedTCPIP)
+            }
+        }
+    }
+}
+
+final class ClientHandshakeHandler: ChannelInboundHandler, Sendable {
+211:        _CustomAlgorithms.publicKeyAlgorithmsLock.withLock {
+212:            _CustomAlgorithms.publicKeyAlgorithms
+248:        _CustomAlgorithms.publicKeyAlgorithmsLock.withLockVoid {
+249:            if !_CustomAlgorithms.publicKeyAlgorithms.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(type) }) {
+250:                _CustomAlgorithms.publicKeyAlgorithms.append(type)
+261:        _CustomAlgorithms.publicKeyAlgorithmsLock.withLockVoid {
+262:            _CustomAlgorithms.publicKeyAlgorithms = []
+290:    static var publicKeyAlgorithmsLock = NIOLock()
+291:    static var publicKeyAlgorithms: [NIOSSHPublicKeyProtocol.Type] = []
+    46	                            Text("Host key").font(HF.ui(13, .medium)).foregroundStyle(HC.muted)
+    47	                            Text(fp).font(HF.mono(11)).foregroundStyle(HC.fg).textSelection(.enabled).lineLimit(2)
+    48	                        }
+    49	                        Button("Forget host key", role: .destructive) { confirmForget = m }
+    50	                    }
+    51	                }
+    52	                .confirmationDialog("Forget the host key?", isPresented: Binding(get: { confirmForget != nil }, set: { if !$0 { confirmForget = nil } }),
+    53	                                    titleVisibility: .visible, presenting: confirmForget) { m in
+    54	                    Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
+    55	                } message: { m in
+    56	                    Text("Only after \(m.host) was reinstalled. The next key it presents will be trusted and pinned.")
+    57	                }
+    58	
+    59	                NotificationSection()
+    60	
+    61	                Section("Appearance") {
+    62	                    Picker("Theme", selection: $appearance) {
+    63	                        Text("System").tag("system")
+docs/2026-11-01_herdr-ios-code-review.md:24:| `App/Sources` | Net (Citadel SSH, Keychain, host key), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore mod host), Notify |
+docs/2026-11-01_herdr-ios-code-review.md:25:| External dependencies | Citadel `from: 0.12.1`, SwiftTerm `exactVersion: 1.20.0` |
+docs/2026-11-01_herdr-ios-code-review.md:33:| High (confirmed in source) | `App/Sources/Net/HostKeys.swift:58-60` | On the first connection, the host key is pinned without confirmation, and the fingerprint is shown only after pinning. With a man-in-the-middle attack on the first connection, password authentication hands over the password as is. Storage is UserDefaults, not Keychain | On the first connection, show the fingerprint and require approval. Store in Keychain |
+docs/2026-11-01_herdr-ios-code-review.md:37:| Medium | `project.yml:14-19` | The Citadel version is not pinned, and `Package.resolved` is gitignored. `__pycache__/*.pyc` is tracked and bundled into the app | Use `exactVersion` and commit resolved. Delete the pyc files |
+docs/2026-11-01_herdr-ios-code-review.md:54:- Code comments refer to `SPEC.md`, but `SPEC.md` is not in the repo.
+docs/HANDOVER.md:16:   - The host key is shown and approved before it is pinned, and pins live in the Keychain.
+docs/HANDOVER.md:17:   - Citadel is pinned to an exact version; the tracked `.pyc` is gone.
+docs/HANDOVER.md:21:   question about Citadel keeping the `hc connect` stdio alive (on the simulator, not a device).
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:94:| 規模・構成 | Swift のコードが多く、relay・plugin・docs-site を含む | Swift のファイルが 49 個。`HerdrKit`（protocol と model、SwiftPM、テストあり）と `App`（Citadel の SSH、SwiftTerm）に分かれる |
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:92:| Size and structure | Large amount of Swift code, includes relay, plugin and docs-site | 49 Swift files. Split into `HerdrKit` (protocol and model, SwiftPM, with tests) and `App` (Citadel SSH, SwiftTerm) |
+docs/2026-11-01_herdr-ios-code-review.ja.md:26:| `App/Sources` | Net（Citadel の SSH、Keychain、host key）、Store（`AppStore`）、UI、Chat、Mods（JavaScriptCore の mod host）、Notify |
+docs/2026-11-01_herdr-ios-code-review.ja.md:27:| 外部の依存 | Citadel `from: 0.12.1`、SwiftTerm `exactVersion: 1.20.0` |
+docs/2026-11-01_herdr-ios-code-review.ja.md:35:| 高（原文で確認） | `App/Sources/Net/HostKeys.swift:58-60` | 初回の接続で host key を確認なしに固定し、fingerprint は固定した後にしか見せない。初回に中間者攻撃を受けると、password 認証では password がそのまま渡る。保存先は Keychain ではなく UserDefaults である | 初回は fingerprint を見せて承認させる。保存先を Keychain にする |
+docs/2026-11-01_herdr-ios-code-review.ja.md:39:| 中 | `project.yml:14-19` | Citadel の版が固定されておらず、`Package.resolved` も gitignore されている。`__pycache__/*.pyc` が追跡され、アプリに同梱される | `exactVersion` にし、resolved を commit する。pyc を消す |
+docs/2026-11-01_herdr-ios-code-review.ja.md:56:- コードのコメントが `SPEC.md` を参照しているが、`SPEC.md` は repo に無い。
+README.md:41:- **Host key:** the box's host key is pinned on first connect.
+README.md:103:  Net                 Citadel SSH transport, Keychain key store, host-key pinning
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+codex
+Citadel 0.12.1 と解決済みの NIOSSH ソースで、ホスト鍵の検証成功前には認証を開始せず、`Unknown` がそのままアプリへ返ることを確認しました。初回鍵の承認は RootView 経由で到達可能です。残る確認対象は、接続拒否後のソケット解放と、Keychain 読み取り失敗を「未登録」と扱う経路です。
+
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '200,225p' 'build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/Keys And Signatures/NIOSSHPublicKey.swift'; sed -n '275,313p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift; rg -n 'deinit|func errorCaught|close\\(' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift; nl -ba App/Sources/Net/CitadelTransport.swift | sed -n '30,52p'; nl -ba App/Sources/UI/ConnectionViews.swift | sed -n '276,293p'; git log -5 --oneline; rg -n 'missing|methods|compat' Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift; cat project.yml | head -30" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+    }
+
+    private static let bundledAlgorithms: [String.UTF8View] = [
+        Self.ed25519PublicKeyPrefix, Self.ecdsaP384PublicKeyPrefix, Self.ecdsaP256PublicKeyPrefix, Self.ecdsaP521PublicKeyPrefix,
+    ]
+
+    static var knownAlgorithms: [String.UTF8View] {
+        bundledAlgorithms + customPublicKeyAlgorithms.map { $0.publicKeyPrefix.utf8 }
+    }
+
+    static var customPublicKeyAlgorithms: [NIOSSHPublicKeyProtocol.Type] {
+        _CustomAlgorithms.publicKeyAlgorithmsLock.withLock {
+            _CustomAlgorithms.publicKeyAlgorithms
+        }
+    }
+
+    static var customSignatures: [NIOSSHSignatureProtocol.Type] {
+        _CustomAlgorithms.signaturesLock.withLock {
+            _CustomAlgorithms.signatures
+        }
+    }
+}
+
+public enum NIOSSHAlgorithms {
+    public static func register(keyExchangeAlgorithm type: NIOSSHKeyExchangeAlgorithmProtocol.Type) {
+        _CustomAlgorithms.keyExchangeAlgorithmsLock.withLockVoid {
+    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
+    /// - connectTimeout: Pass in the time before the connection times out. Default 30 seconds.
+    /// - Returns: An SSH client.
+    public static func connect(
+        host: String,
+        port: Int = 22,
+        authenticationMethod: SSHAuthenticationMethod,
+        hostKeyValidator: SSHHostKeyValidator,
+        reconnect: SSHReconnectMode,
+        algorithms: SSHAlgorithms = SSHAlgorithms(),
+        protocolOptions: Set<SSHProtocolOption> = [],
+        group: MultiThreadedEventLoopGroup = .singleton,
+        channelHandlers: [ChannelHandler] = [],
+        connectTimeout:TimeAmount = .seconds(30)
+    ) async throws -> SSHClient {
+        let session = try await SSHClientSession.connect(
+            host: host,
+            port: port,
+            authenticationMethod: authenticationMethod,
+            hostKeyValidator: hostKeyValidator,
+            algorithms: algorithms,
+            protocolOptions: protocolOptions,
+            group: group,
+            channelHandlers: channelHandlers,
+            connectTimeout: connectTimeout
+        )
+        
+        let client = SSHClient(
+            session: session,
+            authenticationMethod: authenticationMethod,
+            hostKeyValidator: hostKeyValidator,
+            algorithms: algorithms,
+            protocolOptions: protocolOptions
+        )
+        
+        switch reconnect.mode {
+        case .always:
+            client.connectionSettings.reconnect = .always(to: host, port: port)
+        case .once:
+230:            context.close(promise: nil)
+    30	               onStderr: @escaping @Sendable (Data) -> Void,
+    31	               onClose: @escaping @Sendable (Error?) -> Void) async throws {
+    32	        let method: SSHAuthenticationMethod = switch auth {
+    33	        case .key(let k): .ed25519(username: user, privateKey: k)
+    34	        case .password(let p): .passwordBased(username: user, password: p)
+    35	        }
+    36	        let client: SSHClient
+    37	        do {
+    38	            client = try await SSHClient.connect(
+    39	                host: host, port: port, authenticationMethod: method,
+    40	                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
+    41	                reconnect: .never, connectTimeout: .seconds(12))
+    42	        } catch {
+    43	            throw Self.friendly(error, host: host, user: user)
+    44	        }
+    45	        let isClosed: Bool = lock.withLock {
+    46	            self.client = client; self.onClose = onClose; return closed
+    47	        }
+    48	        if isClosed { try? await client.close(); throw HerdrError(code: -1, kind: "closed", message: "Disconnected") }
+    49	
+    50	        // The exec channel lives in this task; `start` returns once stdin is writable.
+    51	        try await withCheckedThrowingContinuation { (ready: CheckedContinuation<Void, Error>) in
+    52	            let readyOnce = Once(ready)
+   276	                .padding(.top, 6)
+   277	                if let key = store.unknownHostKey {
+   278	                    VStack(alignment: .leading, spacing: 8) {
+   279	                        Text("New host key").font(HF.ui(15, .semibold))
+   280	                        Text(key.fingerprint)
+   281	                            .font(HF.mono(12.5))
+   282	                            .textSelection(.enabled)
+   283	                            .accessibilityIdentifier("hostKeyFingerprint")
+   284	                        Text("On \(key.host), compare it with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
+   285	                            .font(HF.ui(13)).foregroundStyle(HC.muted)
+   286	                        Button { store.trustHostKey(key) } label: {
+   287	                            Label("Trust and connect", systemImage: "checkmark.shield")
+   288	                        }
+   289	                        .buttonStyle(.glassProminent)
+   290	                        .font(HF.ui(15, .medium))
+   291	                    }
+   292	                    .padding(14)
+   293	                    .herdrCard()
+1b740be List every core method the app calls in requiredMethods
+362b8bc Ask before pinning a new host key, and keep pins in the Keychain
+407eccd Stop re-reading the transcript on every terminal title change
+2357d77 Pin Citadel and commit the resolved package versions
+4d7576a Add agent instructions, devshell and the fork's founding research
+43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
+61:        XCTAssertThrowsError(try HerdrClient.check(hello: ["result": ["generation": 1, "version": "0.1.9", "methods": []]]))
+62:        XCTAssertThrowsError(try HerdrClient.check(hello: ["result": ["generation": 2, "version": "0.2.0", "methods": []]]))
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
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '245,288p' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift; rg -n 'channelHandlers' build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/{ClientSession,Client}.swift; sed -n '225,245p' build/dd/SourcePackages/checkouts/swift-nio-ssh/Sources/NIOSSH/NIOSSHHandler.swift; rg -n 'func errorCaught|unhandledError' build/dd/SourcePackages/checkouts/swift-nio/Sources/NIOCore/ChannelPipeline.swift | tail -10" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+    /// - algorithms: The algorithms to use, will use the default algorithms if not specified.
+    /// - protocolOptions: The protocol options to use, will use the default options if not specified.
+    /// - group: The event loop group to use, will use a new group with one thread if not specified.
+    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
+    /// - connectTimeout: Pass in the time before the connection times out. Default 30 seconds.
+    static func connect(
+        host: String,
+        port: Int = 22,
+        authenticationMethod: @Sendable @escaping @autoclosure () -> SSHAuthenticationMethod,
+        hostKeyValidator: SSHHostKeyValidator,
+        algorithms: SSHAlgorithms = SSHAlgorithms(),
+        protocolOptions: Set<SSHProtocolOption> = [],
+        group: EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
+        channelHandlers: [ChannelHandler] = [],
+        connectTimeout: TimeAmount = .seconds(30)
+    ) async throws -> SSHClientSession {
+        var settings = SSHClientSettings(
+            host: host,
+            port: port,
+            authenticationMethod: authenticationMethod,
+            hostKeyValidator: hostKeyValidator
+        )
+
+        settings.algorithms = algorithms
+        settings.protocolOptions = protocolOptions
+        settings.group = group
+        settings.channelHandlers = channelHandlers
+        settings.connectTimeout = connectTimeout
+        
+        return try await connect(
+            settings: settings
+        )
+    }
+}
+
+public struct InvalidHostKey: Error, Equatable {}
+
+/// A host key validator that can be used to validate an SSH host key. This can be used to validate the host key against a set of trusted keys, or to accept any key.
+public struct SSHHostKeyValidator: NIOSSHClientServerAuthenticationDelegate, Sendable {
+    private enum Method {
+        case trustedKeys(Set<NIOSSHPublicKey>)
+        case acceptAnything
+        case custom(NIOSSHClientServerAuthenticationDelegate)
+    }
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:109:    internal var channelHandlers: [ChannelHandler & Sendable] = []
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:248:    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:258:        channelHandlers: [ChannelHandler] = [],
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/ClientSession.swift:271:        settings.channelHandlers = channelHandlers
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:275:    /// - channelHandlers: Pass in an array of channel prehandlers that execute first. Default empty array
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:287:        channelHandlers: [ChannelHandler] = [],
+build/dd/SourcePackages/checkouts/Citadel/Sources/Citadel/Client.swift:298:            channelHandlers: channelHandlers,
+            try self.handleGlobalRequest(message)
+        case .globalRequestResponse(let response):
+            try self.handleGlobalRequestResponse(response)
+        case .disconnect:
+            // Welp, we immediately have to close.
+            context.close(promise: nil)
+        case .event(let event):
+            context.fireUserInboundEventTriggered(event)
+        }
+    }
+}
+
+// MARK: Create a child channel
+
+extension NIOSSHHandler {
+    /// Creates an SSH channel.
+    ///
+    /// This function is **not** thread-safe: it may only be called from on the channel.
+    ///
+    /// - parameters:
+    ///     - promise: An `EventLoopPromise` that will be fulfilled with the channel when it becomes active.
+1832:    func errorCaught(context: ChannelHandlerContext, error: Error) {
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+codex
+指摘は4件です。
+
+1. **medium — [ChatModel.swift:95](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/ChatModel.swift:95)**  
+   `load()` 中に `stop()` → `start()` すると、停止済みループも `pause()` に進みます。新旧ループが `wake` を上書きし、片方の continuation が未解放になります。**修正:** `load()` の直後、キャンセル済みなら `pause()` に進まず終了する。通常の nudge による二重 resume は **no findings**。MainActor 上で resume と nil 代入は分断されません。
+
+2. **medium — [HostKeys.swift:65](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/HostKeys.swift:65)**  
+   `Unknown` で接続を拒否しても、Citadel 0.12.1 は handshake の promise を失敗させるだけで TCP channel を閉じません。アプリも `SSHClient` を受け取れず、解放できません。初回接続の再試行で未認証接続が蓄積し、sshd の接続制限に達し得ます。**修正:** handshake 失敗時に channel を閉じてからエラーを返すよう Citadel の接続処理を修正する。
+
+3. **medium — [KeyStore.swift:97](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/KeyStore.swift:97)**  
+   Keychain の読み取りエラーを `nil` に変換するため、一時的な Keychain 障害でも登録済みホストを「初回」と表示します。その後の保存が成功すると、既存 pin を別の鍵で上書きできます。**修正:** 未登録と読み取り失敗を区別し、失敗は validator から接続エラーとして返す。
+
+4. **low — [ConnectionViews.swift:284](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ConnectionViews.swift:284)**  
+   ECDSA のみを提供するホストでも、照合コマンドは ed25519 固定です。表示された fingerprint を指定の手順で確認できません。**修正:** 提示された鍵種別に対応するファイルを案内するか、全ホスト公開鍵の fingerprint を表示するコマンドにする。
+
+認証情報送信前の停止は **no findings**。解決済み NIOSSH は検証成功後にのみ `NEWKEYS` を送信し、認証へ進みます。[NIOSSH ソース](https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Key%20Exchange/SSHKeyExchangeStateMachine.swift#L308)
+
+承認への到達性も **no findings**。`Unknown` は既存セッションの有無にかかわらず RootView が FailureView に振り分けます。MainView の mismatch は Settings の Forget → 再接続 → 承認へ進めます。ただし [SettingsView.swift:56](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/SettingsView.swift:56) の「次の鍵を自動で信頼・保存する」という説明は実装と不一致です。
+
+`requiredMethods` の追加は **no findings**。
+
+ファイル変更、テスト実行、実機確認はしていません。指摘はアプリと解決済み依存ライブラリのソース追跡に基づきます。
+hook: Stop
+hook: Stop
+hook: Stop Completed
+hook: Stop Completed
+tokens used
+80,714
+指摘は4件です。
+
+1. **medium — [ChatModel.swift:95](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/ChatModel.swift:95)**  
+   `load()` 中に `stop()` → `start()` すると、停止済みループも `pause()` に進みます。新旧ループが `wake` を上書きし、片方の continuation が未解放になります。**修正:** `load()` の直後、キャンセル済みなら `pause()` に進まず終了する。通常の nudge による二重 resume は **no findings**。MainActor 上で resume と nil 代入は分断されません。
+
+2. **medium — [HostKeys.swift:65](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/HostKeys.swift:65)**  
+   `Unknown` で接続を拒否しても、Citadel 0.12.1 は handshake の promise を失敗させるだけで TCP channel を閉じません。アプリも `SSHClient` を受け取れず、解放できません。初回接続の再試行で未認証接続が蓄積し、sshd の接続制限に達し得ます。**修正:** handshake 失敗時に channel を閉じてからエラーを返すよう Citadel の接続処理を修正する。
+
+3. **medium — [KeyStore.swift:97](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Net/KeyStore.swift:97)**  
+   Keychain の読み取りエラーを `nil` に変換するため、一時的な Keychain 障害でも登録済みホストを「初回」と表示します。その後の保存が成功すると、既存 pin を別の鍵で上書きできます。**修正:** 未登録と読み取り失敗を区別し、失敗は validator から接続エラーとして返す。
+
+4. **low — [ConnectionViews.swift:284](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ConnectionViews.swift:284)**  
+   ECDSA のみを提供するホストでも、照合コマンドは ed25519 固定です。表示された fingerprint を指定の手順で確認できません。**修正:** 提示された鍵種別に対応するファイルを案内するか、全ホスト公開鍵の fingerprint を表示するコマンドにする。
+
+認証情報送信前の停止は **no findings**。解決済み NIOSSH は検証成功後にのみ `NEWKEYS` を送信し、認証へ進みます。[NIOSSH ソース](https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Key%20Exchange/SSHKeyExchangeStateMachine.swift#L308)
+
+承認への到達性も **no findings**。`Unknown` は既存セッションの有無にかかわらず RootView が FailureView に振り分けます。MainView の mismatch は Settings の Forget → 再接続 → 承認へ進めます。ただし [SettingsView.swift:56](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/SettingsView.swift:56) の「次の鍵を自動で信頼・保存する」という説明は実装と不一致です。
+
+`requiredMethods` の追加は **no findings**。
+
+ファイル変更、テスト実行、実機確認はしていません。指摘はアプリと解決済み依存ライブラリのソース追跡に基づきます。
diff --git a/docs/reviews/2026-11-01-fixes-judgement.ja.md b/docs/reviews/2026-11-01-fixes-judgement.ja.md
new file mode 100644
index 0000000..36e5e2e
--- /dev/null
+++ b/docs/reviews/2026-11-01-fixes-judgement.ja.md
@@ -0,0 +1,16 @@
+# 判断: 使い始める前の 3 つの修正へのレビュー（2026-11-01）
+
+この文書は `2026-11-01-fixes-judgement.md` の日本語訳である。内容が食い違うときは英語版に従う。
+
+対象の commit: 407eccd（Chat の nudge）、362b8bc（host key の承認と Keychain）、1b740be（requiredMethods）。
+レビューの出力そのもの: `2026-11-01-fixes-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。
+
+| # | 指摘 | 判断 | 理由 |
+|---|---|---|---|
+| 1 | `ChatModel`: `load()` の最中に `stop()`・`start()` すると、止めたループも `pause()` に進んで `wake` を上書きし、continuation が 1 つ再開されずに残る | 直す | `load()` の後に guard を 1 行足すだけで済む。残った continuation は、その task を永久に止める |
+| 2 | Citadel 0.12.1 は、host key を拒否したとき handshake の promise を失敗させるだけで、TCP の channel を閉じない | 今は直さない | `Citadel/Sources/Citadel/ClientSession.swift` で確認した（handshake handler は promise を失敗させるだけ）。鍵を拒否する経路は `Mismatch` で以前からあった。`Unknown` は自動で再試行せず、sshd は認証されない接続を `LoginGraceTime`（既定 120 秒）で切るので、接続は積み上がらない。直す場所は Citadel（handshake の失敗で channel を閉じる）で、upstream への PR にする。`PENDING.md` に載せた |
+| 3 | Keychain の読み取りの失敗を「未登録」と読むので、登録済みのホストが初回に見え、pin を置き換えられうる | 直す | `KeyStore.hostKey` を throw にし、validator は Keychain のエラーで接続を失敗させる |
+| 4 | 照合のコマンドが、ホストが別の種類の鍵を出しても ed25519 の鍵のファイルを指す | 直す | `HostKeys.Unknown.checkCommand` が、提示された鍵の種類のファイルを指す |
+| 5 | Settings の Forget の確認文が、次の鍵を自動で信頼すると書いている | 直す | 次の鍵には承認が要る、という文に直した |
+
+修正後に確かめたこと: `HerdrUITests.testFirstConnectAsksForHostKey` が、iOS 27.1 の simulator から、この Mac の herdr-core に SSH でつないで通る（ログインの前に fingerprint を表示し、その値が host key の `ssh-keygen -lf` と一致し、承認した後にだけホームに進む）。HerdrKit の単体テスト 33 件が通る。
diff --git a/docs/reviews/2026-11-01-fixes-judgement.md b/docs/reviews/2026-11-01-fixes-judgement.md
new file mode 100644
index 0000000..a1795a4
--- /dev/null
+++ b/docs/reviews/2026-11-01-fixes-judgement.md
@@ -0,0 +1,14 @@
+# Judgement: review of the three pre-use fixes (2026-11-01)
+
+Reviewed commits: 407eccd (Chat nudge), 362b8bc (host key approval, Keychain), 1b740be (requiredMethods).
+Raw review: `2026-11-01-fixes-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).
+
+| # | Finding | Decision | Why |
+|---|---|---|---|
+| 1 | `ChatModel`: a `stop()`/`start()` during `load()` lets the stopped loop reach `pause()` and overwrite `wake`, leaving one continuation unresumed | Fix | One guard after `load()`; a leaked continuation hangs that task forever |
+| 2 | Citadel 0.12.1 fails the handshake promise on a rejected host key but does not close the TCP channel | No fix now | Confirmed in `Citadel/Sources/Citadel/ClientSession.swift` (the handshake handler only fails its promise). The rejected-key path already existed for `Mismatch`. `Unknown` is not retried automatically, and sshd drops an unauthenticated connection after `LoginGraceTime` (120 s by default), so connections cannot pile up. The fix belongs in Citadel (close the channel when the handshake fails), sent upstream as a PR; listed in `PENDING.md` |
+| 3 | A Keychain read failure is read as "nothing pinned", so a pinned host looks new and its pin could be replaced | Fix | `KeyStore.hostKey` now throws; the validator fails the connection with the Keychain error |
+| 4 | The check command names the ed25519 host key file even when the host presented another key type | Fix | `HostKeys.Unknown.checkCommand` names the file for the presented type |
+| 5 | Settings' Forget dialog says the next key is trusted automatically | Fix | Text now says the next key will need approval |
+
+Verified after the fixes: `HerdrUITests.testFirstConnectAsksForHostKey` passes on the iOS 27.1 simulator against this Mac's herdr-core over SSH (fingerprint shown before any login, equal to `ssh-keygen -lf` of the host key, home reached only after approval). HerdrKit's 33 unit tests pass.
diff --git a/docs/reviews/PENDING.md b/docs/reviews/PENDING.md
new file mode 100644
index 0000000..2de0e62
--- /dev/null
+++ b/docs/reviews/PENDING.md
@@ -0,0 +1,3 @@
+# Pending review work
+
+- Citadel 0.12.1 leaves the TCP channel open when the host key is rejected (`docs/reviews/2026-11-01-fixes-judgement.md` #2). Fix in a fork of `orlandos-nl/Citadel` and send upstream as a PR; until then sshd's `LoginGraceTime` bounds the leak.

commit 95acd13ca4e833de53971d04a7b0d11e69b3b4d6
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:58:45 2026 +0900

    Bound Files reads on the box and clean up preview copies
    
    Codex's review found that a 12 MiB file filled the whole frame as base64,
    that a file growing after the listing (or a FIFO) was read unbounded, that a
    slow earlier fetch could delete a newer preview, and that copies stayed on
    the phone. Reads now go through python3 with a regular-file check and an
    8 MiB cap enforced on the box, each preview gets its own folder that is
    deleted when Quick Look closes, and non-UTF-8 names are skipped and counted.

diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
index ab485c0..ac00f9d 100644
--- a/App/Sources/UI/FilesView.swift
+++ b/App/Sources/UI/FilesView.swift
@@ -3,7 +3,7 @@ import QuickLook
 import HerdrKit
 
 /// A space's folder on the box: browse it and open files in Quick Look
-/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
 struct FilesView: View {
     @Environment(AppStore.self) private var store
     var path: String
@@ -18,26 +18,50 @@ struct FilesView: View {
 
     @State private var dir: String?
     @State private var entries: [Entry] = []
+    @State private var skipped = 0
     @State private var error: String?
     @State private var opening: String?
+    @State private var fetch: Task<Void, Never>?
     @State private var preview: URL?
 
-    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
-    static let maxBytes = 12 << 20
+    /// The largest file read in one machine.exec. The reply is base64 (4/3) inside JSON in one
+    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
+    static let maxBytes = Frame.maxPayload / 2
 
-    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
+    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
+    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
     static let listScript = """
     import json, os, sys
     d = os.path.realpath(os.path.expanduser(sys.argv[1]))
-    out = []
+    out, skipped = [], 0
     with os.scandir(d) as it:
         for e in it:
             try:
+                e.name.encode("utf-8")
                 isdir = e.is_dir()
                 out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
-            except OSError:
-                pass
-    print(json.dumps({"dir": d, "entries": out}))
+            except (OSError, UnicodeEncodeError):
+                skipped += 1
+    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
+    """
+
+    // Writes at most argv[2] bytes of the regular file argv[1]; exit 3 when it is larger or not a
+    // regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
+    static let readScript = """
+    import os, stat, sys
+    limit = int(sys.argv[2])
+    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
+    if not stat.S_ISREG(os.fstat(fd).st_mode):
+        sys.exit("not a regular file")
+    data = b""
+    while len(data) <= limit:
+        chunk = os.read(fd, min(1 << 20, limit + 1 - len(data)))
+        if not chunk:
+            break
+        data += chunk
+    if len(data) > limit:
+        sys.stderr.write("larger than %d bytes" % limit); sys.exit(3)
+    sys.stdout.buffer.write(data)
     """
 
     var body: some View {
@@ -49,10 +73,14 @@ struct FilesView: View {
                 if e.isDir, let dir {
                     NavigationLink(value: dir + "/" + e.name) { row(e) }
                 } else {
-                    Button { Task { await open(e) } } label: { row(e) }
+                    Button { open(e) } label: { row(e) }
                         .disabled(opening != nil)
                 }
             }
+            if skipped > 0 {
+                Text("\(skipped) item(s) with names that can't be shown are hidden.")
+                    .font(HF.ui(13)).foregroundStyle(HC.dim)
+            }
         }
         .overlay { if dir == nil && error == nil { ProgressView() } }
         .navigationTitle(title)
@@ -60,6 +88,9 @@ struct FilesView: View {
         .task { await load() }
         .refreshable { await load() }
         .quickLookPreview($preview)
+        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
+        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
+        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil }
     }
 
     private func row(_ e: Entry) -> some View {
@@ -79,25 +110,35 @@ struct FilesView: View {
         .accessibilityLabel(e.name)
     }
 
+    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
+        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+        return why.isEmpty ? fallback : String(why.suffix(300))
+    }
+
     private func load() async {
         do {
             let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
             guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
-                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
-                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
+                error = Self.failure(r, "Couldn't list \(path)")
                 return
             }
             entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
                 guard let n = a[0].string else { return nil }
                 return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
             })
+            skipped = v["skipped"].int ?? 0
             dir = d
             error = nil
         } catch {
-            self.error = error.localizedDescription
+            self.error = Self.message(error)
         }
     }
 
+    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
+    private static func message(_ error: Error) -> String {
+        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
+    }
+
     /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
     static func sorted(_ entries: [Entry]) -> [Entry] {
         entries.sorted { a, b in
@@ -108,32 +149,40 @@ struct FilesView: View {
         }
     }
 
-    private func open(_ e: Entry) async {
-        guard let dir else { return }
-        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
+    private func open(_ e: Entry) {
+        guard let dir, opening == nil else { return }
+        // shortcut: files over maxBytes (8 MiB) are refused; read them in ranges when large files matter.
         guard e.size <= Self.maxBytes else {
-            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
+            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over \(Self.maxBytes.formatted(.byteCount(style: .file))) can't be previewed yet."
             return
         }
         opening = e.name
-        defer { opening = nil }
-        do {
-            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
-            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
-                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
-                return
+        fetch = Task {
+            defer { if !Task.isCancelled { opening = nil; fetch = nil } }
+            do {
+                let r = try await store.exec(argv: ["python3", "-c", Self.readScript, dir + "/" + e.name, String(Self.maxBytes)],
+                                             cwd: nil, on: nil, timeout: 60, input: nil)
+                guard !Task.isCancelled else { return }
+                guard r.code == 0, !r.timedOut else { error = Self.failure(r, "Couldn't read \(e.name)"); return }
+                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
+                let folder = FileManager.default.temporaryDirectory
+                    .appendingPathComponent("preview", isDirectory: true)
+                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
+                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+                let url = folder.appendingPathComponent(e.name)
+                try r.stdout.write(to: url, options: .completeFileProtection)
+                error = nil
+                preview = url
+            } catch {
+                if !Task.isCancelled { self.error = Self.message(error) }
             }
-            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
-            try? FileManager.default.removeItem(at: folder)
-            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
-            let url = folder.appendingPathComponent(e.name)
-            try r.stdout.write(to: url, options: .completeFileProtection)
-            error = nil
-            preview = url
-        } catch {
-            self.error = error.localizedDescription
         }
     }
+
+    /// Deletes a closed preview's downloaded copy (its own folder).
+    private static func discard(_ url: URL) {
+        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
+    }
 }
 
 /// The Files sheet for one space: its own stack so folders push inside the sheet.
@@ -154,5 +203,7 @@ struct FilesSheet: View {
                     }
                 }
         }
+        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
+        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
     }
 }
diff --git a/docs/reviews/2026-11-01-files-codex.md b/docs/reviews/2026-11-01-files-codex.md
new file mode 100644
index 0000000..652504d
--- /dev/null
+++ b/docs/reviews/2026-11-01-files-codex.md
@@ -0,0 +1,2915 @@
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
+session id: 01a1934e-3f3a-78c0-b877-a7357408e0c6
+--------
+user
+Review the last commit in this repo (git show HEAD): a Files browser with Quick Look preview for an iOS client of herdr-core. Context: AGENTS.md, docs/2026-11-01_herdr-ios-code-review.md (section on where features plug in), Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift (exec, frame limit). Review only; do not edit files. For each finding give severity (high/medium/low), file:line, a concrete failure scenario and a suggested fix. Check: path handling and injection (argv to machine.exec, names with odd characters, symlinks, '~'), the 12 MiB limit vs the actual frame/base64/JSON overhead and what happens just above it, temp file handling and data protection, SwiftUI state races (open twice, dismiss during fetch, navigation), and anything that breaks on a box without python3. Say 'no findings' where there are none. Be concise.
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
+I’ll review the commit and the client’s exec/frame handling, then check the preview lifecycle and failure paths. I’ll use the ponytail review skill and leave files unchanged.
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'pwd && git status --short && git show --stat HEAD' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+?? docs/reviews/2026-11-01-files-codex.md
+commit 6c7e200ae6bb6ec4d3cc94e86232ac2a3afa69ff
+Author: i2 <95607264+YosukeIida@users.noreply.github.com>
+Date:   Sun Nov 1 03:52:21 2026 +0900
+
+    Browse a space's folder and preview its files in Quick Look
+    
+    The phone had no way to read what agents produce on the box: PDFs, Office
+    documents, images. Files lists the space folder with the box's python3 (as
+    Chat already does) and fetches a file with cat over machine.exec into a
+    temporary file for Quick Look, which renders PDF, docx, xlsx and images on
+    the device. Files over 12 MiB are refused for now: one exec reply must fit
+    in a 16 MiB frame as base64.
+
+ App/Sources/UI/FilesView.swift | 158 +++++++++++++++++++++++++++++++++++++++++
+ App/Sources/UI/SpaceView.swift |   6 ++
+ UITests/HerdrUITests.swift     |  29 ++++++++
+ 3 files changed, 193 insertions(+)
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md && cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail/SKILL.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
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
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc 'cat docs/2026-11-01_herdr-ios-code-review.md && nl -ba Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+# Code quality check of zzulanas/herdr-ios
+
+On 2026-11-01, commit `a030501` (2026-10-30) was checked.
+
+Two methods were used.
+
+- Ran the HerdrKit unit tests (Swift 6.4, macOS). All 33 passed.
+- Had another agent read the code and collected its findings. The 2 high-severity findings were confirmed in the source.
+
+The build and behavior on a real device were not checked.
+
+## Conclusion
+
+It can be used as the foundation. However, before starting to use it, the 2 high-severity findings and the dependency version pinning must be fixed.
+
+- HerdrKit (framing, JSON-RPC, events, the Layout document) is solidly built and covered by tests.
+- The problems are concentrated in the App layer, and all can be fixed locally.
+
+## Size and structure
+
+| Part | Contents |
+|---|---|
+| `Packages/HerdrKit` | protocol and model (SwiftPM, no external dependencies, 33 tests), `herdr-probe` (macOS CLI) |
+| `App/Sources` | Net (Citadel SSH, Keychain, host key), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore mod host), Notify |
+| External dependencies | Citadel `from: 0.12.1`, SwiftTerm `exactVersion: 1.20.0` |
+| Size | About 11,500 lines of Swift |
+
+## Findings
+
+| Severity | Location | Description | Fix |
+|---|---|---|---|
+| High (confirmed in source) | `App/Sources/Chat/ChatView.swift:46`, `ChatModel.swift:91-97` | Calls `model.nudge()` on every `title` change. `title` changes every 0.1 s while working, so while Chat is open, the python that reads the transcript on the Mac side is launched almost continuously. There is also a race: when the sleep of a previous wait ends, it also releases the next wait | Remove the nudge on `title`, keep only `status` and `turn`. Distinguish sleeping Tasks with a token |
+| High (confirmed in source) | `App/Sources/Net/HostKeys.swift:58-60` | On the first connection, the host key is pinned without confirmation, and the fingerprint is shown only after pinning. With a man-in-the-middle attack on the first connection, password authentication hands over the password as is. Storage is UserDefaults, not Keychain | On the first connection, show the fingerprint and require approval. Store in Keychain |
+| Medium | `AppStore.swift:138-143, 486-508` | Closes the connection 8 s after entering the background. On return, it waits for SSH, hello, subscribe and docGet in sequence. The last screen is kept only in memory, so after the process ends it starts from the connection screen | Wait for subscribe and docGet concurrently. Save the snapshot to disk and show it immediately on return |
+| Medium | `EventLines.swift:131` → `AppStore.swift:629-642` | Replaces the whole terminal list on every `title` notification, and every screen is re-evaluated | Route `title`-only updates separately, or thin them out |
+| Medium | `HerdrClient.swift:28-29` | `requiredMethods` does not include `terminal.read/send/keys/interrupt` and `server.status`, which are used | Add them to the array |
+| Medium | `project.yml:14-19` | The Citadel version is not pinned, and `Package.resolved` is gitignored. `__pycache__/*.pyc` is tracked and bundled into the app | Use `exactVersion` and commit resolved. Delete the pyc files |
+| Medium | `Package.swift`, `project.yml` | The Swift language mode is v5, relying on hand-written locks. Some reads happen outside the lock (`HerdrClient.swift:113` and `221`) | First move HerdrKit to v6 |
+| Medium (by design) | `Mods/ModHub.swift:310, 325` | Passes the command a mod specifies straight to `machine.exec` on the Mac side. The trust boundary is the same as the Herdr app | Operate by bundling only mods you wrote yourself |
+| Low | `herdr-notify.py:87, 91`, `Push.swift:78` | Puts the APNs JWT in curl arguments (visible in `ps`). Does not validate the device token. Does not create the devices file with umask 077 | Pass the JWT on standard input. Check the token format. Create with umask 077 |
+| Low | `herdr-notify.py:184-191` | Sends "finished" when blocked changes to error. This differs from the app's decision | Align the decision with `AttentionTracker` |
+| Low | Entire App | The App side has no unit tests | Write tests starting from `ChatModel.rebuild` (a pure function) |
+
+Within the checked scope, there was no room for shell injection. All values passed to `sh -c` are passed as positional arguments, and session IDs are constrained to a fixed format by a regular expression. The Layout document is edited while preserving unknown fields, and version conflicts are handled by compare-and-swap (CAS).
+
+## Where to add the new features
+
+- **Codex chat**: The Mac-side script outputs a common format that represents the kind (user, text, tool, result), and the Swift side only folds it. The dependency on Claude Code is in only 2 places: `AgentScreen.swift:13` and `ChatModel.swift:107`. Add a script that outputs the rollout in the same format, and select it by program.
+- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
+- **launchd notifier**: In `NotificationSettings.swift:180-205` and `scripts/install-notifier.sh`, on macOS, place a plist in `~/Library/LaunchAgents` and run `launchctl bootstrap`. Add the Homebrew and nix locations to the `hc` search paths in `herdr-notify.py:21`.
+
+## Inconsistencies between documentation and code
+
+- Code comments refer to `SPEC.md`, but `SPEC.md` is not in the repo.
+- The README says "mod exec runs on the Mac side", but `open` and pbcopy are handled on the smartphone side.
+- The README describes the notifier only as being for systemd, but the code has an alternative path that starts it with nohup.
+
+## What to read before building
+
+Building runs the following 2 items without a sandbox. Their contents must be read before building.
+
+- The pre-build `bundle-mods.sh` (`ENABLE_USER_SCRIPT_SANDBOXING: NO`)
+- SwiftTerm's build plugin
+     1	import Foundation
+     2	
+     3	/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
+     4	/// JSON-RPC on channel 0, terminal and event streams on core-allocated channels.
+     5	///
+     6	/// Thread model: transport bytes are parsed on whatever thread the transport
+     7	/// calls back on (serially), under one lock. Writes go through a single serial
+     8	/// writer task. Stream and event callbacks are delivered on `callbackQueue`.
+     9	public final class HerdrClient: @unchecked Sendable {
+    10	    public let transport: ByteTransport
+    11	    /// Where stream/event/disconnect callbacks run. Set before `connect()`.
+    12	    public var callbackQueue: DispatchQueue = .main
+    13	    /// No bytes on any channel for this long = the connection is dead.
+    14	    public var livenessTimeout: TimeInterval = 45
+    15	    /// Called once on `callbackQueue` when the connection drops unexpectedly
+    16	    /// (not after `close()`).
+    17	    public var onDisconnect: ((HerdrError) -> Void)? {
+    18	        get { lock.withLock { _onDisconnect } }
+    19	        set { lock.withLock { _onDisconnect = newValue } }
+    20	    }
+    21	    private var _onDisconnect: ((HerdrError) -> Void)?
+    22	
+    23	    public private(set) var hello: HelloInfo?
+    24	    /// Remote stderr so far (capped), for failure screens.
+    25	    public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }
+    26	
+    27	    /// Methods the app calls; a core lacking one can't serve it.
+    28	    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
+    29	                                         "terminal.attach", "terminal.keep", "terminal.read", "terminal.send", "terminal.keys",
+    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+    31	                                         "machine.list", "server.status"]
+    32	    public static let minCoreVersion = "0.1.11"
+    33	    public static let generation: UInt64 = 1
+    34	
+    35	    private enum Route { case terminal(TerminalStream), events(EventSubscription) }
+    36	    private enum Mode { case idle, plain, framed, closed }
+    37	
+    38	    private let lock = NSLock()
+    39	    private var mode = Mode.idle
+    40	    private var plain = Data()
+    41	    private var helloCont: CheckedContinuation<JSONValue, Error>?
+    42	    private var decoder = FrameDecoder()
+    43	    private var nextID: UInt64 = 0
+    44	    private var pending: [UInt64: CheckedContinuation<JSONValue, Error>] = [:]
+    45	    private var cancelled: Set<UInt64> = []
+    46	    private var routes: [UInt32: Route] = [:]
+    47	    private var early: [UInt32: [Frame]] = [:]
+    48	    /// Channels we closed: drop their frames, swallow the CLOSE echo.
+    49	    private var closing: Set<UInt32> = []
+    50	    private var lastReceive = Date()
+    51	    private var stderrBuf = Data()
+    52	    private var closedByUs = false
+    53	
+    54	    private let outbox: AsyncStream<Data>.Continuation
+    55	    private let outStream: AsyncStream<Data>
+    56	    private var writerTask: Task<Void, Never>?
+    57	    private var livenessTask: Task<Void, Never>?
+    58	
+    59	    public init(transport: ByteTransport) {
+    60	        self.transport = transport
+    61	        (outStream, outbox) = AsyncStream<Data>.makeStream(bufferingPolicy: .unbounded)
+    62	    }
+    63	
+    64	    deinit {
+    65	        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
+    66	    }
+    67	
+    68	    public var isConnected: Bool { lock.withLock { mode == .framed } }
+    69	
+    70	    // MARK: Connect
+    71	
+    72	    /// Starts the transport, says hello in plain mode, then switches to frames.
+    73	    public func connect(helloTimeout: TimeInterval = 20) async throws -> HelloInfo {
+    74	        let started: Bool = lock.withLock {
+    75	            guard mode == .idle else { return false }
+    76	            mode = .plain; lastReceive = Date(); return true
+    77	        }
+    78	        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }
+    79	
+    80	        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
+    81	            for await chunk in outStream {
+    82	                do { try await transport.write(chunk) } catch {
+    83	                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
+    84	                    return
+    85	                }
+    86	            }
+    87	        }
+    88	
+    89	        try await transport.start(
+    90	            onBytes: { [weak self] in self?.receive($0) },
+    91	            onStderr: { [weak self] d in self?.lock.withLock {
+    92	                guard let self, self.stderrBuf.count < 16_384 else { return }
+    93	                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
+    94	            } },
+    95	            onClose: { [weak self] err in self?.transportClosed(err) })
+    96	
+    97	        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
+    98	            let alreadyClosed: Bool = lock.withLock {
+    99	                if mode == .closed { return true }
+   100	                helloCont = cont; return false
+   101	            }
+   102	            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
+   103	            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
+   104	            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
+   105	                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
+   106	                    defer { self.helloCont = nil }; return self.helloCont
+   107	                }) else { return }
+   108	                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
+   109	                                              hint: self.stderrText.trimmed.nilIfEmpty))
+   110	                self.close()
+   111	            }
+   112	        }
+   113	        do {
+   114	            let info = try Self.check(hello: reply)
+   115	            lock.withLock { hello = info }
+   116	            startLiveness()
+   117	            return info
+   118	        } catch {
+   119	            close()
+   120	            throw error
+   121	        }
+   122	    }
+   123	
+   124	    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
+   125	    public static func check(hello reply: JSONValue) throws -> HelloInfo {
+   126	        if !reply["error"].isNull { throw rpcError(reply["error"]) }
+   127	        let r = reply["result"]
+   128	        let gen = r["generation"].uint64 ?? 0
+   129	        let version = r["version"].string ?? "0"
+   130	        if gen > generation {
+   131	            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
+   132	        }
+   133	        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
+   134	            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
+   135	        }
+   136	        let methods = r["methods"].array?.compactMap(\.string) ?? []
+   137	        let missing = requiredMethods.filter { !methods.contains($0) }
+   138	        if !missing.isEmpty {
+   139	            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
+   140	        }
+   141	        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
+   142	                         version: version, methods: methods)
+   143	    }
+   144	
+   145	    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }
+   146	
+   147	    static func semver(_ v: String) -> [Int] {
+   148	        var s = v.trimmingCharacters(in: .whitespaces)
+   149	        if s.hasPrefix("hc ") { s.removeFirst(3) }
+   150	        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
+   151	        return (0..<3).map { $0 < parts.count ? parts[$0] : 0 }
+   152	    }
+   153	
+   154	    /// Closes the connection. Pending calls fail with `lost`; streams get `onLost`.
+   155	    public func close() {
+   156	        lock.withLock { closedByUs = true }
+   157	        transport.close()
+   158	        fail(HerdrError(code: -1, kind: "closed", message: "Disconnected"))
+   159	    }
+   160	
+   161	    // MARK: Calls
+   162	
+   163	    /// One JSON-RPC call on channel 0. Errors are `HerdrError` (message, hint,
+   164	    /// kind). Cancelling the task sends `$/cancelRequest`.
+   165	    @discardableResult
+   166	    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
+   167	        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
+   168	        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
+   169	                              "params": params.isNull ? [:] : params]
+   170	        return try await withTaskCancellationHandler {
+   171	            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
+   172	                enum Outcome { case go, cancelled, closed }
+   173	                let outcome: Outcome = lock.withLock {
+   174	                    if cancelled.remove(id) != nil { return .cancelled }
+   175	                    if mode != .framed { return .closed }
+   176	                    pending[id] = cont; return .go
+   177	                }
+   178	                switch outcome {
+   179	                case .cancelled: cont.resume(throwing: CancellationError()); return
+   180	                case .closed: cont.resume(throwing: HerdrError.lost); return
+   181	                case .go: break
+   182	                }
+   183	                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
+   184	                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
+   185	                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
+   186	                }
+   187	            }
+   188	        } onCancel: {
+   189	            let wasPending = lock.withLock { () -> Bool in
+   190	                if pending[id] != nil { return true }
+   191	                cancelled.insert(id); return false
+   192	            }
+   193	            if wasPending {
+   194	                finish(id, .failure(CancellationError()))
+   195	                notify("$/cancelRequest", ["id": .number(Double(id))])
+   196	            }
+   197	        }
+   198	    }
+   199	
+   200	    /// A notification (no id, no reply).
+   201	    public func notify(_ method: String, _ params: JSONValue = [:]) {
+   202	        let msg: JSONValue = ["jsonrpc": "2.0", "method": .string(method), "params": params]
+   203	        send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
+   204	    }
+   205	
+   206	    private func finish(_ id: UInt64, _ result: Result<JSONValue, Error>) {
+   207	        guard let cont = lock.withLock({ pending.removeValue(forKey: id) }) else { return }
+   208	        cont.resume(with: result)
+   209	    }
+   210	
+   211	    static func rpcError(_ e: JSONValue) -> HerdrError {
+   212	        HerdrError(code: e["code"].int ?? -32000, kind: e["data"]["kind"].string,
+   213	                   message: e["message"].string ?? "core call failed", hint: e["data"]["hint"].string)
+   214	    }
+   215	
+   216	    // MARK: Typed helpers
+   217	
+   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
+   219	    /// exit or timeout is a result, not an error.
+   220	    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
+   221	        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
+   222	        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
+   223	        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
+   224	        if let input { p["input"] = .string(input.base64EncodedString()) }
+   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+   226	        return ExecResult(code: r["code"].int,
+   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+   228	                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
+   229	                          timedOut: r["timed_out"].bool ?? false)
+   230	    }
+   231	
+   232	    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
+   233	        let r = try await call("doc.get", ["name": .string(name)])
+   234	        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
+   235	    }
+   236	
+   237	    /// CAS write; throws kind "conflict" when `version` is stale. Returns the new version.
+   238	    public func docSet(_ name: String = "herdr-app", value: JSONValue, version: UInt64) async throws -> UInt64 {
+   239	        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
+   240	        return r["version"].uint64 ?? version + 1
+   241	    }
+   242	
+   243	    public func listTerminals(all: Bool = false) async throws -> [TerminalRecord] {
+   244	        let r = try await call("terminal.list", ["all": .bool(all)])
+   245	        return (r["terminals"].array ?? []).map(TerminalRecord.init(raw:))
+   246	    }
+   247	
+   248	    public func read(terminal: String, lines: Int = 200) async throws -> String {
+   249	        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
+   250	    }
+   251	
+   252	    // MARK: Streams
+   253	
+   254	    /// `terminal.attach`: opens a stream channel. Data that arrives before the
+   255	    /// reply (or before handlers are set) is kept and delivered in order.
+   256	    public func attach(terminal: String, cols: Int, rows: Int, history: Int = 2000,
+   257	                       display: JSONValue? = nil, observe: Bool = false) async throws -> TerminalStream {
+   258	        var p: JSONValue = ["terminal": .string(terminal), "cols": .number(Double(max(cols, 1))),
+   259	                            "rows": .number(Double(max(rows, 1))), "history": .number(Double(history)), "observe": .bool(observe)]
+   260	        if let display { p["display"] = display }
+   261	        let r = try await call("terminal.attach", p)
+   262	        guard let ch = r["channel"].uint64.map({ UInt32(clamping: $0) }), ch > 0 else {
+   263	            throw HerdrError(code: -32603, kind: "internal", message: "attach reply had no channel")
+   264	        }
+   265	        let stream = TerminalStream(channel: ch, record: TerminalRecord(raw: r["terminal"]))
+   266	        stream.sink = { [weak self] kind, payload in self?.streamSend(ch, kind, payload) }
+   267	        let queue = callbackQueue
+   268	        let backlog: [Frame]? = lock.withLock {
+   269	            guard mode == .framed else { return nil }
+   270	            routes[ch] = .terminal(stream)
+   271	            let frames = early.removeValue(forKey: ch) ?? []
+   272	            // Flush inside the lock so later frames queue behind these.
+   273	            for f in frames { route(f, to: .terminal(stream), queue: queue) }
+   274	            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
+   275	            return frames
+   276	        }
+   277	        if backlog == nil { queue.async { stream.deliver(.lost) } }
+   278	        return stream
+   279	    }
+   280	
+   281	    /// `events.subscribe` with no filter (filtered subscriptions miss doc events).
+   282	    public func subscribe(coalesce: TimeInterval = 0.08) async throws -> EventSubscription {
+   283	        let r = try await call("events.subscribe", [:])
+   284	        guard let ch = r["channel"].uint64.map({ UInt32(clamping: $0) }), ch > 0 else {
+   285	            throw HerdrError(code: -32603, kind: "internal", message: "subscribe reply had no channel")
+   286	        }
+   287	        let sub = EventSubscription(channel: ch, snapshot: r, queue: callbackQueue, coalesce: coalesce)
+   288	        sub.closer = { [weak self] in self?.streamSend(ch, FrameKind.close, Data()) }
+   289	        let ok: Bool = lock.withLock {
+   290	            guard mode == .framed else { return false }
+   291	            routes[ch] = .events(sub)
+   292	            let frames = early.removeValue(forKey: ch) ?? []
+   293	            for f in frames { route(f, to: .events(sub), queue: callbackQueue) }
+   294	            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
+   295	            return true
+   296	        }
+   297	        guard ok else { throw HerdrError.lost }
+   298	        send(Frame.credit(ch, 1 << 20))
+   299	        return sub
+   300	    }
+   301	
+   302	    private func streamSend(_ ch: UInt32, _ kind: UInt8, _ payload: Data) {
+   303	        if kind == FrameKind.close {
+   304	            let wasOpen: Bool = lock.withLock {
+   305	                guard routes.removeValue(forKey: ch) != nil else { return false }
+   306	                closing.insert(ch); return true
+   307	            }
+   308	            guard wasOpen else { return }
+   309	        } else if kind == FrameKind.data, payload.isEmpty {
+   310	            return
+   311	        }
+   312	        send(Frame(channel: ch, kind: kind, payload: payload))
+   313	    }
+   314	
+   315	    private func send(_ f: Frame) {
+   316	        outbox.yield(f.encoded())
+   317	    }
+   318	
+   319	    // MARK: Reading
+   320	
+   321	    private func receive(_ bytes: Data) {
+   322	        var actions: [() -> Void] = []
+   323	        var protocolError: HerdrError?
+   324	        lock.withLock {
+   325	            lastReceive = Date()
+   326	            switch mode {
+   327	            case .idle, .closed:
+   328	                return
+   329	            case .plain:
+   330	                plain.append(bytes)
+   331	                guard let nl = plain.firstIndex(of: 0x0a) else { return }
+   332	                let line = plain[plain.startIndex..<nl]
+   333	                let rest = plain[plain.index(after: nl)...]
+   334	                let reply = (try? JSONValue.parse(Data(line))) ?? .null
+   335	                mode = .framed
+   336	                decoder.append(Data(rest))
+   337	                plain = Data()
+   338	                if let c = helloCont {
+   339	                    helloCont = nil
+   340	                    if reply.isNull {
+   341	                        actions.append { c.resume(throwing: HerdrError(kind: "parse_error", message: "The core's hello reply wasn't JSON")) }
+   342	                    } else {
+   343	                        actions.append { c.resume(returning: reply) }
+   344	                    }
+   345	                }
+   346	            case .framed:
+   347	                decoder.append(bytes)
+   348	            }
+   349	            do {
+   350	                while let f = try decoder.next() { handle(f, &actions) }
+   351	            } catch {
+   352	                protocolError = HerdrError(code: -32700, kind: "lost", message: "Lost the core", hint: "\(error)")
+   353	            }
+   354	        }
+   355	        for a in actions { a() }
+   356	        if let protocolError { fail(protocolError); transport.close() }
+   357	    }
+   358	
+   359	    /// Called with the lock held.
+   360	    private func handle(_ f: Frame, _ actions: inout [() -> Void]) {
+   361	        if f.channel == 0 {
+   362	            guard f.kind == FrameKind.data, let msg = try? JSONValue.parse(f.payload),
+   363	                  let id = msg["id"].uint64 else { return }
+   364	            guard let cont = pending.removeValue(forKey: id) else {
+   365	                // A reply nobody waits for (cancelled or timed out). If it opened a
+   366	                // stream (attach, subscribe), close it so the core drops the viewer.
+   367	                if let ch = msg["result"]["channel"].uint64.flatMap({ UInt32(exactly: $0) }), ch > 0, routes[ch] == nil {
+   368	                    early.removeValue(forKey: ch)
+   369	                    closing.insert(ch)
+   370	                    send(Frame(channel: ch, kind: FrameKind.close, payload: Data()))
+   371	                }
+   372	                return
+   373	            }
+   374	            if msg["error"].isNull {
+   375	                let result = msg["result"]
+   376	                actions.append { cont.resume(returning: result) }
+   377	            } else {
+   378	                let err = Self.rpcError(msg["error"])
+   379	                actions.append { cont.resume(throwing: err) }
+   380	            }
+   381	            return
+   382	        }
+   383	        if closing.contains(f.channel) {
+   384	            if f.kind == FrameKind.close { closing.remove(f.channel) }
+   385	            return
+   386	        }
+   387	        guard let r = routes[f.channel] else {
+   388	            early[f.channel, default: []].append(f)
+   389	            return
+   390	        }
+   391	        if f.kind == FrameKind.close { routes.removeValue(forKey: f.channel) }
+   392	        route(f, to: r, queue: callbackQueue)
+   393	    }
+   394	
+   395	    /// Called with the lock held.
+   396	    private func route(_ f: Frame, to r: Route, queue: DispatchQueue) {
+   397	        switch r {
+   398	        case .terminal(let s):
+   399	            switch f.kind {
+   400	            case FrameKind.data:
+   401	                let d = f.payload
+   402	                queue.async { s.deliver(.data(d)) }
+   403	            case FrameKind.close:
+   404	                let why = f.payload.isEmpty ? JSONValue.null : ((try? JSONValue.parse(f.payload)) ?? .null)
+   405	                queue.async { s.deliver(.close(why)) }
+   406	            default: break
+   407	            }
+   408	        case .events(let sub):
+   409	            switch f.kind {
+   410	            case FrameKind.data:
+   411	                sub.push(f.payload)
+   412	                send(Frame.credit(f.channel, f.payload.count))
+   413	            case FrameKind.close:
+   414	                sub.ended(lost: false)
+   415	            default: break
+   416	            }
+   417	        }
+   418	    }
+   419	
+   420	    // MARK: Loss
+   421	
+   422	    private func transportClosed(_ err: Error?) {
+   423	        let (hint, byUs): (String?, Bool) = lock.withLock {
+   424	            (String(decoding: stderrBuf, as: UTF8.self).trimmed.nilIfEmpty, closedByUs)
+   425	        }
+   426	        if byUs { return }
+   427	        fail(closedError(err, stderr: hint))
+   428	    }
+   429	
+   430	    private func closedError(_ err: Error?, stderr: String? = nil) -> HerdrError {
+   431	        let stderr = stderr ?? stderrText.trimmed.nilIfEmpty
+   432	        if let stderr, stderr.contains("not installed") {
+   433	            return HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine", hint: stderr)
+   434	        }
+   435	        return HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: stderr ?? err.map { "\($0.localizedDescription)" })
+   436	    }
+   437	
+   438	    /// Fails everything once: pending calls, hello, every stream.
+   439	    private func fail(_ error: HerdrError) {
+   440	        var conts: [CheckedContinuation<JSONValue, Error>] = []
+   441	        var helloC: CheckedContinuation<JSONValue, Error>?
+   442	        var lostRoutes: [Route] = []
+   443	        let first: Bool = lock.withLock {
+   444	            guard mode != .closed else { return false }
+   445	            mode = .closed
+   446	            conts = Array(pending.values); pending.removeAll()
+   447	            helloC = helloCont; helloCont = nil
+   448	            lostRoutes = Array(routes.values); routes.removeAll(); early.removeAll(); closing.removeAll()
+   449	            return true
+   450	        }
+   451	        guard first else { return }
+   452	        livenessTask?.cancel()
+   453	        outbox.finish()
+   454	        let lost = HerdrError(code: -1, kind: error.kind ?? "lost", message: error.message, hint: error.hint)
+   455	        helloC?.resume(throwing: lost)
+   456	        for c in conts { c.resume(throwing: lost) }
+   457	        let queue = callbackQueue
+   458	        for r in lostRoutes {
+   459	            switch r {
+   460	            case .terminal(let s): queue.async { s.deliver(.lost) }
+   461	            case .events(let sub): sub.ended(lost: true)
+   462	            }
+   463	        }
+   464	        let cb: ((HerdrError) -> Void)? = lock.withLock { closedByUs ? nil : _onDisconnect }
+   465	        if let cb { queue.async { cb(lost) } }
+   466	    }
+   467	
+   468	    private func startLiveness() {
+   469	        livenessTask = Task.detached { [weak self] in
+   470	            while !Task.isCancelled {
+   471	                try? await Task.sleep(for: .seconds(5))
+   472	                guard let self else { return }
+   473	                let idle = self.lock.withLock { Date().timeIntervalSince(self.lastReceive) }
+   474	                if idle > self.livenessTimeout {
+   475	                    self.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core",
+   476	                                         hint: "no data for \(Int(idle)) s"))
+   477	                    self.transport.close()
+   478	                    return
+   479	                }
+   480	            }
+   481	        }
+   482	    }
+   483	}
+   484	
+   485	/// What an events subscription delivered (coalesced).
+   486	public struct EventUpdate: Sendable {
+   487	    public var pushed: Pushed
+   488	    /// Every terminal the stream describes (live and finished), stream order.
+   489	    public var terminals: [TerminalRecord]
+   490	    public var seq: UInt64
+   491	}
+   492	
+   493	/// An `events.subscribe` channel. Lines are applied off the main thread;
+   494	/// `onUpdate` gets coalesced results on the callback queue.
+   495	public final class EventSubscription: @unchecked Sendable {
+   496	    public let channel: UInt32
+   497	    /// The snapshot from the subscribe reply (all terminals, live and finished).
+   498	    public let snapshot: [TerminalRecord]
+   499	    public let snapshotSeq: UInt64
+   500	    public var onUpdate: ((EventUpdate) -> Void)? { didSet { queue.async { [weak self] in self?.flushIfReady() } } }
+   501	    /// The core closed the channel: subscribe again.
+   502	    public var onClose: (() -> Void)?
+   503	    /// The connection dropped.
+   504	    public var onLost: (() -> Void)?
+   505	
+   506	    var closer: (() -> Void)?
+   507	    private let queue: DispatchQueue
+   508	    private let coalesce: TimeInterval
+   509	    private let lock = NSLock()
+   510	    private var lines: EventLines
+   511	    private var accumulated = Pushed()
+   512	    private var scheduled = false
+   513	    private var endedState: Bool?   // nil = open, false = closed by core, true = lost
+   514	
+   515	    init(channel: UInt32, snapshot: JSONValue, queue: DispatchQueue, coalesce: TimeInterval) {
+   516	        self.channel = channel
+   517	        self.queue = queue
+   518	        self.coalesce = coalesce
+   519	        lines = EventLines(snapshot: snapshot)
+   520	        self.snapshot = lines.terminals.map(TerminalRecord.init(raw:))
+   521	        snapshotSeq = lines.seq
+   522	    }
+   523	
+   524	    /// Current state of every terminal (thread-safe).
+   525	    public var terminals: [TerminalRecord] { lock.withLock { lines.terminals.map(TerminalRecord.init(raw:)) } }
+   526	
+   527	    /// Stop the subscription (sends CLOSE).
+   528	    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }
+   529	
+   530	    /// Lines received so far (heartbeats included).
+   531	    public var lineCount: Int { lock.withLock { linesSeen } }
+   532	    private var linesSeen = 0
+   533	
+   534	    func push(_ bytes: Data) {
+   535	        let schedule: Bool = lock.withLock {
+   536	            let p = lines.push(bytes)
+   537	            linesSeen += p.lines
+   538	            accumulated.merge(p)
+   539	            guard !scheduled, p.terminals || !p.docs.isEmpty || p.missed else { return false }
+   540	            scheduled = true
+   541	            return true
+   542	        }
+   543	        if schedule { queue.asyncAfter(deadline: .now() + coalesce) { [weak self] in self?.flushIfReady() } }
+   544	    }
+   545	
+   546	    func ended(lost: Bool) {
+   547	        lock.withLock { endedState = lost }
+   548	        queue.async { [weak self] in
+   549	            guard let self else { return }
+   550	            self.flushIfReady()
+   551	            if lost { self.onLost?() } else { self.onClose?() }
+   552	        }
+   553	    }
+   554	
+   555	    /// On the callback queue.
+   556	    private func flushIfReady() {
+   557	        guard let onUpdate else { return }
+   558	        let update: EventUpdate? = lock.withLock {
+   559	            scheduled = false
+   560	            let p = accumulated
+   561	            guard p.terminals || !p.docs.isEmpty || p.missed else { return nil }
+   562	            accumulated = Pushed()
+   563	            return EventUpdate(pushed: p, terminals: lines.terminals.map(TerminalRecord.init(raw:)), seq: lines.seq)
+   564	        }
+   565	        if let update { onUpdate(update) }
+   566	    }
+   567	}
+   568	
+   569	extension String {
+   570	    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
+   571	    var nilIfEmpty: String? { isEmpty ? nil : self }
+   572	}
+
+exec
+/bin/zsh -lc 'nl -ba App/Sources/UI/FilesView.swift && nl -ba App/Sources/UI/SpaceView.swift && cat README.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+     1	import SwiftUI
+     2	import QuickLook
+     3	import HerdrKit
+     4	
+     5	/// A space's folder on the box: browse it and open files in Quick Look
+     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+     7	struct FilesView: View {
+     8	    @Environment(AppStore.self) private var store
+     9	    var path: String
+    10	    var title: String
+    11	
+    12	    struct Entry: Identifiable, Hashable {
+    13	        var name: String
+    14	        var isDir: Bool
+    15	        var size: Int
+    16	        var id: String { name }
+    17	    }
+    18	
+    19	    @State private var dir: String?
+    20	    @State private var entries: [Entry] = []
+    21	    @State private var error: String?
+    22	    @State private var opening: String?
+    23	    @State private var preview: URL?
+    24	
+    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
+    26	    static let maxBytes = 12 << 20
+    27	
+    28	    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
+    29	    static let listScript = """
+    30	    import json, os, sys
+    31	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
+    32	    out = []
+    33	    with os.scandir(d) as it:
+    34	        for e in it:
+    35	            try:
+    36	                isdir = e.is_dir()
+    37	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
+    38	            except OSError:
+    39	                pass
+    40	    print(json.dumps({"dir": d, "entries": out}))
+    41	    """
+    42	
+    43	    var body: some View {
+    44	        List {
+    45	            if let error {
+    46	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
+    47	            }
+    48	            ForEach(entries) { e in
+    49	                if e.isDir, let dir {
+    50	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
+    51	                } else {
+    52	                    Button { Task { await open(e) } } label: { row(e) }
+    53	                        .disabled(opening != nil)
+    54	                }
+    55	            }
+    56	        }
+    57	        .overlay { if dir == nil && error == nil { ProgressView() } }
+    58	        .navigationTitle(title)
+    59	        .navigationBarTitleDisplayMode(.inline)
+    60	        .task { await load() }
+    61	        .refreshable { await load() }
+    62	        .quickLookPreview($preview)
+    63	    }
+    64	
+    65	    private func row(_ e: Entry) -> some View {
+    66	        HStack(spacing: 12) {
+    67	            Image(systemName: e.isDir ? "folder" : "doc")
+    68	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
+    69	                .frame(width: 22)
+    70	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
+    71	            Spacer(minLength: 8)
+    72	            if opening == e.name {
+    73	                ProgressView()
+    74	            } else if !e.isDir {
+    75	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
+    76	            }
+    77	        }
+    78	        .accessibilityElement(children: .combine)
+    79	        .accessibilityLabel(e.name)
+    80	    }
+    81	
+    82	    private func load() async {
+    83	        do {
+    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+    86	                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+    87	                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
+    88	                return
+    89	            }
+    90	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
+    91	                guard let n = a[0].string else { return nil }
+    92	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
+    93	            })
+    94	            dir = d
+    95	            error = nil
+    96	        } catch {
+    97	            self.error = error.localizedDescription
+    98	        }
+    99	    }
+   100	
+   101	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
+   102	    static func sorted(_ entries: [Entry]) -> [Entry] {
+   103	        entries.sorted { a, b in
+   104	            if a.isDir != b.isDir { return a.isDir }
+   105	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
+   106	            if ad != bd { return bd }
+   107	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
+   108	        }
+   109	    }
+   110	
+   111	    private func open(_ e: Entry) async {
+   112	        guard let dir else { return }
+   113	        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
+   114	        guard e.size <= Self.maxBytes else {
+   115	            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
+   116	            return
+   117	        }
+   118	        opening = e.name
+   119	        defer { opening = nil }
+   120	        do {
+   121	            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
+   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
+   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
+   124	                return
+   125	            }
+   126	            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
+   127	            try? FileManager.default.removeItem(at: folder)
+   128	            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+   129	            let url = folder.appendingPathComponent(e.name)
+   130	            try r.stdout.write(to: url, options: .completeFileProtection)
+   131	            error = nil
+   132	            preview = url
+   133	        } catch {
+   134	            self.error = error.localizedDescription
+   135	        }
+   136	    }
+   137	}
+   138	
+   139	/// The Files sheet for one space: its own stack so folders push inside the sheet.
+   140	struct FilesSheet: View {
+   141	    @Environment(\.dismiss) private var dismiss
+   142	    var folder: String
+   143	    var title: String
+   144	
+   145	    var body: some View {
+   146	        NavigationStack {
+   147	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
+   148	                .navigationDestination(for: String.self) { p in
+   149	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
+   150	                }
+   151	                .toolbar {
+   152	                    ToolbarItem(placement: .cancellationAction) {
+   153	                        Button("Close", systemImage: "xmark") { dismiss() }
+   154	                    }
+   155	                }
+   156	        }
+   157	    }
+   158	}
+     1	import SwiftUI
+     2	import HerdrKit
+     3	
+     4	/// One space: a glass chip bar of tabs, then the selected tab's panes.
+     5	/// Phone: one pane at a time, paged. iPad: a grid of pane cards.
+     6	struct SpaceView: View {
+     7	    @Environment(AppStore.self) private var store
+     8	    @Environment(Navigator.self) private var nav
+     9	    @Environment(\.horizontalSizeClass) private var hsc
+    10	    var spaceID: String
+    11	    @State private var paneIndex = 0
+    12	    @State private var showFiles = false
+    13	
+    14	    private var space: SpaceRef? { store.spaces.first { $0.id == spaceID } }
+    15	
+    16	    var body: some View {
+    17	        Group {
+    18	            if let space {
+    19	                content(space)
+    20	            } else {
+    21	                ContentUnavailableView("Space closed", systemImage: "square.dashed",
+    22	                                       description: Text("This space is no longer in the layout."))
+    23	            }
+    24	        }
+    25	        .background(HC.canvas)
+    26	        .navigationBarTitleDisplayMode(.inline)
+    27	    }
+    28	
+    29	    private func selectedTab(_ space: SpaceRef) -> TabRef? {
+    30	        let id = store.selectedTabBySpace[space.id]
+    31	        return space.tabs.first { $0.id == id } ?? space.tabs.first
+    32	    }
+    33	
+    34	    @ViewBuilder private func content(_ space: SpaceRef) -> some View {
+    35	        let name = store.spaceName(space)
+    36	        let tab = selectedTab(space)
+    37	        VStack(spacing: 0) {
+    38	            TabChipBar(space: space, selected: tab?.id) { id in
+    39	                withAnimation(.smooth(duration: 0.25)) {
+    40	                    store.selectedTabBySpace[space.id] = id
+    41	                    paneIndex = 0
+    42	                }
+    43	            }
+    44	            if let tab {
+    45	                if tab.panes.isEmpty {
+    46	                    ContentUnavailableView("Empty tab", systemImage: "rectangle.dashed")
+    47	                } else if hsc == .regular {
+    48	                    ScrollView {
+    49	                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 380), spacing: 14)], spacing: 14) {
+    50	                            ForEach(tab.panes) { pane in
+    51	                                PaneCard(pane: pane, spaceName: name).frame(height: 360)
+    52	                            }
+    53	                        }
+    54	                        .padding(16)
+    55	                    }
+    56	                } else {
+    57	                    TabView(selection: $paneIndex) {
+    58	                        ForEach(Array(tab.panes.enumerated()), id: \.element.id) { i, pane in
+    59	                            PaneCard(pane: pane, spaceName: name)
+    60	                                .padding(.horizontal, 16)
+    61	                                .padding(.top, 12)
+    62	                                .padding(.bottom, tab.panes.count > 1 ? 44 : 16)
+    63	                                .tag(i)
+    64	                        }
+    65	                    }
+    66	                    .tabViewStyle(.page(indexDisplayMode: tab.panes.count > 1 ? .always : .never))
+    67	                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
+    68	                    .id(tab.id)
+    69	                }
+    70	            } else {
+    71	                ContentUnavailableView("No tabs", systemImage: "rectangle.stack")
+    72	            }
+    73	        }
+    74	        .toolbar {
+    75	            ToolbarItem(placement: .principal) {
+    76	                HStack(spacing: 8) {
+    77	                    SpaceBadge(name: name.isEmpty ? "~" : name, colorKey: SpaceBadge.colorKey(for: space.id), size: 20)
+    78	                    Text(name.isEmpty ? "~" : name).font(HF.ui(16, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
+    79	                }
+    80	            }
+    81	            ToolbarItem(placement: .topBarTrailing) {
+    82	                Button { showFiles = true } label: { Image(systemName: "folder") }
+    83	                    .accessibilityLabel("Files")
+    84	            }
+    85	            ToolbarItem(placement: .topBarTrailing) {
+    86	                Button { nav.newAgentSpace = space.id; nav.showNewAgent = true } label: { Image(systemName: "plus") }
+    87	                    .accessibilityLabel("New agent in this space")
+    88	            }
+    89	        }
+    90	        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
+    91	        .onAppear { store.selectedSpaceID = space.id }
+    92	    }
+    93	}
+    94	
+    95	/// Horizontally scrolling glass chips, one per tab, tinted by status.
+    96	struct TabChipBar: View {
+    97	    @Environment(AppStore.self) private var store
+    98	    var space: SpaceRef
+    99	    var selected: String?
+   100	    var onSelect: (String) -> Void
+   101	
+   102	    var body: some View {
+   103	        ScrollViewReader { proxy in
+   104	            ScrollView(.horizontal) {
+   105	                GlassEffectContainer(spacing: 6) {
+   106	                    HStack(spacing: 6) {
+   107	                        ForEach(Array(space.tabs.enumerated()), id: \.element.id) { i, tab in
+   108	                            chip(tab, index: i).id(tab.id)
+   109	                        }
+   110	                    }
+   111	                    .padding(.horizontal, 16)
+   112	                    .padding(.vertical, 8)
+   113	                }
+   114	            }
+   115	            .scrollIndicators(.hidden)
+   116	            .onAppear { if let selected { proxy.scrollTo(selected, anchor: .center) } }
+   117	            .onChange(of: selected) { _, s in withAnimation { proxy.scrollTo(s, anchor: .center) } }
+   118	        }
+   119	    }
+   120	
+   121	    private func chip(_ tab: TabRef, index: Int) -> some View {
+   122	        let att = store.attention(ofTab: tab.id)
+   123	        let isSel = tab.id == selected
+   124	        let firstTerminal = tab.panes.lazy.compactMap(\.terminal).first
+   125	        return Button { onSelect(tab.id) } label: {
+   126	            HStack(spacing: 7) {
+   127	                ProgramIcon(program: firstTerminal.flatMap { store.programKey(of: $0) }, size: 14)
+   128	                Text(store.tabName(tab, index: index))
+   129	                    .font(HF.ui(14, isSel ? .semibold : .medium))
+   130	                    .foregroundStyle(isSel ? HC.fg : HC.muted)
+   131	                    .lineLimit(1)
+   132	                    .frame(maxWidth: 170)
+   133	                StatusMark(attention: att, compact: true)
+   134	            }
+   135	            .padding(.horizontal, 12)
+   136	            .frame(height: 34)
+   137	        }
+   138	        .buttonStyle(.plain)
+   139	        .contentShape(.rect(cornerRadius: HM.chipRadius))
+   140	        .glassEffect(glass(att, selected: isSel), in: .rect(cornerRadius: HM.chipRadius))
+   141	    }
+   142	
+   143	    private func glass(_ a: Attention, selected: Bool) -> Glass {
+   144	        let base: Glass = .regular.interactive()
+   145	        switch a {
+   146	        case .blocked: return base.tint(HC.blocked.opacity(selected ? 0.35 : 0.2))
+   147	        case .working: return base.tint(HC.working.opacity(selected ? 0.28 : 0.14))
+   148	        case .done: return base.tint(HC.done.opacity(selected ? 0.3 : 0.16))
+   149	        default: return selected ? base.tint(HC.selected) : base
+   150	        }
+   151	    }
+   152	}
+   153	
+   154	/// One pane as a crisp card: header + a text preview of the screen. Tap opens the terminal.
+   155	struct PaneCard: View {
+   156	    @Environment(AppStore.self) private var store
+   157	    @Environment(Navigator.self) private var nav
+   158	    var pane: PaneRef
+   159	    var spaceName: String
+   160	
+   161	    var body: some View {
+   162	        VStack(spacing: 0) {
+   163	            if let addr = pane.terminal {
+   164	                Button { nav.open(.terminal(addr)) } label: {
+   165	                    VStack(spacing: 0) {
+   166	                        header(addr)
+   167	                        Rectangle().fill(HC.border).frame(height: HM.hairline)
+   168	                        TerminalPreview(address: addr)
+   169	                    }
+   170	                    .contentShape(.rect)
+   171	                }
+   172	                .buttonStyle(.plain)
+   173	            } else if let mod = pane.mod {
+   174	                HStack {
+   175	                    Image(systemName: "puzzlepiece.extension").foregroundStyle(HC.muted)
+   176	                    Text(mod).font(HF.ui(13.5, .medium)).foregroundStyle(HC.fg)
+   177	                    Spacer()
+   178	                }
+   179	                .padding(.horizontal, 12).frame(height: 38)
+   180	                Rectangle().fill(HC.border).frame(height: HM.hairline)
+   181	                ModPanelView(mod: mod, props: pane.modProps.object?.mapValues(\.any))
+   182	                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
+   183	            } else {
+   184	                Spacer()
+   185	            }
+   186	        }
+   187	        .clipShape(.rect(cornerRadius: HM.cardRadius))
+   188	        .herdrCard()
+   189	    }
+   190	
+   191	    private func header(_ addr: String) -> some View {
+   192	        let rec = store.terminals[addr]
+   193	        return HStack(spacing: 8) {
+   194	            ProgramIcon(program: store.programKey(of: addr), size: 16)
+   195	            Text(store.displayName(of: addr)).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(1)
+   196	            Text(store.tildePath(rec?.cwd ?? "")).font(HF.ui(12.5)).foregroundStyle(HC.dim).lineLimit(1)
+   197	            Spacer(minLength: 4)
+   198	            StatusMark(attention: store.attention(of: addr))
+   199	            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(HC.dim)
+   200	        }
+   201	        .padding(.horizontal, 12)
+   202	        .frame(height: 40)
+   203	    }
+   204	}
+   205	
+   206	/// Plain-text tail of a terminal (terminal.read), refreshed when its turn/status changes.
+   207	struct TerminalPreview: View {
+   208	    @Environment(AppStore.self) private var store
+   209	    var address: String
+   210	    @State private var text: String = ""
+   211	    @State private var loaded = false
+   212	
+   213	    var body: some View {
+   214	        let rec = store.terminals[address]
+   215	        let key = "\(address)|\(rec?.turn ?? 0)|\(rec?.statusWord ?? "")|\(rec?.title ?? "")"
+   216	        ZStack(alignment: .bottomLeading) {
+   217	            HC.background
+   218	            if text.isEmpty {
+   219	                VStack(spacing: 8) {
+   220	                    Image(systemName: "terminal").font(.system(size: 22, weight: .light)).foregroundStyle(HC.dim)
+   221	                    Text(loaded ? "Tap to open" : "Loading…").font(HF.ui(13)).foregroundStyle(HC.dim)
+   222	                }
+   223	                .frame(maxWidth: .infinity, maxHeight: .infinity)
+   224	            } else {
+   225	                // A cropped screen: one Text per line, never soft-wrapped. In an overlay
+   226	                // so lines wider than the card pin to the left edge instead of centring.
+   227	                Color.clear
+   228	                    .overlay(alignment: .bottomLeading) {
+   229	                        VStack(alignment: .leading, spacing: 1) {
+   230	                            ForEach(Array(text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { _, line in
+   231	                                Text(line.isEmpty ? " " : String(line)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
+   232	                            }
+   233	                        }
+   234	                        .font(HF.mono(10.5))
+   235	                        .foregroundStyle(Color(uiColor: .herdr("terminal_foreground")))
+   236	                        .padding(10)
+   237	                    }
+   238	                    .clipped()
+   239	            }
+   240	        }
+   241	        .task(id: key) {
+   242	            let t = (try? await store.read(address, lines: 60)) ?? ""
+   243	            text = Self.trim(t)
+   244	            loaded = true
+   245	        }
+   246	    }
+   247	
+   248	    /// Drop trailing blank lines so the preview hugs the bottom.
+   249	    private static func trim(_ s: String) -> String {
+   250	        var lines = s.split(separator: "\n", omittingEmptySubsequences: false).map { $0.replacingOccurrences(of: "\r", with: "") }
+   251	        while let l = lines.last, l.trimmingCharacters(in: .whitespaces).isEmpty { lines.removeLast() }
+   252	        return lines.suffix(60).joined(separator: "\n")
+   253	    }
+   254	}
+# Herdr for iOS (unofficial)
+
+A native iPhone and iPad client for [herdr](https://herdr.dev). See which of your coding agents need you, read and answer them, and open their live terminals. It connects over plain SSH to the `herdr-core` already running on your machine.
+
+<p>
+<img src="docs/demo.gif" width="300" alt="Demo: agents by attention, an agent's Chat, a space, starting an agent, and a 'needs you' notification" />
+<img src="docs/screenshots/notification.png" width="300" alt="A time-sensitive notification: OAuth needs you, with the agent's question and options" />
+</p>
+<p><a href="docs/demo.mp4">Full demo video (MP4, 53 s)</a> · demo data, recorded in the iOS simulator</p>
+
+<p>
+<img src="docs/screenshots/home-dark.png" width="240" alt="Home: agents grouped by Needs you, Working and Idle, then spaces" />
+<img src="docs/screenshots/chat-dark.png" width="240" alt="Chat: an agent's conversation as native messages, with folded work and a table" />
+<img src="docs/screenshots/new-dark.png" width="240" alt="New agent: pick a program, a space and an optional first task" />
+</p>
+<p>
+<img src="docs/screenshots/home-light.png" width="240" alt="Home in light mode" />
+<img src="docs/screenshots/chat-light.png" width="240" alt="Chat in light mode" />
+</p>
+
+## What it does
+
+- **Agents, sorted by who needs you.** Every agent on the machine is grouped as Needs you, Working, Done or Idle, using herdr's own status words and "done while you weren't looking" rule. Sub-agents nest under their parent.
+- **Spaces and tabs.** The same spaces, tabs and panes as the desktop app, read live from the core's `herdr-app` layout document. Changes you make on one screen show up on the other.
+- **Chat** (Claude Code). An agent's conversation as native messages instead of a terminal:
+  - prompts appear as bubbles, replies as formatted text with tables;
+  - finished turns fold behind "Worked for 5m 18s · 12 steps";
+  - each tool call is one tappable line;
+  - a blocked agent's dialog becomes buttons.
+- **Terminal.** The real terminal (SwiftTerm), mirroring the desktop size by default with pinch-to-zoom. A "Fit to phone" toggle resizes it to the phone instead. A glass key bar adds esc, ctrl, arrows and ^C, and a compose box sends whole prompts.
+- **New agents.** Start Claude Code, Codex, a shell or any program from herdr's list, in an existing space or a new folder, with an optional first task.
+- **Notifications.** Get "OAuth needs you" (with the agent's question and options) or "Refactor finished", even when the app is closed; tap to open that agent. Your machine sends them straight to Apple, with no relay in between.
+- **Mods.** Your own herdr mods run on the phone. A small JavaScriptCore host implements the `herdr`, `gpui-kit` and `gpui-base` APIs they use and draws their element trees in SwiftUI. Their `exec` calls run on the box.
+- **herdr's look.** It uses the Graphite and Paper themes, Geist and JetBrains Mono, and herdr's status marks, with iOS 26 Liquid Glass on the chrome only.
+
+## How it connects
+
+The app opens an SSH exec channel to your machine and runs `herdr-core connect`. That's the same framed JSON-RPC stream the desktop app uses for remote machines (`ssh box hc connect`). Nothing else needs to be installed on the machine, and no server or relay is involved.
+
+- **Login:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
+- **Host key:** the box's host key is pinned on first connect.
+- **Network:** the box has to be reachable from the phone, for example over Tailscale.
+- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap.
+- **Opening Chat** never attaches to the terminal, so it doesn't resize anything on your desktop.
+
+## Notifications
+
+iOS closes the app's SSH connection in the background, so the phone can't see an agent start waiting. Your machine sends the notification instead:
+- **The notifier:** `herdr-notify` is a short Python script running as a systemd user service. It follows `hc events` and, when an agent becomes blocked or finishes a turn, pushes to Apple over HTTP/2 with your APNs key.
+- **Your phone's address:** the app hands its push token to the machine over the open connection, in `~/.config/herdr-ios/devices/`.
+
+Setup needs a paid Apple Developer account:
+1. Create an APNs key at developer.apple.com → Certificates, IDs & Profiles → Keys, with Apple Push Notifications service enabled.
+2. Install the notifier, either from the app (Settings → Notifications → Set up on <machine>, then choose the `.p8`) or from your Mac:
+   ```sh
+   scripts/install-notifier.sh <ssh host> AuthKey_XXXXXXXXXX.p8 <team id> <bundle id>
+   ```
+3. Open Herdr while connected and allow notifications. Settings → Notifications → Send a test.
+
+The key stays on your machine in `~/.config/herdr-ios`, readable only by you. Sub-agents and plain shells don't notify, and you can tune what does in `~/.config/herdr-ios/notify.json` (`{"on": ["blocked", "done"]}`).
+
+## Build and run
+
+Requirements:
+- **Mac:** macOS with Xcode 26.2+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).
+- **Phone:** iOS 26.
+- **Optional:** [bun](https://bun.sh), to bundle your mods.
+- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat.
+
+```sh
+git clone https://github.com/zzulanas/herdr-ios && cd herdr-ios
+cp Config/Local.example.xcconfig Config/Local.xcconfig   # your team id and bundle id
+xcodegen generate
+open Herdr.xcodeproj                                     # run the Herdr scheme
+```
+
+Command-line builds need `-skipPackagePluginValidation` (SwiftTerm ships a build plugin).
+
+### Your mods
+
+List the mods to bundle in `Config/mods.txt`, one per line. Each line has the folder name in `~/.config/herdr-app/mods`, plus the block id it uses in the desktop layout if that differs from the name:
+
+```
+linear
+prs
+my-drawer drawer
+```
+
+The pre-build step bundles them with bun into `App/Resources/Mods`. That folder is gitignored, so each person ships their own mods. Machine-specific tweaks to a mod's `exec` go in `Config/host-local.js`, also gitignored:
+
+```js
+herdrIOS.onExec((cmd, args, on) => ({ cmd, args }))
+```
+
+## Layout
+
+```
+Packages/HerdrKit     protocol and model (SwiftPM, platform-independent, unit-tested)
+  HerdrClient         framing, JSON-RPC, terminal streams with credit, events
+  Layout / Names      the herdr-app layout doc: parse and edit, keeping unknown fields
+  herdr-probe         macOS CLI that speaks the protocol over `ssh <host>`
+App/Sources
+  Net                 Citadel SSH transport, Keychain key store, host-key pinning
+  Store               AppStore: connection, live terminals and layout, attention, actions
+  UI                  SwiftUI screens, theme, terminal (SwiftTerm)
+  Chat                transcript reader and Chat view
+  Mods                JavaScriptCore mod host and SwiftUI renderer
+scripts/              mod bundling and a headless mod test
+```
+
+Tests:
+- **Protocol and model:** `cd Packages/HerdrKit && swift test`.
+- **UI:** run the `HerdrUITests` target against a real box in watch-only mode. Set `HERDR_DEBUG_KEY_PATH` and `HERDR_TEST_TERMINAL`.
+- **Demo data:** `HERDR_DEMO=1` launches with fake data, which is how these screenshots were made.
+
+## Status
+
+This is early. It's tested against herdr-core 0.1.14 on a real Linux machine. Known gaps:
+- Chat covers Claude Code only.
+- Replying straight from a notification (Yes/No) isn't built yet; tapping opens the agent.
+- Machines added inside herdr-core (`hc machine add`) aren't browsable yet.
+
+## Credits
+
+- [herdr](https://herdr.dev) and [herdr-app](https://github.com/herdrdev/herdr-app) by [ogulcancelik](https://github.com/ogulcancelik); this app's icon, themes and program icons come from herdr-app.
+- The Chat view was inspired by [Heeler](https://github.com/ZingerLittleBee/Heeler).
+- See [NOTICE](NOTICE) for third-party licenses.
+
+Not affiliated with or endorsed by the herdr project.
+
+## License
+
+[Apache-2.0](LICENSE)
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse
+exec
+/bin/zsh -lc 'git show HEAD -- && cat AGENTS.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+commit 6c7e200ae6bb6ec4d3cc94e86232ac2a3afa69ff
+Author: i2 <95607264+YosukeIida@users.noreply.github.com>
+Date:   Sun Nov 1 03:52:21 2026 +0900
+
+    Browse a space's folder and preview its files in Quick Look
+    
+    The phone had no way to read what agents produce on the box: PDFs, Office
+    documents, images. Files lists the space folder with the box's python3 (as
+    Chat already does) and fetches a file with cat over machine.exec into a
+    temporary file for Quick Look, which renders PDF, docx, xlsx and images on
+    the device. Files over 12 MiB are refused for now: one exec reply must fit
+    in a 16 MiB frame as base64.
+
+diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
+new file mode 100644
+index 0000000..ab485c0
+--- /dev/null
++++ b/App/Sources/UI/FilesView.swift
+@@ -0,0 +1,158 @@
++import SwiftUI
++import QuickLook
++import HerdrKit
++
++/// A space's folder on the box: browse it and open files in Quick Look
++/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
++struct FilesView: View {
++    @Environment(AppStore.self) private var store
++    var path: String
++    var title: String
++
++    struct Entry: Identifiable, Hashable {
++        var name: String
++        var isDir: Bool
++        var size: Int
++        var id: String { name }
++    }
++
++    @State private var dir: String?
++    @State private var entries: [Entry] = []
++    @State private var error: String?
++    @State private var opening: String?
++    @State private var preview: URL?
++
++    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
++    static let maxBytes = 12 << 20
++
++    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
++    static let listScript = """
++    import json, os, sys
++    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
++    out = []
++    with os.scandir(d) as it:
++        for e in it:
++            try:
++                isdir = e.is_dir()
++                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
++            except OSError:
++                pass
++    print(json.dumps({"dir": d, "entries": out}))
++    """
++
++    var body: some View {
++        List {
++            if let error {
++                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
++            }
++            ForEach(entries) { e in
++                if e.isDir, let dir {
++                    NavigationLink(value: dir + "/" + e.name) { row(e) }
++                } else {
++                    Button { Task { await open(e) } } label: { row(e) }
++                        .disabled(opening != nil)
++                }
++            }
++        }
++        .overlay { if dir == nil && error == nil { ProgressView() } }
++        .navigationTitle(title)
++        .navigationBarTitleDisplayMode(.inline)
++        .task { await load() }
++        .refreshable { await load() }
++        .quickLookPreview($preview)
++    }
++
++    private func row(_ e: Entry) -> some View {
++        HStack(spacing: 12) {
++            Image(systemName: e.isDir ? "folder" : "doc")
++                .foregroundStyle(e.isDir ? HC.working : HC.muted)
++                .frame(width: 22)
++            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
++            Spacer(minLength: 8)
++            if opening == e.name {
++                ProgressView()
++            } else if !e.isDir {
++                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
++            }
++        }
++        .accessibilityElement(children: .combine)
++        .accessibilityLabel(e.name)
++    }
++
++    private func load() async {
++        do {
++            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
++            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
++                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
++                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
++                return
++            }
++            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
++                guard let n = a[0].string else { return nil }
++                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
++            })
++            dir = d
++            error = nil
++        } catch {
++            self.error = error.localizedDescription
++        }
++    }
++
++    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
++    static func sorted(_ entries: [Entry]) -> [Entry] {
++        entries.sorted { a, b in
++            if a.isDir != b.isDir { return a.isDir }
++            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
++            if ad != bd { return bd }
++            return a.name.localizedStandardCompare(b.name) == .orderedAscending
++        }
++    }
++
++    private func open(_ e: Entry) async {
++        guard let dir else { return }
++        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
++        guard e.size <= Self.maxBytes else {
++            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
++            return
++        }
++        opening = e.name
++        defer { opening = nil }
++        do {
++            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
++            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
++                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
++                return
++            }
++            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
++            try? FileManager.default.removeItem(at: folder)
++            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
++            let url = folder.appendingPathComponent(e.name)
++            try r.stdout.write(to: url, options: .completeFileProtection)
++            error = nil
++            preview = url
++        } catch {
++            self.error = error.localizedDescription
++        }
++    }
++}
++
++/// The Files sheet for one space: its own stack so folders push inside the sheet.
++struct FilesSheet: View {
++    @Environment(\.dismiss) private var dismiss
++    var folder: String
++    var title: String
++
++    var body: some View {
++        NavigationStack {
++            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
++                .navigationDestination(for: String.self) { p in
++                    FilesView(path: p, title: (p as NSString).lastPathComponent)
++                }
++                .toolbar {
++                    ToolbarItem(placement: .cancellationAction) {
++                        Button("Close", systemImage: "xmark") { dismiss() }
++                    }
++                }
++        }
++    }
++}
+diff --git a/App/Sources/UI/SpaceView.swift b/App/Sources/UI/SpaceView.swift
+index c37e929..b47a42b 100644
+--- a/App/Sources/UI/SpaceView.swift
++++ b/App/Sources/UI/SpaceView.swift
+@@ -9,6 +9,7 @@ struct SpaceView: View {
+     @Environment(\.horizontalSizeClass) private var hsc
+     var spaceID: String
+     @State private var paneIndex = 0
++    @State private var showFiles = false
+ 
+     private var space: SpaceRef? { store.spaces.first { $0.id == spaceID } }
+ 
+@@ -77,11 +78,16 @@ struct SpaceView: View {
+                     Text(name.isEmpty ? "~" : name).font(HF.ui(16, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
+                 }
+             }
++            ToolbarItem(placement: .topBarTrailing) {
++                Button { showFiles = true } label: { Image(systemName: "folder") }
++                    .accessibilityLabel("Files")
++            }
+             ToolbarItem(placement: .topBarTrailing) {
+                 Button { nav.newAgentSpace = space.id; nav.showNewAgent = true } label: { Image(systemName: "plus") }
+                     .accessibilityLabel("New agent in this space")
+             }
+         }
++        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
+         .onAppear { store.selectedSpaceID = space.id }
+     }
+ }
+diff --git a/UITests/HerdrUITests.swift b/UITests/HerdrUITests.swift
+index 5f9cfea..4b4feed 100644
+--- a/UITests/HerdrUITests.swift
++++ b/UITests/HerdrUITests.swift
+@@ -61,6 +61,35 @@ final class HerdrUITests: XCTestCase {
+         shot(app, "home-after-approval")
+     }
+ 
++    /// Files: from a space ($HERDR_TEST_SPACE) walk $HERDR_TEST_FILES_PATH (slash-separated folders
++    /// under the space folder) and open each of $HERDR_TEST_FILES (comma-separated) in Quick Look.
++    /// Needs a pinned host key (run testFirstConnectAsksForHostKey first).
++    func testFilesPreviewInQuickLook() throws {
++        let env = ProcessInfo.processInfo.environment
++        let app = launch(["HERDR_DEBUG_OPEN": try XCTUnwrap(env["HERDR_TEST_SPACE"])])
++        let files = app.buttons["Files"]
++        XCTAssertTrue(files.waitForExistence(timeout: 30), "no Files button in the space")
++        files.tap()
++        for folder in (env["HERDR_TEST_FILES_PATH"] ?? "").split(separator: "/") {
++            let row = app.buttons[String(folder)]
++            XCTAssertTrue(row.waitForExistence(timeout: 20), "no folder \(folder)")
++            row.tap()
++        }
++        for name in try XCTUnwrap(env["HERDR_TEST_FILES"]).split(separator: ",").map(String.init) {
++            let row = app.buttons[name]
++            XCTAssertTrue(row.waitForExistence(timeout: 20), "no file \(name)")
++            row.tap()
++            let done = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'QLOverlayDoneButton'")).firstMatch
++            // Images open full screen with the controls hidden; a tap brings them back.
++            if !done.waitForExistence(timeout: 15) { app.tap() }
++            XCTAssertTrue(done.waitForExistence(timeout: 15), "Quick Look did not open \(name)")
++            sleep(2)
++            shot(app, "preview-\(name)")
++            done.tap()
++            XCTAssertTrue(row.waitForExistence(timeout: 10), "did not return to the list after \(name)")
++        }
++    }
++
+     /// Chat reads a Claude agent's transcript ($HERDR_TEST_TERMINAL); folds open on tap. Never sends anything.
+     func testChatRendersAndFolds() throws {
+         let app = launch(["HERDR_DEBUG_OPEN": ProcessInfo.processInfo.environment["HERDR_TEST_TERMINAL"] ?? "t1"])
+# herdr-pocket
+
+A native iPhone and iPad client for herdr-core: read and answer Claude Code and Codex sessions as chat, preview the box's files, and see every agent's state, while the desktop uses the Herdr app on the same herdr-core. The app talks to herdr-core only over SSH (an exec channel running `herdr-core connect`), with no resident server or third-party relay. It is a fork of `zzulanas/herdr-ios` (`upstream`); `origin` is `YosukeIida/herdr-pocket`. Why this base was chosen and what it lacks are in `docs/2026-11-01_existing-apps-and-orca-mobile-survey.md` and `docs/2026-11-01_herdr-ios-code-review.md`.
+
+## Layout
+
+- `Packages/HerdrKit`: protocol and model (SwiftPM, no external dependencies, unit tests). Run `swift test` there.
+- `App/Sources`: the iOS app (SwiftUI). Net (Citadel SSH, Keychain), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore), Notify.
+- `project.yml`: XcodeGen spec. `Herdr.xcodeproj` is generated (`xcodegen generate`) and not tracked.
+- Requires iOS 26 or later. Develop against the iOS simulator on the Mac; the simulator reaches the Mac's own sshd at `127.0.0.1`.
+
+## Language
+
+Write repository files (README, AGENTS.md, everything under `docs/`, code comments, commit messages) in English unless a file says otherwise. The English file is the source of truth. Markdown documents also get a Japanese translation next to them as `<name>.ja.md` (`AGENTS.ja.md`, `docs/<name>.ja.md`), updated in the same change as the English file. Working notes overwritten every session (`docs/HANDOVER.md`, `docs/reviews/PENDING.md`) and raw reviewer output (`docs/reviews/*-codex.md`) get no translation. Files inherited from upstream (README.md) get a translation when we first change them.
+
+## How work is done (the sandwich)
+
+1. Design and implementation: Claude Opus 5.5 (`claude-opus-5-5`).
+2. Review: Codex `gpt-6.1-sol`, effort medium, on the labteam account (`CODEX_HOME=$HOME/.codex-labteam`, or `cx labteam` before starting Codex). Review only, read-only sandbox, no edits. Raw output goes to `docs/reviews/<date>-<unit>-codex.md`.
+3. Judgement: Claude Opus 5.5. For each finding, decide fix or no fix and why (`docs/reviews/<date>-<unit>-judgement.md`), and send the fixes back to step 1.
+
+When labteam credits run out, do not switch accounts and do not skip the review: list the unit in `docs/reviews/PENDING.md` and continue with work that does not depend on it.
+
+## Environment
+
+The devshell (`.envrc` → `nix/flake.nix`) provides XcodeGen and bun; Swift and the iOS SDK come from Xcode. Agents get it from dotfiles' agent-switch shims, which load direnv when `claude` or `codex` starts in the repo. Command-line builds need `-skipPackagePluginValidation` (SwiftTerm ships a build plugin). `scripts/bundle-mods.sh` runs as an unsandboxed pre-build step; read any change to it before building.
+
+## Prior art
+
+- Upstream `zzulanas/herdr-ios` (Apache-2.0). Keep `NOTICE` and the license; changes we want upstream go as PRs from a branch, not from `main`.
+- Heeler (`ZingerLittleBee/Heeler`, Apache-2.0): SSH, terminal and chat views; PR #538 has herdr-core support.
+- HerdrChat (Apache-2.0): Claude and Codex transcript parsing.
+- Ovis, Collie (MIT): herdr-core adapters; Collie's `docs/multiplexers.md` lists herdr-core's limits.
+- Orca Mobile (`stablyai/orca`) and opencode: references for chat behaviour. Check each license before reusing code, and note the source in any file that reuses it.
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "nl -ba Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift | sed -n '1,260p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+     1	import Foundation
+     2	
+     3	/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
+     4	/// JSON-RPC on channel 0, terminal and event streams on core-allocated channels.
+     5	///
+     6	/// Thread model: transport bytes are parsed on whatever thread the transport
+     7	/// calls back on (serially), under one lock. Writes go through a single serial
+     8	/// writer task. Stream and event callbacks are delivered on `callbackQueue`.
+     9	public final class HerdrClient: @unchecked Sendable {
+    10	    public let transport: ByteTransport
+    11	    /// Where stream/event/disconnect callbacks run. Set before `connect()`.
+    12	    public var callbackQueue: DispatchQueue = .main
+    13	    /// No bytes on any channel for this long = the connection is dead.
+    14	    public var livenessTimeout: TimeInterval = 45
+    15	    /// Called once on `callbackQueue` when the connection drops unexpectedly
+    16	    /// (not after `close()`).
+    17	    public var onDisconnect: ((HerdrError) -> Void)? {
+    18	        get { lock.withLock { _onDisconnect } }
+    19	        set { lock.withLock { _onDisconnect = newValue } }
+    20	    }
+    21	    private var _onDisconnect: ((HerdrError) -> Void)?
+    22	
+    23	    public private(set) var hello: HelloInfo?
+    24	    /// Remote stderr so far (capped), for failure screens.
+    25	    public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }
+    26	
+    27	    /// Methods the app calls; a core lacking one can't serve it.
+    28	    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
+    29	                                         "terminal.attach", "terminal.keep", "terminal.read", "terminal.send", "terminal.keys",
+    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+    31	                                         "machine.list", "server.status"]
+    32	    public static let minCoreVersion = "0.1.11"
+    33	    public static let generation: UInt64 = 1
+    34	
+    35	    private enum Route { case terminal(TerminalStream), events(EventSubscription) }
+    36	    private enum Mode { case idle, plain, framed, closed }
+    37	
+    38	    private let lock = NSLock()
+    39	    private var mode = Mode.idle
+    40	    private var plain = Data()
+    41	    private var helloCont: CheckedContinuation<JSONValue, Error>?
+    42	    private var decoder = FrameDecoder()
+    43	    private var nextID: UInt64 = 0
+    44	    private var pending: [UInt64: CheckedContinuation<JSONValue, Error>] = [:]
+    45	    private var cancelled: Set<UInt64> = []
+    46	    private var routes: [UInt32: Route] = [:]
+    47	    private var early: [UInt32: [Frame]] = [:]
+    48	    /// Channels we closed: drop their frames, swallow the CLOSE echo.
+    49	    private var closing: Set<UInt32> = []
+    50	    private var lastReceive = Date()
+    51	    private var stderrBuf = Data()
+    52	    private var closedByUs = false
+    53	
+    54	    private let outbox: AsyncStream<Data>.Continuation
+    55	    private let outStream: AsyncStream<Data>
+    56	    private var writerTask: Task<Void, Never>?
+    57	    private var livenessTask: Task<Void, Never>?
+    58	
+    59	    public init(transport: ByteTransport) {
+    60	        self.transport = transport
+    61	        (outStream, outbox) = AsyncStream<Data>.makeStream(bufferingPolicy: .unbounded)
+    62	    }
+    63	
+    64	    deinit {
+    65	        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
+    66	    }
+    67	
+    68	    public var isConnected: Bool { lock.withLock { mode == .framed } }
+    69	
+    70	    // MARK: Connect
+    71	
+    72	    /// Starts the transport, says hello in plain mode, then switches to frames.
+    73	    public func connect(helloTimeout: TimeInterval = 20) async throws -> HelloInfo {
+    74	        let started: Bool = lock.withLock {
+    75	            guard mode == .idle else { return false }
+    76	            mode = .plain; lastReceive = Date(); return true
+    77	        }
+    78	        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }
+    79	
+    80	        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
+    81	            for await chunk in outStream {
+    82	                do { try await transport.write(chunk) } catch {
+    83	                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
+    84	                    return
+    85	                }
+    86	            }
+    87	        }
+    88	
+    89	        try await transport.start(
+    90	            onBytes: { [weak self] in self?.receive($0) },
+    91	            onStderr: { [weak self] d in self?.lock.withLock {
+    92	                guard let self, self.stderrBuf.count < 16_384 else { return }
+    93	                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
+    94	            } },
+    95	            onClose: { [weak self] err in self?.transportClosed(err) })
+    96	
+    97	        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
+    98	            let alreadyClosed: Bool = lock.withLock {
+    99	                if mode == .closed { return true }
+   100	                helloCont = cont; return false
+   101	            }
+   102	            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
+   103	            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
+   104	            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
+   105	                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
+   106	                    defer { self.helloCont = nil }; return self.helloCont
+   107	                }) else { return }
+   108	                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
+   109	                                              hint: self.stderrText.trimmed.nilIfEmpty))
+   110	                self.close()
+   111	            }
+   112	        }
+   113	        do {
+   114	            let info = try Self.check(hello: reply)
+   115	            lock.withLock { hello = info }
+   116	            startLiveness()
+   117	            return info
+   118	        } catch {
+   119	            close()
+   120	            throw error
+   121	        }
+   122	    }
+   123	
+   124	    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
+   125	    public static func check(hello reply: JSONValue) throws -> HelloInfo {
+   126	        if !reply["error"].isNull { throw rpcError(reply["error"]) }
+   127	        let r = reply["result"]
+   128	        let gen = r["generation"].uint64 ?? 0
+   129	        let version = r["version"].string ?? "0"
+   130	        if gen > generation {
+   131	            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
+   132	        }
+   133	        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
+   134	            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
+   135	        }
+   136	        let methods = r["methods"].array?.compactMap(\.string) ?? []
+   137	        let missing = requiredMethods.filter { !methods.contains($0) }
+   138	        if !missing.isEmpty {
+   139	            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
+   140	        }
+   141	        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
+   142	                         version: version, methods: methods)
+   143	    }
+   144	
+   145	    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }
+   146	
+   147	    static func semver(_ v: String) -> [Int] {
+   148	        var s = v.trimmingCharacters(in: .whitespaces)
+   149	        if s.hasPrefix("hc ") { s.removeFirst(3) }
+   150	        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
+   151	        return (0..<3).map { $0 < parts.count ? parts[$0] : 0 }
+   152	    }
+   153	
+   154	    /// Closes the connection. Pending calls fail with `lost`; streams get `onLost`.
+   155	    public func close() {
+   156	        lock.withLock { closedByUs = true }
+   157	        transport.close()
+   158	        fail(HerdrError(code: -1, kind: "closed", message: "Disconnected"))
+   159	    }
+   160	
+   161	    // MARK: Calls
+   162	
+   163	    /// One JSON-RPC call on channel 0. Errors are `HerdrError` (message, hint,
+   164	    /// kind). Cancelling the task sends `$/cancelRequest`.
+   165	    @discardableResult
+   166	    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
+   167	        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
+   168	        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
+   169	                              "params": params.isNull ? [:] : params]
+   170	        return try await withTaskCancellationHandler {
+   171	            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
+   172	                enum Outcome { case go, cancelled, closed }
+   173	                let outcome: Outcome = lock.withLock {
+   174	                    if cancelled.remove(id) != nil { return .cancelled }
+   175	                    if mode != .framed { return .closed }
+   176	                    pending[id] = cont; return .go
+   177	                }
+   178	                switch outcome {
+   179	                case .cancelled: cont.resume(throwing: CancellationError()); return
+   180	                case .closed: cont.resume(throwing: HerdrError.lost); return
+   181	                case .go: break
+   182	                }
+   183	                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
+   184	                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
+   185	                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
+   186	                }
+   187	            }
+   188	        } onCancel: {
+   189	            let wasPending = lock.withLock { () -> Bool in
+   190	                if pending[id] != nil { return true }
+   191	                cancelled.insert(id); return false
+   192	            }
+   193	            if wasPending {
+   194	                finish(id, .failure(CancellationError()))
+   195	                notify("$/cancelRequest", ["id": .number(Double(id))])
+   196	            }
+   197	        }
+   198	    }
+   199	
+   200	    /// A notification (no id, no reply).
+   201	    public func notify(_ method: String, _ params: JSONValue = [:]) {
+   202	        let msg: JSONValue = ["jsonrpc": "2.0", "method": .string(method), "params": params]
+   203	        send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
+   204	    }
+   205	
+   206	    private func finish(_ id: UInt64, _ result: Result<JSONValue, Error>) {
+   207	        guard let cont = lock.withLock({ pending.removeValue(forKey: id) }) else { return }
+   208	        cont.resume(with: result)
+   209	    }
+   210	
+   211	    static func rpcError(_ e: JSONValue) -> HerdrError {
+   212	        HerdrError(code: e["code"].int ?? -32000, kind: e["data"]["kind"].string,
+   213	                   message: e["message"].string ?? "core call failed", hint: e["data"]["hint"].string)
+   214	    }
+   215	
+   216	    // MARK: Typed helpers
+   217	
+   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
+   219	    /// exit or timeout is a result, not an error.
+   220	    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
+   221	        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
+   222	        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
+   223	        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
+   224	        if let input { p["input"] = .string(input.base64EncodedString()) }
+   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+   226	        return ExecResult(code: r["code"].int,
+   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+   228	                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
+   229	                          timedOut: r["timed_out"].bool ?? false)
+   230	    }
+   231	
+   232	    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
+   233	        let r = try await call("doc.get", ["name": .string(name)])
+   234	        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
+   235	    }
+   236	
+   237	    /// CAS write; throws kind "conflict" when `version` is stale. Returns the new version.
+   238	    public func docSet(_ name: String = "herdr-app", value: JSONValue, version: UInt64) async throws -> UInt64 {
+   239	        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
+   240	        return r["version"].uint64 ?? version + 1
+   241	    }
+   242	
+   243	    public func listTerminals(all: Bool = false) async throws -> [TerminalRecord] {
+   244	        let r = try await call("terminal.list", ["all": .bool(all)])
+   245	        return (r["terminals"].array ?? []).map(TerminalRecord.init(raw:))
+   246	    }
+   247	
+   248	    public func read(terminal: String, lines: Int = 200) async throws -> String {
+   249	        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
+   250	    }
+   251	
+   252	    // MARK: Streams
+   253	
+   254	    /// `terminal.attach`: opens a stream channel. Data that arrives before the
+   255	    /// reply (or before handlers are set) is kept and delivered in order.
+   256	    public func attach(terminal: String, cols: Int, rows: Int, history: Int = 2000,
+   257	                       display: JSONValue? = nil, observe: Bool = false) async throws -> TerminalStream {
+   258	        var p: JSONValue = ["terminal": .string(terminal), "cols": .number(Double(max(cols, 1))),
+   259	                            "rows": .number(Double(max(rows, 1))), "history": .number(Double(history)), "observe": .bool(observe)]
+   260	        if let display { p["display"] = display }
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "rg -n 'func exec|frame|16 <<|maxPayload|cancel|timeout|stdout' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/Frame* && sed -n '66,90p' docs/2026-11-01_herdr-ios-code-review.md && nl -ba App/Sources/UI/FilesView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:3:/// Frame kinds on the framed wire (SPEC.md §1, core `wire.rs`).
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:13:/// One frame: `channel u32 LE | kind u8 | len u32 LE | payload`.
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:17:    public static let maxPayload = 16 << 20
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:45:    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:48:/// Incremental frame parser: feed it bytes as they arrive, take whole frames
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:56:    /// Bytes waiting for the rest of their frame.
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:68:    /// The next whole frame, nil if more bytes are needed. Throws on an
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:78:        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
+Packages/HerdrKit/Sources/HerdrKit/Frame.swift:86:    /// Every whole frame currently buffered.
+App/Sources/Store/AppStore.swift:117:            backgroundTask?.cancel(); backgroundTask = nil
+App/Sources/Store/AppStore.swift:127:                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
+App/Sources/Store/AppStore.swift:401:            _ = try? await c.call("terminal.kill", ["terminal": .string(terminal)], timeout: 15)
+App/Sources/Store/AppStore.swift:419:        _ = try await connectedClient().call("terminal.send", ["terminal": .string(address), "text": .string(text)], timeout: 15)
+App/Sources/Store/AppStore.swift:425:        _ = try await connectedClient().call("terminal.interrupt", ["terminal": .string(address), "timeout": 10], timeout: 20)
+App/Sources/Store/AppStore.swift:428:        _ = try await connectedClient().call("terminal.kill", ["terminal": .string(address)], timeout: 20)
+App/Sources/Store/AppStore.swift:432:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
+App/Sources/Store/AppStore.swift:433:        try await connectedClient().exec(argv: argv, cwd: cwd, on: on, timeout: timeout, input: input)
+App/Sources/Store/AppStore.swift:470:        reconnectTask?.cancel(); reconnectTask = nil
+App/Sources/Store/AppStore.swift:471:        connectTask?.cancel()
+App/Sources/Store/AppStore.swift:475:        // Synchronously, so no frame shows the idle/failure screen before the task runs.
+App/Sources/Store/AppStore.swift:541:        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
+App/Sources/Store/AppStore.swift:564:        reconnectTask?.cancel()
+App/Sources/Store/AppStore.swift:577:        connectTask?.cancel(); connectTask = nil
+App/Sources/Store/AppStore.swift:578:        reconnectTask?.cancel(); reconnectTask = nil
+App/Sources/Store/AppStore.swift:599:              let r = try? await c.exec(argv: ["sh", "-c", "printf %s \"$HOME\""], timeout: 10),
+App/Sources/Store/AppStore.swift:601:        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+App/Sources/Store/AppStore.swift:622:                    guard gen == self.generation else { s.cancel(); return }
+App/Sources/Store/AppStore.swift:768:        ], timeout: 20)
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:3:/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:36:    private enum Mode { case idle, plain, framed, closed }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:45:    private var cancelled: Set<UInt64> = []
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:48:    /// Channels we closed: drop their frames, swallow the CLOSE echo.
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:65:        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:68:    public var isConnected: Bool { lock.withLock { mode == .framed } }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:72:    /// Starts the transport, says hello in plain mode, then switches to frames.
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:103:            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:108:                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:164:    /// kind). Cancelling the task sends `$/cancelRequest`.
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:166:    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:172:                enum Outcome { case go, cancelled, closed }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:174:                    if cancelled.remove(id) != nil { return .cancelled }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:175:                    if mode != .framed { return .closed }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:179:                case .cancelled: cont.resume(throwing: CancellationError()); return
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:184:                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:185:                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:191:                cancelled.insert(id); return false
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:195:                notify("$/cancelRequest", ["id": .number(Double(id))])
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:219:    /// exit or timeout is a result, not an error.
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:221:        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:227:                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:269:            guard mode == .framed else { return nil }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:271:            let frames = early.removeValue(forKey: ch) ?? []
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:272:            // Flush inside the lock so later frames queue behind these.
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:273:            for f in frames { route(f, to: .terminal(stream), queue: queue) }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:274:            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:275:            return frames
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:290:            guard mode == .framed else { return false }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:292:            let frames = early.removeValue(forKey: ch) ?? []
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:293:            for f in frames { route(f, to: .events(sub), queue: callbackQueue) }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:294:            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:335:                mode = .framed
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:346:            case .framed:
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:365:                // A reply nobody waits for (cancelled or timed out). If it opened a
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:452:        livenessTask?.cancel()
+Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:528:    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }
+     1	import SwiftUI
+     2	import QuickLook
+     3	import HerdrKit
+     4	
+     5	/// A space's folder on the box: browse it and open files in Quick Look
+     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+     7	struct FilesView: View {
+     8	    @Environment(AppStore.self) private var store
+     9	    var path: String
+    10	    var title: String
+    11	
+    12	    struct Entry: Identifiable, Hashable {
+    13	        var name: String
+    14	        var isDir: Bool
+    15	        var size: Int
+    16	        var id: String { name }
+    17	    }
+    18	
+    19	    @State private var dir: String?
+    20	    @State private var entries: [Entry] = []
+    21	    @State private var error: String?
+    22	    @State private var opening: String?
+    23	    @State private var preview: URL?
+    24	
+    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
+    26	    static let maxBytes = 12 << 20
+    27	
+    28	    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
+    29	    static let listScript = """
+    30	    import json, os, sys
+    31	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
+    32	    out = []
+    33	    with os.scandir(d) as it:
+    34	        for e in it:
+    35	            try:
+    36	                isdir = e.is_dir()
+    37	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
+    38	            except OSError:
+    39	                pass
+    40	    print(json.dumps({"dir": d, "entries": out}))
+    41	    """
+    42	
+    43	    var body: some View {
+    44	        List {
+    45	            if let error {
+    46	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
+    47	            }
+    48	            ForEach(entries) { e in
+    49	                if e.isDir, let dir {
+    50	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
+    51	                } else {
+    52	                    Button { Task { await open(e) } } label: { row(e) }
+    53	                        .disabled(opening != nil)
+    54	                }
+    55	            }
+    56	        }
+    57	        .overlay { if dir == nil && error == nil { ProgressView() } }
+    58	        .navigationTitle(title)
+    59	        .navigationBarTitleDisplayMode(.inline)
+    60	        .task { await load() }
+    61	        .refreshable { await load() }
+    62	        .quickLookPreview($preview)
+    63	    }
+    64	
+    65	    private func row(_ e: Entry) -> some View {
+    66	        HStack(spacing: 12) {
+    67	            Image(systemName: e.isDir ? "folder" : "doc")
+    68	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
+    69	                .frame(width: 22)
+    70	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
+    71	            Spacer(minLength: 8)
+    72	            if opening == e.name {
+    73	                ProgressView()
+    74	            } else if !e.isDir {
+    75	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
+    76	            }
+    77	        }
+    78	        .accessibilityElement(children: .combine)
+    79	        .accessibilityLabel(e.name)
+    80	    }
+    81	
+    82	    private func load() async {
+    83	        do {
+    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+    86	                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+    87	                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
+    88	                return
+    89	            }
+    90	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
+    91	                guard let n = a[0].string else { return nil }
+    92	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
+    93	            })
+    94	            dir = d
+    95	            error = nil
+    96	        } catch {
+    97	            self.error = error.localizedDescription
+    98	        }
+    99	    }
+   100	
+   101	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
+   102	    static func sorted(_ entries: [Entry]) -> [Entry] {
+   103	        entries.sorted { a, b in
+   104	            if a.isDir != b.isDir { return a.isDir }
+   105	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
+   106	            if ad != bd { return bd }
+   107	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
+   108	        }
+   109	    }
+   110	
+   111	    private func open(_ e: Entry) async {
+   112	        guard let dir else { return }
+   113	        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
+   114	        guard e.size <= Self.maxBytes else {
+   115	            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
+   116	            return
+   117	        }
+   118	        opening = e.name
+   119	        defer { opening = nil }
+   120	        do {
+   121	            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
+   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
+   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
+   124	                return
+   125	            }
+   126	            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
+   127	            try? FileManager.default.removeItem(at: folder)
+   128	            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+   129	            let url = folder.appendingPathComponent(e.name)
+   130	            try r.stdout.write(to: url, options: .completeFileProtection)
+   131	            error = nil
+   132	            preview = url
+   133	        } catch {
+   134	            self.error = error.localizedDescription
+   135	        }
+   136	    }
+   137	}
+   138	
+   139	/// The Files sheet for one space: its own stack so folders push inside the sheet.
+   140	struct FilesSheet: View {
+   141	    @Environment(\.dismiss) private var dismiss
+   142	    var folder: String
+   143	    var title: String
+   144	
+   145	    var body: some View {
+   146	        NavigationStack {
+   147	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
+   148	                .navigationDestination(for: String.self) { p in
+   149	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
+   150	                }
+   151	                .toolbar {
+   152	                    ToolbarItem(placement: .cancellationAction) {
+   153	                        Button("Close", systemImage: "xmark") { dismiss() }
+   154	                    }
+   155	                }
+   156	        }
+   157	    }
+   158	}
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '310,365p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift && sed -n '410,455p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift && cat Packages/HerdrKit/Sources/HerdrKit/Frame.swift && rg -n 'machine.exec|stdout|16 MiB|output.*limit|python3' docs SPEC.md Packages/HerdrKit/Tests -g '*.md' -g '*.swift'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ exited 2 in 0ms:
+            return
+        }
+        send(Frame(channel: ch, kind: kind, payload: payload))
+    }
+
+    private func send(_ f: Frame) {
+        outbox.yield(f.encoded())
+    }
+
+    // MARK: Reading
+
+    private func receive(_ bytes: Data) {
+        var actions: [() -> Void] = []
+        var protocolError: HerdrError?
+        lock.withLock {
+            lastReceive = Date()
+            switch mode {
+            case .idle, .closed:
+                return
+            case .plain:
+                plain.append(bytes)
+                guard let nl = plain.firstIndex(of: 0x0a) else { return }
+                let line = plain[plain.startIndex..<nl]
+                let rest = plain[plain.index(after: nl)...]
+                let reply = (try? JSONValue.parse(Data(line))) ?? .null
+                mode = .framed
+                decoder.append(Data(rest))
+                plain = Data()
+                if let c = helloCont {
+                    helloCont = nil
+                    if reply.isNull {
+                        actions.append { c.resume(throwing: HerdrError(kind: "parse_error", message: "The core's hello reply wasn't JSON")) }
+                    } else {
+                        actions.append { c.resume(returning: reply) }
+                    }
+                }
+            case .framed:
+                decoder.append(bytes)
+            }
+            do {
+                while let f = try decoder.next() { handle(f, &actions) }
+            } catch {
+                protocolError = HerdrError(code: -32700, kind: "lost", message: "Lost the core", hint: "\(error)")
+            }
+        }
+        for a in actions { a() }
+        if let protocolError { fail(protocolError); transport.close() }
+    }
+
+    /// Called with the lock held.
+    private func handle(_ f: Frame, _ actions: inout [() -> Void]) {
+        if f.channel == 0 {
+            guard f.kind == FrameKind.data, let msg = try? JSONValue.parse(f.payload),
+                  let id = msg["id"].uint64 else { return }
+            guard let cont = pending.removeValue(forKey: id) else {
+                // A reply nobody waits for (cancelled or timed out). If it opened a
+            case FrameKind.data:
+                sub.push(f.payload)
+                send(Frame.credit(f.channel, f.payload.count))
+            case FrameKind.close:
+                sub.ended(lost: false)
+            default: break
+            }
+        }
+    }
+
+    // MARK: Loss
+
+    private func transportClosed(_ err: Error?) {
+        let (hint, byUs): (String?, Bool) = lock.withLock {
+            (String(decoding: stderrBuf, as: UTF8.self).trimmed.nilIfEmpty, closedByUs)
+        }
+        if byUs { return }
+        fail(closedError(err, stderr: hint))
+    }
+
+    private func closedError(_ err: Error?, stderr: String? = nil) -> HerdrError {
+        let stderr = stderr ?? stderrText.trimmed.nilIfEmpty
+        if let stderr, stderr.contains("not installed") {
+            return HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine", hint: stderr)
+        }
+        return HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: stderr ?? err.map { "\($0.localizedDescription)" })
+    }
+
+    /// Fails everything once: pending calls, hello, every stream.
+    private func fail(_ error: HerdrError) {
+        var conts: [CheckedContinuation<JSONValue, Error>] = []
+        var helloC: CheckedContinuation<JSONValue, Error>?
+        var lostRoutes: [Route] = []
+        let first: Bool = lock.withLock {
+            guard mode != .closed else { return false }
+            mode = .closed
+            conts = Array(pending.values); pending.removeAll()
+            helloC = helloCont; helloCont = nil
+            lostRoutes = Array(routes.values); routes.removeAll(); early.removeAll(); closing.removeAll()
+            return true
+        }
+        guard first else { return }
+        livenessTask?.cancel()
+        outbox.finish()
+        let lost = HerdrError(code: -1, kind: error.kind ?? "lost", message: error.message, hint: error.hint)
+        helloC?.resume(throwing: lost)
+import Foundation
+
+/// Frame kinds on the framed wire (SPEC.md §1, core `wire.rs`).
+public enum FrameKind {
+    public static let data: UInt8 = 0
+    public static let credit: UInt8 = 1
+    public static let close: UInt8 = 2
+    public static let resize: UInt8 = 3
+    public static let focus: UInt8 = 4
+    public static let facts: UInt8 = 5
+}
+
+/// One frame: `channel u32 LE | kind u8 | len u32 LE | payload`.
+public struct Frame: Equatable, Sendable {
+    public static let headerSize = 9
+    /// Largest payload the core accepts or sends (16 MiB).
+    public static let maxPayload = 16 << 20
+
+    public var channel: UInt32
+    public var kind: UInt8
+    public var payload: Data
+
+    public init(channel: UInt32, kind: UInt8, payload: Data = Data()) {
+        self.channel = channel; self.kind = kind; self.payload = payload
+    }
+
+    public func encoded() -> Data {
+        var d = Data(capacity: Self.headerSize + payload.count)
+        withUnsafeBytes(of: channel.littleEndian) { d.append(contentsOf: $0) }
+        d.append(kind)
+        withUnsafeBytes(of: UInt32(payload.count).littleEndian) { d.append(contentsOf: $0) }
+        d.append(payload)
+        return d
+    }
+
+    public static func credit(_ channel: UInt32, _ bytes: Int) -> Frame {
+        Frame(channel: channel, kind: FrameKind.credit, payload: le32(UInt32(clamping: bytes)))
+    }
+
+    static func le32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
+}
+
+public struct FrameError: Error, Equatable, CustomStringConvertible {
+    public var length: Int
+    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
+}
+
+/// Incremental frame parser: feed it bytes as they arrive, take whole frames
+/// out. Frame boundaries may fall anywhere in the input.
+public struct FrameDecoder: Sendable {
+    private var buffer: [UInt8] = []
+    private var head = 0
+
+    public init() {}
+
+    /// Bytes waiting for the rest of their frame.
+    public var buffered: Int { buffer.count - head }
+
+    public mutating func append(_ data: Data) {
+        if head > 0, head >= buffer.count {
+            buffer.removeAll(keepingCapacity: true); head = 0
+        } else if head > 65_536, head * 2 > buffer.count {
+            buffer.removeSubrange(0..<head); head = 0
+        }
+        buffer.append(contentsOf: data)
+    }
+
+    /// The next whole frame, nil if more bytes are needed. Throws on an
+    /// oversized length (a protocol error: drop the connection).
+    public mutating func next() throws -> Frame? {
+        guard buffer.count - head >= Frame.headerSize else { return nil }
+        let (channel, kind, len) = buffer.withUnsafeBytes { raw -> (UInt32, UInt8, Int) in
+            let ch = raw.loadUnaligned(fromByteOffset: head, as: UInt32.self)
+            let k = raw[head + 4]
+            let l = raw.loadUnaligned(fromByteOffset: head + 5, as: UInt32.self)
+            return (UInt32(littleEndian: ch), k, Int(UInt32(littleEndian: l)))
+        }
+        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
+        guard buffer.count - head >= Frame.headerSize + len else { return nil }
+        let start = head + Frame.headerSize
+        let payload = Data(buffer[start..<start + len])
+        head = start + len
+        return Frame(channel: channel, kind: kind, payload: payload)
+    }
+
+    /// Every whole frame currently buffered.
+    public mutating func drain() throws -> [Frame] {
+        var out: [Frame] = []
+        while let f = try next() { out.append(f) }
+        return out
+    }
+}
+rg: SPEC.md: No such file or directory (os error 2)
+Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:277:        XCTAssertEqual(Programs.identify(app: nil, argv: ["python3", "-m", "http.server"]).key, "python")
+docs/reviews/2026-11-01-fixes-codex.md:345:-                                         "terminal.keep", "doc.get", "doc.set", "events.subscribe", "machine.exec"]
+docs/reviews/2026-11-01-fixes-codex.md:348:+                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+docs/reviews/2026-11-01-fixes-codex.md:361:-    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec"]}}"# + "\n").utf8)
+docs/reviews/2026-11-01-fixes-codex.md:362:+    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
+docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
+docs/reviews/2026-11-01-fixes-codex.md:663:                if !apply(r.stdout) { return }
+docs/reviews/2026-11-01-fixes-codex.md:1045:                            case .stdout(let b): onBytes(Data(b.readableBytesView))
+docs/reviews/2026-11-01-fixes-codex.md:2191:Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+docs/reviews/2026-11-01-fixes-codex.md:3358:43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:145:        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" } }
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:146:        let id = try JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" }!.payload)["id"]
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:192:        t.reply(msg["id"].int!, ["code": 0, "stdout": .string(Data("hi\n".utf8).base64EncodedString()), "stderr": "", "timed_out": false])
+Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:194:        XCTAssertEqual(res, ExecResult(code: 0, stdout: Data("hi\n".utf8), stderr: Data(), timedOut: false))
+docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:19:| 接続 | stdin・stdout の改行区切りの JSON-RPC で話せる。`hello` は generation 1、version 0.1.15 を返す | `hc connect` |
+docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:26:| PDF・docx・xlsx | `file.read` は `not_text` で拒否し、「for bytes: hc exec cat」と案内する。`machine.exec {argv: ["cat", path]}` で base64 として取り出すと、PDF 3.4 MB が 18 ms、docx・xlsx が 5 ms 前後で、元のファイルと SHA-256 が一致した | `machine.exec` |
+docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:38:| `machine.exec`（PDF 3.4 MB を `cat`） | 445 ms | 3394636 bytes で元のファイルと一致し、`truncated` は false |
+docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:57:- 送ったバイナリの大きさの上限。`machine.exec` の出力は `truncated` を返す。どの大きさで打ち切られるかは確かめていない。
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:49:| Keep (first version) | File tree and preview (**add docx and xlsx**) | `machine.exec` (ls, and cat returned as base64). Display with QLPreviewController and WKWebView |
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:53:| Later | Quick Commands, Source Control, creating a new workspace, resuming past sessions, diagnostics screen, photo attachments, voice input | `machine.exec` (git, gh), `terminal.run` |
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:70:Both can run on the Mac Studio side through `machine.exec`.
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:113:- File tree and preview (retrieve with `machine.exec`, display with Quick Look)
+docs/reviews/2026-11-01-files-codex.md:14:Review the last commit in this repo (git show HEAD): a Files browser with Quick Look preview for an iOS client of herdr-core. Context: AGENTS.md, docs/2026-11-01_herdr-ios-code-review.md (section on where features plug in), Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift (exec, frame limit). Review only; do not edit files. For each finding give severity (high/medium/low), file:line, a concrete failure scenario and a suggested fix. Check: path handling and injection (argv to machine.exec, names with odd characters, symlinks, '~'), the 12 MiB limit vs the actual frame/base64/JSON overhead and what happens just above it, temp file handling and data protection, SwiftUI state races (open twice, dismiss during fetch, navigation), and anything that breaks on a box without python3. Say 'no findings' where there are none. Be concise.
+docs/reviews/2026-11-01-files-codex.md:45:    documents, images. Files lists the space folder with the box's python3 (as
+docs/reviews/2026-11-01-files-codex.md:46:    Chat already does) and fetches a file with cat over machine.exec into a
+docs/reviews/2026-11-01-files-codex.md:49:    in a 16 MiB frame as base64.
+docs/reviews/2026-11-01-files-codex.md:270:| Medium (by design) | `Mods/ModHub.swift:310, 325` | Passes the command a mod specifies straight to `machine.exec` on the Mac side. The trust boundary is the same as the Herdr app | Operate by bundling only mods you wrote yourself |
+docs/reviews/2026-11-01-files-codex.md:280:- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
+docs/reviews/2026-11-01-files-codex.md:324:    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+docs/reviews/2026-11-01-files-codex.md:512:   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
+docs/reviews/2026-11-01-files-codex.md:519:   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+docs/reviews/2026-11-01-files-codex.md:521:   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+docs/reviews/2026-11-01-files-codex.md:876:     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+docs/reviews/2026-11-01-files-codex.md:895:    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
+docs/reviews/2026-11-01-files-codex.md:954:    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+docs/reviews/2026-11-01-files-codex.md:955:    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+docs/reviews/2026-11-01-files-codex.md:992:   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
+docs/reviews/2026-11-01-files-codex.md:993:   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
+docs/reviews/2026-11-01-files-codex.md:1000:   130	            try r.stdout.write(to: url, options: .completeFileProtection)
+docs/reviews/2026-11-01-files-codex.md:1325:- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap.
+docs/reviews/2026-11-01-files-codex.md:1350:- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat.
+docs/reviews/2026-11-01-files-codex.md:1431:    documents, images. Files lists the space folder with the box's python3 (as
+docs/reviews/2026-11-01-files-codex.md:1432:    Chat already does) and fetches a file with cat over machine.exec into a
+docs/reviews/2026-11-01-files-codex.md:1435:    in a 16 MiB frame as base64.
+docs/reviews/2026-11-01-files-codex.md:1448:+/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+docs/reviews/2026-11-01-files-codex.md:1467:+    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
+docs/reviews/2026-11-01-files-codex.md:1526:+            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+docs/reviews/2026-11-01-files-codex.md:1527:+            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+docs/reviews/2026-11-01-files-codex.md:1564:+            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
+docs/reviews/2026-11-01-files-codex.md:1565:+                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
+docs/reviews/2026-11-01-files-codex.md:1572:+            try r.stdout.write(to: url, options: .completeFileProtection)
+docs/reviews/2026-11-01-files-codex.md:1747:    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
+docs/reviews/2026-11-01-files-codex.md:1935:   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
+docs/reviews/2026-11-01-files-codex.md:1942:   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+docs/reviews/2026-11-01-files-codex.md:1944:   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+docs/reviews/2026-11-01-files-codex.md:1986:/bin/zsh -lc "rg -n 'func exec|frame|16 <<|maxPayload|cancel|timeout|stdout' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/Frame* && sed -n '66,90p' docs/2026-11-01_herdr-ios-code-review.md && nl -ba App/Sources/UI/FilesView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+docs/reviews/2026-11-01-files-codex.md:1991:Packages/HerdrKit/Sources/HerdrKit/Frame.swift:45:    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
+docs/reviews/2026-11-01-files-codex.md:2013:App/Sources/Store/AppStore.swift:601:        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+docs/reviews/2026-11-01-files-codex.md:2038:Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
+docs/reviews/2026-11-01-files-codex.md:2039:Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:227:                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
+docs/reviews/2026-11-01-files-codex.md:2060:     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+docs/reviews/2026-11-01-files-codex.md:2079:    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
+docs/reviews/2026-11-01-files-codex.md:2138:    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+docs/reviews/2026-11-01-files-codex.md:2139:    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+docs/reviews/2026-11-01-files-codex.md:2176:   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
+docs/reviews/2026-11-01-files-codex.md:2177:   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
+docs/reviews/2026-11-01-files-codex.md:2184:   130	            try r.stdout.write(to: url, options: .completeFileProtection)
+docs/2026-11-01_herdr-core-mobile-client-spike.md:17:| Connection | Speaks newline-delimited JSON-RPC over stdin and stdout. `hello` returns generation 1, version 0.1.15 | `hc connect` |
+docs/2026-11-01_herdr-core-mobile-client-spike.md:24:| PDF, docx, xlsx | `file.read` rejects them with `not_text` and suggests "for bytes: hc exec cat". Retrieved as base64 with `machine.exec {argv: ["cat", path]}`: a 3.4 MB PDF took 18 ms, docx and xlsx about 5 ms each, and the SHA-256 matched the original files | `machine.exec` |
+docs/2026-11-01_herdr-core-mobile-client-spike.md:36:| `machine.exec` (`cat` of a 3.4 MB PDF) | 445 ms | 3394636 bytes, matched the original file, `truncated` is false |
+docs/2026-11-01_herdr-core-mobile-client-spike.md:55:- The size limit for transferred binaries. The output of `machine.exec` returns `truncated`. The size at which it truncates was not checked.
+docs/2026-11-01_herdr-ios-code-review.md:39:| Medium (by design) | `Mods/ModHub.swift:310, 325` | Passes the command a mod specifies straight to `machine.exec` on the Mac side. The trust boundary is the same as the Herdr app | Operate by bundling only mods you wrote yourself |
+docs/2026-11-01_herdr-ios-code-review.md:49:- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
+docs/2026-11-01_herdr-ios-code-review.ja.md:41:| 中（仕様） | `Mods/ModHub.swift:310, 325` | mod が指定したコマンドを、そのまま Mac 側で `machine.exec` に渡す。信頼の範囲は Herdr app と同じである | 自分で書いた mod だけを同梱する運用にする |
+docs/2026-11-01_herdr-ios-code-review.ja.md:51:- **ファイルツリーとプレビュー**: 入口は `SpaceView.swift:73` の toolbar に置き、基準のフォルダは `SpaceRef.folder` にする。一覧は `store.exec`（`AppStore.swift:417`）で取る。本体は `cat --` で base64 として受け取り、一時ファイルに書いて `QLPreviewController` に渡す。1 回の受け取りの上限は約 12 MiB で（frame の上限 16 MiB から base64 の増加分を引いた値）、これを超えるファイルは分割して読む。
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:51:| 残す（最初の版） | ファイルツリーとプレビュー（**docx・xlsx を足す**） | `machine.exec`（ls・cat を base64 で返す）。表示は QLPreviewController と WKWebView |
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:55:| 後で | Quick Commands、Source Control、新しい workspace の作成、過去のセッションの再開、診断の画面、写真の添付、音声入力 | `machine.exec`（git・gh）、`terminal.run` |
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:72:どちらも `machine.exec` で Mac Studio 側で実行できる。
+docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:115:- ファイルツリーとプレビュー（`machine.exec` で取り出し、Quick Look で表示する）
+
+hook: PostToolUse
+hook: PostToolUse
+exec
+/bin/zsh -lc "sed -n '55,75p' docs/2026-11-01_herdr-ios-code-review.md && sed -n '1,55p' App/Sources/Store/AppStore.swift && sed -n '525,575p' App/Sources/Store/AppStore.swift && rg --files -g AGENTS.md -g '*SPEC*' -g '*exec*' -g '*wire*' && cat /Users/yosuke/workspace/github.com/YosukeIida/knowledge/orca-remote-file-open-and-reveal-limits.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+- The README says "mod exec runs on the Mac side", but `open` and pbcopy are handled on the smartphone side.
+- The README describes the notifier only as being for systemd, but the code has an alternative path that starts it with nohup.
+
+## What to read before building
+
+Building runs the following 2 items without a sandbox. Their contents must be read before building.
+
+- The pre-build `bundle-mods.sh` (`ENABLE_USER_SCRIPT_SANDBOXING: NO`)
+- SwiftTerm's build plugin
+import SwiftUI
+import UIKit
+import HerdrKit
+
+// CONTRACT FILE (owned by the core/store builder). UI and Mods are written
+// against these signatures in parallel: implement the bodies, add API freely,
+// but do not rename or remove anything here.
+
+/// Where to connect. Persisted in UserDefaults (the key lives in the Keychain).
+struct MachineConfig: Codable, Hashable, Identifiable {
+    var id: UUID = UUID()
+    var label: String = ""
+    var host: String = ""
+    var port: Int = 22
+    var user: String = ""
+    /// Optional password; nil = use the app's Ed25519 key.
+    var usePassword: Bool = false
+}
+
+enum ConnectionPhase: Equatable {
+    case idle
+    case connecting(String)            // human step: "Opening SSH", "Saying hello"...
+    case connected
+    case failed(String)                // message shown to the user, with retry
+}
+
+/// One agent row in the agents list.
+struct AgentRow: Identifiable, Hashable {
+    var id: String { address }
+    var address: String
+    var label: String                  // SPEC §5 Names: agent row label
+    var program: String?               // "claude", "codex", "shell", ...
+    var attention: Attention
+    var spaceID: String?
+    var tabID: String?
+    var parent: String?                // sub-agents are nested under parent
+    var since: Date?
+}
+
+@MainActor
+@Observable
+final class AppStore {
+    // MARK: Connection
+    var machines: [MachineConfig] = [] { didSet { persistMachines() } }
+    var activeMachineID: UUID? { didSet { persistMachines() } }
+    var phase: ConnectionPhase = .idle
+    var hello: HelloInfo?
+    /// Last stderr from the remote, for the failure screen.
+    var diagnostics: String = ""
+
+    // MARK: Live state
+    var terminals: [String: TerminalRecord] = [:]
+    var doc: LayoutDoc = LayoutDoc(value: .null, version: 0)
+    var spaces: [SpaceRef] = []
+    /// Remote $HOME, learned at connect (for names).
+        } catch {
+            guard gen == generation else { return }
+            diagnostics = c.stderrText
+            fail(error, gen: gen, retry: Self.isRetryable(error))
+        }
+    }
+
+    private static func isRetryable(_ error: Error) -> Bool {
+        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return false }
+        if let e = error as? HerdrError, ["auth", "needs_update", "not_installed"].contains(e.kind ?? "") { return false }
+        return true
+    }
+
+    private func fail(_ error: Error, gen: Int, retry: Bool) {
+        guard gen == generation else { return }
+        teardownClient()
+        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
+        hostKeyMismatch = error is HostKeys.Mismatch
+        unknownHostKey = error as? HostKeys.Unknown
+        connectStep = -1
+        phase = .failed((error as? LocalizedError)?.errorDescription ?? "\(error)")
+        // Only keep trying on our own when there's a session to get back to.
+        if retry, wantConnected, hello != nil { scheduleReconnect() }
+    }
+
+    private func connectionLost(_ error: HerdrError, gen: Int) {
+        // Only a live session is "lost": while connecting, runConnect's catch owns the error
+        // (otherwise a non-retryable failure would be replaced by an endless "Reconnecting").
+        guard gen == generation, phase == .connected else { return }
+        teardownClient()
+        alertsArmed = false
+        guard wantConnected else { phase = .idle; return }
+        connectStep = 0
+        phase = .connecting("Reconnecting")
+        if sceneActive { scheduleReconnect(immediate: attempt == 0) }
+    }
+
+    private func scheduleReconnect(immediate: Bool = false) {
+        guard wantConnected, sceneActive, let m = currentMachine() else { return }
+        reconnectTask?.cancel()
+        let delay = immediate ? 0.3 : min(15, pow(2, Double(min(attempt, 4))))   // 1, 2, 4, 8, 15 s
+        attempt += 1
+        reconnectTask = Task { [weak self] in
+            try? await Task.sleep(for: .seconds(delay))
+            guard !Task.isCancelled, let self, self.wantConnected, self.sceneActive else { return }
+            self.startConnect(m, reconnecting: true)
+        }
+    }
+
+    /// Closes the connection quietly (no reconnect from its callbacks).
+    private func dropConnection(phase newPhase: ConnectionPhase) {
+AGENTS.md
+---
+type: Concept
+title: 'Orca で remote のファイルを開く・Finder に表示するときの制限（512 KiB の打ち切り、50MB の上限、Reveal は Local only）'
+description: 'Orca の remote ランタイム上のファイルは、通常は分割読みで 50MB まで開ける。ワークスペース外の host ファイルと復元タブの経路だけ 512 KiB で打ち切られる。Reveal in Finder は remote では無効で、T3 Code も同様に未対応'
+aliases: 'Remote file is too large to open in the editor, 524289 bytes, Reveal in Finder, Local only, PAGED_REMOTE_FILE_MAX_BYTES, terminal artifact, T3 Code, t3code, 復元タブ'
+sources:
+  - resource: https://github.com/stablyai/orca/issues/28907
+    title: Orca "Reveal in Finder" in the terminal right-click menu（SSH / remote-runtime では Local only で無効にする提案）
+  - resource: https://github.com/stablyai/orca/pull/29426
+    title: Orca fix(remote-files) open large HTML, PDFs and images on a paired runtime
+  - resource: https://github.com/stablyai/orca/pull/27165
+    title: Orca fix(shell) OS open actions follow the file's owner, not the focused server
+  - resource: https://github.com/stablyai/orca/blob/main/src/renderer/src/runtime/runtime-terminal-artifact-read.ts
+    title: Orca runtime-terminal-artifact-read.ts（truncated で分割読みせずに失敗させる経路）
+  - resource: https://github.com/stablyai/orca/blob/main/src/renderer/src/runtime/runtime-file-read-client.ts
+    title: Orca runtime-file-read-client.ts（通常経路の分割読み）
+  - resource: https://github.com/pingdotgg/t3code/issues/18473
+    title: T3 Code 同じ Mac の saved environment で Reveal in file manager が出ない（closed、未対応の回答）
+  - resource: https://github.com/pingdotgg/t3code/issues/23604
+    title: T3 Code remote スレッドのファイルリンクがサーバ上で開かれる（open）
+  - resource: transcript:666134d4-cb8f-4360-8c26-f57bb2d25f95#L71-L123
+    title: remote の Reveal in Finder と T3 Code との比較の調査
+  - resource: transcript:666134d4-cb8f-4360-8c26-f57bb2d25f95#L197-L363
+    title: 「Remote file is too large to open in the editor (524289 bytes)」の原因をソースから読む
+generated: { by: claude-code/claude-sonnet-5-5, at: 2026-10-27T18:15:42+09:00 }
+status: draft
+---
+
+別の機械の Orca ランタイム（`orca serve` や、別の Mac の GUI の Orca）に接続して、そのファイルを手元の Orca で開くときの挙動。
+
+## Finder 表示は remote では使えない
+
+- ファイルエクスプローラ・エディタのタブ・Source Control の「Reveal in Finder」は、SSH／remote-runtime のファイルでは設計上 disabled（「Local only」の表示）。「Open With」サブメニューも remote のファイルでは出ない（Orca #13993）。
+- remote を選択中に、ローカルのファイルまで Reveal できなくなる不具合があり、#25932 と #27165（OS の open 操作を、フォーカス中のサーバではなくファイルの所有者で判定する）が対応している。merge の有無は確かめていない。
+- remote のファイルを手元に落として Reveal する機能の要望は、検索では見つからなかった。手元で扱うには、右クリックの「Download」で落とす。
+- 比較: T3 Code（pingdotgg/t3code）も remote では「Open in」にファイルマネージャが出ない。#18473 は「Local 環境だけを local とみなす仕様」として closed、#23604（remote スレッドのファイルリンクが、手元ではなくサーバ上で開かれる）は open。Emdash・Zed・VS Code Remote-SSH も、remote のファイルを手元の Finder に出す機能は、公式ドキュメントでは確認できなかった。
+
+## ファイルを開くときのサイズの扱い
+
+ソース（stablyai/orca の main、手元は 1.4.239）を読んだ結果で、実機では確かめていない。
+
+- 通常の remote ファイルは、512 KiB を超えると 384 KiB ずつの分割読みに入り、50MB（`PAGED_REMOTE_FILE_MAX_BYTES = 50 * 1024 * 1024`、設定では変えられない）まで開ける。分割読みは #29426（2026-10-16）で入った。
+- 「Remote file is too large to open in the editor (524289 bytes)」は、ファイルの大きさではない。`524289` は、512 KiB で打ち切った内容の長さ（512 KiB + 1 バイト）を指す。ファイル自体が 1.2MB でも、この数字が出た。
+- このエラー文は `runtime-terminal-artifact-read.ts` の経路にしかない。ワークスペース外の host ファイル、または再起動で復元したタブの絶対パスを開くときに使われ、`truncated` になった時点で分割読みをせずに失敗させる。
+- 古い remote host（`files.stat`／`files.readChunk` を持たない版）では、別の文面「Remote file is larger than the 512 KB this Orca server can send. Update the server to open it.」で 512 KB が上限になる。サーバ側の版を上げる必要があるのは、こちらの場合である。
+- クライアントを最新にしても、前者の経路には分割読みが無いので直らない。回避は、タブを閉じてファイルツリーから開き直す（通常経路に入る可能性がある）、それでも駄目なら Download で手元に落とす。
+- この経路の未対応を扱う issue は、検索では見つからなかった。
+
+前提: Orca 1.4.239（最新は 1.4.242、2026-10-27 時点）、T3 Code の issue は 2026-10 時点。経路の判定はソースの読み取りに基づく推測で、どちらの経路を通ったかは実機で確かめていない。
+
+関連:
+- [Orca の画面なしの実行環境（orca serve）を別の機械に置くと、ペアリングは loopback のトンネルで通す](./orca-serve-remote-runtime-pairing.md) - remote ランタイムへ接続する手順を読むときにたどる。
+- [macOS の「Finder で表示」を新しいウィンドウでなくタブで開かせる](./macos-finder-reveal-opens-in-tab.md) - ローカルでの Reveal の挙動を読むときにたどる。
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+codex
+The 12 MiB limit leaves no room for the JSON envelope, and the read checks size only after fetching the whole file. I also found that a fetch can continue after dismissal and delete a newer preview’s shared temp directory. I’m checking the remaining path and dependency cases.
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "sed -n '1,155p' Packages/HerdrKit/Sources/HerdrKit/JSONValue.swift && sed -n '135,165p' Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift && command -v ruby && command -v swift && git diff --stat" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 0ms:
+import Foundation
+
+/// Untyped JSON, as the core speaks it. Keeps unknown fields so documents
+/// written back to the core lose nothing.
+public enum JSONValue: Equatable, Hashable, Sendable {
+    case null
+    case bool(Bool)
+    case number(Double)
+    case string(String)
+    case array([JSONValue])
+    case object([String: JSONValue])
+
+    public subscript(key: String) -> JSONValue {
+        get {
+            if case .object(let o) = self { return o[key] ?? .null }
+            return .null
+        }
+        set {
+            var o = object ?? [:]
+            o[key] = newValue
+            self = .object(o)
+        }
+    }
+    public subscript(index: Int) -> JSONValue {
+        if case .array(let a) = self, a.indices.contains(index) { return a[index] }
+        return .null
+    }
+    public var string: String? { if case .string(let s) = self { return s }; return nil }
+    public var double: Double? { if case .number(let n) = self { return n }; return nil }
+    public var int: Int? { double.flatMap { $0.isFinite ? Int(exactly: $0.rounded(.towardZero)) : nil } }
+    public var uint64: UInt64? { double.flatMap { $0.isFinite ? UInt64(exactly: max(0, $0).rounded(.towardZero)) : nil } }
+    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
+    public var array: [JSONValue]? { if case .array(let a) = self { return a }; return nil }
+    public var object: [String: JSONValue]? { if case .object(let o) = self { return o }; return nil }
+    public var isNull: Bool { self == .null }
+
+    /// Removes `key` from an object (no-op otherwise).
+    public mutating func removeValue(forKey key: String) {
+        guard case .object(var o) = self else { return }
+        o.removeValue(forKey: key)
+        self = .object(o)
+    }
+
+    /// Compact JSON text, for logs and debugging.
+    public var jsonString: String { String(decoding: encoded(), as: UTF8.self) }
+
+    public init(any: Any?) {
+        switch any {
+        case nil, is NSNull: self = .null
+        case let n as NSNumber:
+            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .bool(n.boolValue) } else { self = .number(n.doubleValue) }
+        case let s as String: self = .string(s)
+        case let a as [Any]: self = .array(a.map { JSONValue(any: $0) })
+        case let o as [String: Any]: self = .object(o.mapValues { JSONValue(any: $0) })
+        default: self = .null
+        }
+    }
+
+    public var any: Any {
+        switch self {
+        case .null: return NSNull()
+        case .bool(let b): return b
+        case .number(let n): return n.rounded() == n && abs(n) < 9e15 ? Int64(n) as Any : n
+        case .string(let s): return s
+        case .array(let a): return a.map { $0.any }
+        case .object(let o): return o.mapValues { $0.any }
+        }
+    }
+
+    public static func parse(_ data: Data) throws -> JSONValue {
+        JSONValue(any: try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]))
+    }
+    public func encoded() -> Data {
+        (try? JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed, .withoutEscapingSlashes])) ?? Data("null".utf8)
+    }
+}
+
+extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral,
+    ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral, ExpressibleByFloatLiteral {
+    public init(stringLiteral v: String) { self = .string(v) }
+    public init(integerLiteral v: Int) { self = .number(Double(v)) }
+    public init(floatLiteral v: Double) { self = .number(v) }
+    public init(booleanLiteral v: Bool) { self = .bool(v) }
+    public init(arrayLiteral e: JSONValue...) { self = .array(e) }
+    public init(dictionaryLiteral e: (String, JSONValue)...) { self = .object(Dictionary(e, uniquingKeysWith: { $1 })) }
+    public init(nilLiteral: ()) { self = .null }
+}
+        t.onClose?(nil)
+        do { _ = try await pending; XCTFail() } catch let e as HerdrError { XCTAssertEqual(e.kind, "lost") }
+        await fulfillment(of: [disconnected], timeout: 2)
+        do { _ = try await c.call("x"); XCTFail() } catch {}
+    }
+
+    func testTimeoutAndCancel() async throws {
+        let (c, t) = try await connected()
+        do { _ = try await c.call("slow", timeout: 0.1); XCTFail() } catch let e as HerdrError { XCTAssertEqual(e.kind, "timeout") }
+        let task = Task { try await c.exec(argv: ["sleep", "9"]) }
+        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" } }
+        let id = try JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" }!.payload)["id"]
+        task.cancel()
+        let r = await task.result
+        XCTAssertThrowsError(try r.get())
+        let all = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "$/cancelRequest" } }
+        let cancel = try JSONValue.parse(all.first { (try? JSONValue.parse($0.payload))?["method"] == "$/cancelRequest" }!.payload)
+        XCTAssertEqual(cancel["params"]["id"], id)
+        XCTAssertEqual(cancel["id"], .null)
+    }
+
+    /// A cancelled attach whose reply arrives late: the client closes the
+    /// channel it names (the core would otherwise keep a typing viewer) and
+    /// drops the early frames it buffered.
+    func testLateAttachReplyClosesChannel() async throws {
+        let (c, t) = try await connected()
+        let task = Task { try await c.attach(terminal: "t3", cols: 80, rows: 24) }
+        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "terminal.attach" } }
+        let id = try XCTUnwrap(JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "terminal.attach" }!.payload)["id"].int)
+        task.cancel()
+        _ = await task.result
+/usr/bin/ruby
+/usr/bin/swift
+ README.md | 24 +++++++++++++++++-------
+ 1 file changed, 17 insertions(+), 7 deletions(-)
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "/usr/bin/ruby -rjson -e 'n = 12 << 20; b64 = 4 * ((n + 2) / 3); overhead = JSON.generate({jsonrpc: \"2.0\", id: 1, result: {code: 0, stdout: \"\", stderr: \"\", timed_out: false}}).bytesize; puts \"bytes=#{n}, base64=#{b64}, minimum-example-json=#{overhead}, payload=#{b64 + overhead}, frame-limit=#{16 << 20}\"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 1735ms:
+bytes=12582912, base64=16777216, minimum-example-json=86, payload=16777302, frame-limit=16777216
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "/usr/bin/osascript -l JavaScript -e 'ObjC.import(\"Foundation\"); const data = "'$.NSString.stringWithString("{'"\\\"name\\\":\\\"\\\\udcff\\\"}\").dataUsingEncoding("'$.NSUTF8StringEncoding); const err = Ref(); const result = $.NSJSONSerialization.JSONObjectWithDataOptionsError(data, 0, err); console.log(result ? "parsed" : "rejected"); if (!result) console.log(ObjC.unwrap(err[0].localizedDescription));'"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ succeeded in 80ms:
+parsed
+2026-11-01 03:53:16.961 osascript[50686:20244667] Connection Invalid error for service com.apple.hiservices-xpcservice.
+2026-11-01 03:53:16.961 osascript[50686:20244665] Error received in message reply handler: Connection invalid
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+hook: PreToolUse
+hook: PreToolUse Completed
+exec
+/bin/zsh -lc "/usr/bin/osascript -l JavaScript -e 'ObjC.import(\"Foundation\"); const data = "'$.NSString.stringWithString("{'"\\\"name\\\":\\\"\\\\udcff\\\"}\").dataUsingEncoding("'$.NSUTF8StringEncoding); const err = Ref(); const result = $.NSJSONSerialization.JSONObjectWithDataOptionsError(data, 0, err); console.log(JSON.stringify(ObjC.deepUnwrap(result))); console.log(ObjC.unwrap(err[0].localizedDescription));'"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
+ exited 139 in 4ms:
+undefined
+2026-11-01 03:53:20.343 osascript[50745:20244839] Connection Invalid error for service com.apple.hiservices-xpcservice.
+2026-11-01 03:53:20.343 osascript[50745:20244837] Error received in message reply handler: Connection invalid
+
+hook: PostToolUse
+hook: PostToolUse
+hook: PostToolUse Completed
+hook: PostToolUse Completed
+codex
+Reviewed `6c7e200`. Findings:
+
+1. **High — 12 MiB does not fit the frame.** [FilesView.swift:26](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:26)  
+   Exactly 12 MiB becomes 16,777,216 base64 bytes, leaving **zero** room for JSON. An oversized reply makes `FrameDecoder` disconnect the entire client, including terminal streams. **Fix:** reserve envelope/stderr overhead and enforce a smaller transfer bound. Files listed just above 12 MiB are correctly refused before fetching.
+
+2. **High — stale metadata does not bound the read.** [FilesView.swift:121](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:121)  
+   A file listed as 1 MiB can grow—or its symlink target can change—before opening. `cat` reads everything; the size check runs after transfer, too late to prevent an oversized reply. FIFOs are also listed as files and can block. **Fix:** open and validate a regular file remotely, then read at most the safe limit plus one byte and reject overflow.
+
+3. **Medium — abandoned fetches can destroy another preview.** [FilesView.swift:52](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:52), [FilesView.swift:126](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:126)  
+   Start a slow fetch, dismiss/reopen Files or navigate into another directory, then open another file. The original unstructured task survives and can delete the shared `preview` directory beneath the newer Quick Look preview. Disabling buttons also provides no internal guard against already queued opens. **Fix:** guard concurrent opens, retain/cancel the task on disappearance, reject stale completions, and use a unique directory per preview.
+
+4. **Low — preview copies remain after dismissal.** [FilesView.swift:130](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:130)  
+   Preview a confidential document and close Files: its downloaded copy remains until another successful preview replaces it or the OS purges temporary storage. **Fix:** remove the owned preview directory after Quick Look dismissal and when the browser closes.
+
+5. **Medium — non-UTF-8 filenames can break the entire listing.** [FilesView.swift:40](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:40)  
+   A Linux filename containing byte `0xFF` becomes a Python surrogate escape; `json.dumps` emits an unpaired surrogate that Foundation cannot represent as a valid Swift string. The listing can fail rather than merely omit that entry. **Fix:** encode raw filename bytes separately from display names, or explicitly skip unsupported names with a warning.
+
+6. **Medium — Files requires an undocumented remote dependency.** [FilesView.swift:84](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:84)  
+   On a box with herdr-core but no `python3`, Files cannot list anything or reach preview. **Fix:** explicitly require Python for Files, detect its absence, and show an actionable error; alternatively remove that dependency.
+
+**No findings:** shell injection through argv; spaces, quotes, newlines, leading hyphens and valid Unicode names; remote `~` expansion; ordinary symlink traversal, assuming the space folder is not a security boundary; `.completeFileProtection`.
+
+Documentation discrepancies: the feature guide describes chunked reads, whereas this commit refuses large files; README names Python as a Chat dependency only.
+
+Not checked: simulator/device behavior or herdr-core’s server-side output cap. The exact oversized-response outcome depends on whether core sends, rejects, or truncates it. No files edited.
+hook: Stop
+hook: Stop
+hook: Stop Completed
+hook: Stop Completed
+tokens used
+59,562
+Reviewed `6c7e200`. Findings:
+
+1. **High — 12 MiB does not fit the frame.** [FilesView.swift:26](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:26)  
+   Exactly 12 MiB becomes 16,777,216 base64 bytes, leaving **zero** room for JSON. An oversized reply makes `FrameDecoder` disconnect the entire client, including terminal streams. **Fix:** reserve envelope/stderr overhead and enforce a smaller transfer bound. Files listed just above 12 MiB are correctly refused before fetching.
+
+2. **High — stale metadata does not bound the read.** [FilesView.swift:121](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:121)  
+   A file listed as 1 MiB can grow—or its symlink target can change—before opening. `cat` reads everything; the size check runs after transfer, too late to prevent an oversized reply. FIFOs are also listed as files and can block. **Fix:** open and validate a regular file remotely, then read at most the safe limit plus one byte and reject overflow.
+
+3. **Medium — abandoned fetches can destroy another preview.** [FilesView.swift:52](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:52), [FilesView.swift:126](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:126)  
+   Start a slow fetch, dismiss/reopen Files or navigate into another directory, then open another file. The original unstructured task survives and can delete the shared `preview` directory beneath the newer Quick Look preview. Disabling buttons also provides no internal guard against already queued opens. **Fix:** guard concurrent opens, retain/cancel the task on disappearance, reject stale completions, and use a unique directory per preview.
+
+4. **Low — preview copies remain after dismissal.** [FilesView.swift:130](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:130)  
+   Preview a confidential document and close Files: its downloaded copy remains until another successful preview replaces it or the OS purges temporary storage. **Fix:** remove the owned preview directory after Quick Look dismissal and when the browser closes.
+
+5. **Medium — non-UTF-8 filenames can break the entire listing.** [FilesView.swift:40](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:40)  
+   A Linux filename containing byte `0xFF` becomes a Python surrogate escape; `json.dumps` emits an unpaired surrogate that Foundation cannot represent as a valid Swift string. The listing can fail rather than merely omit that entry. **Fix:** encode raw filename bytes separately from display names, or explicitly skip unsupported names with a warning.
+
+6. **Medium — Files requires an undocumented remote dependency.** [FilesView.swift:84](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:84)  
+   On a box with herdr-core but no `python3`, Files cannot list anything or reach preview. **Fix:** explicitly require Python for Files, detect its absence, and show an actionable error; alternatively remove that dependency.
+
+**No findings:** shell injection through argv; spaces, quotes, newlines, leading hyphens and valid Unicode names; remote `~` expansion; ordinary symlink traversal, assuming the space folder is not a security boundary; `.completeFileProtection`.
+
+Documentation discrepancies: the feature guide describes chunked reads, whereas this commit refuses large files; README names Python as a Chat dependency only.
+
+Not checked: simulator/device behavior or herdr-core’s server-side output cap. The exact oversized-response outcome depends on whether core sends, rejects, or truncates it. No files edited.
diff --git a/docs/reviews/2026-11-01-files-judgement.ja.md b/docs/reviews/2026-11-01-files-judgement.ja.md
new file mode 100644
index 0000000..04f97e9
--- /dev/null
+++ b/docs/reviews/2026-11-01-files-judgement.ja.md
@@ -0,0 +1,16 @@
+# 判断: Files と Quick Look のプレビューへのレビュー（2026-11-01）
+
+この文書は `2026-11-01-files-judgement.md` の日本語訳である。内容が食い違うときは英語版に従う。
+
+対象の commit: 6c7e200。レビューの出力そのもの: `2026-11-01-files-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。
+
+| # | 指摘 | 判断 | 理由・変更 |
+|---|---|---|---|
+| 1 | 12 MiB を base64 にすると 16 MiB の frame を使い切り、それより大きい応答で接続が切れる | 直す | 上限を `Frame.maxPayload / 2`（8 MiB、base64 で約 11 MB）にし、JSON と stderr の分を残した |
+| 2 | 一覧で得た大きさは読む時点では古く、`cat` は全部を読み、FIFO では止まる | 直す | 読み取りを python3 のスクリプトに移した。`O_NONBLOCK` で開き、通常のファイルだけを受け付け（`fstat`）、上限 + 1 バイトまでしか読まず、上限を超えたら終了コード 3 で終わる |
+| 3 | 放置された取得が、新しいプレビューの下のフォルダを消しうる。重ねて開く操作を防いでいない | 直す | プレビューごとにフォルダを分け（UUID）、取得中は `open` が何もせず戻る。取得の task を保持し、画面が消えたら cancel し、cancel された結果は捨てる |
+| 4 | プレビューを閉じても、取り出した複製が残る | 直す | Quick Look を閉じたときに複製のフォルダを消す。プレビュー中にアプリが終わって残った分は、次に Files を開いたときに消す。`onDisappear` では消さない。Quick Look を出すと、ファイルを表示している間に `onDisappear` が呼ばれうるため |
+| 5 | UTF-8 でないファイル名があると、一覧全体が壊れうる | 直す | そうした名前は飛ばして数え、隠した件数を一覧に出す。APFS はその名前を作らせないので Mac では再現できない。Linux の機体で効く |
+| 6 | Files が機体の python3 に依存することを書いていない | 直す | README に、Chat と Files には python3 が要ると書いた。python3 が無い場合（herdr-core 0.1.15 は `spawn_failed` を返すことを確かめた）は「Files needs python3 on the box.」と出す |
+
+修正後に確かめたこと: `testFilesPreviewInQuickLook` が、iOS 27.1 の simulator で PDF・docx・xlsx・png を開く。読み取りのスクリプトを Mac で直接動かし、13 KB の PDF（読めた）、ちょうど 8 MiB（読めた）、8 MiB + 1 バイトと 9 MiB（拒否）、FIFO とディレクトリ（拒否）を確かめた。
diff --git a/docs/reviews/2026-11-01-files-judgement.md b/docs/reviews/2026-11-01-files-judgement.md
new file mode 100644
index 0000000..e641fb3
--- /dev/null
+++ b/docs/reviews/2026-11-01-files-judgement.md
@@ -0,0 +1,14 @@
+# Judgement: review of Files and Quick Look preview (2026-11-01)
+
+Reviewed commit: 6c7e200. Raw review: `2026-11-01-files-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).
+
+| # | Finding | Decision | Why / what changed |
+|---|---|---|---|
+| 1 | 12 MiB as base64 fills the whole 16 MiB frame; a larger reply drops the connection | Fix | Limit is `Frame.maxPayload / 2` (8 MiB, about 11 MB as base64), leaving room for JSON and stderr |
+| 2 | The listed size is stale by the time of the read; `cat` reads everything; FIFOs hang | Fix | Reading moved to a python3 script that opens with `O_NONBLOCK`, accepts only regular files (`fstat`), reads at most limit + 1 bytes and exits 3 above the limit |
+| 3 | An abandoned fetch can delete the folder under a newer preview; queued opens are not guarded | Fix | One folder per preview (UUID), `open` returns while another runs, the fetch task is kept and cancelled when the view goes away, cancelled results are dropped |
+| 4 | Downloaded copies stay after the preview closes | Fix | The copy's folder is deleted when Quick Look closes; leftovers (app quit mid-preview) are deleted when Files opens. Not deleted on `onDisappear`, since presenting Quick Look can fire it while the file is shown |
+| 5 | A non-UTF-8 file name can break the whole listing | Fix | Such names are skipped and counted; the list says how many are hidden. Not reproducible on APFS, which refuses those names; applies to Linux boxes |
+| 6 | Files depends on python3 on the box without saying so | Fix | README lists python3 for Chat and Files; a missing python3 (herdr-core 0.1.15 answers `spawn_failed`, checked) shows "Files needs python3 on the box." |
+
+Verified after the fixes: `testFilesPreviewInQuickLook` opens PDF, docx, xlsx and png on the iOS 27.1 simulator. The read script was run on the Mac against a 13 KB PDF (read), exactly 8 MiB (read), 8 MiB + 1 byte and 9 MiB (refused), a FIFO and a directory (refused).

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat docs/reviews/2026-11-01-fixes-judgement.md docs/reviews/2026-11-01-files-judgement.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
# Judgement: review of the three pre-use fixes (2026-11-01)

Reviewed commits: 407eccd (Chat nudge), 362b8bc (host key approval, Keychain), 1b740be (requiredMethods).
Raw review: `2026-11-01-fixes-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why |
|---|---|---|---|
| 1 | `ChatModel`: a `stop()`/`start()` during `load()` lets the stopped loop reach `pause()` and overwrite `wake`, leaving one continuation unresumed | Fix | One guard after `load()`; a leaked continuation hangs that task forever |
| 2 | Citadel 0.12.1 fails the handshake promise on a rejected host key but does not close the TCP channel | No fix now | Confirmed in `Citadel/Sources/Citadel/ClientSession.swift` (the handshake handler only fails its promise). The rejected-key path already existed for `Mismatch`. `Unknown` is not retried automatically, and sshd drops an unauthenticated connection after `LoginGraceTime` (120 s by default), so connections cannot pile up. The fix belongs in Citadel (close the channel when the handshake fails), sent upstream as a PR; listed in `PENDING.md` |
| 3 | A Keychain read failure is read as "nothing pinned", so a pinned host looks new and its pin could be replaced | Fix | `KeyStore.hostKey` now throws; the validator fails the connection with the Keychain error |
| 4 | The check command names the ed25519 host key file even when the host presented another key type | Fix | `HostKeys.Unknown.checkCommand` names the file for the presented type |
| 5 | Settings' Forget dialog says the next key is trusted automatically | Fix | Text now says the next key will need approval |

Verified after the fixes: `HerdrUITests.testFirstConnectAsksForHostKey` passes on the iOS 27.1 simulator against this Mac's herdr-core over SSH (fingerprint shown before any login, equal to `ssh-keygen -lf` of the host key, home reached only after approval). HerdrKit's 33 unit tests pass.
# Judgement: review of Files and Quick Look preview (2026-11-01)

Reviewed commit: 6c7e200. Raw review: `2026-11-01-files-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | 12 MiB as base64 fills the whole 16 MiB frame; a larger reply drops the connection | Fix | Limit is `Frame.maxPayload / 2` (8 MiB, about 11 MB as base64), leaving room for JSON and stderr |
| 2 | The listed size is stale by the time of the read; `cat` reads everything; FIFOs hang | Fix | Reading moved to a python3 script that opens with `O_NONBLOCK`, accepts only regular files (`fstat`), reads at most limit + 1 bytes and exits 3 above the limit |
| 3 | An abandoned fetch can delete the folder under a newer preview; queued opens are not guarded | Fix | One folder per preview (UUID), `open` returns while another runs, the fetch task is kept and cancelled when the view goes away, cancelled results are dropped |
| 4 | Downloaded copies stay after the preview closes | Fix | The copy's folder is deleted when Quick Look closes; leftovers (app quit mid-preview) are deleted when Files opens. Not deleted on `onDisappear`, since presenting Quick Look can fire it while the file is shown |
| 5 | A non-UTF-8 file name can break the whole listing | Fix | Such names are skipped and counted; the list says how many are hidden. Not reproducible on APFS, which refuses those names; applies to Linux boxes |
| 6 | Files depends on python3 on the box without saying so | Fix | README lists python3 for Chat and Files; a missing python3 (herdr-core 0.1.15 answers `spawn_failed`, checked) shows "Files needs python3 on the box." |

Verified after the fixes: `testFilesPreviewInQuickLook` opens PDF, docx, xlsx and png on the iOS 27.1 simulator. The read script was run on the Mac against a 13 KB PDF (read), exactly 8 MiB (read), 8 MiB + 1 byte and 9 MiB (refused), a FIFO and a directory (refused).

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'git show 95acd13 -- App/Sources/UI/FilesView.swift README.md UITests/HerdrUITests.swift; git status --short' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 95acd13ca4e833de53971d04a7b0d11e69b3b4d6
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:58:45 2026 +0900

    Bound Files reads on the box and clean up preview copies
    
    Codex's review found that a 12 MiB file filled the whole frame as base64,
    that a file growing after the listing (or a FIFO) was read unbounded, that a
    slow earlier fetch could delete a newer preview, and that copies stayed on
    the phone. Reads now go through python3 with a regular-file check and an
    8 MiB cap enforced on the box, each preview gets its own folder that is
    deleted when Quick Look closes, and non-UTF-8 names are skipped and counted.

diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
index ab485c0..ac00f9d 100644
--- a/App/Sources/UI/FilesView.swift
+++ b/App/Sources/UI/FilesView.swift
@@ -3,7 +3,7 @@ import QuickLook
 import HerdrKit
 
 /// A space's folder on the box: browse it and open files in Quick Look
-/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
 struct FilesView: View {
     @Environment(AppStore.self) private var store
     var path: String
@@ -18,26 +18,50 @@ struct FilesView: View {
 
     @State private var dir: String?
     @State private var entries: [Entry] = []
+    @State private var skipped = 0
     @State private var error: String?
     @State private var opening: String?
+    @State private var fetch: Task<Void, Never>?
     @State private var preview: URL?
 
-    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
-    static let maxBytes = 12 << 20
+    /// The largest file read in one machine.exec. The reply is base64 (4/3) inside JSON in one
+    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
+    static let maxBytes = Frame.maxPayload / 2
 
-    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
+    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
+    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
     static let listScript = """
     import json, os, sys
     d = os.path.realpath(os.path.expanduser(sys.argv[1]))
-    out = []
+    out, skipped = [], 0
     with os.scandir(d) as it:
         for e in it:
             try:
+                e.name.encode("utf-8")
                 isdir = e.is_dir()
                 out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
-            except OSError:
-                pass
-    print(json.dumps({"dir": d, "entries": out}))
+            except (OSError, UnicodeEncodeError):
+                skipped += 1
+    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
+    """
+
+    // Writes at most argv[2] bytes of the regular file argv[1]; exit 3 when it is larger or not a
+    // regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
+    static let readScript = """
+    import os, stat, sys
+    limit = int(sys.argv[2])
+    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
+    if not stat.S_ISREG(os.fstat(fd).st_mode):
+        sys.exit("not a regular file")
+    data = b""
+    while len(data) <= limit:
+        chunk = os.read(fd, min(1 << 20, limit + 1 - len(data)))
+        if not chunk:
+            break
+        data += chunk
+    if len(data) > limit:
+        sys.stderr.write("larger than %d bytes" % limit); sys.exit(3)
+    sys.stdout.buffer.write(data)
     """
 
     var body: some View {
@@ -49,10 +73,14 @@ struct FilesView: View {
                 if e.isDir, let dir {
                     NavigationLink(value: dir + "/" + e.name) { row(e) }
                 } else {
-                    Button { Task { await open(e) } } label: { row(e) }
+                    Button { open(e) } label: { row(e) }
                         .disabled(opening != nil)
                 }
             }
+            if skipped > 0 {
+                Text("\(skipped) item(s) with names that can't be shown are hidden.")
+                    .font(HF.ui(13)).foregroundStyle(HC.dim)
+            }
         }
         .overlay { if dir == nil && error == nil { ProgressView() } }
         .navigationTitle(title)
@@ -60,6 +88,9 @@ struct FilesView: View {
         .task { await load() }
         .refreshable { await load() }
         .quickLookPreview($preview)
+        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
+        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
+        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil }
     }
 
     private func row(_ e: Entry) -> some View {
@@ -79,25 +110,35 @@ struct FilesView: View {
         .accessibilityLabel(e.name)
     }
 
+    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
+        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+        return why.isEmpty ? fallback : String(why.suffix(300))
+    }
+
     private func load() async {
         do {
             let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
             guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
-                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
-                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
+                error = Self.failure(r, "Couldn't list \(path)")
                 return
             }
             entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
                 guard let n = a[0].string else { return nil }
                 return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
             })
+            skipped = v["skipped"].int ?? 0
             dir = d
             error = nil
         } catch {
-            self.error = error.localizedDescription
+            self.error = Self.message(error)
         }
     }
 
+    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
+    private static func message(_ error: Error) -> String {
+        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
+    }
+
     /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
     static func sorted(_ entries: [Entry]) -> [Entry] {
         entries.sorted { a, b in
@@ -108,32 +149,40 @@ struct FilesView: View {
         }
     }
 
-    private func open(_ e: Entry) async {
-        guard let dir else { return }
-        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
+    private func open(_ e: Entry) {
+        guard let dir, opening == nil else { return }
+        // shortcut: files over maxBytes (8 MiB) are refused; read them in ranges when large files matter.
         guard e.size <= Self.maxBytes else {
-            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
+            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over \(Self.maxBytes.formatted(.byteCount(style: .file))) can't be previewed yet."
             return
         }
         opening = e.name
-        defer { opening = nil }
-        do {
-            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
-            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
-                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
-                return
+        fetch = Task {
+            defer { if !Task.isCancelled { opening = nil; fetch = nil } }
+            do {
+                let r = try await store.exec(argv: ["python3", "-c", Self.readScript, dir + "/" + e.name, String(Self.maxBytes)],
+                                             cwd: nil, on: nil, timeout: 60, input: nil)
+                guard !Task.isCancelled else { return }
+                guard r.code == 0, !r.timedOut else { error = Self.failure(r, "Couldn't read \(e.name)"); return }
+                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
+                let folder = FileManager.default.temporaryDirectory
+                    .appendingPathComponent("preview", isDirectory: true)
+                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
+                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+                let url = folder.appendingPathComponent(e.name)
+                try r.stdout.write(to: url, options: .completeFileProtection)
+                error = nil
+                preview = url
+            } catch {
+                if !Task.isCancelled { self.error = Self.message(error) }
             }
-            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
-            try? FileManager.default.removeItem(at: folder)
-            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
-            let url = folder.appendingPathComponent(e.name)
-            try r.stdout.write(to: url, options: .completeFileProtection)
-            error = nil
-            preview = url
-        } catch {
-            self.error = error.localizedDescription
         }
     }
+
+    /// Deletes a closed preview's downloaded copy (its own folder).
+    private static func discard(_ url: URL) {
+        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
+    }
 }
 
 /// The Files sheet for one space: its own stack so folders push inside the sheet.
@@ -154,5 +203,7 @@ struct FilesSheet: View {
                     }
                 }
         }
+        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
+        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
     }
 }
 M docs/HANDOVER.md
?? docs/reviews/2026-11-01-review-fixes-codex.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'nl -ba App/Sources/UI/FilesView.swift; nl -ba App/Sources/Net/KeyStore.swift; nl -ba App/Sources/Net/HostKeys.swift; nl -ba App/Sources/Chat/ChatModel.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	import SwiftUI
     2	import QuickLook
     3	import HerdrKit
     4	
     5	/// A space's folder on the box: browse it and open files in Quick Look
     6	/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
     7	struct FilesView: View {
     8	    @Environment(AppStore.self) private var store
     9	    var path: String
    10	    var title: String
    11	
    12	    struct Entry: Identifiable, Hashable {
    13	        var name: String
    14	        var isDir: Bool
    15	        var size: Int
    16	        var id: String { name }
    17	    }
    18	
    19	    @State private var dir: String?
    20	    @State private var entries: [Entry] = []
    21	    @State private var skipped = 0
    22	    @State private var error: String?
    23	    @State private var opening: String?
    24	    @State private var fetch: Task<Void, Never>?
    25	    @State private var preview: URL?
    26	
    27	    /// The largest file read in one machine.exec. The reply is base64 (4/3) inside JSON in one
    28	    /// frame of `Frame.maxPayload` (16 MiB); half of it leaves room for the envelope and stderr.
    29	    static let maxBytes = Frame.maxPayload / 2
    30	
    31	    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
    32	    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
    33	    static let listScript = """
    34	    import json, os, sys
    35	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    36	    out, skipped = [], 0
    37	    with os.scandir(d) as it:
    38	        for e in it:
    39	            try:
    40	                e.name.encode("utf-8")
    41	                isdir = e.is_dir()
    42	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
    43	            except (OSError, UnicodeEncodeError):
    44	                skipped += 1
    45	    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
    46	    """
    47	
    48	    // Writes at most argv[2] bytes of the regular file argv[1]; exit 3 when it is larger or not a
    49	    // regular file. O_NONBLOCK so a FIFO listed as a file cannot hang the read.
    50	    static let readScript = """
    51	    import os, stat, sys
    52	    limit = int(sys.argv[2])
    53	    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
    54	    if not stat.S_ISREG(os.fstat(fd).st_mode):
    55	        sys.exit("not a regular file")
    56	    data = b""
    57	    while len(data) <= limit:
    58	        chunk = os.read(fd, min(1 << 20, limit + 1 - len(data)))
    59	        if not chunk:
    60	            break
    61	        data += chunk
    62	    if len(data) > limit:
    63	        sys.stderr.write("larger than %d bytes" % limit); sys.exit(3)
    64	    sys.stdout.buffer.write(data)
    65	    """
    66	
    67	    var body: some View {
    68	        List {
    69	            if let error {
    70	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
    71	            }
    72	            ForEach(entries) { e in
    73	                if e.isDir, let dir {
    74	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
    75	                } else {
    76	                    Button { open(e) } label: { row(e) }
    77	                        .disabled(opening != nil)
    78	                }
    79	            }
    80	            if skipped > 0 {
    81	                Text("\(skipped) item(s) with names that can't be shown are hidden.")
    82	                    .font(HF.ui(13)).foregroundStyle(HC.dim)
    83	            }
    84	        }
    85	        .overlay { if dir == nil && error == nil { ProgressView() } }
    86	        .navigationTitle(title)
    87	        .navigationBarTitleDisplayMode(.inline)
    88	        .task { await load() }
    89	        .refreshable { await load() }
    90	        .quickLookPreview($preview)
    91	        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
    92	        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
    93	        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil }
    94	    }
    95	
    96	    private func row(_ e: Entry) -> some View {
    97	        HStack(spacing: 12) {
    98	            Image(systemName: e.isDir ? "folder" : "doc")
    99	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
   100	                .frame(width: 22)
   101	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
   102	            Spacer(minLength: 8)
   103	            if opening == e.name {
   104	                ProgressView()
   105	            } else if !e.isDir {
   106	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
   107	            }
   108	        }
   109	        .accessibilityElement(children: .combine)
   110	        .accessibilityLabel(e.name)
   111	    }
   112	
   113	    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
   114	        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
   115	        return why.isEmpty ? fallback : String(why.suffix(300))
   116	    }
   117	
   118	    private func load() async {
   119	        do {
   120	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
   121	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
   122	                error = Self.failure(r, "Couldn't list \(path)")
   123	                return
   124	            }
   125	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
   126	                guard let n = a[0].string else { return nil }
   127	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
   128	            })
   129	            skipped = v["skipped"].int ?? 0
   130	            dir = d
   131	            error = nil
   132	        } catch {
   133	            self.error = Self.message(error)
   134	        }
   135	    }
   136	
   137	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
   138	    private static func message(_ error: Error) -> String {
   139	        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
   140	    }
   141	
   142	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
   143	    static func sorted(_ entries: [Entry]) -> [Entry] {
   144	        entries.sorted { a, b in
   145	            if a.isDir != b.isDir { return a.isDir }
   146	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
   147	            if ad != bd { return bd }
   148	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
   149	        }
   150	    }
   151	
   152	    private func open(_ e: Entry) {
   153	        guard let dir, opening == nil else { return }
   154	        // shortcut: files over maxBytes (8 MiB) are refused; read them in ranges when large files matter.
   155	        guard e.size <= Self.maxBytes else {
   156	            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over \(Self.maxBytes.formatted(.byteCount(style: .file))) can't be previewed yet."
   157	            return
   158	        }
   159	        opening = e.name
   160	        fetch = Task {
   161	            defer { if !Task.isCancelled { opening = nil; fetch = nil } }
   162	            do {
   163	                let r = try await store.exec(argv: ["python3", "-c", Self.readScript, dir + "/" + e.name, String(Self.maxBytes)],
   164	                                             cwd: nil, on: nil, timeout: 60, input: nil)
   165	                guard !Task.isCancelled else { return }
   166	                guard r.code == 0, !r.timedOut else { error = Self.failure(r, "Couldn't read \(e.name)"); return }
   167	                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
   168	                let folder = FileManager.default.temporaryDirectory
   169	                    .appendingPathComponent("preview", isDirectory: true)
   170	                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
   171	                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
   172	                let url = folder.appendingPathComponent(e.name)
   173	                try r.stdout.write(to: url, options: .completeFileProtection)
   174	                error = nil
   175	                preview = url
   176	            } catch {
   177	                if !Task.isCancelled { self.error = Self.message(error) }
   178	            }
   179	        }
   180	    }
   181	
   182	    /// Deletes a closed preview's downloaded copy (its own folder).
   183	    private static func discard(_ url: URL) {
   184	        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
   185	    }
   186	}
   187	
   188	/// The Files sheet for one space: its own stack so folders push inside the sheet.
   189	struct FilesSheet: View {
   190	    @Environment(\.dismiss) private var dismiss
   191	    var folder: String
   192	    var title: String
   193	
   194	    var body: some View {
   195	        NavigationStack {
   196	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
   197	                .navigationDestination(for: String.self) { p in
   198	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
   199	                }
   200	                .toolbar {
   201	                    ToolbarItem(placement: .cancellationAction) {
   202	                        Button("Close", systemImage: "xmark") { dismiss() }
   203	                    }
   204	                }
   205	        }
   206	        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
   207	        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
   208	    }
   209	}
     1	import Foundation
     2	import Security
     3	import Crypto
     4	import Citadel
     5	
     6	/// The app's SSH identity and saved passwords, in the Keychain
     7	/// (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: never synced or backed up).
     8	enum KeyStore {
     9	    private static let service = "com.zzulanas.herdr.ssh"
    10	    private static let keyAccount = "ed25519"
    11	
    12	    enum KeyError: LocalizedError {
    13	        case keychain(OSStatus)
    14	        case badKey(String)
    15	        var errorDescription: String? {
    16	            switch self {
    17	            case .keychain(let s): "Keychain error \(s)"
    18	            case .badKey(let why): why
    19	            }
    20	        }
    21	    }
    22	
    23	    /// The signing key: a DEBUG override file, else the Keychain, else a new one (saved).
    24	    static func signingKey() throws -> Curve25519.Signing.PrivateKey {
    25	        #if DEBUG
    26	        if let path = ProcessInfo.processInfo.environment["HERDR_DEBUG_KEY_PATH"], !path.isEmpty {
    27	            let text = try String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8)
    28	            return try parseOpenSSH(text)
    29	        }
    30	        #endif
    31	        if let raw = try read(account: keyAccount) {
    32	            return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
    33	        }
    34	        let key = Curve25519.Signing.PrivateKey()
    35	        try write(key.rawRepresentation, account: keyAccount)
    36	        return key
    37	    }
    38	
    39	    /// OpenSSH one-line public key: `ssh-ed25519 AAAA… herdr-ios`.
    40	    static func publicKeyLine() -> String {
    41	        guard let key = try? signingKey() else { return "" }
    42	        return publicKeyLine(for: key.publicKey)
    43	    }
    44	
    45	    static func publicKeyLine(for pub: Curve25519.Signing.PublicKey, comment: String = "herdr-ios") -> String {
    46	        var blob = Data()
    47	        func sshString(_ d: Data) {
    48	            withUnsafeBytes(of: UInt32(d.count).bigEndian) { blob.append(contentsOf: $0) }
    49	            blob.append(d)
    50	        }
    51	        sshString(Data("ssh-ed25519".utf8))
    52	        sshString(pub.rawRepresentation)
    53	        return "ssh-ed25519 \(blob.base64EncodedString()) \(comment)"
    54	    }
    55	
    56	    /// Replaces the app key with a pasted, unencrypted OpenSSH ed25519 private key.
    57	    static func importPrivateKey(_ openSSHText: String) throws {
    58	        let key = try parseOpenSSH(openSSHText)
    59	        try write(key.rawRepresentation, account: keyAccount)
    60	    }
    61	
    62	    /// Generates a fresh key (the old one is gone for good).
    63	    static func regenerateKey() throws {
    64	        try write(Curve25519.Signing.PrivateKey().rawRepresentation, account: keyAccount)
    65	    }
    66	
    67	    private static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
    68	        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    69	        guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
    70	            throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
    71	        }
    72	        do {
    73	            return try Curve25519.Signing.PrivateKey(sshEd25519: trimmed + "\n")
    74	        } catch {
    75	            throw KeyError.badKey("Couldn't read that key: only unencrypted ed25519 keys work (\(error))")
    76	        }
    77	    }
    78	
    79	    // MARK: Passwords
    80	
    81	    static func password(for machine: UUID) -> String? {
    82	        (try? read(account: "pw." + machine.uuidString)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    83	    }
    84	
    85	    static func setPassword(_ password: String?, for machine: UUID) {
    86	        let account = "pw." + machine.uuidString
    87	        if let password, !password.isEmpty {
    88	            try? write(Data(password.utf8), account: account)
    89	        } else {
    90	            delete(account: account)
    91	        }
    92	    }
    93	
    94	    // MARK: Host keys
    95	
    96	    /// nil only when nothing is pinned; a Keychain failure throws so it is never taken for a first connection.
    97	    static func hostKey(_ hostPort: String) throws -> String? {
    98	        try read(account: "hostkey." + hostPort).flatMap { String(data: $0, encoding: .utf8) }
    99	    }
   100	
   101	    static func setHostKey(_ line: String?, for hostPort: String) throws {
   102	        let account = "hostkey." + hostPort
   103	        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
   104	    }
   105	
   106	    // MARK: Keychain
   107	
   108	    private static func query(_ account: String) -> [String: Any] {
   109	        [kSecClass as String: kSecClassGenericPassword,
   110	         kSecAttrService as String: service,
   111	         kSecAttrAccount as String: account]
   112	    }
   113	
   114	    private static func read(account: String) throws -> Data? {
   115	        var q = query(account)
   116	        q[kSecReturnData as String] = true
   117	        q[kSecMatchLimit as String] = kSecMatchLimitOne
   118	        var out: CFTypeRef?
   119	        let status = SecItemCopyMatching(q as CFDictionary, &out)
   120	        if status == errSecItemNotFound { return nil }
   121	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
   122	        return out as? Data
   123	    }
   124	
   125	    /// Update in place, add only when missing: a failed write never loses the existing item.
   126	    private static func write(_ data: Data, account: String) throws {
   127	        let attrs: [String: Any] = [kSecValueData as String: data,
   128	                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
   129	        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
   130	        if status == errSecItemNotFound {
   131	            var q = query(account)
   132	            for (k, v) in attrs { q[k] = v }
   133	            status = SecItemAdd(q as CFDictionary, nil)
   134	        }
   135	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
   136	    }
   137	
   138	    private static func delete(account: String) {
   139	        SecItemDelete(query(account) as CFDictionary)
   140	    }
   141	}
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
    23	        /// The command that prints this key's fingerprint on the machine itself.
    24	        var checkCommand: String {
    25	            let type = line.hasPrefix("ssh-ed25519") ? "ed25519" : line.hasPrefix("ecdsa-") ? "ecdsa" : "rsa"
    26	            return "ssh-keygen -lf /etc/ssh/ssh_host_\(type)_key.pub"
    27	        }
    28	        var errorDescription: String? {
    29	            "First connection to \(host). Compare its host key with the machine before trusting it."
    30	        }
    31	    }
    32	
    33	    /// The pinned key's fingerprint, for display.
    34	    static func pinnedFingerprint(host: String, port: Int) -> String? {
    35	        (try? pinned(host: host, port: port))?.map(fingerprint)
    36	    }
    37	
    38	    static func pinned(host: String, port: Int) throws -> String? { try KeyStore.hostKey("\(host):\(port)") }
    39	
    40	    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }
    41	
    42	    static func pin(_ line: String, host: String, port: Int) throws {
    43	        try KeyStore.setHostKey(line, for: "\(host):\(port)")
    44	    }
    45	
    46	    /// `SHA256:<base64>` like ssh-keygen -l.
    47	    static func fingerprint(_ openSSHLine: String) -> String {
    48	        let parts = openSSHLine.split(separator: " ")
    49	        guard parts.count >= 2, let blob = Data(base64Encoded: String(parts[1])) else { return openSSHLine }
    50	        let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
    51	        return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
    52	    }
    53	
    54	    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
    55	    /// so the app can show the fingerprint and pin it on approval.
    56	    final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
    57	        let host: String, port: Int
    58	        init(host: String, port: Int) { self.host = host; self.port = port }
    59	
    60	        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
    61	            let line = String(openSSHPublicKey: hostKey)
    62	            let known: String?
    63	            do { known = try HostKeys.pinned(host: host, port: port) } catch {
    64	                validationCompletePromise.fail(error); return
    65	            }
    66	            if let known {
    67	                if known == line {
    68	                    validationCompletePromise.succeed(())
    69	                } else {
    70	                    validationCompletePromise.fail(Mismatch(host: host, expected: HostKeys.fingerprint(known),
    71	                                                            got: HostKeys.fingerprint(line)))
    72	                }
    73	            } else {
    74	                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
    75	            }
    76	        }
    77	    }
    78	}
     1	import SwiftUI
     2	import HerdrKit
     3	
     4	/// One entry the box-side script emitted (TranscriptScript).
     5	enum ChatEntry {
     6	    case user(String, Date?)
     7	    case note(String)
     8	    case command(String)
     9	    case compact
    10	    case text(String)
    11	    case tool(id: String, name: String, summary: String, detail: String, at: Date?)
    12	    case result(id: String, isError: Bool, output: String)
    13	    case duration(ms: Int)
    14	}
    15	
    16	struct ToolCall: Identifiable, Equatable {
    17	    var id: String
    18	    var name: String
    19	    var summary: String
    20	    var detail: String
    21	    var output: String?
    22	    var isError = false
    23	}
    24	
    25	enum ChatStep: Identifiable, Equatable {
    26	    case text(Int, String)
    27	    case tools(Int, [ToolCall])
    28	    var id: Int { switch self { case .text(let i, _), .tools(let i, _): i } }
    29	    var toolCount: Int { if case .tools(_, let c) = self { c.count } else { 0 } }
    30	}
    31	
    32	/// One prompt and everything the agent did in answer.
    33	struct ChatTurn: Identifiable, Equatable {
    34	    enum Prompt: Equatable { case user(String), note(String), command(String) }
    35	    var id: Int
    36	    var prompt: Prompt?
    37	    var compacted = false
    38	    var steps: [ChatStep] = []
    39	    var durationMs: Int?
    40	    var startedAt: Date?
    41	}
    42	
    43	/// Reads an agent's Claude Code transcript from the box and folds it into
    44	/// turns. Polls quickly while the agent works, slowly otherwise; never
    45	/// attaches to (or resizes) the terminal.
    46	@MainActor @Observable
    47	final class ChatModel {
    48	    enum Phase: Equatable { case loading, ready, unavailable(String), failed(String) }
    49	
    50	    let address: String
    51	    private(set) var phase: Phase = .loading
    52	    private(set) var turns: [ChatTurn] = []
    53	    /// The transcript continues above what was loaded (we only read its tail).
    54	    private(set) var hasEarlier = false
    55	    private(set) var revision = 0
    56	
    57	    private var entries: [ChatEntry] = []
    58	    private var session = ""
    59	    private var offset: Int64 = -1
    60	    private var loop: Task<Void, Never>?
    61	    private var wake: CheckedContinuation<Void, Never>?
    62	    private var sleeper: Task<Void, Never>?
    63	    private weak var store: AppStore?
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
    77	                guard !Task.isCancelled else { return }
    78	                await self.pause()
    79	            }
    80	        }
    81	    }
    82	
    83	    func stop() {
    84	        loop?.cancel(); loop = nil
    85	        sleeper?.cancel(); sleeper = nil
    86	        wake?.resume(); wake = nil
    87	    }
    88	
    89	    /// Something changed (status, turn): read now instead of waiting.
    90	    func nudge() { wake?.resume(); wake = nil }
    91	
    92	    private func pause() async {
    93	        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
    94	        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
    95	        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
    96	            wake = c
    97	            // Cancelled so an earlier pause's timer can never end this one early.
    98	            sleeper?.cancel()
    99	            sleeper = Task { [weak self] in
   100	                try? await Task.sleep(for: delay)
   101	                guard !Task.isCancelled else { return }
   102	                self?.nudge()
   103	            }
   104	        }
   105	    }
   106	
   107	    private func load() async {
   108	        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
   109	        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
   110	        let argv = String(decoding: rec.raw["argv"].encoded(), as: UTF8.self)
   111	        for _ in 0..<4 {   // follow "more" a few times on a big backlog
   112	            do {
   113	                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
   114	                                             cwd: nil, on: nil, timeout: 20, input: nil)
   115	                guard r.code == 0 else {
   116	                    let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
   117	                    phase = .failed(err.isEmpty ? "Couldn't read the conversation." : String(err.suffix(300)))
   118	                    return
   119	                }
   120	                if !apply(r.stdout) { return }
   121	            } catch {
   122	                if case .ready = phase {} else { phase = .failed(error.localizedDescription) }
   123	                return
   124	            }
   125	        }
   126	    }
   127	
   128	    /// Returns true when the box has more to send right away.
   129	    private func apply(_ data: Data) -> Bool {
   130	        var lines = data.split(separator: UInt8(ascii: "\n"))
   131	        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())) else { return false }
   132	        if let why = head["why"].string {
   133	            phase = .unavailable(why == "no-session"
   134	                ? "No Claude Code conversation found for this terminal yet."
   135	                : "Claude Code's transcript for this session isn't on disk yet.")
   136	            return false
   137	        }
   138	        let fresh = head["fresh"].bool ?? false
   139	        if fresh {
   140	            entries = []
   141	            session = head["session"].string ?? ""
   142	            hasEarlier = (head["start"].int ?? 0) > 0
   143	        }
   144	        offset = Int64(head["next"].double ?? Double(offset))
   145	        var added = false
   146	        for line in lines {
   147	            guard let e = try? JSONValue.parse(Data(line)), let entry = Self.entry(e) else { continue }
   148	            entries.append(entry); added = true
   149	        }
   150	        if fresh || added { rebuild() }
   151	        phase = .ready
   152	        return head["more"].bool ?? false
   153	    }
   154	
   155	    private static let iso: ISO8601DateFormatter = {
   156	        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
   157	    }()
   158	
   159	    private static func entry(_ e: JSONValue) -> ChatEntry? {
   160	        let t = e["t"].string ?? ""
   161	        let ts = e["ts"].string.flatMap { iso.date(from: $0) }
   162	        switch e["k"].string {
   163	        case "user": return .user(t, ts)
   164	        case "note": return .note(t)
   165	        case "cmd": return .command(t)
   166	        case "compact": return .compact
   167	        case "text": return .text(t)
   168	        case "tool": return .tool(id: e["id"].string ?? "", name: e["name"].string ?? "Tool",
   169	                                  summary: e["sum"].string ?? "", detail: e["detail"].string ?? "", at: ts)
   170	        case "result": return .result(id: e["id"].string ?? "", isError: e["err"].bool ?? false, output: e["out"].string ?? "")
   171	        case "dur": return .duration(ms: e["ms"].int ?? 0)
   172	        default: return nil
   173	        }
   174	    }
   175	
   176	    /// Folds entries into turns: a prompt starts one; texts and tool calls
   177	    /// follow; consecutive tool calls share a group; results attach by id.
   178	    private func rebuild() {
   179	        var out: [ChatTurn] = []
   180	        var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
   181	        var n = 0
   182	        func next() -> Int { n += 1; return n }
   183	        func current() -> Int {
   184	            if out.isEmpty { out.append(ChatTurn(id: next())) }
   185	            return out.count - 1
   186	        }
   187	        for e in entries {
   188	            switch e {
   189	            case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
   190	            case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
   191	            case .command(let s): out.append(ChatTurn(id: next(), prompt: .command(s)))
   192	            case .compact:
   193	                // A boundary and its "continued from" summary arrive together: one marker.
   194	                if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
   195	                out.append(ChatTurn(id: next(), compacted: true))
   196	            case .text(let s):
   197	                let i = current(); out[i].steps.append(.text(next(), s))
   198	            case .tool(let id, let name, let sum, let detail, let at):
   199	                let i = current()
   200	                if out[i].startedAt == nil { out[i].startedAt = at }
   201	                let call = ToolCall(id: id, name: name, summary: sum, detail: detail)
   202	                if case .tools(let sid, var calls)? = out[i].steps.last {
   203	                    calls.append(call)
   204	                    out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
   205	                    where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
   206	                } else {
   207	                    out[i].steps.append(.tools(next(), [call]))
   208	                    where_[id] = (i, out[i].steps.count - 1, 0)
   209	                }
   210	            case .result(let id, let err, let output):
   211	                guard let w = where_[id], case .tools(let sid, var calls) = out[w.turn].steps[w.step] else { continue }
   212	                calls[w.call].output = output
   213	                calls[w.call].isError = err
   214	                out[w.turn].steps[w.step] = .tools(sid, calls)
   215	            case .duration(let ms):
   216	                if !out.isEmpty { out[out.count - 1].durationMs = ms }
   217	            }
   218	        }
   219	        // A trailing "continued from earlier" marker with nothing after it reads oddly; keep it, it's honest.
   220	        turns = out
   221	        revision += 1
   222	    }
   223	}
   224	
   225	// MARK: Display helpers
   226	
   227	enum ToolStyle {
   228	    static func symbol(_ name: String) -> String {
   229	        switch name {
   230	        case "Bash", "BashOutput", "KillShell": "terminal"
   231	        case "Read": "doc.text"
   232	        case "Edit", "MultiEdit": "pencil"
   233	        case "Write", "NotebookEdit": "square.and.pencil"
   234	        case "Grep", "Glob", "ToolSearch": "magnifyingglass"
   235	        case "WebSearch", "WebFetch": "globe"
   236	        case "Agent", "Task", "SendMessage": "person.2"
   237	        case "TodoWrite": "checklist"
   238	        case "Skill": "sparkles"
   239	        case "Workflow": "point.3.connected.trianglepath.dotted"
   240	        default: name.hasPrefix("mcp__") ? "puzzlepiece.extension" : "wrench.and.screwdriver"
   241	        }
   242	    }
   243	
   244	    /// "mcp__claude-artifacts__get_artifact" -> "claude-artifacts · get_artifact"
   245	    static func title(_ name: String) -> String {
   246	        guard name.hasPrefix("mcp__") else { return name }
   247	        let parts = name.dropFirst(5).components(separatedBy: "__")
   248	        return parts.count >= 2 ? "\(parts[0]) · \(parts.dropFirst().joined(separator: "__"))" : String(name.dropFirst(5))
   249	    }
   250	
   251	    static func duration(ms: Int) -> String {
   252	        let s = ms / 1000
   253	        if s < 60 { return "\(max(s, 1))s" }
   254	        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
   255	        return "\(s / 3600)h \((s % 3600) / 60)m"
   256	    }
   257	}
   258	
   259	#if DEBUG
   260	// A canned conversation for screenshots (HERDR_DEMO=1).
   261	extension ChatModel {
   262	    fileprivate func loadDemo() {
   263	        let now = Date()
   264	        entries = [
   265	            .user("Add a global time slider to the analytics dashboard so every chart shares one range", now.addingTimeInterval(-900)),
   266	            .text("I'll start by looking at how the dashboard wires its charts together."),
   267	            .tool(id: "a", name: "Read", summary: "~/projects/webapp/src/dashboard/Dashboard.tsx", detail: "", at: nil),
   268	            .result(id: "a", isError: false, output: "214 lines"),
   269	            .tool(id: "b", name: "Grep", summary: "useTimeRange", detail: "", at: nil),
   270	            .result(id: "b", isError: false, output: "Found 7 files"),
   271	            .tool(id: "c", name: "Edit", summary: "~/projects/webapp/src/dashboard/TimeSlider.tsx", detail: "+ export function TimeSlider({ range, onChange }: TimeSliderProps) {\n+   const [draft, setDraft] = useState(range);", at: nil),
   272	            .result(id: "c", isError: false, output: "Updated with 48 additions and 3 removals"),
   273	            .tool(id: "d", name: "Bash", summary: "Run the dashboard tests", detail: "npm test -- dashboard", at: nil),
   274	            .result(id: "d", isError: false, output: "Tests: 42 passed, 42 total"),
   275	            .text("""
   276	            Every chart on the dashboard now follows **one shared time range**.
   277	
   278	            **What changed**
   279	            - A new `TimeSlider` sits in the dashboard header; dragging it updates every chart after a short debounce.
   280	            - Charts read the range from `useTimeRange()` instead of keeping their own.
   281	
   282	            | Chart | Before | After |
   283	            |---|---|---|
   284	            | Net flow | own range | shared |
   285	            | Volume | own range | shared |
   286	            | Latency | fixed 24h | shared |
   287	
   288	            Tests pass (42/42). Want me to persist the range in the URL so links keep it?
   289	            """),
   290	            .duration(ms: 318_000),
   291	            .user("Yes, put it in the URL", now.addingTimeInterval(-95)),
   292	            .text("Adding a `range` query parameter and reading it on load."),
   293	            .tool(id: "e", name: "Edit", summary: "~/projects/webapp/src/dashboard/useTimeRange.ts", detail: "", at: nil),
   294	            .result(id: "e", isError: false, output: "Updated"),
   295	            .tool(id: "f", name: "Bash", summary: "Type-check the project", detail: "npx tsc --noEmit", at: nil),
   296	        ]
   297	        rebuild()
   298	        phase = .ready
   299	    }
   300	}
   301	#endif

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc "cat App/Sources/Net/KeyStore.swift App/Sources/Net/CitadelTransport.swift; sed -n '188,215p' App/Sources/UI/FilesView.swift; cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
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

    /// nil only when nothing is pinned; a Keychain failure throws so it is never taken for a first connection.
    static func hostKey(_ hostPort: String) throws -> String? {
        try read(account: "hostkey." + hostPort).flatMap { String(data: $0, encoding: .utf8) }
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
        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return error }
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
/bin/zsh -lc "rg -n 'hostKey\\(|pinned\\(|pinnedFingerprint|FilesSheet|func exec|func request|cancel|stdout|output.*limit' App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift App/Sources/Net App/Sources/UI/RootView.swift App/Sources/UI/MainView.swift UITests/HerdrUITests.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:45:    private var cancelled: Set<UInt64> = []
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:65:        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:164:    /// kind). Cancelling the task sends `$/cancelRequest`.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:172:                enum Outcome { case go, cancelled, closed }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:174:                    if cancelled.remove(id) != nil { return .cancelled }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:179:                case .cancelled: cont.resume(throwing: CancellationError()); return
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:191:                cancelled.insert(id); return false
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:195:                notify("$/cancelRequest", ["id": .number(Double(id))])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:227:                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:365:                // A reply nobody waits for (cancelled or timed out). If it opened a
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:452:        livenessTask?.cancel()
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:528:    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }
App/Sources/Store/AppStore.swift:117:            backgroundTask?.cancel(); backgroundTask = nil
App/Sources/Store/AppStore.swift:216:    func hostKeyFingerprint(_ machine: MachineConfig) -> String? { HostKeys.pinnedFingerprint(host: machine.host, port: machine.port) }
App/Sources/Store/AppStore.swift:432:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
App/Sources/Store/AppStore.swift:470:        reconnectTask?.cancel(); reconnectTask = nil
App/Sources/Store/AppStore.swift:471:        connectTask?.cancel()
App/Sources/Store/AppStore.swift:541:        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
App/Sources/Store/AppStore.swift:564:        reconnectTask?.cancel()
App/Sources/Store/AppStore.swift:577:        connectTask?.cancel(); connectTask = nil
App/Sources/Store/AppStore.swift:578:        reconnectTask?.cancel(); reconnectTask = nil
App/Sources/Store/AppStore.swift:601:        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
App/Sources/Store/AppStore.swift:622:                    guard gen == self.generation else { s.cancel(); return }
App/Sources/Net/HostKeys.swift:34:    static func pinnedFingerprint(host: String, port: Int) -> String? {
App/Sources/Net/HostKeys.swift:35:        (try? pinned(host: host, port: port))?.map(fingerprint)
App/Sources/Net/HostKeys.swift:38:    static func pinned(host: String, port: Int) throws -> String? { try KeyStore.hostKey("\(host):\(port)") }
App/Sources/Net/HostKeys.swift:63:            do { known = try HostKeys.pinned(host: host, port: port) } catch {
App/Sources/Net/KeyStore.swift:97:    static func hostKey(_ hostPort: String) throws -> String? {
App/Sources/Net/CitadelTransport.swift:61:                            case .stdout(let b): onBytes(Data(b.readableBytesView))
App/Sources/Net/CitadelTransport.swift:92:        t?.cancel()

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "git show --stat 95acd13; rg -n 'Files|chunk|python' README.md docs/2026-11-01* --glob '"'!*.ja.md'"'; sed -n '80,165p' UITests/HerdrUITests.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 95acd13ca4e833de53971d04a7b0d11e69b3b4d6
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:58:45 2026 +0900

    Bound Files reads on the box and clean up preview copies
    
    Codex's review found that a 12 MiB file filled the whole frame as base64,
    that a file growing after the listing (or a FIFO) was read unbounded, that a
    slow earlier fetch could delete a newer preview, and that copies stayed on
    the phone. Reads now go through python3 with a regular-file check and an
    8 MiB cap enforced on the box, each preview gets its own folder that is
    deleted when Quick Look closes, and non-UTF-8 names are skipped and counted.

 App/Sources/UI/FilesView.swift                |  113 +-
 docs/reviews/2026-11-01-files-codex.md        | 2915 +++++++++++++++++++++++++
 docs/reviews/2026-11-01-files-judgement.ja.md |   16 +
 docs/reviews/2026-11-01-files-judgement.md    |   14 +
 4 files changed, 3027 insertions(+), 31 deletions(-)
docs/2026-11-01_herdr-ios-code-review.md:32:| High (confirmed in source) | `App/Sources/Chat/ChatView.swift:46`, `ChatModel.swift:91-97` | Calls `model.nudge()` on every `title` change. `title` changes every 0.1 s while working, so while Chat is open, the python that reads the transcript on the Mac side is launched almost continuously. There is also a race: when the sleep of a previous wait ends, it also releases the next wait | Remove the nudge on `title`, keep only `status` and `turn`. Distinguish sleeping Tasks with a token |
docs/2026-11-01_herdr-ios-code-review.md:49:- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
docs/2026-11-01_herdr-ios-code-review.ja.md:34:| 高（原文で確認） | `App/Sources/Chat/ChatView.swift:46`、`ChatModel.swift:91-97` | `title` が変わるたびに `model.nudge()` を呼ぶ。`title` は作業中に 0.1 秒ごとに変わるので、Chat を開いている間、Mac 側で transcript を読む python がほぼ切れ目なく起動される。前の待機の sleep が終わったとき、次の待機まで解いてしまう競合もある | `title` での nudge を外し、`status` と `turn` だけにする。sleep する Task をトークンで区別する |
docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:38:| Secure ShellFish | × | ○ (Quick Look in the Files app) | × | ○ (SSH only) |
README.md:32:- **Files.** Browse a space's folder on the box and open PDFs, Word and Excel documents, images and text in Quick Look, on the phone. Files over 8 MiB are not previewed yet.
README.md:46:- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap.
README.md:71:- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat and Files.
README.md:123:- **UI:** run the `HerdrUITests` target against a real box in watch-only mode. Pass settings to the test runner with the `TEST_RUNNER_` prefix (e.g. `TEST_RUNNER_HERDR_DEBUG_KEY_PATH`): `HERDR_DEBUG_KEY_PATH` always; `HERDR_TEST_HOST`, `HERDR_TEST_USER`, `HERDR_TEST_HOST_FP` for first-connect approval; `HERDR_TEST_SPACE`, `HERDR_TEST_FILES_PATH`, `HERDR_TEST_FILES` for Files; `HERDR_TEST_TERMINAL` for Chat.
            XCTAssertTrue(row.waitForExistence(timeout: 20), "no file \(name)")
            row.tap()
            let done = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'QLOverlayDoneButton'")).firstMatch
            // Images open full screen with the controls hidden; a tap brings them back.
            if !done.waitForExistence(timeout: 15) { app.tap() }
            XCTAssertTrue(done.waitForExistence(timeout: 15), "Quick Look did not open \(name)")
            sleep(2)
            shot(app, "preview-\(name)")
            done.tap()
            XCTAssertTrue(row.waitForExistence(timeout: 10), "did not return to the list after \(name)")
        }
    }

    /// Chat reads a Claude agent's transcript ($HERDR_TEST_TERMINAL); folds open on tap. Never sends anything.
    func testChatRendersAndFolds() throws {
        let app = launch(["HERDR_DEBUG_OPEN": ProcessInfo.processInfo.environment["HERDR_TEST_TERMINAL"] ?? "t1"])
        let field = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 30), "no composer")
        sleep(4)
        shot(app, "chat-bottom")
        let folds = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Worked'"))
        var tries = 0
        while folds.count == 0 && tries < 6 { app.swipeDown(); tries += 1 }
        XCTAssertGreaterThan(folds.count, 0, "no Worked-for row")
        folds.element(boundBy: folds.count - 1).tap()
        sleep(1)
        shot(app, "chat-fold-open")
        let tool = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Bash'")).firstMatch
        if tool.exists { tool.tap(); sleep(1); shot(app, "chat-tool-open") }
    }

    /// A scripted tour for the README video (demo data only). Run while
    /// recording; the harness sends a push with `xcrun simctl push` once
    /// the app is in the background.
    func testDemoTour() throws {
        let app = XCUIApplication()
        app.launchEnvironment["HERDR_DEMO"] = "1"
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        app.launch()
        // Notification permission (demo mode asks too, so the push can show).
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
        sleep(3)
        // Home -> an agent's chat.
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Global time slider'")).firstMatch.tap()
        sleep(3)
        let fold = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Worked'")).firstMatch
        if fold.waitForExistence(timeout: 3) { fold.tap(); sleep(3); app.swipeUp(); sleep(2) }
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(2)
        // A space with its tabs, then the new-agent sheet.
        app.swipeUp(); sleep(1)
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'webapp'")).firstMatch.tap()
        sleep(3)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        app.swipeDown(); sleep(1)
        app.buttons["New agent"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(3)
        app.buttons["Cancel"].tap()
        sleep(1)
        // Background the app; the harness pushes "OAuth needs you".
        XCUIDevice.shared.press(.home)
        try? "ready".write(toFile: "/tmp/herdr-tour-ready", atomically: true, encoding: .utf8)
        let banner = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'needs you'")).firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 60), "no notification banner")
        sleep(2)
        banner.tap()
        sleep(5)
    }
}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
読み取り上限は8 MiBで実際の読み取り時にも適用され、cancel済みの取得結果はプレビューへ反映されない構造です。残る確認は、Quick Lookの表示・終了と削除処理の順序、およびKeychainエラーの伝播経路です。
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '155,235p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; sed -n '190,225p' App/Sources/Store/AppStore.swift; sed -n '428,444p' App/Sources/Store/AppStore.swift; sed -n '480,582p' App/Sources/Store/AppStore.swift; rg -n 'FilesSheet|filesSheet|showFiles' App/Sources" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
    public func close() {
        lock.withLock { closedByUs = true }
        transport.close()
        fail(HerdrError(code: -1, kind: "closed", message: "Disconnected"))
    }

    // MARK: Calls

    /// One JSON-RPC call on channel 0. Errors are `HerdrError` (message, hint,
    /// kind). Cancelling the task sends `$/cancelRequest`.
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
    public func notify(_ method: String, _ params: JSONValue = [:]) {
        let msg: JSONValue = ["jsonrpc": "2.0", "method": .string(method), "params": params]
        send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
    }

    private func finish(_ id: UInt64, _ result: Result<JSONValue, Error>) {
        guard let cont = lock.withLock({ pending.removeValue(forKey: id) }) else { return }
        cont.resume(with: result)
    }

    static func rpcError(_ e: JSONValue) -> HerdrError {
        HerdrError(code: e["code"].int ?? -32000, kind: e["data"]["kind"].string,
                   message: e["message"].string ?? "core call failed", hint: e["data"]["hint"].string)
    }

    // MARK: Typed helpers

    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
    /// exit or timeout is a result, not an error.
    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
        if let input { p["input"] = .string(input.base64EncodedString()) }
        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
        return ExecResult(code: r["code"].int,
                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
                          timedOut: r["timed_out"].bool ?? false)
    }

    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
        let r = try await call("doc.get", ["name": .string(name)])
        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
    }
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
App/Sources/UI/SpaceView.swift:12:    @State private var showFiles = false
App/Sources/UI/SpaceView.swift:82:                Button { showFiles = true } label: { Image(systemName: "folder") }
App/Sources/UI/SpaceView.swift:90:        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
App/Sources/UI/FilesView.swift:189:struct FilesSheet: View {

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "git show 8f48ed6 --format= --name-only; git log -4 --oneline; rg -n 'quickLook|onAppear|preview|flush|NONBLOCK|exit' docs/reviews/2026-11-01-files-judgement.md project.yml; command -v uv" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
App/Sources/Chat/ChatModel.swift
App/Sources/Net/CitadelTransport.swift
App/Sources/Net/HostKeys.swift
App/Sources/Net/KeyStore.swift
App/Sources/UI/ConnectionViews.swift
App/Sources/UI/SettingsView.swift
UITests/HerdrUITests.swift
docs/reviews/2026-11-01-fixes-codex.md
docs/reviews/2026-11-01-fixes-judgement.ja.md
docs/reviews/2026-11-01-fixes-judgement.md
docs/reviews/PENDING.md
7b77440 Describe the fork, Files, host key approval and simulator builds in README
95acd13 Bound Files reads on the box and clean up preview copies
6c7e200 Browse a space's folder and preview its files in Quick Look
8f48ed6 Act on the review of the pre-use fixes and test first-connect approval
docs/reviews/2026-11-01-files-judgement.md:1:# Judgement: review of Files and Quick Look preview (2026-11-01)
docs/reviews/2026-11-01-files-judgement.md:8:| 2 | The listed size is stale by the time of the read; `cat` reads everything; FIFOs hang | Fix | Reading moved to a python3 script that opens with `O_NONBLOCK`, accepts only regular files (`fstat`), reads at most limit + 1 bytes and exits 3 above the limit |
docs/reviews/2026-11-01-files-judgement.md:9:| 3 | An abandoned fetch can delete the folder under a newer preview; queued opens are not guarded | Fix | One folder per preview (UUID), `open` returns while another runs, the fetch task is kept and cancelled when the view goes away, cancelled results are dropped |
docs/reviews/2026-11-01-files-judgement.md:10:| 4 | Downloaded copies stay after the preview closes | Fix | The copy's folder is deleted when Quick Look closes; leftovers (app quit mid-preview) are deleted when Files opens. Not deleted on `onDisappear`, since presenting Quick Look can fire it while the file is shown |
/etc/profiles/per-user/yosuke/bin/uv

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "rg --files /Users/yosuke/workspace/github.com | rg '(herdr-core|herdr)/.*(exec|machine|ClientSession|HostKey).*\\.(rs|swift)"'$'"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 exited 1 in 139ms:
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
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
exec
/bin/zsh -lc "git show 95acd13:README.md | rg -n 'python|Files|MiB'; git show 95acd13:App/Sources/UI/FilesView.swift | tail -22; rg -n 'maxPayload' Packages/HerdrKit/Sources/HerdrKit; sed -n '225,240p' App/Sources/Store/AppStore.swift; rg --files -g AGENTS.md -g '*.swift' App/Tests Tests | head -35" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
43:- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap.
68:- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat.
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
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:17:    public static let maxPayload = 16 << 20
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:78:        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
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
rg: App/Tests: No such file or directory (os error 2)
rg: Tests: No such file or directory (os error 2)

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
exec
/bin/zsh -lc "git show 8f48ed6 -- docs/reviews/PENDING.md; rg -n 'First connection|Forget|Check .*host|checkCommand' App/Sources/UI/ConnectionViews.swift App/Sources/UI/SettingsView.swift; rg --files -g AGENTS.md -g '*Key*Test*' -g '*Files*Test*' -g '*Chat*Test*'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 8f48ed6eb86f9af6b9cffc57759f1515efa2c777
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:45:03 2026 +0900

    Act on the review of the pre-use fixes and test first-connect approval
    
    A Keychain read failure made a pinned host look new, so its pin could be
    replaced; it now fails the connection. A Chat loop stopped during a load
    could leave a continuation hanging. The approval card names the host key
    file for the presented key type, and the failure title says what is being
    asked. A UI test drives a fresh install through approval against a real
    herdr-core and checks the fingerprint against the host's key.

diff --git a/docs/reviews/PENDING.md b/docs/reviews/PENDING.md
new file mode 100644
index 0000000..2de0e62
--- /dev/null
+++ b/docs/reviews/PENDING.md
@@ -0,0 +1,3 @@
+# Pending review work
+
+- Citadel 0.12.1 leaves the TCP channel open when the host key is rejected (`docs/reviews/2026-11-01-fixes-judgement.md` #2). Fix in a fork of `orlandos-nl/Citadel` and send upstream as a PR; until then sshd's `LoginGraceTime` bounds the leak.
App/Sources/UI/SettingsView.swift:11:    @State private var confirmForget: MachineConfig?
App/Sources/UI/SettingsView.swift:49:                        Button("Forget host key", role: .destructive) { confirmForget = m }
App/Sources/UI/SettingsView.swift:52:                .confirmationDialog("Forget the host key?", isPresented: Binding(get: { confirmForget != nil }, set: { if !$0 { confirmForget = nil } }),
App/Sources/UI/SettingsView.swift:53:                                    titleVisibility: .visible, presenting: confirmForget) { m in
App/Sources/UI/SettingsView.swift:54:                    Button("Forget", role: .destructive) { store.forgetHostKey(m); if store.phase != .connected { store.reconnect() } }
App/Sources/UI/ConnectionViews.swift:233:    @State private var confirmForget = false
App/Sources/UI/ConnectionViews.swift:241:                Text(store.unknownHostKey != nil ? "Check \(store.machineTitle)'s host key" : store.phase == .idle ? "Not connected to \(store.machineTitle)" : "Couldn't reach \(store.machineTitle)")
App/Sources/UI/ConnectionViews.swift:284:                        Text("On \(key.host), compare it with: \(key.checkCommand)")
App/Sources/UI/ConnectionViews.swift:296:                    Button(role: .destructive) { confirmForget = true } label: {
App/Sources/UI/ConnectionViews.swift:297:                        Label("Forget host key", systemImage: "key.slash")
App/Sources/UI/ConnectionViews.swift:301:                    .confirmationDialog("Forget \(m.host)'s host key?", isPresented: $confirmForget, titleVisibility: .visible) {
App/Sources/UI/ConnectionViews.swift:302:                        Button("Forget and reconnect", role: .destructive) {
App/Sources/UI/ConnectionViews.swift:310:                Text("Check that the host is reachable (e.g. Tailscale is on), the key is in authorized_keys, and herdr-core is installed in ~/.local/bin.")
AGENTS.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
**no findings（動作上の不具合）**。

両コミットを判断表と照合しました。8 MiB上限とlimit + 1の読み取り、通常ファイルでの`O_NONBLOCK`、stdoutの終了時flush、取得taskのcancelと`opening`の解除、プレビュー単位の削除、Keychain読取エラーによる接続拒否に、新たな不具合は見つかりませんでした。

記述上の不一致はあります。

- [FilesView.swift:48](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:48)：コメントは非通常ファイルもexit 3としていますが、実際はexit 1です。呼び出し側は両方を拒否するため、動作への影響はありません。
- Files判断表#6のREADME更新は、対象2コミットには含まれず、後続の`7b77440`で実施されています。
- 既存レビュー文書の「大きなファイルは分割読み」は、現在の8 MiB超を拒否する実装と一致しません。

未確認：SimulatorでのQuick LookライフサイクルとKeychain障害の実機再現。スクリプトの実行検証はread-only sandbox制約で実施できていません。ファイル変更なし。
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
58,452
**no findings（動作上の不具合）**。

両コミットを判断表と照合しました。8 MiB上限とlimit + 1の読み取り、通常ファイルでの`O_NONBLOCK`、stdoutの終了時flush、取得taskのcancelと`opening`の解除、プレビュー単位の削除、Keychain読取エラーによる接続拒否に、新たな不具合は見つかりませんでした。

記述上の不一致はあります。

- [FilesView.swift:48](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:48)：コメントは非通常ファイルもexit 3としていますが、実際はexit 1です。呼び出し側は両方を拒否するため、動作への影響はありません。
- Files判断表#6のREADME更新は、対象2コミットには含まれず、後続の`7b77440`で実施されています。
- 既存レビュー文書の「大きなファイルは分割読み」は、現在の8 MiB超を拒否する実装と一致しません。

未確認：SimulatorでのQuick LookライフサイクルとKeychain障害の実機再現。スクリプトの実行検証はread-only sandbox制約で実施できていません。ファイル変更なし。
