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
session id: 01a197dd-557d-79a3-992c-439be04495cd
--------
user
Review commit 2f98a3b (git show 2f98a3b): QR pairing for a native iOS client of herdr-core. scripts/pair.sh runs on the box: makes an ed25519 key for the phone, appends 'restrict,command="<herdr-core> connect" <pub>' to ~/.ssh/authorized_keys, and prints a QR of herdr-pair:base64url(JSON{v,host,port,user,hostKey,key}). The app (PairingOffer in HerdrKit, KeyStore per-machine key, AppStore.pair, PairingCard/PairingScanner in ConnectionViews.swift) pins the host key from the code and stores the key per machine. Review only: security (key exposure, temp file handling, authorized_keys injection via host/name/paths, forced-command bypass, host key pinning overriding an existing pin), correctness (JSON escaping in sh, base64 on macOS vs Linux, re-pairing the same machine, removing machines, DEBUG key override), and edge cases. Do not edit. Numbered findings with severity, file:line, scenario, fix; then a verdict.
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
レビュー用スキルを参照し、コミット差分と鍵管理・SSH 接続の呼び出し先を読みます。指定された攻撃シナリオと再ペアリング時の状態遷移を確認し、変更せずに所見を返します。
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
/bin/zsh -lc 'git status --short; git show --stat 2f98a3b; git show 2f98a3b' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 6ms:
?? docs/reviews/2026-11-02-pairing-codex.md
commit 2f98a3b60fc6ea46722999793f1cfebfa929e35c
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:06:55 2026 +0900

    Pair a phone by scanning a QR code from scripts/pair.sh
    
    The box makes the phone's SSH key, authorizes it for herdr-core connect only and
    shows it with the box's address and host key in a QR code, so pairing rides on
    herdr-core's own remote path (SSH) with nothing listening and no fingerprint to
    compare. Paired keys are kept per machine instead of replacing the app key.

 AGENTS.ja.md                                       |  2 +-
 AGENTS.md                                          |  2 +-
 App/Sources/Net/KeyStore.swift                     | 12 ++-
 App/Sources/Store/AppStore.swift                   | 16 +++-
 App/Sources/UI/ConnectionViews.swift               | 91 ++++++++++++++++++++++
 Packages/HerdrKit/Sources/HerdrKit/Pairing.swift   | 46 +++++++++++
 .../Tests/HerdrKitTests/HerdrKitTests.swift        | 26 +++++++
 README.ja.md                                       |  3 +-
 README.md                                          |  3 +-
 UITests/HerdrUITests.swift                         | 19 +++++
 docs/HANDOVER.md                                   |  2 +
 nix/flake.nix                                      |  1 +
 project.yml                                        |  1 +
 scripts/pair.sh                                    | 52 +++++++++++++
 14 files changed, 270 insertions(+), 6 deletions(-)
commit 2f98a3b60fc6ea46722999793f1cfebfa929e35c
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:06:55 2026 +0900

    Pair a phone by scanning a QR code from scripts/pair.sh
    
    The box makes the phone's SSH key, authorizes it for herdr-core connect only and
    shows it with the box's address and host key in a QR code, so pairing rides on
    herdr-core's own remote path (SSH) with nothing listening and no fingerprint to
    compare. Paired keys are kept per machine instead of replacing the app key.

diff --git a/AGENTS.ja.md b/AGENTS.ja.md
index fb26eb5..6469bc7 100644
--- a/AGENTS.ja.md
+++ b/AGENTS.ja.md
@@ -25,7 +25,7 @@ labteam のクレジットが切れたら、アカウントを切り替えず、
 
 ## 環境
 
-devshell（`.envrc` → `nix/flake.nix`）が XcodeGen と bun を入れる。Swift と iOS の SDK は Xcode のものを使う。agent には、dotfiles の agent-switch の shim が、repo で `claude` か `codex` を起動したときに direnv を読み込んで効かせる。コマンドラインでのビルドには `-skipPackagePluginValidation` が要る（SwiftTerm が build plugin を持つ）。`scripts/bundle-mods.sh` は sandbox なしの pre-build として動くので、変更があればビルドの前に読む。
+devshell（`.envrc` → `nix/flake.nix`）が XcodeGen、bun、qrencode（`scripts/pair.sh` 用）を入れる。Swift と iOS の SDK は Xcode のものを使う。agent には、dotfiles の agent-switch の shim が、repo で `claude` か `codex` を起動したときに direnv を読み込んで効かせる。コマンドラインでのビルドには `-skipPackagePluginValidation` が要る（SwiftTerm が build plugin を持つ）。`scripts/bundle-mods.sh` は sandbox なしの pre-build として動くので、変更があればビルドの前に読む。
 
 ## 先行実装
 
diff --git a/AGENTS.md b/AGENTS.md
index 6eb613c..5fb323a 100644
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -23,7 +23,7 @@ When labteam credits run out, do not switch accounts and do not skip the review:
 
 ## Environment
 
-The devshell (`.envrc` → `nix/flake.nix`) provides XcodeGen and bun; Swift and the iOS SDK come from Xcode. Agents get it from dotfiles' agent-switch shims, which load direnv when `claude` or `codex` starts in the repo. Command-line builds need `-skipPackagePluginValidation` (SwiftTerm ships a build plugin). `scripts/bundle-mods.sh` runs as an unsandboxed pre-build step; read any change to it before building.
+The devshell (`.envrc` → `nix/flake.nix`) provides XcodeGen, bun and qrencode (for `scripts/pair.sh`); Swift and the iOS SDK come from Xcode. Agents get it from dotfiles' agent-switch shims, which load direnv when `claude` or `codex` starts in the repo. Command-line builds need `-skipPackagePluginValidation` (SwiftTerm ships a build plugin). `scripts/bundle-mods.sh` runs as an unsandboxed pre-build step; read any change to it before building.
 
 ## Prior art
 
diff --git a/App/Sources/Net/KeyStore.swift b/App/Sources/Net/KeyStore.swift
index 6c7a198..63f0883 100644
--- a/App/Sources/Net/KeyStore.swift
+++ b/App/Sources/Net/KeyStore.swift
@@ -64,7 +64,17 @@ enum KeyStore {
         try write(Curve25519.Signing.PrivateKey().rawRepresentation, account: keyAccount)
     }
 
-    private static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
+    /// A machine's own key, from pairing; nil when the machine uses the app key.
+    static func machineKey(for machine: UUID) throws -> Curve25519.Signing.PrivateKey? {
+        try read(account: "key." + machine.uuidString).map { try Curve25519.Signing.PrivateKey(rawRepresentation: $0) }
+    }
+
+    static func setMachineKey(_ key: Curve25519.Signing.PrivateKey?, for machine: UUID) throws {
+        let account = "key." + machine.uuidString
+        if let key { try write(key.rawRepresentation, account: account) } else { delete(account: account) }
+    }
+
+    static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
         let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
         guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
             throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
diff --git a/App/Sources/Store/AppStore.swift b/App/Sources/Store/AppStore.swift
index 0947e07..a0dad6d 100644
--- a/App/Sources/Store/AppStore.swift
+++ b/App/Sources/Store/AppStore.swift
@@ -187,6 +187,7 @@ final class AppStore {
         }
         machines.removeAll { $0.id == id }
         KeyStore.setPassword(nil, for: id)
+        try? KeyStore.setMachineKey(nil, for: id)
         HostKeys.forget(host: m.host, port: m.port)
         for k in ["attention.", "view.", "home."] { defaults.removeObject(forKey: k + id.uuidString) }
     }
@@ -199,6 +200,19 @@ final class AppStore {
         return k
     }
 
+    /// Adds the machine a `scripts/pair.sh` code describes, with its own key and its host key pinned, and connects.
+    func pair(_ offer: PairingOffer) throws {
+        let key = try KeyStore.parseOpenSSH(offer.privateKey)
+        let m = machines.first { $0.host == offer.host && $0.port == offer.port && $0.user == offer.user }
+            ?? MachineConfig(label: offer.host, host: offer.host, port: offer.port, user: offer.user)
+        try KeyStore.setMachineKey(key, for: m.id)
+        try HostKeys.pin(offer.hostKey, host: offer.host, port: offer.port)
+        var saved = m
+        saved.usePassword = false
+        saveMachine(saved, password: nil)
+        connect(to: saved)
+    }
+
     /// Replace the app key with a pasted OpenSSH ed25519 private key.
     func importPrivateKey(_ text: String) throws {
         try KeyStore.importPrivateKey(text)
@@ -486,7 +500,7 @@ final class AppStore {
         guard step("\(verb) to \(m.host)", 0, gen) else { return }
         let auth: CitadelTransport.Auth
         do {
-            if m.usePassword, let pw = KeyStore.password(for: m.id) { auth = .password(pw) } else { auth = .key(try KeyStore.signingKey()) }
+            if m.usePassword, let pw = KeyStore.password(for: m.id) { auth = .password(pw) } else { auth = .key(try KeyStore.machineKey(for: m.id) ?? KeyStore.signingKey()) }
         } catch {
             fail(error, gen: gen, retry: false); return
         }
diff --git a/App/Sources/UI/ConnectionViews.swift b/App/Sources/UI/ConnectionViews.swift
index 7a56291..3183e43 100644
--- a/App/Sources/UI/ConnectionViews.swift
+++ b/App/Sources/UI/ConnectionViews.swift
@@ -1,5 +1,6 @@
 import SwiftUI
 import HerdrKit
+import VisionKit
 
 // MARK: Onboarding
 
@@ -44,6 +45,7 @@ struct MachineForm: View {
 
     var body: some View {
         VStack(alignment: .leading, spacing: 0) {
+            if machine.host.isEmpty { PairingCard() }
             SectionLabel(title: "Machine")
             VStack(spacing: 0) {
                 field("Name", text: $machine.label, prompt: "my-box")
@@ -327,3 +329,92 @@ struct FailureView: View {
         }
     }
 }
+
+// MARK: Pairing
+
+/// Adds a machine from the code `scripts/pair.sh` shows on it: scanned with the camera, or pasted.
+struct PairingCard: View {
+    @Environment(AppStore.self) private var store
+    @Environment(\.dismiss) private var dismiss
+    @State private var scanning = false
+    @State private var code = ""
+    @State private var error: String?
+
+    var body: some View {
+        SectionLabel(title: "Pair with a code")
+        VStack(alignment: .leading, spacing: 12) {
+            Text("On the machine, run scripts/pair.sh from herdr-pocket. It authorizes a key for herdr-core only and shows a QR code.")
+                .font(HF.ui(14)).foregroundStyle(HC.muted)
+            if PairingScanner.available {
+                Button { scanning = true } label: {
+                    Label("Scan pairing code", systemImage: "qrcode.viewfinder").frame(maxWidth: .infinity)
+                }
+                .buttonStyle(.glassProminent)
+            }
+            HStack(spacing: 10) {
+                TextField("or paste herdr-pair:…", text: $code)
+                    .font(HF.mono(13)).textInputAutocapitalization(.never).autocorrectionDisabled()
+                    .accessibilityIdentifier("pairingCode")
+                Button("Pair") { use(code) }.buttonStyle(.glass).disabled(code.isEmpty)
+            }
+            if let error {
+                Label(error, systemImage: "exclamationmark.triangle.fill").font(HF.ui(13.5)).foregroundStyle(HC.blocked)
+            }
+        }
+        .padding(14)
+        .herdrCard()
+        .fullScreenCover(isPresented: $scanning) {
+            PairingScanner { text in scanning = false; use(text) }
+                .ignoresSafeArea()
+                .overlay(alignment: .topTrailing) {
+                    Button("Cancel", systemImage: "xmark") { scanning = false }.buttonStyle(.glass).padding(20)
+                }
+        }
+    }
+
+    private func use(_ text: String) {
+        do {
+            try store.pair(PairingOffer.decode(text))
+            error = nil
+            dismiss()
+        } catch {
+            self.error = error.localizedDescription
+        }
+    }
+}
+
+
+
+/// The camera, reporting the first QR code it reads.
+struct PairingScanner: UIViewControllerRepresentable {
+    var onCode: (String) -> Void
+
+    static var available: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }
+
+    func makeUIViewController(context: Context) -> DataScannerViewController {
+        let vc = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .accurate,
+                                           isHighlightingEnabled: true)
+        vc.delegate = context.coordinator
+        try? vc.startScanning()
+        return vc
+    }
+
+    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}
+
+    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }
+
+    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
+        let onCode: (String) -> Void
+        private var done = false
+        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }
+
+        func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
+            for case .barcode(let b) in items {
+                guard !done, let s = b.payloadStringValue, s.hasPrefix(PairingOffer.prefix) else { continue }
+                done = true
+                scanner.stopScanning()
+                onCode(s)
+            }
+        }
+    }
+}
diff --git a/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift b/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift
new file mode 100644
index 0000000..47dc054
--- /dev/null
+++ b/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift
@@ -0,0 +1,46 @@
+import Foundation
+
+/// What `scripts/pair.sh` puts in its QR code: everything a phone needs to reach `herdr-core connect`
+/// on a box over SSH. The box made the key pair and authorized the public half for that command only,
+/// so nothing goes back from the phone.
+///
+/// Text form: `herdr-pair:` + base64url(JSON `{"v":1,"host","port","user","hostKey","key"}`).
+public struct PairingOffer: Equatable, Sendable {
+    public var host: String
+    public var port: Int
+    public var user: String
+    /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
+    public var hostKey: String
+    /// The phone's private key, unencrypted OpenSSH text.
+    public var privateKey: String
+
+    public static let prefix = "herdr-pair:"
+
+    public init(host: String, port: Int, user: String, hostKey: String, privateKey: String) {
+        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.privateKey = privateKey
+    }
+
+    public struct Invalid: LocalizedError, Equatable {
+        public var reason: String
+        public var errorDescription: String? { "Not a herdr pairing code: \(reason)." }
+    }
+
+    public static func decode(_ text: String) throws -> PairingOffer {
+        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
+        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
+        var b64 = String(s.dropFirst(prefix.count)).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
+        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
+        guard let data = Data(base64Encoded: b64), let v = try? JSONValue.parse(data) else { throw Invalid(reason: "the code is damaged") }
+        guard v["v"].int == 1 else { throw Invalid(reason: "made by a newer pair.sh") }
+        guard let host = v["host"].string, !host.isEmpty, let user = v["user"].string, !user.isEmpty else {
+            throw Invalid(reason: "no host or user")
+        }
+        let port = v["port"].int ?? 22
+        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
+        guard let hostKey = v["hostKey"].string, hostKey.hasPrefix("ssh-"), hostKey.split(separator: " ").count == 2 else {
+            throw Invalid(reason: "no host key")
+        }
+        guard let key = v["key"].string, key.contains("BEGIN OPENSSH PRIVATE KEY") else { throw Invalid(reason: "no key") }
+        return PairingOffer(host: host, port: port, user: user, hostKey: hostKey, privateKey: key)
+    }
+}
diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
index 0760cda..3a7d291 100644
--- a/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
+++ b/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
@@ -334,3 +334,29 @@ final class AttentionTests: XCTestCase {
         XCTAssertEqual(now.display("t9"), .idle)               // first sighting
     }
 }
+
+final class PairingTests: XCTestCase {
+    private func code(_ obj: [String: Any]) -> String {
+        let data = try! JSONSerialization.data(withJSONObject: obj)
+        let b64 = data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
+            .replacingOccurrences(of: "=", with: "")
+        return PairingOffer.prefix + b64
+    }
+    private let key = "-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----\n"
+    private let hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqu"
+
+    func testDecodesWhatPairShPrints() throws {
+        let o = try PairingOffer.decode(code(["v": 1, "host": "100.64.0.9", "port": 2222, "user": "me", "hostKey": hostKey, "key": key]) + "\n")
+        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: hostKey, privateKey: key))
+    }
+
+    func testRejectsOtherTextAndIncompleteOffers() {
+        XCTAssertThrowsError(try PairingOffer.decode("orca://pair?code=abc"))
+        XCTAssertThrowsError(try PairingOffer.decode(PairingOffer.prefix + "!!!"))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "host": "h", "user": "u", "hostKey": hostKey, "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "", "user": "u", "hostKey": hostKey, "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "user": "u", "hostKey": "AAAA", "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "port": 0, "user": "u", "hostKey": hostKey, "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "user": "u", "hostKey": hostKey, "key": "nope"])))
+    }
+}
diff --git a/README.ja.md b/README.ja.md
index e5e945e..c8f8d43 100644
--- a/README.ja.md
+++ b/README.ja.md
@@ -43,7 +43,8 @@
 
 アプリは user のマシンに SSH の exec チャネルを開き、`herdr-core connect` を実行する。これは、デスクトップアプリがリモートのマシンに使うのと同じ、フレーム化された JSON-RPC のストリームである（`ssh box hc connect`）。マシンに追加でインストールするものはなく、サーバも relay も介さない。
 
-- **ログイン:** アプリは Ed25519 の鍵を Keychain の中に生成する。その公開鍵をマシンの `~/.ssh/authorized_keys` に追加する。オンボーディングの画面に、コピーできる 1 行のコマンドが表示される。パスワードや、貼り付けた秘密鍵でもログインできる。
+- **ペアリング:** マシンで `scripts/pair.sh` を実行する（qrencode のある devshell で）。スクリプトは iPhone 用の SSH の鍵を作り、`herdr-core connect` だけに使える鍵として `~/.ssh/authorized_keys` に登録し（`restrict,command=…`）、鍵・マシンのアドレス・host key を入れた QR コードを表示する。アプリでそれを読み取る（またはコードを貼る）。host key はコードから pin するので、fingerprint を見比べる手順は無い。マシンでは何も待ち受けず、常駐もしない。iPhone の登録を外すときは、その行を消す。
+- **ペアリングを使わないログイン:** アプリは Ed25519 の鍵を Keychain の中に生成する。その公開鍵をマシンの `~/.ssh/authorized_keys` に追加する。オンボーディングの画面に、コピーできる 1 行のコマンドが表示される。パスワードや、貼り付けた秘密鍵でもログインできる。
 - **host key:** 初回の接続では、アプリはログインの前に止まり、マシンの host key の fingerprint を表示する。user が承認すると、その host key を Keychain に pin する。
 - **ネットワーク:** マシンは iPhone から到達できる必要がある。たとえば Tailscale を経由する。
 - **Chat:** マシン上の Claude Code の transcript を、読み取り専用の短い `python3` スクリプトで読む。スクリプトは herdr-core の `machine.exec` を通して実行する。セッションは、terminal のプロセスツリーから `~/.claude/sessions` を介して特定する。transcript は末尾だけを読み、その後は新しく追加されたバイトだけを読む。そのため、大きな transcript でも負荷は小さい。 Codex では、terminal のプロセスが開いている rollout を読む。共有の app-server につながった Codex は rollout を開いていないので、terminal の title（thread の名前）とフォルダから、Codex の state のデータベースで thread を引く。起動したばかりの Codex は、最初のメッセージを送るまで rollout を持たない。
diff --git a/README.md b/README.md
index e9febdf..77376d6 100644
--- a/README.md
+++ b/README.md
@@ -41,7 +41,8 @@ A native iPhone and iPad client for [herdr](https://herdr.dev). See which of you
 
 The app opens an SSH exec channel to your machine and runs `herdr-core connect`. That's the same framed JSON-RPC stream the desktop app uses for remote machines (`ssh box hc connect`). Nothing else needs to be installed on the machine, and no server or relay is involved.
 
-- **Login:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
+- **Pairing:** on the box, run `scripts/pair.sh` (in the devshell, which has qrencode). It makes an SSH key for the phone, authorizes it in `~/.ssh/authorized_keys` for `herdr-core connect` only (`restrict,command=…`), and shows a QR code with the key, the box's address and its host key; scan it in the app (or paste the code). The host key is pinned from the code, so there is no fingerprint to compare, and nothing listens or keeps running on the box. Remove a phone by deleting its line.
+- **Login without pairing:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
 - **Host key:** on first connect the app stops before logging in and shows the box's host key fingerprint; it is pinned in the Keychain once you approve it.
 - **Network:** the box has to be reachable from the phone, for example over Tailscale.
 - **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
diff --git a/UITests/HerdrUITests.swift b/UITests/HerdrUITests.swift
index ea03a08..0f79411 100644
--- a/UITests/HerdrUITests.swift
+++ b/UITests/HerdrUITests.swift
@@ -69,6 +69,25 @@ final class HerdrUITests: XCTestCase {
         shot(app, "home-after-approval")
     }
 
+    /// Pairing: a fresh install pastes the code `scripts/pair.sh` printed ($HERDR_TEST_PAIR_CODE) and
+    /// reaches home with no host key prompt, since the code carries the host key.
+    /// Run after uninstalling the app and resetting the simulator keychain.
+    func testPairWithPastedCode() throws {
+        let code = try XCTUnwrap(ProcessInfo.processInfo.environment["HERDR_TEST_PAIR_CODE"])
+        let app = XCUIApplication()
+        app.launchEnvironment["HERDR_DEBUG_OBSERVE"] = "1"
+        app.launch()
+        let field = app.textFields["pairingCode"]
+        XCTAssertTrue(field.waitForExistence(timeout: 15), "no pairing field on first run")
+        field.tap()
+        field.typeText(code)
+        shot(app, "pairing-code")
+        app.buttons["Pair"].tap()
+        XCTAssertFalse(app.staticTexts["hostKeyFingerprint"].waitForExistence(timeout: 5), "asked for the host key despite the code")
+        XCTAssertTrue(app.buttons["New agent"].waitForExistence(timeout: 30), "did not reach home after pairing")
+        shot(app, "home-after-pairing")
+    }
+
     /// Files: from a space ($HERDR_TEST_SPACE) walk $HERDR_TEST_FILES_PATH (slash-separated folders
     /// under the space folder) and open each of $HERDR_TEST_FILES (comma-separated) in Quick Look.
     /// Needs a pinned host key (run testFirstConnectAsksForHostKey first).
diff --git a/docs/HANDOVER.md b/docs/HANDOVER.md
index 855f7c1..be857c4 100644
--- a/docs/HANDOVER.md
+++ b/docs/HANDOVER.md
@@ -76,6 +76,8 @@ All five targets are met on the simulator, and Codex chat was added as well. Eve
 
 ## Things on this Mac to undo when done
 
+- `~/.ssh/authorized_keys`: the line with comment `herdr-pocket-simulator-pair` (`restrict,command=…`), added by
+  running `scripts/pair.sh` for `testPairWithPastedCode`.
 - `~/.ssh/authorized_keys`: the last line, comment `herdr-pocket-simulator` (the key used by the UI
   tests). Its private key is `docs/private/sim_key` (gitignored); delete both together.
 - `~/.ssh/known_hosts`: entries for `127.0.0.1` and the Tailscale IP added while testing
diff --git a/nix/flake.nix b/nix/flake.nix
index 1dcbe4c..ae9215c 100644
--- a/nix/flake.nix
+++ b/nix/flake.nix
@@ -21,6 +21,7 @@
           default = pkgs.mkShellNoCC {
             packages = with pkgs; [
               xcodegen
+              qrencode   # scripts/pair.sh draws the pairing QR code
               bun
             ];
           };
diff --git a/project.yml b/project.yml
index e45d89f..a1252d9 100644
--- a/project.yml
+++ b/project.yml
@@ -48,6 +48,7 @@ targets:
         UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]
         UISupportedInterfaceOrientations~ipad: [UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]
         NSLocalNetworkUsageDescription: "Herdr connects to your machines over SSH on your network."
+        NSCameraUsageDescription: "Herdr scans the pairing code that scripts/pair.sh shows on your machine."
         UIAppFonts: [Geist-Regular.ttf, Geist-Medium.ttf, Geist-SemiBold.ttf, Geist-Bold.ttf, Geist-Italic.ttf, Geist-SemiBoldItalic.ttf, JetBrainsMono-Variable.ttf, JetBrainsMono-Italic-Variable.ttf, SymbolsNerdFont-Regular.ttf]
         ITSAppUsesNonExemptEncryption: false
     preBuildScripts:
diff --git a/scripts/pair.sh b/scripts/pair.sh
new file mode 100755
index 0000000..caa6e6b
--- /dev/null
+++ b/scripts/pair.sh
@@ -0,0 +1,52 @@
+#!/bin/sh
+# Pairs a phone with this box for herdr-pocket, on top of herdr-core's own remote path
+# (`ssh box herdr-core connect`): it makes an SSH key for the phone, authorizes it in
+# ~/.ssh/authorized_keys for `herdr-core connect` only, and shows a QR code holding the key,
+# this box's address and its host key. Scan it in the app (or paste the code). Nothing listens
+# on the network and nothing keeps running.
+#
+#   scripts/pair.sh [host] [name]
+#
+# host: the address the phone uses (default: this box's Tailscale IPv4, else its hostname).
+# name: a label for the key in authorized_keys (default: herdr-pocket-<date>).
+# Unpair a phone by deleting its line from ~/.ssh/authorized_keys.
+set -eu
+
+host="${1:-$(tailscale ip -4 2>/dev/null | head -n 1 || true)}"
+[ -n "$host" ] || host="$(hostname)"
+name="${2:-herdr-pocket-$(date +%Y%m%d-%H%M%S)}"
+user="$(id -un)"
+port=22
+
+core="$(command -v herdr-core || true)"
+[ -n "$core" ] || core="$HOME/.local/bin/herdr-core"
+[ -x "$core" ] || { echo "herdr-core is not installed here" >&2; exit 1; }
+case "$core" in *[!A-Za-z0-9/._-]*) echo "can't use herdr-core at $core (unusual characters in the path)" >&2; exit 1 ;; esac
+
+hostkey="$(awk '{print $1" "$2}' /etc/ssh/ssh_host_ed25519_key.pub)"
+
+if command -v qrencode >/dev/null 2>&1; then qr() { qrencode -t ansiutf8 -l M; }
+elif command -v nix >/dev/null 2>&1; then qr() { nix run nixpkgs#qrencode -- -t ansiutf8 -l M; }
+else echo "needs qrencode (or nix) to draw the QR code" >&2; exit 1; fi
+
+dir="$(mktemp -d)"
+trap 'rm -f "$dir/key" "$dir/key.pub"; rmdir "$dir"' EXIT
+ssh-keygen -q -t ed25519 -N "" -C "$name" -f "$dir/key"
+
+mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
+# restrict: no forwarding, agent or pty; command=: the key can only start herdr-core connect.
+printf 'restrict,command="%s connect" %s\n' "$core" "$(cat "$dir/key.pub")" >> "$HOME/.ssh/authorized_keys"
+chmod 600 "$HOME/.ssh/authorized_keys"
+
+json() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}' | sed 's/\\n$//'; }
+payload="{\"v\":1,\"host\":\"$(json "$host")\",\"port\":$port,\"user\":\"$(json "$user")\",\"hostKey\":\"$(json "$hostkey")\",\"key\":\"$(json "$(cat "$dir/key")")\"}"
+code="herdr-pair:$(printf '%s' "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')"
+
+if [ "${HERDR_PAIR_PRINT:-}" = 1 ]; then printf '%s\n' "$code"; exit 0; fi
+
+printf '%s' "$code" | qr
+echo "Scan this in herdr-pocket (Add machine → Scan pairing code) to reach $user@$host."
+echo "Authorized as \"$name\" in ~/.ssh/authorized_keys. Anyone who photographs this code can connect;"
+printf 'press Enter when the phone is paired to clear the screen. '
+read -r _ || true
+clear 2>/dev/null || printf '\033[2J\033[H'

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
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
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'nl -ba scripts/pair.sh; nl -ba Packages/HerdrKit/Sources/HerdrKit/Pairing.swift; nl -ba App/Sources/Net/KeyStore.swift; nl -ba App/Sources/Net/HostKeys.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	#!/bin/sh
     2	# Pairs a phone with this box for herdr-pocket, on top of herdr-core's own remote path
     3	# (`ssh box herdr-core connect`): it makes an SSH key for the phone, authorizes it in
     4	# ~/.ssh/authorized_keys for `herdr-core connect` only, and shows a QR code holding the key,
     5	# this box's address and its host key. Scan it in the app (or paste the code). Nothing listens
     6	# on the network and nothing keeps running.
     7	#
     8	#   scripts/pair.sh [host] [name]
     9	#
    10	# host: the address the phone uses (default: this box's Tailscale IPv4, else its hostname).
    11	# name: a label for the key in authorized_keys (default: herdr-pocket-<date>).
    12	# Unpair a phone by deleting its line from ~/.ssh/authorized_keys.
    13	set -eu
    14	
    15	host="${1:-$(tailscale ip -4 2>/dev/null | head -n 1 || true)}"
    16	[ -n "$host" ] || host="$(hostname)"
    17	name="${2:-herdr-pocket-$(date +%Y%m%d-%H%M%S)}"
    18	user="$(id -un)"
    19	port=22
    20	
    21	core="$(command -v herdr-core || true)"
    22	[ -n "$core" ] || core="$HOME/.local/bin/herdr-core"
    23	[ -x "$core" ] || { echo "herdr-core is not installed here" >&2; exit 1; }
    24	case "$core" in *[!A-Za-z0-9/._-]*) echo "can't use herdr-core at $core (unusual characters in the path)" >&2; exit 1 ;; esac
    25	
    26	hostkey="$(awk '{print $1" "$2}' /etc/ssh/ssh_host_ed25519_key.pub)"
    27	
    28	if command -v qrencode >/dev/null 2>&1; then qr() { qrencode -t ansiutf8 -l M; }
    29	elif command -v nix >/dev/null 2>&1; then qr() { nix run nixpkgs#qrencode -- -t ansiutf8 -l M; }
    30	else echo "needs qrencode (or nix) to draw the QR code" >&2; exit 1; fi
    31	
    32	dir="$(mktemp -d)"
    33	trap 'rm -f "$dir/key" "$dir/key.pub"; rmdir "$dir"' EXIT
    34	ssh-keygen -q -t ed25519 -N "" -C "$name" -f "$dir/key"
    35	
    36	mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    37	# restrict: no forwarding, agent or pty; command=: the key can only start herdr-core connect.
    38	printf 'restrict,command="%s connect" %s\n' "$core" "$(cat "$dir/key.pub")" >> "$HOME/.ssh/authorized_keys"
    39	chmod 600 "$HOME/.ssh/authorized_keys"
    40	
    41	json() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}' | sed 's/\\n$//'; }
    42	payload="{\"v\":1,\"host\":\"$(json "$host")\",\"port\":$port,\"user\":\"$(json "$user")\",\"hostKey\":\"$(json "$hostkey")\",\"key\":\"$(json "$(cat "$dir/key")")\"}"
    43	code="herdr-pair:$(printf '%s' "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')"
    44	
    45	if [ "${HERDR_PAIR_PRINT:-}" = 1 ]; then printf '%s\n' "$code"; exit 0; fi
    46	
    47	printf '%s' "$code" | qr
    48	echo "Scan this in herdr-pocket (Add machine → Scan pairing code) to reach $user@$host."
    49	echo "Authorized as \"$name\" in ~/.ssh/authorized_keys. Anyone who photographs this code can connect;"
    50	printf 'press Enter when the phone is paired to clear the screen. '
    51	read -r _ || true
    52	clear 2>/dev/null || printf '\033[2J\033[H'
     1	import Foundation
     2	
     3	/// What `scripts/pair.sh` puts in its QR code: everything a phone needs to reach `herdr-core connect`
     4	/// on a box over SSH. The box made the key pair and authorized the public half for that command only,
     5	/// so nothing goes back from the phone.
     6	///
     7	/// Text form: `herdr-pair:` + base64url(JSON `{"v":1,"host","port","user","hostKey","key"}`).
     8	public struct PairingOffer: Equatable, Sendable {
     9	    public var host: String
    10	    public var port: Int
    11	    public var user: String
    12	    /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
    13	    public var hostKey: String
    14	    /// The phone's private key, unencrypted OpenSSH text.
    15	    public var privateKey: String
    16	
    17	    public static let prefix = "herdr-pair:"
    18	
    19	    public init(host: String, port: Int, user: String, hostKey: String, privateKey: String) {
    20	        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.privateKey = privateKey
    21	    }
    22	
    23	    public struct Invalid: LocalizedError, Equatable {
    24	        public var reason: String
    25	        public var errorDescription: String? { "Not a herdr pairing code: \(reason)." }
    26	    }
    27	
    28	    public static func decode(_ text: String) throws -> PairingOffer {
    29	        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    30	        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
    31	        var b64 = String(s.dropFirst(prefix.count)).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    32	        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
    33	        guard let data = Data(base64Encoded: b64), let v = try? JSONValue.parse(data) else { throw Invalid(reason: "the code is damaged") }
    34	        guard v["v"].int == 1 else { throw Invalid(reason: "made by a newer pair.sh") }
    35	        guard let host = v["host"].string, !host.isEmpty, let user = v["user"].string, !user.isEmpty else {
    36	            throw Invalid(reason: "no host or user")
    37	        }
    38	        let port = v["port"].int ?? 22
    39	        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
    40	        guard let hostKey = v["hostKey"].string, hostKey.hasPrefix("ssh-"), hostKey.split(separator: " ").count == 2 else {
    41	            throw Invalid(reason: "no host key")
    42	        }
    43	        guard let key = v["key"].string, key.contains("BEGIN OPENSSH PRIVATE KEY") else { throw Invalid(reason: "no key") }
    44	        return PairingOffer(host: host, port: port, user: user, hostKey: hostKey, privateKey: key)
    45	    }
    46	}
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
    67	    /// A machine's own key, from pairing; nil when the machine uses the app key.
    68	    static func machineKey(for machine: UUID) throws -> Curve25519.Signing.PrivateKey? {
    69	        try read(account: "key." + machine.uuidString).map { try Curve25519.Signing.PrivateKey(rawRepresentation: $0) }
    70	    }
    71	
    72	    static func setMachineKey(_ key: Curve25519.Signing.PrivateKey?, for machine: UUID) throws {
    73	        let account = "key." + machine.uuidString
    74	        if let key { try write(key.rawRepresentation, account: account) } else { delete(account: account) }
    75	    }
    76	
    77	    static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
    78	        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    79	        guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
    80	            throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
    81	        }
    82	        do {
    83	            return try Curve25519.Signing.PrivateKey(sshEd25519: trimmed + "\n")
    84	        } catch {
    85	            throw KeyError.badKey("Couldn't read that key: only unencrypted ed25519 keys work (\(error))")
    86	        }
    87	    }
    88	
    89	    // MARK: Passwords
    90	
    91	    static func password(for machine: UUID) -> String? {
    92	        (try? read(account: "pw." + machine.uuidString)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    93	    }
    94	
    95	    static func setPassword(_ password: String?, for machine: UUID) {
    96	        let account = "pw." + machine.uuidString
    97	        if let password, !password.isEmpty {
    98	            try? write(Data(password.utf8), account: account)
    99	        } else {
   100	            delete(account: account)
   101	        }
   102	    }
   103	
   104	    // MARK: Host keys
   105	
   106	    /// nil only when nothing is pinned; a Keychain failure throws so it is never taken for a first connection.
   107	    static func hostKey(_ hostPort: String) throws -> String? {
   108	        try read(account: "hostkey." + hostPort).flatMap { String(data: $0, encoding: .utf8) }
   109	    }
   110	
   111	    static func setHostKey(_ line: String?, for hostPort: String) throws {
   112	        let account = "hostkey." + hostPort
   113	        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
   114	    }
   115	
   116	    // MARK: Keychain
   117	
   118	    private static func query(_ account: String) -> [String: Any] {
   119	        [kSecClass as String: kSecClassGenericPassword,
   120	         kSecAttrService as String: service,
   121	         kSecAttrAccount as String: account]
   122	    }
   123	
   124	    private static func read(account: String) throws -> Data? {
   125	        var q = query(account)
   126	        q[kSecReturnData as String] = true
   127	        q[kSecMatchLimit as String] = kSecMatchLimitOne
   128	        var out: CFTypeRef?
   129	        let status = SecItemCopyMatching(q as CFDictionary, &out)
   130	        if status == errSecItemNotFound { return nil }
   131	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
   132	        return out as? Data
   133	    }
   134	
   135	    /// Update in place, add only when missing: a failed write never loses the existing item.
   136	    private static func write(_ data: Data, account: String) throws {
   137	        let attrs: [String: Any] = [kSecValueData as String: data,
   138	                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
   139	        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
   140	        if status == errSecItemNotFound {
   141	            var q = query(account)
   142	            for (k, v) in attrs { q[k] = v }
   143	            status = SecItemAdd(q as CFDictionary, nil)
   144	        }
   145	        guard status == errSecSuccess else { throw KeyError.keychain(status) }
   146	    }
   147	
   148	    private static func delete(account: String) {
   149	        SecItemDelete(query(account) as CFDictionary)
   150	    }
   151	}
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

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg -n 'func (connect|saveMachine|removeMachine)|DEBUG|HERDR_|machineKey|pair\\(|HostKeys\\.|exec|command' App/Sources/Store/AppStore.swift App/Sources/Net/CitadelTransport.swift App/Sources/UI/ConnectionViews.swift; cat Packages/HerdrKit/Sources/HerdrKit/MachineConfig.swift; git diff 2f98a3b"'^ 2f98a3b -- Packages/HerdrKit/Tests README.md; git rev-parse HEAD; rg --files -g AGENTS.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 66ms:
App/Sources/UI/ConnectionViews.swift:114:                    Label(copied == "line" ? "Copied" : "Copy command", systemImage: copied == "line" ? "checkmark" : "terminal")
App/Sources/UI/ConnectionViews.swift:122:            Text("The command appends the key with the right permissions:")
App/Sources/UI/ConnectionViews.swift:141:    private func connect() {
App/Sources/UI/ConnectionViews.swift:377:            try store.pair(PairingOffer.decode(text))
App/Sources/Store/AppStore.swift:100:        #if DEBUG
App/Sources/Store/AppStore.swift:101:        if ProcessInfo.processInfo.environment["HERDR_DEBUG_AUTOCONNECT"] == "1", let m = currentMachine() {
App/Sources/Store/AppStore.swift:147:    func connect(to machine: MachineConfig) {
App/Sources/Store/AppStore.swift:172:    func saveMachine(_ m: MachineConfig, password: String?) {
App/Sources/Store/AppStore.swift:181:    func removeMachine(_ id: UUID) {
App/Sources/Store/AppStore.swift:191:        HostKeys.forget(host: m.host, port: m.port)
App/Sources/Store/AppStore.swift:204:    func pair(_ offer: PairingOffer) throws {
App/Sources/Store/AppStore.swift:209:        try HostKeys.pin(offer.hostKey, host: offer.host, port: offer.port)
App/Sources/Store/AppStore.swift:223:    func forgetHostKey(_ machine: MachineConfig) { HostKeys.forget(host: machine.host, port: machine.port) }
App/Sources/Store/AppStore.swift:226:    func hostKeyFingerprint(_ machine: MachineConfig) -> String? { HostKeys.pinnedFingerprint(host: machine.host, port: machine.port) }
App/Sources/Store/AppStore.swift:232:    private(set) var unknownHostKey: HostKeys.Unknown?
App/Sources/Store/AppStore.swift:235:    func trustHostKey(_ key: HostKeys.Unknown) {
App/Sources/Store/AppStore.swift:237:            try HostKeys.pin(key.line, host: key.host, port: key.port)
App/Sources/Store/AppStore.swift:327:        #if DEBUG
App/Sources/Store/AppStore.swift:329:        if ProcessInfo.processInfo.environment["HERDR_DEBUG_OBSERVE"] == "1" { observe = true }
App/Sources/Store/AppStore.swift:442:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
App/Sources/Store/AppStore.swift:443:        try await connectedClient().exec(argv: argv, cwd: cwd, on: on, timeout: timeout, input: input)
App/Sources/Store/AppStore.swift:472:    private func connectedClient() throws -> HerdrClient {
App/Sources/Store/AppStore.swift:503:            if m.usePassword, let pw = KeyStore.password(for: m.id) { auth = .password(pw) } else { auth = .key(try KeyStore.machineKey(for: m.id) ?? KeyStore.signingKey()) }
App/Sources/Store/AppStore.swift:543:        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return false }
App/Sources/Store/AppStore.swift:552:        hostKeyMismatch = error is HostKeys.Mismatch
App/Sources/Store/AppStore.swift:553:        unknownHostKey = error as? HostKeys.Unknown
App/Sources/Store/AppStore.swift:560:    private func connectionLost(_ error: HerdrError, gen: Int) {
App/Sources/Store/AppStore.swift:609:              let r = try? await c.exec(argv: ["sh", "-c", "printf %s \"$HOME\""], timeout: 10),
App/Sources/Store/AppStore.swift:769:            argvOut = ["sh", "-c", "\"$@\"; exec \"${SHELL:-sh}\" -i", "sh"] + argv
App/Sources/Net/CitadelTransport.swift:8:/// `ByteTransport` over an SSH exec channel (no PTY) running
App/Sources/Net/CitadelTransport.swift:40:                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
App/Sources/Net/CitadelTransport.swift:50:        // The exec channel lives in this task; `start` returns once stdin is writable.
App/Sources/Net/CitadelTransport.swift:110:        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return error }
cat: Packages/HerdrKit/Sources/HerdrKit/MachineConfig.swift: No such file or directory
diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
index 0760cda..3a7d291 100644
--- a/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
+++ b/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
@@ -334,3 +334,29 @@ final class AttentionTests: XCTestCase {
         XCTAssertEqual(now.display("t9"), .idle)               // first sighting
     }
 }
+
+final class PairingTests: XCTestCase {
+    private func code(_ obj: [String: Any]) -> String {
+        let data = try! JSONSerialization.data(withJSONObject: obj)
+        let b64 = data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
+            .replacingOccurrences(of: "=", with: "")
+        return PairingOffer.prefix + b64
+    }
+    private let key = "-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----\n"
+    private let hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqu"
+
+    func testDecodesWhatPairShPrints() throws {
+        let o = try PairingOffer.decode(code(["v": 1, "host": "100.64.0.9", "port": 2222, "user": "me", "hostKey": hostKey, "key": key]) + "\n")
+        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: hostKey, privateKey: key))
+    }
+
+    func testRejectsOtherTextAndIncompleteOffers() {
+        XCTAssertThrowsError(try PairingOffer.decode("orca://pair?code=abc"))
+        XCTAssertThrowsError(try PairingOffer.decode(PairingOffer.prefix + "!!!"))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "host": "h", "user": "u", "hostKey": hostKey, "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "", "user": "u", "hostKey": hostKey, "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "user": "u", "hostKey": "AAAA", "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "port": 0, "user": "u", "hostKey": hostKey, "key": key])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "user": "u", "hostKey": hostKey, "key": "nope"])))
+    }
+}
diff --git a/README.md b/README.md
index e9febdf..77376d6 100644
--- a/README.md
+++ b/README.md
@@ -41,7 +41,8 @@ A native iPhone and iPad client for [herdr](https://herdr.dev). See which of you
 
 The app opens an SSH exec channel to your machine and runs `herdr-core connect`. That's the same framed JSON-RPC stream the desktop app uses for remote machines (`ssh box hc connect`). Nothing else needs to be installed on the machine, and no server or relay is involved.
 
-- **Login:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
+- **Pairing:** on the box, run `scripts/pair.sh` (in the devshell, which has qrencode). It makes an SSH key for the phone, authorizes it in `~/.ssh/authorized_keys` for `herdr-core connect` only (`restrict,command=…`), and shows a QR code with the key, the box's address and its host key; scan it in the app (or paste the code). The host key is pinned from the code, so there is no fingerprint to compare, and nothing listens or keeps running on the box. Remove a phone by deleting its line.
+- **Login without pairing:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
 - **Host key:** on first connect the app stops before logging in and shows the box's host key fingerprint; it is pinned in the Keychain once you approve it.
 - **Network:** the box has to be reachable from the phone, for example over Tailscale.
 - **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
2f98a3b60fc6ea46722999793f1cfebfa929e35c
AGENTS.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '1,250p' App/Sources/Store/AppStore.swift; sed -n '475,545p' App/Sources/Store/AppStore.swift; nl -ba App/Sources/Net/CitadelTransport.swift | head -n 115; nl -ba App/Sources/UI/ConnectionViews.swift | head -n 165; rg -n 'struct MachineConfig|HERDR_DEBUG_KEY_PATH|regenerateKey|importPrivateKey|shell|machine.exec' App README.md docs/HANDOVER.md Packages/HerdrKit/Sources/HerdrKit" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 240ms:
import SwiftUI
import UIKit
import HerdrKit

/// Where to connect. Persisted in UserDefaults (the key lives in the Keychain).
struct MachineConfig: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String = ""
    var host: String = ""
    var port: Int = 22
    var user: String = ""
    /// Optional password; nil = use the app's Ed25519 key.
    var usePassword: Bool = false
}

enum ConnectionPhase: Equatable {
    case idle
    case connecting(String)            // human step: "Opening SSH", "Saying hello"...
    case connected
    case failed(String)                // message shown to the user, with retry
}

/// One agent row in the agents list.
struct AgentRow: Identifiable, Hashable {
    var id: String { address }
    var address: String
    var label: String                  // Names: agent row label
    var program: String?               // "claude", "codex", "shell", ...
    var attention: Attention
    var spaceID: String?
    var tabID: String?
    var parent: String?                // sub-agents are nested under parent
    var since: Date?
}

@MainActor
@Observable
final class AppStore {
    // MARK: Connection
    var machines: [MachineConfig] = [] { didSet { persistMachines() } }
    var activeMachineID: UUID? { didSet { persistMachines() } }
    var phase: ConnectionPhase = .idle
    var hello: HelloInfo?
    /// Last stderr from the remote, for the failure screen.
    var diagnostics: String = ""

    // MARK: Live state
    var terminals: [String: TerminalRecord] = [:]
    var doc: LayoutDoc = LayoutDoc(value: .null, version: 0)
    var spaces: [SpaceRef] = []
    /// Remote $HOME, learned at connect (for names).
    var home: String = "~"

    // MARK: Per-device view state
    var selectedSpaceID: String? { didSet { persistView() } }
    var selectedTabBySpace: [String: String] = [:] { didSet { persistView() } }
    /// Terminal screen currently on screen (marks it seen).
    var visibleTerminal: String? { didSet { if let v = visibleTerminal { markSeen(v) } } }

    /// Toasts (in-app notifications; mods' notify() lands here too).
    struct Toast: Identifiable, Equatable {
        var id = UUID(); var title: String; var body: String?; var level: String = "info"
        /// Terminal the toast is about: tapping it opens that terminal.
        var address: String? = nil
            /// Seconds on screen; nil = the level's default.
        var duration: Double? = nil
    }
    var toasts: [Toast] = []
    /// A terminal the UI should open (tapped alert); the navigator clears it.
    var pendingOpen: String?

    /// Attention words and seen state, persisted per machine.
    private(set) var attentionState = AttentionTracker()

    // MARK: Private connection state
    @ObservationIgnored private var client: HerdrClient?
    @ObservationIgnored private var subscription: EventSubscription?
    /// Bumped per connection attempt; callbacks from older ones are dropped.
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var connectTask: Task<Void, Never>?
    @ObservationIgnored private var reconnectTask: Task<Void, Never>?
    @ObservationIgnored private var backgroundTask: Task<Void, Never>?
    @ObservationIgnored private var attempt = 0
    /// The person wants to be connected (false after an explicit disconnect).
    @ObservationIgnored private var wantConnected = false
    @ObservationIgnored private var sceneActive = true
    /// Skip alerts until the first snapshot after a connect has been absorbed.
    @ObservationIgnored private var alertsArmed = false
    @ObservationIgnored private var docRefresh: Task<Void, Never>?
    @ObservationIgnored private var docRefreshAgain = false
    @ObservationIgnored private var docGeneration = -1
    @ObservationIgnored private var saveAttentionTask: Task<Void, Never>?
    @ObservationIgnored private var restoringView = false
    @ObservationIgnored private var cachedPublicKey: String?
    private let defaults = UserDefaults.standard

    init() {
        loadMachines()
        loadMachineState()
        #if DEBUG
        if ProcessInfo.processInfo.environment["HERDR_DEBUG_AUTOCONNECT"] == "1", let m = currentMachine() {
            connect(to: m)
        }
        #endif
    }

    // MARK: Lifecycle

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            sceneActive = true
            backgroundTask?.cancel(); backgroundTask = nil
            markSeenVisible()
            guard wantConnected, let m = currentMachine() else { return }
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
        try? KeyStore.setMachineKey(nil, for: id)
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

    /// Adds the machine a `scripts/pair.sh` code describes, with its own key and its host key pinned, and connects.
    func pair(_ offer: PairingOffer) throws {
        let key = try KeyStore.parseOpenSSH(offer.privateKey)
        let m = machines.first { $0.host == offer.host && $0.port == offer.port && $0.user == offer.user }
            ?? MachineConfig(label: offer.host, host: offer.host, port: offer.port, user: offer.user)
        try KeyStore.setMachineKey(key, for: m.id)
        try HostKeys.pin(offer.hostKey, host: offer.host, port: offer.port)
        var saved = m
        saved.usePassword = false
        saveMachine(saved, password: nil)
        connect(to: saved)
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
        }
        return client
    }

    private func startConnect(_ m: MachineConfig, reconnecting: Bool) {
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
            if m.usePassword, let pw = KeyStore.password(for: m.id) { auth = .password(pw) } else { auth = .key(try KeyStore.machineKey(for: m.id) ?? KeyStore.signingKey()) }
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
     1	import Foundation
     2	import HerdrKit
     3	import Citadel
     4	import Crypto
     5	import NIOCore
     6	import NIOSSH
     7	
     8	/// `ByteTransport` over an SSH exec channel (no PTY) running
     9	/// `herdrConnectCommand`, via Citadel.
    10	final class CitadelTransport: ByteTransport, @unchecked Sendable {
    11	    enum Auth {
    12	        case key(Curve25519.Signing.PrivateKey)
    13	        case password(String)
    14	    }
    15	
    16	    let host: String, port: Int, user: String
    17	    private let auth: Auth
    18	    private let lock = NSLock()
    19	    private var client: SSHClient?
    20	    private var writer: TTYStdinWriter?
    21	    private var task: Task<Void, Never>?
    22	    private var closed = false
    23	    private var onClose: (@Sendable (Error?) -> Void)?
    24	
    25	    init(host: String, port: Int, user: String, auth: Auth) {
    26	        self.host = host; self.port = port; self.user = user; self.auth = auth
    27	    }
    28	
    29	    func start(onBytes: @escaping @Sendable (Data) -> Void,
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
    53	            let t = Task.detached { [weak self] in
    54	                var failure: Error?
    55	                do {
    56	                    try await client.withExec(herdrConnectCommand) { inbound, outbound in
    57	                        self?.lock.withLock { self?.writer = outbound }
    58	                        readyOnce.resume(.success(()))
    59	                        for try await out in inbound {
    60	                            switch out {
    61	                            case .stdout(let b): onBytes(Data(b.readableBytesView))
    62	                            case .stderr(let b): onStderr(Data(b.readableBytesView))
    63	                            }
    64	                        }
    65	                    }
    66	                } catch let e as SSHClient.CommandFailed where e.exitCode == 127 {
    67	                    failure = HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine",
    68	                                         hint: "install herdr-core in ~/.local/bin")
    69	                } catch is CancellationError {
    70	                } catch {
    71	                    failure = error
    72	                }
    73	                readyOnce.resume(.failure(failure ?? HerdrError.lost))
    74	                self?.finish(failure)
    75	            }
    76	            lock.withLock { task = t }
    77	        }
    78	    }
    79	
    80	    func write(_ data: Data) async throws {
    81	        guard let w = lock.withLock({ closed ? nil : writer }) else { throw HerdrError.lost }
    82	        try await w.write(ByteBuffer(bytes: data))
    83	    }
    84	
    85	    func close() {
    86	        let (t, c, cb): (Task<Void, Never>?, SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
    87	            guard !closed else { return (nil, nil, nil) }
    88	            closed = true
    89	            defer { onClose = nil; writer = nil }
    90	            return (task, client, onClose)
    91	        }
    92	        t?.cancel()
    93	        if let c { Task.detached { try? await c.close() } }
    94	        cb?(nil)
    95	    }
    96	
    97	    private func finish(_ err: Error?) {
    98	        let (c, cb): (SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
    99	            guard !closed else { return (nil, nil) }
   100	            closed = true
   101	            defer { onClose = nil; writer = nil }
   102	            return (client, onClose)
   103	        }
   104	        if let c { Task.detached { try? await c.close() } }
   105	        cb?(err)
   106	    }
   107	
   108	    /// SSH failures in words a person can act on.
   109	    static func friendly(_ error: Error, host: String, user: String) -> Error {
   110	        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return error }
   111	        if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
   112	            return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
   113	                              hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
   114	        }
   115	        let text = String(describing: error)
     1	import SwiftUI
     2	import HerdrKit
     3	import VisionKit
     4	
     5	// MARK: Onboarding
     6	
     7	struct OnboardingView: View {
     8	    @Environment(AppStore.self) private var store
     9	
    10	    var body: some View {
    11	        NavigationStack {
    12	            ScrollView {
    13	                VStack(spacing: 22) {
    14	                    VStack(spacing: 12) {
    15	                        Image("HerdrMark").resizable().frame(width: 64, height: 64)
    16	                            .clipShape(.rect(cornerRadius: 15))
    17	                        Text("Herdr").font(HF.ui(30, .semibold, relativeTo: .largeTitle)).foregroundStyle(HC.fg)
    18	                        Text("Your agents and terminals, from your pocket.\nConnect to a machine running herdr-core.")
    19	                            .font(HF.ui(15)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
    20	                    }
    21	                    .padding(.top, 24)
    22	
    23	                    MachineForm(machine: store.machines.first ?? MachineConfig(), isFirstRun: true)
    24	                }
    25	                .padding(.horizontal, 18)
    26	                .padding(.bottom, 40)
    27	                .frame(maxWidth: 560)
    28	                .frame(maxWidth: .infinity)
    29	            }
    30	            .scrollDismissesKeyboard(.interactively)
    31	            .background(HC.canvas)
    32	        }
    33	    }
    34	}
    35	
    36	/// Add / edit a machine. Shows the app's public key with a copyable install line.
    37	struct MachineForm: View {
    38	    @Environment(AppStore.self) private var store
    39	    @Environment(\.dismiss) private var dismiss
    40	    @State var machine: MachineConfig
    41	    var isFirstRun = false
    42	    @State private var password = ""
    43	    @State private var portText = ""
    44	    @State private var copied: String?
    45	
    46	    var body: some View {
    47	        VStack(alignment: .leading, spacing: 0) {
    48	            if machine.host.isEmpty { PairingCard() }
    49	            SectionLabel(title: "Machine")
    50	            VStack(spacing: 0) {
    51	                field("Name", text: $machine.label, prompt: "my-box")
    52	                divider
    53	                field("Host", text: $machine.host, prompt: "100.x.y.z or my-box.local", keyboard: .URL)
    54	                divider
    55	                field("Port", text: $portText, prompt: "22", keyboard: .numberPad)
    56	                divider
    57	                field("User", text: $machine.user, prompt: "username")
    58	                divider
    59	                Toggle(isOn: $machine.usePassword.animation(.smooth)) {
    60	                    Text("Use a password").font(HF.ui(15.5)).foregroundStyle(HC.fg)
    61	                }
    62	                .padding(.horizontal, 14).frame(minHeight: HM.rowHeight)
    63	                if machine.usePassword {
    64	                    divider
    65	                    HStack {
    66	                        Text("Password").font(HF.ui(15.5)).foregroundStyle(HC.muted).frame(width: 84, alignment: .leading)
    67	                        SecureField("Stored in the Keychain", text: $password)
    68	                            .font(HF.ui(15.5)).textContentType(.password)
    69	                    }
    70	                    .padding(.horizontal, 14).frame(minHeight: HM.rowHeight)
    71	                }
    72	            }
    73	            .herdrCard()
    74	
    75	            if !machine.usePassword { keySection }
    76	
    77	            Button(action: connect) {
    78	                Text(isFirstRun ? "Connect" : "Save and connect")
    79	                    .font(HF.ui(16.5, .semibold))
    80	                    .frame(maxWidth: .infinity)
    81	                    .padding(.vertical, 6)
    82	            }
    83	            .buttonStyle(.glassProminent)
    84	            .controlSize(.large)
    85	            .disabled(machine.host.trimmingCharacters(in: .whitespaces).isEmpty || machine.user.isEmpty)
    86	            .padding(.top, 22)
    87	        }
    88	        .onAppear { portText = String(machine.port) }
    89	    }
    90	
    91	    @ViewBuilder private var keySection: some View {
    92	        let key = store.publicKeyLine()
    93	        SectionLabel(title: "This device's key")
    94	        VStack(alignment: .leading, spacing: 12) {
    95	            Text("Add this line to ~/.ssh/authorized_keys on \(machine.label.isEmpty ? "the machine" : machine.label):")
    96	                .font(HF.ui(14)).foregroundStyle(HC.muted)
    97	            Text(key.isEmpty ? "Generating key…" : key)
    98	                .font(HF.mono(11.5))
    99	                .foregroundStyle(HC.fg)
   100	                .textSelection(.enabled)
   101	                .lineLimit(4)
   102	                .padding(10)
   103	                .frame(maxWidth: .infinity, alignment: .leading)
   104	                .background(HC.canvas, in: .rect(cornerRadius: 8))
   105	            HStack(spacing: 10) {
   106	                Button {
   107	                    copy(key, as: "key")
   108	                } label: {
   109	                    Label(copied == "key" ? "Copied" : "Copy key", systemImage: copied == "key" ? "checkmark" : "doc.on.doc")
   110	                }
   111	                Button {
   112	                    copy(installLine(key), as: "line")
   113	                } label: {
   114	                    Label(copied == "line" ? "Copied" : "Copy command", systemImage: copied == "line" ? "checkmark" : "terminal")
   115	                }
   116	                Spacer(minLength: 0)
   117	                ShareLink(item: key) { Image(systemName: "square.and.arrow.up") }
   118	            }
   119	            .buttonStyle(.glass)
   120	            .font(HF.ui(14, .medium))
   121	            .disabled(key.isEmpty)
   122	            Text("The command appends the key with the right permissions:")
   123	                .font(HF.ui(12.5)).foregroundStyle(HC.dim)
   124	            Text(installLine(key.isEmpty ? "ssh-ed25519 AAAA… herdr-ios" : key))
   125	                .font(HF.mono(10.5)).foregroundStyle(HC.muted).lineLimit(3).textSelection(.enabled)
   126	        }
   127	        .padding(14)
   128	        .herdrCard()
   129	    }
   130	
   131	    private func installLine(_ key: String) -> String {
   132	        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '\(key)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   133	    }
   134	
   135	    private func copy(_ s: String, as tag: String) {
   136	        UIPasteboard.general.string = s
   137	        withAnimation { copied = tag }
   138	        Task { try? await Task.sleep(for: .seconds(2)); withAnimation { if copied == tag { copied = nil } } }
   139	    }
   140	
   141	    private func connect() {
   142	        var m = machine
   143	        m.host = m.host.trimmingCharacters(in: .whitespaces)
   144	        m.user = m.user.trimmingCharacters(in: .whitespaces)
   145	        if m.label.trimmingCharacters(in: .whitespaces).isEmpty { m.label = m.host }
   146	        m.port = Int(portText) ?? 22
   147	        store.saveMachine(m, password: m.usePassword && !password.isEmpty ? password : nil)
   148	        store.connect(to: m)
   149	        dismiss()
   150	    }
   151	
   152	    private var divider: some View {
   153	        Rectangle().fill(HC.border).frame(height: HM.hairline).padding(.leading, 14)
   154	    }
   155	
   156	    private func field(_ label: String, text: Binding<String>, prompt: String, keyboard: UIKeyboardType = .default) -> some View {
   157	        HStack {
   158	            Text(label).font(HF.ui(15.5)).foregroundStyle(HC.muted).frame(width: 84, alignment: .leading)
   159	            TextField(prompt, text: text)
   160	                .font(HF.ui(15.5))
   161	                .foregroundStyle(HC.fg)
   162	                .keyboardType(keyboard)
   163	                .textInputAutocapitalization(.never)
   164	                .autocorrectionDisabled()
   165	        }
README.md:35:- **New agents.** Start Claude Code, Codex, a shell or any program from herdr's list, in an existing space or a new folder, with an optional first task.
README.md:44:- **Pairing:** on the box, run `scripts/pair.sh` (in the devshell, which has qrencode). It makes an SSH key for the phone, authorizes it in `~/.ssh/authorized_keys` for `herdr-core connect` only (`restrict,command=…`), and shows a QR code with the key, the box's address and its host key; scan it in the app (or paste the code). The host key is pinned from the code, so there is no fingerprint to compare, and nothing listens or keeps running on the box. Remove a phone by deleting its line.
README.md:48:- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
README.md:65:The key stays on your machine in `~/.config/herdr-ios`, readable only by you. Sub-agents and plain shells don't notify, and you can tune what does in `~/.config/herdr-ios/notify.json` (`{"on": ["blocked", "done"]}`).
README.md:125:- **UI:** run the `HerdrUITests` target against a real box in watch-only mode. Pass settings to the test runner with the `TEST_RUNNER_` prefix (e.g. `TEST_RUNNER_HERDR_DEBUG_KEY_PATH`): `HERDR_DEBUG_KEY_PATH` always; `HERDR_TEST_HOST`, `HERDR_TEST_USER`, `HERDR_TEST_HOST_FP` for first-connect approval; `HERDR_TEST_SPACE`, `HERDR_TEST_FILES_PATH`, `HERDR_TEST_FILES` for Files; `HERDR_TEST_TERMINAL` for Chat.
docs/HANDOVER.md:13:   translations, nix devshell (`.envrc`, `nix/flake.nix`), Xcode MCP (`.mcp.json`).
docs/HANDOVER.md:32:  translations, devshell (`nix develop ./nix` gives XcodeGen 2.44.1 and bun 1.3.13; Swift comes
docs/HANDOVER.md:52:  a space's toolbar. Lists and reads with python3 on the box, 4,000,000 bytes per machine.exec (the core
docs/HANDOVER.md:97:export TEST_RUNNER_HERDR_DEBUG_KEY_PATH=$PWD/docs/private/sim_key
App/Sources/Store/AppStore.swift:6:struct MachineConfig: Codable, Hashable, Identifiable {
App/Sources/Store/AppStore.swift:28:    var program: String?               // "claude", "codex", "shell", ...
App/Sources/Store/AppStore.swift:217:    func importPrivateKey(_ text: String) throws {
App/Sources/Store/AppStore.swift:218:        try KeyStore.importPrivateKey(text)
App/Sources/Store/AppStore.swift:765:    /// person's shell wrapper so the shell takes over when they exit.
App/Sources/Chat/CodexTranscriptScript.swift:102:def shell(cmd):
App/Sources/Chat/CodexTranscriptScript.swift:143:        cmd = shell(i.get('command'))
App/Sources/Net/KeyStore.swift:26:        if let path = ProcessInfo.processInfo.environment["HERDR_DEBUG_KEY_PATH"], !path.isEmpty {
App/Sources/Net/KeyStore.swift:57:    static func importPrivateKey(_ openSSHText: String) throws {
App/Sources/Net/KeyStore.swift:63:    static func regenerateKey() throws {
App/Sources/UI/ChangesView.swift:5:/// Runs the box's git through machine.exec, read-only.
App/Sources/UI/ChangesView.swift:52:    /// The space folder as an absolute path: argv reaches git without a shell, so "~" is not expanded.
App/Sources/UI/Components.swift:110:        let info = ProgramCatalog.info(program) ?? ProgramCatalog.info(program == nil ? "shell" : "program")
App/Sources/UI/Components.swift:286:    static let shells: Set<String> = ["zsh", "bash", "fish", "sh", "dash", "nu", "pwsh", "powershell", "cmd", "elvish", "xonsh", "tcsh", "csh", "ksh", "ion"]
App/Sources/UI/Components.swift:302:        if a.count > 4, shells.contains(base(a[0])), a[1] == "-c", a[2].contains("\"$@\"") {
App/Sources/UI/Components.swift:306:        if a.count >= 3, shells.contains(base(a[0])), a[1].hasPrefix("-"), a[1].contains("c") {
App/Sources/UI/Components.swift:311:        if shells.contains(b) { return "shell" }
App/Sources/UI/Programs.swift:21:    static let order: [String] = ["claude", "codex", "pi", "opencode", "cursor", "copilot", "amp", "grok", "antigravity", "kimi", "kiro", "hermes", "mastracode", "qoder", "muse", "crush", "command-code", "prime-agent", "gemini", "ollama", "agent", "shell", "program", "vim", "nvim", "hx", "emacs", "nano", "less", "lazygit", "git", "gh", "glab", "htop", "ssh", "tmux", "rg", "curl", "ffmpeg", "make", "cmake", "jupyter", "node", "bun", "deno", "python", "uv", "poetry", "ruby", "go", "cargo", "java", "gradle", "mvn", "dotnet", "php", "composer", "iex", "erl", "ghci", "ocaml", "zig", "swift", "kotlin", "scala", "lua", "perl", "R", "julia", "dart", "flutter", "tsc", "npm", "pnpm", "yarn", "vite", "next", "astro", "nuxt", "turbo", "webpack", "esbuild", "vitest", "jest", "pytest", "eslint", "prettier", "biome", "ruff", "expo", "tauri", "electron", "prisma", "supabase", "django-admin", "flask", "fastapi", "psql", "mysql", "sqlite3", "redis-cli", "mongosh", "docker", "podman", "kubectl", "helm", "terraform", "ansible", "gcloud", "vercel", "netlify", "wrangler", "fly", "caddy", "nginx", "nix", "brew", "apt", "dnf", "pacman"]
App/Sources/UI/Programs.swift:45:        "shell": .init(key: "shell", name: "Shell", run: nil, tint: true, isAgent: false),
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:16:        /// Table key ("claude", "shell", "program", ...); also the icon name (`icons/<key>.svg`).
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:50:            if let e = find(app) { return shown(e, name: nil, shell: false, agent: true) }
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:51:            return shown(entry("agent"), name: app, shell: false, agent: true)
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:54:        if argv.count > 4, shells.contains(base(argv[0])), argv[1].hasPrefix("-"), argv[1].hasSuffix("c"),
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:58:        guard let firstArg = argv.first else { return shown(entry("shell"), name: nil, shell: true, agent: false) }
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:64:                if let e = find(stem), !interpreters.contains(e.key) { return shown(e, name: nil, shell: false, agent: false) }
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:67:        if let e = find(first) { return shown(e, name: nil, shell: false, agent: false) }
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:68:        if shells.contains(first) { return shown(entry("shell"), name: first, shell: true, agent: false) }
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:71:        return shown(e, name: first, shell: false, agent: false)
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:87:    private static func shown(_ e: Entry, name: String?, shell: Bool, agent: Bool) -> Program {
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:88:        Program(key: e.key, name: name ?? e.name, tile: e.tile, color: e.color, tint: e.tint, isShell: shell, isAgent: agent)
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:67:    /// Status word from OSC 7501 ("working", "blocked", "done", "idle", "error", ...); nil = plain shell.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:30:                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:218:    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
Packages/HerdrKit/Sources/HerdrKit/ProgramTable.swift:5:    static let shells: Set<String> = ["zsh", "bash", "fish", "sh", "dash", "nu", "pwsh", "powershell", "cmd", "elvish", "xonsh", "tcsh", "csh", "ksh", "ion"]
Packages/HerdrKit/Sources/HerdrKit/ProgramTable.swift:30:        Entry(key: "shell", name: "Shell", match: [], tile: "#16241a", color: "#4ec95f", tint: true),
Packages/HerdrKit/Sources/HerdrKit/ProgramTable.swift:60:        Entry(key: "java", name: "Java", match: ["javac", "jshell"], tile: "#1c1d21", color: "#ffffff", tint: true),
Packages/HerdrKit/Sources/HerdrKit/ProgramTable.swift:124:        Entry(key: "nix", name: "Nix", match: ["nix-shell", "nixos-rebuild"], tile: "#5277c3", color: "#ffffff", tint: true),
App/Sources/UI/NewAgentSheet.swift:4:/// Start an agent (or shell): pick program, where, optional first task.
App/Sources/UI/NewAgentSheet.swift:23:    private static let featured = ["claude", "codex", "shell"]
App/Sources/UI/NewAgentSheet.swift:33:                    if program != "shell" {
App/Sources/UI/NewAgentSheet.swift:102:                            Text(p.key == "shell" ? "Shell" : p.name)
App/Sources/UI/NewAgentSheet.swift:183:        let t: String? = program == "shell" || taskText.isEmpty ? nil : taskText
App/Sources/UI/FilesView.swift:35:    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
App/Resources/Assets.xcassets/Programs/prog-shell.imageset/Contents.json:4:      "filename": "shell.svg",

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "cat /Users/yosuke/workspace/github.com/YosukeIida/knowledge/herdr-app-core-vs-tui.md; rg --files scripts; command -v shellcheck; command -v swift; command -v ssh-keygen; nl -ba README.md | sed -n '37,58p'; nl -ba App/Sources/Store/AppStore.swift | sed -n '145,222p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 153ms:
---
type: Concept
title: 'Herdr app・herdr-core と Herdr TUI は agent を共有しない別製品で、TUI のサーバから core へは移せない'
description: 'herdr-core（hc）は画面を持たない端末の常駐サーバで、Herdr app はその client。TUI のサーバとは別物で、動いている agent を移す手段は無い。core は hc update でも端末を落とさず、子の agent の起動と報告を持つが、Orca の Run のような帳簿は無い'
aliases: 'herdr-core, hc, Herdr app, herdr-app, Herdr TUI, herdr server, OSC 7501, Program Status Protocol, releases.herdr.dev'
sources:
  - resource: https://herdr.dev/
    title: Herdr app の公式サイト（FAQ に TUI との違い）
  - resource: https://github.com/herdrdev/herdr-core
    title: herdr-core の README（0.1.14）と docs/commands.md・docs/templates.md
  - resource: https://github.com/herdrdev/herdr-app
    title: Herdr app の README
  - resource: transcript:86c2b965-0f5b-46c8-9d33-927c92838a84#L329-L329
    title: 配布物の署名と、app が herdr-core を探す場所の確認
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-31T23:30:00+09:00 }
status: draft
---

2026-10-29 に、herdr-core と、その上で動く Herdr app（デスクトップアプリ）が出た。従来の Herdr TUI（`herdr`、自前のサーバ）とは**別の製品**で、agent を共有しない。TUI で動いている agent は app から見えず、TUI のサーバの端末を core に移す手段も無い。移行で移せるのはワークスペースのフォルダだけで、agent は `claude --resume` などで起こし直す。TUI は今後も更新されるが、core の上に移る予定は示されていない。

herdr-core の性質:

- 画面を持たない（"Core draws nothing"）。`hc` の CLI と、OpenRPC の API（`hc schema`、`hc connect` は SSH 越しも可）だけを持つ。Herdr app はその client の 1 つで、Herdr TUI からはつなげない。端末からは `hc ls`・`hc attach <t>`（Ctrl+\ で離れる）・`hc read` で使える
- `hc update` で core を更新しても端末は落ちない。端末を保持するプロセスが core とは別にある。TUI のサーバの再起動は全ペインを終わらせる点が違う。機体の再起動では中のプログラムは止まり、シェルだけが同じフォルダで戻る
- agent が agent を起こす仕組みを持つ。`hc run --bg --name <n> <テンプレート> "<タスク>"` で子を起こし、`hc send` で渡し、`hc wait --children any|all` で待つ。子が止まる・終わると core が親の入力欄に知らせを書く。既定では親が終わると子も終わる（`--no-parent`・`--outlive-parent` で外す）。席は `~/.config/herdr-core/templates/<名前>.md` の `command`（kind・model・アカウントを含む起動コマンド）で定義する。Orca の orchestration の Run・Task・依存関係・ask/reply にあたる帳簿は無い
- agent の状態は、画面の読み取りではなく OSC 7501（Program Status Protocol）の報告だけで決める。Claude Code は 2.1.295 から送る。Codex は 2026-10-09 に main に入った。対応していない agent は状態が出ない
- `hc machine add` で SSH の機体を足すと、その機体の core の端末が同じ一覧に並ぶ。Herdr app は相手に core が無ければ入れ、場所は `command -v herdr-core` か `~/.local/bin/herdr-core` で探す

配布と署名（2026-10-31 時点、app 0.1.10・core 0.1.15）:

- nixpkgs・Homebrew・公式の tap・flake のどれにも無い。配布は `releases.herdr.dev/{app,core}/latest.json`（版・url・sha256 の manifest）と install.sh だけで、install.sh は `~/Applications` と `~/.local/bin` に入れる。パッケージマネージャで入れた core には手を出さない
- Herdr.app は Developer ID（Herdr, Inc.、Team 2W9652Q7QR）で署名され、bundle ID は `dev.herdr.app`。herdr-core は ad-hoc 署名なので、TCC の FDA は更新のたびに外れる見込みである（[Orca や herdr の中の CLI agent の FDA](./macos-fda-for-cli-agents-orca-vs-herdr.md) と同じ理由）
- app は core を PATH・login shell の PATH・`~/.local/bin`・Homebrew・mise・Nix の順の候補から探す。設定は `~/.config/herdr-app/`（AGENTS.md・settings.json・keys.json・layouts/・mods/・themes/）で、テレメトリは既定で有効（`"telemetry": false`、`HERDR_TELEMETRY=0`）
- 公式のモバイル client は無い。サードパーティの herdr-mobile などは TUI のサーバ向けである

前提: Herdr app 0.1.9〜0.1.10、herdr-core 0.1.14〜0.1.15、Herdr TUI 0.9.5、2026-10-29〜31 の公式サイトと README。Herdr app と hc の実機での動作（席を起こす・報告を受け取る）は、この時点では確かめていない。

## Yosuke の判断

- 2026-10-31: Herdr TUI のサーバを常駐から外し、Herdr app と herdr-core を試すことにした。入れ方は自前の tap（experience の own-tap-cask-for-installer-only-tools）で、Herdr app は cask、herdr-core は同日に cask から formula に移した
scripts/mods-test/main.swift
scripts/mods-test/run.sh
scripts/mods-transform.mjs
scripts/bundle-mods.sh
scripts/pair.sh
scripts/install-notifier.sh
/usr/bin/swift
/usr/bin/ssh-keygen
    37	- **Mods.** Your own herdr mods run on the phone. A small JavaScriptCore host implements the `herdr`, `gpui-kit` and `gpui-base` APIs they use and draws their element trees in SwiftUI. Their `exec` calls run on the box, except `open` and clipboard writes (`pbcopy`), which the phone handles itself.
    38	- **herdr's look.** It uses the Graphite and Paper themes, Geist and JetBrains Mono, and herdr's status marks, with iOS 26 Liquid Glass on the chrome only.
    39	
    40	## How it connects
    41	
    42	The app opens an SSH exec channel to your machine and runs `herdr-core connect`. That's the same framed JSON-RPC stream the desktop app uses for remote machines (`ssh box hc connect`). Nothing else needs to be installed on the machine, and no server or relay is involved.
    43	
    44	- **Pairing:** on the box, run `scripts/pair.sh` (in the devshell, which has qrencode). It makes an SSH key for the phone, authorizes it in `~/.ssh/authorized_keys` for `herdr-core connect` only (`restrict,command=…`), and shows a QR code with the key, the box's address and its host key; scan it in the app (or paste the code). The host key is pinned from the code, so there is no fingerprint to compare, and nothing listens or keeps running on the box. Remove a phone by deleting its line.
    45	- **Login without pairing:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
    46	- **Host key:** on first connect the app stops before logging in and shows the box's host key fingerprint; it is pinned in the Keychain once you approve it.
    47	- **Network:** the box has to be reachable from the phone, for example over Tailscale.
    48	- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
    49	- **Opening Chat** never attaches to the terminal, so it doesn't resize anything on your desktop.
    50	
    51	## Notifications
    52	
    53	iOS closes the app's SSH connection in the background, so the phone can't see an agent start waiting. Your machine sends the notification instead:
    54	- **The notifier:** `herdr-notify` is a short Python script running as a service: a launchd agent (`dev.herdr.notify`) on macOS, a systemd user service on Linux, or nohup where neither exists. It follows `hc events` and, when an agent becomes blocked or finishes a turn, pushes to Apple over HTTP/2 with your APNs key.
    55	- **Your phone's address:** the app hands its push token to the machine over the open connection, in `~/.config/herdr-ios/devices/`.
    56	
    57	Setup needs a paid Apple Developer account:
    58	1. Create an APNs key at developer.apple.com → Certificates, IDs & Profiles → Keys, with Apple Push Notifications service enabled.
   145	    }
   146	
   147	    func connect(to machine: MachineConfig) {
   148	        if !machines.contains(where: { $0.id == machine.id }) { machines.append(machine) }
   149	        if activeMachineID != machine.id {
   150	            dropConnection(phase: .idle)
   151	            activeMachineID = machine.id
   152	            clearLiveState()
   153	            loadMachineState()
   154	        }
   155	        wantConnected = true
   156	        attempt = 0
   157	        startConnect(machine, reconnecting: false)
   158	    }
   159	
   160	    func reconnect() {
   161	        guard let m = currentMachine() else { return }
   162	        wantConnected = true
   163	        attempt = 0
   164	        startConnect(m, reconnecting: hello != nil)
   165	    }
   166	
   167	    func disconnect() {
   168	        wantConnected = false
   169	        dropConnection(phase: .idle)
   170	    }
   171	
   172	    func saveMachine(_ m: MachineConfig, password: String?) {
   173	        let old = machines.first { $0.id == m.id }
   174	        if let i = machines.firstIndex(where: { $0.id == m.id }) { machines[i] = m } else { machines.append(m) }
   175	        if let password { KeyStore.setPassword(password, for: m.id) }
   176	        if activeMachineID == nil { activeMachineID = m.id }
   177	        // Changed where/how we connect: reconnect with the new settings.
   178	        if m.id == activeMachineID, let old, old != m, wantConnected { connect(to: m) }
   179	    }
   180	
   181	    func removeMachine(_ id: UUID) {
   182	        guard let m = machines.first(where: { $0.id == id }) else { return }
   183	        if id == activeMachineID {
   184	            disconnect()
   185	            clearLiveState()
   186	            activeMachineID = machines.first { $0.id != id }?.id
   187	        }
   188	        machines.removeAll { $0.id == id }
   189	        KeyStore.setPassword(nil, for: id)
   190	        try? KeyStore.setMachineKey(nil, for: id)
   191	        HostKeys.forget(host: m.host, port: m.port)
   192	        for k in ["attention.", "view.", "home."] { defaults.removeObject(forKey: k + id.uuidString) }
   193	    }
   194	
   195	    /// The app's own SSH public key, OpenSSH one-line form ("ssh-ed25519 AAAA... herdr-ios").
   196	    func publicKeyLine() -> String {
   197	        if let k = cachedPublicKey { return k }
   198	        let k = KeyStore.publicKeyLine()
   199	        if !k.isEmpty { cachedPublicKey = k }
   200	        return k
   201	    }
   202	
   203	    /// Adds the machine a `scripts/pair.sh` code describes, with its own key and its host key pinned, and connects.
   204	    func pair(_ offer: PairingOffer) throws {
   205	        let key = try KeyStore.parseOpenSSH(offer.privateKey)
   206	        let m = machines.first { $0.host == offer.host && $0.port == offer.port && $0.user == offer.user }
   207	            ?? MachineConfig(label: offer.host, host: offer.host, port: offer.port, user: offer.user)
   208	        try KeyStore.setMachineKey(key, for: m.id)
   209	        try HostKeys.pin(offer.hostKey, host: offer.host, port: offer.port)
   210	        var saved = m
   211	        saved.usePassword = false
   212	        saveMachine(saved, password: nil)
   213	        connect(to: saved)
   214	    }
   215	
   216	    /// Replace the app key with a pasted OpenSSH ed25519 private key.
   217	    func importPrivateKey(_ text: String) throws {
   218	        try KeyStore.importPrivateKey(text)
   219	        cachedPublicKey = nil
   220	    }
   221	
   222	    /// Forget a machine's pinned host key (after a legitimate reinstall).

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
既存の host key pin をペアリングコードが無条件に上書きする経路を確認しました。次に、`name` の改行が `authorized_keys` に到達するか、シェルの JSON エスケープが制御文字を処理できるかを、実際の鍵や設定を変更せずに検証します。
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: https://raw.githubusercontent.com/openssh/openssh-portable/master/ssh-keygen.c
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '38,150p' App/Sources/UI/ConnectionViews.swift; sed -n '210,232p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; rg -n 'HERDR_DEBUG_KEY_PATH|pair|restrict|host key' docs/HANDOVER.md README.md; cat Packages/HerdrKit/Package.swift; command -v perl; command -v bun" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var machine: MachineConfig
    var isFirstRun = false
    @State private var password = ""
    @State private var portText = ""
    @State private var copied: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if machine.host.isEmpty { PairingCard() }
            SectionLabel(title: "Machine")
            VStack(spacing: 0) {
                field("Name", text: $machine.label, prompt: "my-box")
                divider
                field("Host", text: $machine.host, prompt: "100.x.y.z or my-box.local", keyboard: .URL)
                divider
                field("Port", text: $portText, prompt: "22", keyboard: .numberPad)
                divider
                field("User", text: $machine.user, prompt: "username")
                divider
                Toggle(isOn: $machine.usePassword.animation(.smooth)) {
                    Text("Use a password").font(HF.ui(15.5)).foregroundStyle(HC.fg)
                }
                .padding(.horizontal, 14).frame(minHeight: HM.rowHeight)
                if machine.usePassword {
                    divider
                    HStack {
                        Text("Password").font(HF.ui(15.5)).foregroundStyle(HC.muted).frame(width: 84, alignment: .leading)
                        SecureField("Stored in the Keychain", text: $password)
                            .font(HF.ui(15.5)).textContentType(.password)
                    }
                    .padding(.horizontal, 14).frame(minHeight: HM.rowHeight)
                }
            }
            .herdrCard()

            if !machine.usePassword { keySection }

            Button(action: connect) {
                Text(isFirstRun ? "Connect" : "Save and connect")
                    .font(HF.ui(16.5, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(machine.host.trimmingCharacters(in: .whitespaces).isEmpty || machine.user.isEmpty)
            .padding(.top, 22)
        }
        .onAppear { portText = String(machine.port) }
    }

    @ViewBuilder private var keySection: some View {
        let key = store.publicKeyLine()
        SectionLabel(title: "This device's key")
        VStack(alignment: .leading, spacing: 12) {
            Text("Add this line to ~/.ssh/authorized_keys on \(machine.label.isEmpty ? "the machine" : machine.label):")
                .font(HF.ui(14)).foregroundStyle(HC.muted)
            Text(key.isEmpty ? "Generating key…" : key)
                .font(HF.mono(11.5))
                .foregroundStyle(HC.fg)
                .textSelection(.enabled)
                .lineLimit(4)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HC.canvas, in: .rect(cornerRadius: 8))
            HStack(spacing: 10) {
                Button {
                    copy(key, as: "key")
                } label: {
                    Label(copied == "key" ? "Copied" : "Copy key", systemImage: copied == "key" ? "checkmark" : "doc.on.doc")
                }
                Button {
                    copy(installLine(key), as: "line")
                } label: {
                    Label(copied == "line" ? "Copied" : "Copy command", systemImage: copied == "line" ? "checkmark" : "terminal")
                }
                Spacer(minLength: 0)
                ShareLink(item: key) { Image(systemName: "square.and.arrow.up") }
            }
            .buttonStyle(.glass)
            .font(HF.ui(14, .medium))
            .disabled(key.isEmpty)
            Text("The command appends the key with the right permissions:")
                .font(HF.ui(12.5)).foregroundStyle(HC.dim)
            Text(installLine(key.isEmpty ? "ssh-ed25519 AAAA… herdr-ios" : key))
                .font(HF.mono(10.5)).foregroundStyle(HC.muted).lineLimit(3).textSelection(.enabled)
        }
        .padding(14)
        .herdrCard()
    }

    private func installLine(_ key: String) -> String {
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '\(key)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    }

    private func copy(_ s: String, as tag: String) {
        UIPasteboard.general.string = s
        withAnimation { copied = tag }
        Task { try? await Task.sleep(for: .seconds(2)); withAnimation { if copied == tag { copied = nil } } }
    }

    private func connect() {
        var m = machine
        m.host = m.host.trimmingCharacters(in: .whitespaces)
        m.user = m.user.trimmingCharacters(in: .whitespaces)
        if m.label.trimmingCharacters(in: .whitespaces).isEmpty { m.label = m.host }
        m.port = Int(portText) ?? 22
        store.saveMachine(m, password: m.usePassword && !password.isEmpty ? password : nil)
        store.connect(to: m)
        dismiss()
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
                          timedOut: r["timed_out"].bool ?? false,
                          truncated: r["truncated"].bool ?? false)
    }

docs/HANDOVER.md:16:   - The host key is shown and approved before it is pinned, and pins live in the Keychain.
docs/HANDOVER.md:34:- Fixes: Chat nudge (407eccd), host key approval + Keychain (362b8bc), `requiredMethods` (1b740be),
docs/HANDOVER.md:79:- `~/.ssh/authorized_keys`: the line with comment `herdr-pocket-simulator-pair` (`restrict,command=…`), added by
docs/HANDOVER.md:80:  running `scripts/pair.sh` for `testPairWithPastedCode`.
docs/HANDOVER.md:97:export TEST_RUNNER_HERDR_DEBUG_KEY_PATH=$PWD/docs/private/sim_key
README.md:44:- **Pairing:** on the box, run `scripts/pair.sh` (in the devshell, which has qrencode). It makes an SSH key for the phone, authorizes it in `~/.ssh/authorized_keys` for `herdr-core connect` only (`restrict,command=…`), and shows a QR code with the key, the box's address and its host key; scan it in the app (or paste the code). The host key is pinned from the code, so there is no fingerprint to compare, and nothing listens or keeps running on the box. Remove a phone by deleting its line.
README.md:45:- **Login without pairing:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
README.md:46:- **Host key:** on first connect the app stops before logging in and shows the box's host key fingerprint; it is pinned in the Keychain once you approve it.
README.md:125:- **UI:** run the `HerdrUITests` target against a real box in watch-only mode. Pass settings to the test runner with the `TEST_RUNNER_` prefix (e.g. `TEST_RUNNER_HERDR_DEBUG_KEY_PATH`): `HERDR_DEBUG_KEY_PATH` always; `HERDR_TEST_HOST`, `HERDR_TEST_USER`, `HERDR_TEST_HOST_FP` for first-connect approval; `HERDR_TEST_SPACE`, `HERDR_TEST_FILES_PATH`, `HERDR_TEST_FILES` for Files; `HERDR_TEST_TERMINAL` for Chat.
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HerdrKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [.library(name: "HerdrKit", targets: ["HerdrKit"])],
    targets: [
        .target(name: "HerdrKit", swiftSettings: [.swiftLanguageMode(.v5)]),
        .executableTarget(name: "herdr-probe", dependencies: ["HerdrKit"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "HerdrKitTests", dependencies: ["HerdrKit"], resources: [.copy("Fixtures")], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
/usr/bin/perl
/etc/profiles/per-user/yosuke/bin/bun

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: https://raw.githubusercontent.com/openssh/openssh-portable/master/authfile.c
hook: PostToolUse
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
/bin/zsh -lc "bun -e 'import { readFileSync } from \"node:fs\";
const helper = readFileSync(\"scripts/pair.sh\", \"utf8\").split(\"\\n\").find(l=>l.startsWith(\"json()\"));
for (const s of [\"box\", \"a\\\"b\\\\c\", \"a\\nb\", \"a\\tb\", \"a\\rb\", \"-----BEGIN OPENSSH PRIVATE KEY-----\\nabc\\n-----END OPENSSH PRIVATE KEY-----\"]) {
const r=Bun.spawnSync([\"/bin/sh\",\"-c\",helper+'\\''\\njson \""'$VALUE"'"'\\''], {env:{...process.env, VALUE:s}});
const escaped=r.stdout.toString();
try { console.log(JSON.stringify(s), JSON.parse('\\''\"'\\''+escaped+'\\''\"'\\'')===s ? \"round-trip OK\":\"MISMATCH\"); }
catch {console.log(JSON.stringify(s), \"INVALID JSON\", JSON.stringify(escaped));}
}
const r=Bun.spawnSync([\"/bin/sh\",\"-c\",'\\''printf %s abc | base64 | tr -d \"\\\\n=\" | tr \"+/\" \"-_\"'\\'']);
console.log(\"macOS base64:\",r.stdout.toString());'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 205ms:
"box" round-trip OK
"a\"b\\c" round-trip OK
"a\nb" round-trip OK
"a\tb" INVALID JSON "a\tb"
"a\rb" INVALID JSON "a\rb"
"-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----" round-trip OK
macOS base64: YWJj

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: 'sshkey_save_public'
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "command -v dash; nl -ba App/Sources/UI/ConnectionViews.swift | sed -n '85,100p'; nl -ba App/Sources/UI/SettingsView.swift | sed -n '1,115p'; git status --short; sh -n scripts/pair.sh" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
/bin/dash
    85	            .disabled(machine.host.trimmingCharacters(in: .whitespaces).isEmpty || machine.user.isEmpty)
    86	            .padding(.top, 22)
    87	        }
    88	        .onAppear { portText = String(machine.port) }
    89	    }
    90	
    91	    @ViewBuilder private var keySection: some View {
    92	        let key = store.publicKeyLine()
    93	        SectionLabel(title: "This device's key")
    94	        VStack(alignment: .leading, spacing: 12) {
    95	            Text("Add this line to ~/.ssh/authorized_keys on \(machine.label.isEmpty ? "the machine" : machine.label):")
    96	                .font(HF.ui(14)).foregroundStyle(HC.muted)
    97	            Text(key.isEmpty ? "Generating key…" : key)
    98	                .font(HF.mono(11.5))
    99	                .foregroundStyle(HC.fg)
   100	                .textSelection(.enabled)
     1	import SwiftUI
     2	import UIKit
     3	import HerdrKit
     4	
     5	struct SettingsView: View {
     6	    @Environment(AppStore.self) private var store
     7	    @Environment(\.dismiss) private var dismiss
     8	    @AppStorage("appearance") private var appearance = "system"
     9	    @AppStorage("terminalFontSize") private var fontSize = 13.0
    10	    @State private var editing: MachineConfig?
    11	    @State private var confirmForget: MachineConfig?
    12	
    13	    var body: some View {
    14	        NavigationStack {
    15	            Form {
    16	                Section("Machines") {
    17	                    ForEach(store.machines) { m in
    18	                        HStack(spacing: 12) {
    19	                            Image(systemName: "server.rack").foregroundStyle(HC.muted).frame(width: 22)
    20	                            VStack(alignment: .leading, spacing: 2) {
    21	                                Text(m.label).font(HF.ui(15.5, .medium)).foregroundStyle(HC.fg)
    22	                                Text(verbatim: "\(m.user)@\(m.host):\(m.port)").font(HF.mono(11.5)).foregroundStyle(HC.dim)
    23	                            }
    24	                            Spacer()
    25	                            if m.id == store.activeMachine?.id { ConnectionDot(phase: store.phase) }
    26	                        }
    27	                        .contentShape(.rect)
    28	                        .onTapGesture { editing = m }
    29	                        .swipeActions {
    30	                            Button("Remove", role: .destructive) { store.removeMachine(m.id) }
    31	                            if m.id != store.activeMachine?.id || store.phase != .connected {
    32	                                Button("Connect") { store.connect(to: m) }.tint(HC.accent)
    33	                            }
    34	                        }
    35	                    }
    36	                    Button { editing = MachineConfig(label: "", host: "", user: "") } label: {
    37	                        Label("Add machine", systemImage: "plus")
    38	                    }
    39	                    if store.phase == .connected {
    40	                        Button("Disconnect", role: .destructive) { store.disconnect() }
    41	                    } else if store.activeMachine != nil {
    42	                        Button("Reconnect") { store.reconnect() }
    43	                    }
    44	                    if let m = store.activeMachine, let fp = store.hostKeyFingerprint(m) {
    45	                        VStack(alignment: .leading, spacing: 4) {
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
    56	                    Text("Only after \(m.host) was reinstalled. You will be asked to approve the next key it presents.")
    57	                }
    58	
    59	                NotificationSection()
    60	
    61	                Section("Appearance") {
    62	                    Picker("Theme", selection: $appearance) {
    63	                        Text("System").tag("system")
    64	                        Text("Graphite (dark)").tag("dark")
    65	                        Text("Paper (light)").tag("light")
    66	                    }
    67	                    VStack(alignment: .leading, spacing: 10) {
    68	                        Stepper(value: $fontSize, in: 9...20, step: 1) {
    69	                            HStack {
    70	                                Text("Terminal text")
    71	                                Spacer()
    72	                                Text("\(Int(fontSize)) pt").foregroundStyle(HC.muted).monospacedDigit()
    73	                            }
    74	                        }
    75	                        Text("The quick brown fox → 0123 {}[]")
    76	                            .font(HF.mono(fontSize))
    77	                            .foregroundStyle(HC.fg)
    78	                            .lineLimit(1)
    79	                            .minimumScaleFactor(0.5)
    80	                    }
    81	                    Text("Terminals mirror the desktop's size and scale down to fit (min 7 pt). Pinch to zoom; use Fit to phone in a terminal's menu to resize the program instead.")
    82	                        .font(HF.ui(12.5)).foregroundStyle(HC.dim)
    83	                }
    84	
    85	                ModSettingsView()
    86	
    87	                Section("About") {
    88	                    LabeledContent("Herdr for iOS", value: appVersion)
    89	                    if let h = store.hello {
    90	                        LabeledContent("Core", value: h.coreName)
    91	                        LabeledContent("herdr-core", value: h.version)
    92	                        LabeledContent("Core id", value: String(h.coreID.prefix(12)))
    93	                    } else {
    94	                        LabeledContent("Core", value: "Not connected")
    95	                    }
    96	                    NavigationLink("Licenses") { LicensesView() }
    97	                }
    98	            }
    99	            .scrollContentBackground(.hidden)
   100	            .background(HC.canvas)
   101	            .font(HF.ui(15.5))
   102	            .navigationTitle("Settings")
   103	            .navigationBarTitleDisplayMode(.inline)
   104	            .toolbar {
   105	                ToolbarItem(placement: .confirmationAction) { Button("Done", systemImage: "checkmark") { dismiss() } }
   106	            }
   107	            .sheet(item: $editing) { m in
   108	                NavigationStack {
   109	                    ScrollView { MachineForm(machine: m).padding(16) }
   110	                        .background(HC.canvas)
   111	                        .navigationTitle(m.host.isEmpty ? "Add machine" : m.label)
   112	                        .navigationBarTitleDisplayMode(.inline)
   113	                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = nil } } }
   114	                }
   115	            }
?? docs/reviews/2026-11-02-pairing-codex.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "bun -e 'for (const shell of [\"/bin/sh\",\"/bin/dash\"]) {
 const r = Bun.spawnSync([shell,\"-c\",\"trap '\\''printf cleanup-ran'\\'' EXIT; kill -TERM "'$$"]);
 console.log(shell, "signal:",r.signalCode,"stdout:",JSON.stringify(r.stdout.toString()));
}
const previous="ssh-ed25519 AAAA old";
const added='"'\\''restrict,command=\"/usr/local/bin/herdr-core connect\" ssh-ed25519 BBBB phone'\\'';
console.log(\"append without final newline:\",JSON.stringify(previous+added+\"\\n\"));'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 49ms:
/bin/sh signal: SIGTERM stdout: ""
/bin/dash signal: SIGTERM stdout: ""
append without final newline: "ssh-ed25519 AAAA oldrestrict,command=\"/usr/local/bin/herdr-core connect\" ssh-ed25519 BBBB phone\n"

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
本コミットは、QR コードから接続先・秘密鍵・host key を取り込み、機体ごとの鍵で SSH 接続する機能を追加しています。以下の修正が必要です。ファイルは変更していません。

1. **[P1] 既存の host key pin を無条件に上書きする** — [AppStore.swift:208](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Store/AppStore.swift:208)

   **シナリオ:** 登録済みの `host:port` に対し、異なる host key を持つコードを読み込むと、既存 pin が確認なしで置き換わります。別ユーザーの接続にも同じ pin が使われるため、影響は今回のペアリング先に限りません。通常接続の `HostKeys.Mismatch` による保護を迂回します。
   
   **修正:** 保存前に既存 pin と比較し、不一致なら拒否するか、旧・新 fingerprint を示して明示的に置換を承認させてください。承認前に機体の秘密鍵も変更しないでください。

2. **[P1] `name` の改行で制限なしの公開鍵を追加できる** — [pair.sh:34](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:34)、[pair.sh:38](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:38)

   **シナリオ:** 第二引数に `phone\nssh-ed25519 <攻撃者の公開鍵>` を渡すと、コメント内の改行が `.pub` に保存され、その全文が `authorized_keys` に追記されます。追加された二行目には `restrict,command=…` が付きません。攻撃者が指定した名前をコピーして実行する経路で成立します。OpenSSH はコメントを改行除去せずに書き出します。[実装](https://github.com/openssh/openssh-portable/blob/master/authfile.c#L461-L478)
   
   **修正:** 鍵生成前に `name` の CR/LF を拒否し、公開鍵が単一行であることも追記前に検証してください。

3. **[P2] シグナル終了で秘密鍵の一時ファイルが残る** — [pair.sh:33](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:33)

   **シナリオ:** `EXIT` trap だけでは、SIGTERM による終了時に cleanup が実行されません。ローカルの `/bin/sh` と `/bin/dash` で確認しました。端末終了等でスクリプトが停止すると、認可済みの無暗号化秘密鍵が一時ディレクトリに残り得ます。ディレクトリのアクセス制限はありますが、秘密鍵の保存期間が意図せず延びます。
   
   **修正:** HUP・INT・TERM に終了ハンドラーを設定し、通常の cleanup を通してください。

4. **[P2] `authorized_keys` の末尾に改行がないと追加鍵が認識されない** — [pair.sh:38](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:38)

   **シナリオ:** 既存ファイルの最終行に改行がない場合、追加する設定が既存の公開鍵行に連結されます。既存行にコメントがあれば追加設定もコメントになり、QR は生成されても新しい鍵で認証できません。
   
   **修正:** 追記するレコードの先頭にも改行を入れ、必ず独立した行として保存してください。

5. **[P2] ペアリング済み機体の設定画面が別の公開鍵を表示する** — [AppStore.swift:503](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Store/AppStore.swift:503)、[ConnectionViews.swift:92](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ConnectionViews.swift:92)

   **シナリオ:** 接続は機体固有の鍵を優先しますが、設定画面の「This device's key」とコピー用コマンドは引き続きアプリ共通鍵を使います。ペアリング鍵をサーバーから削除した後、画面の指示で鍵を追加しても認証は復旧しません。共通の秘密鍵をインポートしても同様です。
   
   **修正:** 当該機体が実際に使う鍵を表示してください。共通鍵のインポートがペアリング済み機体には適用されないことも UI に反映してください。

6. **[P2] 再ペアリングの保存失敗で既存資格情報だけが置き換わる** — [AppStore.swift:208](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Store/AppStore.swift:208)

   **シナリオ:** 既存機体の秘密鍵更新が成功し、続く host key の Keychain 保存が失敗すると、`pair` はエラーを返しますが元の秘密鍵は失われます。接続可能だった旧状態に戻せず、新しい鍵が利用できない場合は再接続も失敗します。
   
   **修正:** 更新前の値を保持し、保存途中の失敗時には復元してください。pin の検証は書き込み開始前に済ませてください。

確認した範囲では、`host` は `authorized_keys` に入らず、`core` のパスは許可文字の検証があるため、これらからの直接の注入経路は見つかりませんでした。JSON の引用符・バックスラッシュ・改行と macOS の base64 処理は確認済みです。ただし JSON ヘルパーはタブ・CR をエスケープせず、その入力では不正 JSON を生成します。

`restrict,command=…` は SSH の起動コマンドと forwarding 等を制限しますが、core 内の `machine.exec` による任意コマンド実行は可能です。これはアプリの機能と整合していますが、鍵漏洩時の権限を限定する仕組みにはなりません。[OpenSSH の制限内容](https://man.openbsd.org/sshd.8#restrict)

機体削除時のローカル鍵削除、同じ接続先への再ペアリング時の UUID 再利用、機体鍵を DEBUG 共通鍵より優先する処理は確認しました。文書との不一致は、README の「初回接続では fingerprint を確認する」がペアリングの例外を明示していない点と、HANDOVER の同様の記述です。

**判定: 修正後に再レビュー。特に 1・2 はマージ前に修正が必要です。**

未確認: Swift テスト、iOS カメラ、実 SSH 接続、Linux 実機での end-to-end 動作。
残るリスク: QR・貼り付けコードは継続利用可能な秘密鍵です。再ペアリングやアプリ内の機体削除では、サーバー上の旧鍵は失効しません。
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
74,753
本コミットは、QR コードから接続先・秘密鍵・host key を取り込み、機体ごとの鍵で SSH 接続する機能を追加しています。以下の修正が必要です。ファイルは変更していません。

1. **[P1] 既存の host key pin を無条件に上書きする** — [AppStore.swift:208](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Store/AppStore.swift:208)

   **シナリオ:** 登録済みの `host:port` に対し、異なる host key を持つコードを読み込むと、既存 pin が確認なしで置き換わります。別ユーザーの接続にも同じ pin が使われるため、影響は今回のペアリング先に限りません。通常接続の `HostKeys.Mismatch` による保護を迂回します。
   
   **修正:** 保存前に既存 pin と比較し、不一致なら拒否するか、旧・新 fingerprint を示して明示的に置換を承認させてください。承認前に機体の秘密鍵も変更しないでください。

2. **[P1] `name` の改行で制限なしの公開鍵を追加できる** — [pair.sh:34](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:34)、[pair.sh:38](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:38)

   **シナリオ:** 第二引数に `phone\nssh-ed25519 <攻撃者の公開鍵>` を渡すと、コメント内の改行が `.pub` に保存され、その全文が `authorized_keys` に追記されます。追加された二行目には `restrict,command=…` が付きません。攻撃者が指定した名前をコピーして実行する経路で成立します。OpenSSH はコメントを改行除去せずに書き出します。[実装](https://github.com/openssh/openssh-portable/blob/master/authfile.c#L461-L478)
   
   **修正:** 鍵生成前に `name` の CR/LF を拒否し、公開鍵が単一行であることも追記前に検証してください。

3. **[P2] シグナル終了で秘密鍵の一時ファイルが残る** — [pair.sh:33](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:33)

   **シナリオ:** `EXIT` trap だけでは、SIGTERM による終了時に cleanup が実行されません。ローカルの `/bin/sh` と `/bin/dash` で確認しました。端末終了等でスクリプトが停止すると、認可済みの無暗号化秘密鍵が一時ディレクトリに残り得ます。ディレクトリのアクセス制限はありますが、秘密鍵の保存期間が意図せず延びます。
   
   **修正:** HUP・INT・TERM に終了ハンドラーを設定し、通常の cleanup を通してください。

4. **[P2] `authorized_keys` の末尾に改行がないと追加鍵が認識されない** — [pair.sh:38](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/scripts/pair.sh:38)

   **シナリオ:** 既存ファイルの最終行に改行がない場合、追加する設定が既存の公開鍵行に連結されます。既存行にコメントがあれば追加設定もコメントになり、QR は生成されても新しい鍵で認証できません。
   
   **修正:** 追記するレコードの先頭にも改行を入れ、必ず独立した行として保存してください。

5. **[P2] ペアリング済み機体の設定画面が別の公開鍵を表示する** — [AppStore.swift:503](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Store/AppStore.swift:503)、[ConnectionViews.swift:92](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/ConnectionViews.swift:92)

   **シナリオ:** 接続は機体固有の鍵を優先しますが、設定画面の「This device's key」とコピー用コマンドは引き続きアプリ共通鍵を使います。ペアリング鍵をサーバーから削除した後、画面の指示で鍵を追加しても認証は復旧しません。共通の秘密鍵をインポートしても同様です。
   
   **修正:** 当該機体が実際に使う鍵を表示してください。共通鍵のインポートがペアリング済み機体には適用されないことも UI に反映してください。

6. **[P2] 再ペアリングの保存失敗で既存資格情報だけが置き換わる** — [AppStore.swift:208](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Store/AppStore.swift:208)

   **シナリオ:** 既存機体の秘密鍵更新が成功し、続く host key の Keychain 保存が失敗すると、`pair` はエラーを返しますが元の秘密鍵は失われます。接続可能だった旧状態に戻せず、新しい鍵が利用できない場合は再接続も失敗します。
   
   **修正:** 更新前の値を保持し、保存途中の失敗時には復元してください。pin の検証は書き込み開始前に済ませてください。

確認した範囲では、`host` は `authorized_keys` に入らず、`core` のパスは許可文字の検証があるため、これらからの直接の注入経路は見つかりませんでした。JSON の引用符・バックスラッシュ・改行と macOS の base64 処理は確認済みです。ただし JSON ヘルパーはタブ・CR をエスケープせず、その入力では不正 JSON を生成します。

`restrict,command=…` は SSH の起動コマンドと forwarding 等を制限しますが、core 内の `machine.exec` による任意コマンド実行は可能です。これはアプリの機能と整合していますが、鍵漏洩時の権限を限定する仕組みにはなりません。[OpenSSH の制限内容](https://man.openbsd.org/sshd.8#restrict)

機体削除時のローカル鍵削除、同じ接続先への再ペアリング時の UUID 再利用、機体鍵を DEBUG 共通鍵より優先する処理は確認しました。文書との不一致は、README の「初回接続では fingerprint を確認する」がペアリングの例外を明示していない点と、HANDOVER の同様の記述です。

**判定: 修正後に再レビュー。特に 1・2 はマージ前に修正が必要です。**

未確認: Swift テスト、iOS カメラ、実 SSH 接続、Linux 実機での end-to-end 動作。
残るリスク: QR・貼り付けコードは継続利用可能な秘密鍵です。再ペアリングやアプリ内の機体削除では、サーバー上の旧鍵は失効しません。
