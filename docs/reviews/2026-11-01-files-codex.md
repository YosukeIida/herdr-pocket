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
session id: 01a1934e-3f3a-78c0-b877-a7357408e0c6
--------
user
Review the last commit in this repo (git show HEAD): a Files browser with Quick Look preview for an iOS client of herdr-core. Context: AGENTS.md, docs/2026-11-01_herdr-ios-code-review.md (section on where features plug in), Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift (exec, frame limit). Review only; do not edit files. For each finding give severity (high/medium/low), file:line, a concrete failure scenario and a suggested fix. Check: path handling and injection (argv to machine.exec, names with odd characters, symlinks, '~'), the 12 MiB limit vs the actual frame/base64/JSON overhead and what happens just above it, temp file handling and data protection, SwiftUI state races (open twice, dismiss during fetch, navigation), and anything that breaks on a box without python3. Say 'no findings' where there are none. Be concise.
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
I’ll review the commit and the client’s exec/frame handling, then check the preview lifecycle and failure paths. I’ll use the ponytail review skill and leave files unchanged.
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'pwd && git status --short && git show --stat HEAD' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
?? docs/reviews/2026-11-01-files-codex.md
commit 6c7e200ae6bb6ec4d3cc94e86232ac2a3afa69ff
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:52:21 2026 +0900

    Browse a space's folder and preview its files in Quick Look
    
    The phone had no way to read what agents produce on the box: PDFs, Office
    documents, images. Files lists the space folder with the box's python3 (as
    Chat already does) and fetches a file with cat over machine.exec into a
    temporary file for Quick Look, which renders PDF, docx, xlsx and images on
    the device. Files over 12 MiB are refused for now: one exec reply must fit
    in a 16 MiB frame as base64.

 App/Sources/UI/FilesView.swift | 158 +++++++++++++++++++++++++++++++++++++++++
 App/Sources/UI/SpaceView.swift |   6 ++
 UITests/HerdrUITests.swift     |  29 ++++++++
 3 files changed, 193 insertions(+)

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md && cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail/SKILL.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
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
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat docs/2026-11-01_herdr-ios-code-review.md && nl -ba Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
# Code quality check of zzulanas/herdr-ios

On 2026-11-01, commit `a030501` (2026-10-30) was checked.

Two methods were used.

- Ran the HerdrKit unit tests (Swift 6.4, macOS). All 33 passed.
- Had another agent read the code and collected its findings. The 2 high-severity findings were confirmed in the source.

The build and behavior on a real device were not checked.

## Conclusion

It can be used as the foundation. However, before starting to use it, the 2 high-severity findings and the dependency version pinning must be fixed.

- HerdrKit (framing, JSON-RPC, events, the Layout document) is solidly built and covered by tests.
- The problems are concentrated in the App layer, and all can be fixed locally.

## Size and structure

| Part | Contents |
|---|---|
| `Packages/HerdrKit` | protocol and model (SwiftPM, no external dependencies, 33 tests), `herdr-probe` (macOS CLI) |
| `App/Sources` | Net (Citadel SSH, Keychain, host key), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore mod host), Notify |
| External dependencies | Citadel `from: 0.12.1`, SwiftTerm `exactVersion: 1.20.0` |
| Size | About 11,500 lines of Swift |

## Findings

| Severity | Location | Description | Fix |
|---|---|---|---|
| High (confirmed in source) | `App/Sources/Chat/ChatView.swift:46`, `ChatModel.swift:91-97` | Calls `model.nudge()` on every `title` change. `title` changes every 0.1 s while working, so while Chat is open, the python that reads the transcript on the Mac side is launched almost continuously. There is also a race: when the sleep of a previous wait ends, it also releases the next wait | Remove the nudge on `title`, keep only `status` and `turn`. Distinguish sleeping Tasks with a token |
| High (confirmed in source) | `App/Sources/Net/HostKeys.swift:58-60` | On the first connection, the host key is pinned without confirmation, and the fingerprint is shown only after pinning. With a man-in-the-middle attack on the first connection, password authentication hands over the password as is. Storage is UserDefaults, not Keychain | On the first connection, show the fingerprint and require approval. Store in Keychain |
| Medium | `AppStore.swift:138-143, 486-508` | Closes the connection 8 s after entering the background. On return, it waits for SSH, hello, subscribe and docGet in sequence. The last screen is kept only in memory, so after the process ends it starts from the connection screen | Wait for subscribe and docGet concurrently. Save the snapshot to disk and show it immediately on return |
| Medium | `EventLines.swift:131` → `AppStore.swift:629-642` | Replaces the whole terminal list on every `title` notification, and every screen is re-evaluated | Route `title`-only updates separately, or thin them out |
| Medium | `HerdrClient.swift:28-29` | `requiredMethods` does not include `terminal.read/send/keys/interrupt` and `server.status`, which are used | Add them to the array |
| Medium | `project.yml:14-19` | The Citadel version is not pinned, and `Package.resolved` is gitignored. `__pycache__/*.pyc` is tracked and bundled into the app | Use `exactVersion` and commit resolved. Delete the pyc files |
| Medium | `Package.swift`, `project.yml` | The Swift language mode is v5, relying on hand-written locks. Some reads happen outside the lock (`HerdrClient.swift:113` and `221`) | First move HerdrKit to v6 |
| Medium (by design) | `Mods/ModHub.swift:310, 325` | Passes the command a mod specifies straight to `machine.exec` on the Mac side. The trust boundary is the same as the Herdr app | Operate by bundling only mods you wrote yourself |
| Low | `herdr-notify.py:87, 91`, `Push.swift:78` | Puts the APNs JWT in curl arguments (visible in `ps`). Does not validate the device token. Does not create the devices file with umask 077 | Pass the JWT on standard input. Check the token format. Create with umask 077 |
| Low | `herdr-notify.py:184-191` | Sends "finished" when blocked changes to error. This differs from the app's decision | Align the decision with `AttentionTracker` |
| Low | Entire App | The App side has no unit tests | Write tests starting from `ChatModel.rebuild` (a pure function) |

Within the checked scope, there was no room for shell injection. All values passed to `sh -c` are passed as positional arguments, and session IDs are constrained to a fixed format by a regular expression. The Layout document is edited while preserving unknown fields, and version conflicts are handled by compare-and-swap (CAS).

## Where to add the new features

- **Codex chat**: The Mac-side script outputs a common format that represents the kind (user, text, tool, result), and the Swift side only folds it. The dependency on Claude Code is in only 2 places: `AgentScreen.swift:13` and `ChatModel.swift:107`. Add a script that outputs the rollout in the same format, and select it by program.
- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
- **launchd notifier**: In `NotificationSettings.swift:180-205` and `scripts/install-notifier.sh`, on macOS, place a plist in `~/Library/LaunchAgents` and run `launchctl bootstrap`. Add the Homebrew and nix locations to the `hc` search paths in `herdr-notify.py:21`.

## Inconsistencies between documentation and code

- Code comments refer to `SPEC.md`, but `SPEC.md` is not in the repo.
- The README says "mod exec runs on the Mac side", but `open` and pbcopy are handled on the smartphone side.
- The README describes the notifier only as being for systemd, but the code has an alternative path that starts it with nohup.

## What to read before building

Building runs the following 2 items without a sandbox. Their contents must be read before building.

- The pre-build `bundle-mods.sh` (`ENABLE_USER_SCRIPT_SANDBOXING: NO`)
- SwiftTerm's build plugin
     1	import Foundation
     2	
     3	/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
     4	/// JSON-RPC on channel 0, terminal and event streams on core-allocated channels.
     5	///
     6	/// Thread model: transport bytes are parsed on whatever thread the transport
     7	/// calls back on (serially), under one lock. Writes go through a single serial
     8	/// writer task. Stream and event callbacks are delivered on `callbackQueue`.
     9	public final class HerdrClient: @unchecked Sendable {
    10	    public let transport: ByteTransport
    11	    /// Where stream/event/disconnect callbacks run. Set before `connect()`.
    12	    public var callbackQueue: DispatchQueue = .main
    13	    /// No bytes on any channel for this long = the connection is dead.
    14	    public var livenessTimeout: TimeInterval = 45
    15	    /// Called once on `callbackQueue` when the connection drops unexpectedly
    16	    /// (not after `close()`).
    17	    public var onDisconnect: ((HerdrError) -> Void)? {
    18	        get { lock.withLock { _onDisconnect } }
    19	        set { lock.withLock { _onDisconnect = newValue } }
    20	    }
    21	    private var _onDisconnect: ((HerdrError) -> Void)?
    22	
    23	    public private(set) var hello: HelloInfo?
    24	    /// Remote stderr so far (capped), for failure screens.
    25	    public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }
    26	
    27	    /// Methods the app calls; a core lacking one can't serve it.
    28	    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
    29	                                         "terminal.attach", "terminal.keep", "terminal.read", "terminal.send", "terminal.keys",
    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
    31	                                         "machine.list", "server.status"]
    32	    public static let minCoreVersion = "0.1.11"
    33	    public static let generation: UInt64 = 1
    34	
    35	    private enum Route { case terminal(TerminalStream), events(EventSubscription) }
    36	    private enum Mode { case idle, plain, framed, closed }
    37	
    38	    private let lock = NSLock()
    39	    private var mode = Mode.idle
    40	    private var plain = Data()
    41	    private var helloCont: CheckedContinuation<JSONValue, Error>?
    42	    private var decoder = FrameDecoder()
    43	    private var nextID: UInt64 = 0
    44	    private var pending: [UInt64: CheckedContinuation<JSONValue, Error>] = [:]
    45	    private var cancelled: Set<UInt64> = []
    46	    private var routes: [UInt32: Route] = [:]
    47	    private var early: [UInt32: [Frame]] = [:]
    48	    /// Channels we closed: drop their frames, swallow the CLOSE echo.
    49	    private var closing: Set<UInt32> = []
    50	    private var lastReceive = Date()
    51	    private var stderrBuf = Data()
    52	    private var closedByUs = false
    53	
    54	    private let outbox: AsyncStream<Data>.Continuation
    55	    private let outStream: AsyncStream<Data>
    56	    private var writerTask: Task<Void, Never>?
    57	    private var livenessTask: Task<Void, Never>?
    58	
    59	    public init(transport: ByteTransport) {
    60	        self.transport = transport
    61	        (outStream, outbox) = AsyncStream<Data>.makeStream(bufferingPolicy: .unbounded)
    62	    }
    63	
    64	    deinit {
    65	        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
    66	    }
    67	
    68	    public var isConnected: Bool { lock.withLock { mode == .framed } }
    69	
    70	    // MARK: Connect
    71	
    72	    /// Starts the transport, says hello in plain mode, then switches to frames.
    73	    public func connect(helloTimeout: TimeInterval = 20) async throws -> HelloInfo {
    74	        let started: Bool = lock.withLock {
    75	            guard mode == .idle else { return false }
    76	            mode = .plain; lastReceive = Date(); return true
    77	        }
    78	        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }
    79	
    80	        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
    81	            for await chunk in outStream {
    82	                do { try await transport.write(chunk) } catch {
    83	                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
    84	                    return
    85	                }
    86	            }
    87	        }
    88	
    89	        try await transport.start(
    90	            onBytes: { [weak self] in self?.receive($0) },
    91	            onStderr: { [weak self] d in self?.lock.withLock {
    92	                guard let self, self.stderrBuf.count < 16_384 else { return }
    93	                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
    94	            } },
    95	            onClose: { [weak self] err in self?.transportClosed(err) })
    96	
    97	        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
    98	            let alreadyClosed: Bool = lock.withLock {
    99	                if mode == .closed { return true }
   100	                helloCont = cont; return false
   101	            }
   102	            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
   103	            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
   104	            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
   105	                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
   106	                    defer { self.helloCont = nil }; return self.helloCont
   107	                }) else { return }
   108	                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
   109	                                              hint: self.stderrText.trimmed.nilIfEmpty))
   110	                self.close()
   111	            }
   112	        }
   113	        do {
   114	            let info = try Self.check(hello: reply)
   115	            lock.withLock { hello = info }
   116	            startLiveness()
   117	            return info
   118	        } catch {
   119	            close()
   120	            throw error
   121	        }
   122	    }
   123	
   124	    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
   125	    public static func check(hello reply: JSONValue) throws -> HelloInfo {
   126	        if !reply["error"].isNull { throw rpcError(reply["error"]) }
   127	        let r = reply["result"]
   128	        let gen = r["generation"].uint64 ?? 0
   129	        let version = r["version"].string ?? "0"
   130	        if gen > generation {
   131	            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
   132	        }
   133	        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
   134	            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
   135	        }
   136	        let methods = r["methods"].array?.compactMap(\.string) ?? []
   137	        let missing = requiredMethods.filter { !methods.contains($0) }
   138	        if !missing.isEmpty {
   139	            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
   140	        }
   141	        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
   142	                         version: version, methods: methods)
   143	    }
   144	
   145	    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }
   146	
   147	    static func semver(_ v: String) -> [Int] {
   148	        var s = v.trimmingCharacters(in: .whitespaces)
   149	        if s.hasPrefix("hc ") { s.removeFirst(3) }
   150	        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
   151	        return (0..<3).map { $0 < parts.count ? parts[$0] : 0 }
   152	    }
   153	
   154	    /// Closes the connection. Pending calls fail with `lost`; streams get `onLost`.
   155	    public func close() {
   156	        lock.withLock { closedByUs = true }
   157	        transport.close()
   158	        fail(HerdrError(code: -1, kind: "closed", message: "Disconnected"))
   159	    }
   160	
   161	    // MARK: Calls
   162	
   163	    /// One JSON-RPC call on channel 0. Errors are `HerdrError` (message, hint,
   164	    /// kind). Cancelling the task sends `$/cancelRequest`.
   165	    @discardableResult
   166	    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
   167	        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
   168	        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
   169	                              "params": params.isNull ? [:] : params]
   170	        return try await withTaskCancellationHandler {
   171	            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
   172	                enum Outcome { case go, cancelled, closed }
   173	                let outcome: Outcome = lock.withLock {
   174	                    if cancelled.remove(id) != nil { return .cancelled }
   175	                    if mode != .framed { return .closed }
   176	                    pending[id] = cont; return .go
   177	                }
   178	                switch outcome {
   179	                case .cancelled: cont.resume(throwing: CancellationError()); return
   180	                case .closed: cont.resume(throwing: HerdrError.lost); return
   181	                case .go: break
   182	                }
   183	                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
   184	                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
   185	                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
   186	                }
   187	            }
   188	        } onCancel: {
   189	            let wasPending = lock.withLock { () -> Bool in
   190	                if pending[id] != nil { return true }
   191	                cancelled.insert(id); return false
   192	            }
   193	            if wasPending {
   194	                finish(id, .failure(CancellationError()))
   195	                notify("$/cancelRequest", ["id": .number(Double(id))])
   196	            }
   197	        }
   198	    }
   199	
   200	    /// A notification (no id, no reply).
   201	    public func notify(_ method: String, _ params: JSONValue = [:]) {
   202	        let msg: JSONValue = ["jsonrpc": "2.0", "method": .string(method), "params": params]
   203	        send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
   204	    }
   205	
   206	    private func finish(_ id: UInt64, _ result: Result<JSONValue, Error>) {
   207	        guard let cont = lock.withLock({ pending.removeValue(forKey: id) }) else { return }
   208	        cont.resume(with: result)
   209	    }
   210	
   211	    static func rpcError(_ e: JSONValue) -> HerdrError {
   212	        HerdrError(code: e["code"].int ?? -32000, kind: e["data"]["kind"].string,
   213	                   message: e["message"].string ?? "core call failed", hint: e["data"]["hint"].string)
   214	    }
   215	
   216	    // MARK: Typed helpers
   217	
   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
   219	    /// exit or timeout is a result, not an error.
   220	    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
   221	        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
   222	        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
   223	        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
   224	        if let input { p["input"] = .string(input.base64EncodedString()) }
   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
   226	        return ExecResult(code: r["code"].int,
   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
   228	                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
   229	                          timedOut: r["timed_out"].bool ?? false)
   230	    }
   231	
   232	    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
   233	        let r = try await call("doc.get", ["name": .string(name)])
   234	        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
   235	    }
   236	
   237	    /// CAS write; throws kind "conflict" when `version` is stale. Returns the new version.
   238	    public func docSet(_ name: String = "herdr-app", value: JSONValue, version: UInt64) async throws -> UInt64 {
   239	        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
   240	        return r["version"].uint64 ?? version + 1
   241	    }
   242	
   243	    public func listTerminals(all: Bool = false) async throws -> [TerminalRecord] {
   244	        let r = try await call("terminal.list", ["all": .bool(all)])
   245	        return (r["terminals"].array ?? []).map(TerminalRecord.init(raw:))
   246	    }
   247	
   248	    public func read(terminal: String, lines: Int = 200) async throws -> String {
   249	        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
   250	    }
   251	
   252	    // MARK: Streams
   253	
   254	    /// `terminal.attach`: opens a stream channel. Data that arrives before the
   255	    /// reply (or before handlers are set) is kept and delivered in order.
   256	    public func attach(terminal: String, cols: Int, rows: Int, history: Int = 2000,
   257	                       display: JSONValue? = nil, observe: Bool = false) async throws -> TerminalStream {
   258	        var p: JSONValue = ["terminal": .string(terminal), "cols": .number(Double(max(cols, 1))),
   259	                            "rows": .number(Double(max(rows, 1))), "history": .number(Double(history)), "observe": .bool(observe)]
   260	        if let display { p["display"] = display }
   261	        let r = try await call("terminal.attach", p)
   262	        guard let ch = r["channel"].uint64.map({ UInt32(clamping: $0) }), ch > 0 else {
   263	            throw HerdrError(code: -32603, kind: "internal", message: "attach reply had no channel")
   264	        }
   265	        let stream = TerminalStream(channel: ch, record: TerminalRecord(raw: r["terminal"]))
   266	        stream.sink = { [weak self] kind, payload in self?.streamSend(ch, kind, payload) }
   267	        let queue = callbackQueue
   268	        let backlog: [Frame]? = lock.withLock {
   269	            guard mode == .framed else { return nil }
   270	            routes[ch] = .terminal(stream)
   271	            let frames = early.removeValue(forKey: ch) ?? []
   272	            // Flush inside the lock so later frames queue behind these.
   273	            for f in frames { route(f, to: .terminal(stream), queue: queue) }
   274	            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
   275	            return frames
   276	        }
   277	        if backlog == nil { queue.async { stream.deliver(.lost) } }
   278	        return stream
   279	    }
   280	
   281	    /// `events.subscribe` with no filter (filtered subscriptions miss doc events).
   282	    public func subscribe(coalesce: TimeInterval = 0.08) async throws -> EventSubscription {
   283	        let r = try await call("events.subscribe", [:])
   284	        guard let ch = r["channel"].uint64.map({ UInt32(clamping: $0) }), ch > 0 else {
   285	            throw HerdrError(code: -32603, kind: "internal", message: "subscribe reply had no channel")
   286	        }
   287	        let sub = EventSubscription(channel: ch, snapshot: r, queue: callbackQueue, coalesce: coalesce)
   288	        sub.closer = { [weak self] in self?.streamSend(ch, FrameKind.close, Data()) }
   289	        let ok: Bool = lock.withLock {
   290	            guard mode == .framed else { return false }
   291	            routes[ch] = .events(sub)
   292	            let frames = early.removeValue(forKey: ch) ?? []
   293	            for f in frames { route(f, to: .events(sub), queue: callbackQueue) }
   294	            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
   295	            return true
   296	        }
   297	        guard ok else { throw HerdrError.lost }
   298	        send(Frame.credit(ch, 1 << 20))
   299	        return sub
   300	    }
   301	
   302	    private func streamSend(_ ch: UInt32, _ kind: UInt8, _ payload: Data) {
   303	        if kind == FrameKind.close {
   304	            let wasOpen: Bool = lock.withLock {
   305	                guard routes.removeValue(forKey: ch) != nil else { return false }
   306	                closing.insert(ch); return true
   307	            }
   308	            guard wasOpen else { return }
   309	        } else if kind == FrameKind.data, payload.isEmpty {
   310	            return
   311	        }
   312	        send(Frame(channel: ch, kind: kind, payload: payload))
   313	    }
   314	
   315	    private func send(_ f: Frame) {
   316	        outbox.yield(f.encoded())
   317	    }
   318	
   319	    // MARK: Reading
   320	
   321	    private func receive(_ bytes: Data) {
   322	        var actions: [() -> Void] = []
   323	        var protocolError: HerdrError?
   324	        lock.withLock {
   325	            lastReceive = Date()
   326	            switch mode {
   327	            case .idle, .closed:
   328	                return
   329	            case .plain:
   330	                plain.append(bytes)
   331	                guard let nl = plain.firstIndex(of: 0x0a) else { return }
   332	                let line = plain[plain.startIndex..<nl]
   333	                let rest = plain[plain.index(after: nl)...]
   334	                let reply = (try? JSONValue.parse(Data(line))) ?? .null
   335	                mode = .framed
   336	                decoder.append(Data(rest))
   337	                plain = Data()
   338	                if let c = helloCont {
   339	                    helloCont = nil
   340	                    if reply.isNull {
   341	                        actions.append { c.resume(throwing: HerdrError(kind: "parse_error", message: "The core's hello reply wasn't JSON")) }
   342	                    } else {
   343	                        actions.append { c.resume(returning: reply) }
   344	                    }
   345	                }
   346	            case .framed:
   347	                decoder.append(bytes)
   348	            }
   349	            do {
   350	                while let f = try decoder.next() { handle(f, &actions) }
   351	            } catch {
   352	                protocolError = HerdrError(code: -32700, kind: "lost", message: "Lost the core", hint: "\(error)")
   353	            }
   354	        }
   355	        for a in actions { a() }
   356	        if let protocolError { fail(protocolError); transport.close() }
   357	    }
   358	
   359	    /// Called with the lock held.
   360	    private func handle(_ f: Frame, _ actions: inout [() -> Void]) {
   361	        if f.channel == 0 {
   362	            guard f.kind == FrameKind.data, let msg = try? JSONValue.parse(f.payload),
   363	                  let id = msg["id"].uint64 else { return }
   364	            guard let cont = pending.removeValue(forKey: id) else {
   365	                // A reply nobody waits for (cancelled or timed out). If it opened a
   366	                // stream (attach, subscribe), close it so the core drops the viewer.
   367	                if let ch = msg["result"]["channel"].uint64.flatMap({ UInt32(exactly: $0) }), ch > 0, routes[ch] == nil {
   368	                    early.removeValue(forKey: ch)
   369	                    closing.insert(ch)
   370	                    send(Frame(channel: ch, kind: FrameKind.close, payload: Data()))
   371	                }
   372	                return
   373	            }
   374	            if msg["error"].isNull {
   375	                let result = msg["result"]
   376	                actions.append { cont.resume(returning: result) }
   377	            } else {
   378	                let err = Self.rpcError(msg["error"])
   379	                actions.append { cont.resume(throwing: err) }
   380	            }
   381	            return
   382	        }
   383	        if closing.contains(f.channel) {
   384	            if f.kind == FrameKind.close { closing.remove(f.channel) }
   385	            return
   386	        }
   387	        guard let r = routes[f.channel] else {
   388	            early[f.channel, default: []].append(f)
   389	            return
   390	        }
   391	        if f.kind == FrameKind.close { routes.removeValue(forKey: f.channel) }
   392	        route(f, to: r, queue: callbackQueue)
   393	    }
   394	
   395	    /// Called with the lock held.
   396	    private func route(_ f: Frame, to r: Route, queue: DispatchQueue) {
   397	        switch r {
   398	        case .terminal(let s):
   399	            switch f.kind {
   400	            case FrameKind.data:
   401	                let d = f.payload
   402	                queue.async { s.deliver(.data(d)) }
   403	            case FrameKind.close:
   404	                let why = f.payload.isEmpty ? JSONValue.null : ((try? JSONValue.parse(f.payload)) ?? .null)
   405	                queue.async { s.deliver(.close(why)) }
   406	            default: break
   407	            }
   408	        case .events(let sub):
   409	            switch f.kind {
   410	            case FrameKind.data:
   411	                sub.push(f.payload)
   412	                send(Frame.credit(f.channel, f.payload.count))
   413	            case FrameKind.close:
   414	                sub.ended(lost: false)
   415	            default: break
   416	            }
   417	        }
   418	    }
   419	
   420	    // MARK: Loss
   421	
   422	    private func transportClosed(_ err: Error?) {
   423	        let (hint, byUs): (String?, Bool) = lock.withLock {
   424	            (String(decoding: stderrBuf, as: UTF8.self).trimmed.nilIfEmpty, closedByUs)
   425	        }
   426	        if byUs { return }
   427	        fail(closedError(err, stderr: hint))
   428	    }
   429	
   430	    private func closedError(_ err: Error?, stderr: String? = nil) -> HerdrError {
   431	        let stderr = stderr ?? stderrText.trimmed.nilIfEmpty
   432	        if let stderr, stderr.contains("not installed") {
   433	            return HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine", hint: stderr)
   434	        }
   435	        return HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: stderr ?? err.map { "\($0.localizedDescription)" })
   436	    }
   437	
   438	    /// Fails everything once: pending calls, hello, every stream.
   439	    private func fail(_ error: HerdrError) {
   440	        var conts: [CheckedContinuation<JSONValue, Error>] = []
   441	        var helloC: CheckedContinuation<JSONValue, Error>?
   442	        var lostRoutes: [Route] = []
   443	        let first: Bool = lock.withLock {
   444	            guard mode != .closed else { return false }
   445	            mode = .closed
   446	            conts = Array(pending.values); pending.removeAll()
   447	            helloC = helloCont; helloCont = nil
   448	            lostRoutes = Array(routes.values); routes.removeAll(); early.removeAll(); closing.removeAll()
   449	            return true
   450	        }
   451	        guard first else { return }
   452	        livenessTask?.cancel()
   453	        outbox.finish()
   454	        let lost = HerdrError(code: -1, kind: error.kind ?? "lost", message: error.message, hint: error.hint)
   455	        helloC?.resume(throwing: lost)
   456	        for c in conts { c.resume(throwing: lost) }
   457	        let queue = callbackQueue
   458	        for r in lostRoutes {
   459	            switch r {
   460	            case .terminal(let s): queue.async { s.deliver(.lost) }
   461	            case .events(let sub): sub.ended(lost: true)
   462	            }
   463	        }
   464	        let cb: ((HerdrError) -> Void)? = lock.withLock { closedByUs ? nil : _onDisconnect }
   465	        if let cb { queue.async { cb(lost) } }
   466	    }
   467	
   468	    private func startLiveness() {
   469	        livenessTask = Task.detached { [weak self] in
   470	            while !Task.isCancelled {
   471	                try? await Task.sleep(for: .seconds(5))
   472	                guard let self else { return }
   473	                let idle = self.lock.withLock { Date().timeIntervalSince(self.lastReceive) }
   474	                if idle > self.livenessTimeout {
   475	                    self.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core",
   476	                                         hint: "no data for \(Int(idle)) s"))
   477	                    self.transport.close()
   478	                    return
   479	                }
   480	            }
   481	        }
   482	    }
   483	}
   484	
   485	/// What an events subscription delivered (coalesced).
   486	public struct EventUpdate: Sendable {
   487	    public var pushed: Pushed
   488	    /// Every terminal the stream describes (live and finished), stream order.
   489	    public var terminals: [TerminalRecord]
   490	    public var seq: UInt64
   491	}
   492	
   493	/// An `events.subscribe` channel. Lines are applied off the main thread;
   494	/// `onUpdate` gets coalesced results on the callback queue.
   495	public final class EventSubscription: @unchecked Sendable {
   496	    public let channel: UInt32
   497	    /// The snapshot from the subscribe reply (all terminals, live and finished).
   498	    public let snapshot: [TerminalRecord]
   499	    public let snapshotSeq: UInt64
   500	    public var onUpdate: ((EventUpdate) -> Void)? { didSet { queue.async { [weak self] in self?.flushIfReady() } } }
   501	    /// The core closed the channel: subscribe again.
   502	    public var onClose: (() -> Void)?
   503	    /// The connection dropped.
   504	    public var onLost: (() -> Void)?
   505	
   506	    var closer: (() -> Void)?
   507	    private let queue: DispatchQueue
   508	    private let coalesce: TimeInterval
   509	    private let lock = NSLock()
   510	    private var lines: EventLines
   511	    private var accumulated = Pushed()
   512	    private var scheduled = false
   513	    private var endedState: Bool?   // nil = open, false = closed by core, true = lost
   514	
   515	    init(channel: UInt32, snapshot: JSONValue, queue: DispatchQueue, coalesce: TimeInterval) {
   516	        self.channel = channel
   517	        self.queue = queue
   518	        self.coalesce = coalesce
   519	        lines = EventLines(snapshot: snapshot)
   520	        self.snapshot = lines.terminals.map(TerminalRecord.init(raw:))
   521	        snapshotSeq = lines.seq
   522	    }
   523	
   524	    /// Current state of every terminal (thread-safe).
   525	    public var terminals: [TerminalRecord] { lock.withLock { lines.terminals.map(TerminalRecord.init(raw:)) } }
   526	
   527	    /// Stop the subscription (sends CLOSE).
   528	    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }
   529	
   530	    /// Lines received so far (heartbeats included).
   531	    public var lineCount: Int { lock.withLock { linesSeen } }
   532	    private var linesSeen = 0
   533	
   534	    func push(_ bytes: Data) {
   535	        let schedule: Bool = lock.withLock {
   536	            let p = lines.push(bytes)
   537	            linesSeen += p.lines
   538	            accumulated.merge(p)
   539	            guard !scheduled, p.terminals || !p.docs.isEmpty || p.missed else { return false }
   540	            scheduled = true
   541	            return true
   542	        }
   543	        if schedule { queue.asyncAfter(deadline: .now() + coalesce) { [weak self] in self?.flushIfReady() } }
   544	    }
   545	
   546	    func ended(lost: Bool) {
   547	        lock.withLock { endedState = lost }
   548	        queue.async { [weak self] in
   549	            guard let self else { return }
   550	            self.flushIfReady()
   551	            if lost { self.onLost?() } else { self.onClose?() }
   552	        }
   553	    }
   554	
   555	    /// On the callback queue.
   556	    private func flushIfReady() {
   557	        guard let onUpdate else { return }
   558	        let update: EventUpdate? = lock.withLock {
   559	            scheduled = false
   560	            let p = accumulated
   561	            guard p.terminals || !p.docs.isEmpty || p.missed else { return nil }
   562	            accumulated = Pushed()
   563	            return EventUpdate(pushed: p, terminals: lines.terminals.map(TerminalRecord.init(raw:)), seq: lines.seq)
   564	        }
   565	        if let update { onUpdate(update) }
   566	    }
   567	}
   568	
   569	extension String {
   570	    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
   571	    var nilIfEmpty: String? { isEmpty ? nil : self }
   572	}

exec
/bin/zsh -lc 'nl -ba App/Sources/UI/FilesView.swift && nl -ba App/Sources/UI/SpaceView.swift && cat README.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	import SwiftUI
     2	import QuickLook
     3	import HerdrKit
     4	
     5	/// A space's folder on the box: browse it and open files in Quick Look
     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
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
    21	    @State private var error: String?
    22	    @State private var opening: String?
    23	    @State private var preview: URL?
    24	
    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
    26	    static let maxBytes = 12 << 20
    27	
    28	    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
    29	    static let listScript = """
    30	    import json, os, sys
    31	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    32	    out = []
    33	    with os.scandir(d) as it:
    34	        for e in it:
    35	            try:
    36	                isdir = e.is_dir()
    37	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
    38	            except OSError:
    39	                pass
    40	    print(json.dumps({"dir": d, "entries": out}))
    41	    """
    42	
    43	    var body: some View {
    44	        List {
    45	            if let error {
    46	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
    47	            }
    48	            ForEach(entries) { e in
    49	                if e.isDir, let dir {
    50	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
    51	                } else {
    52	                    Button { Task { await open(e) } } label: { row(e) }
    53	                        .disabled(opening != nil)
    54	                }
    55	            }
    56	        }
    57	        .overlay { if dir == nil && error == nil { ProgressView() } }
    58	        .navigationTitle(title)
    59	        .navigationBarTitleDisplayMode(.inline)
    60	        .task { await load() }
    61	        .refreshable { await load() }
    62	        .quickLookPreview($preview)
    63	    }
    64	
    65	    private func row(_ e: Entry) -> some View {
    66	        HStack(spacing: 12) {
    67	            Image(systemName: e.isDir ? "folder" : "doc")
    68	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
    69	                .frame(width: 22)
    70	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
    71	            Spacer(minLength: 8)
    72	            if opening == e.name {
    73	                ProgressView()
    74	            } else if !e.isDir {
    75	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
    76	            }
    77	        }
    78	        .accessibilityElement(children: .combine)
    79	        .accessibilityLabel(e.name)
    80	    }
    81	
    82	    private func load() async {
    83	        do {
    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
    86	                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    87	                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
    88	                return
    89	            }
    90	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
    91	                guard let n = a[0].string else { return nil }
    92	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
    93	            })
    94	            dir = d
    95	            error = nil
    96	        } catch {
    97	            self.error = error.localizedDescription
    98	        }
    99	    }
   100	
   101	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
   102	    static func sorted(_ entries: [Entry]) -> [Entry] {
   103	        entries.sorted { a, b in
   104	            if a.isDir != b.isDir { return a.isDir }
   105	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
   106	            if ad != bd { return bd }
   107	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
   108	        }
   109	    }
   110	
   111	    private func open(_ e: Entry) async {
   112	        guard let dir else { return }
   113	        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
   114	        guard e.size <= Self.maxBytes else {
   115	            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
   116	            return
   117	        }
   118	        opening = e.name
   119	        defer { opening = nil }
   120	        do {
   121	            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
   124	                return
   125	            }
   126	            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
   127	            try? FileManager.default.removeItem(at: folder)
   128	            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
   129	            let url = folder.appendingPathComponent(e.name)
   130	            try r.stdout.write(to: url, options: .completeFileProtection)
   131	            error = nil
   132	            preview = url
   133	        } catch {
   134	            self.error = error.localizedDescription
   135	        }
   136	    }
   137	}
   138	
   139	/// The Files sheet for one space: its own stack so folders push inside the sheet.
   140	struct FilesSheet: View {
   141	    @Environment(\.dismiss) private var dismiss
   142	    var folder: String
   143	    var title: String
   144	
   145	    var body: some View {
   146	        NavigationStack {
   147	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
   148	                .navigationDestination(for: String.self) { p in
   149	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
   150	                }
   151	                .toolbar {
   152	                    ToolbarItem(placement: .cancellationAction) {
   153	                        Button("Close", systemImage: "xmark") { dismiss() }
   154	                    }
   155	                }
   156	        }
   157	    }
   158	}
     1	import SwiftUI
     2	import HerdrKit
     3	
     4	/// One space: a glass chip bar of tabs, then the selected tab's panes.
     5	/// Phone: one pane at a time, paged. iPad: a grid of pane cards.
     6	struct SpaceView: View {
     7	    @Environment(AppStore.self) private var store
     8	    @Environment(Navigator.self) private var nav
     9	    @Environment(\.horizontalSizeClass) private var hsc
    10	    var spaceID: String
    11	    @State private var paneIndex = 0
    12	    @State private var showFiles = false
    13	
    14	    private var space: SpaceRef? { store.spaces.first { $0.id == spaceID } }
    15	
    16	    var body: some View {
    17	        Group {
    18	            if let space {
    19	                content(space)
    20	            } else {
    21	                ContentUnavailableView("Space closed", systemImage: "square.dashed",
    22	                                       description: Text("This space is no longer in the layout."))
    23	            }
    24	        }
    25	        .background(HC.canvas)
    26	        .navigationBarTitleDisplayMode(.inline)
    27	    }
    28	
    29	    private func selectedTab(_ space: SpaceRef) -> TabRef? {
    30	        let id = store.selectedTabBySpace[space.id]
    31	        return space.tabs.first { $0.id == id } ?? space.tabs.first
    32	    }
    33	
    34	    @ViewBuilder private func content(_ space: SpaceRef) -> some View {
    35	        let name = store.spaceName(space)
    36	        let tab = selectedTab(space)
    37	        VStack(spacing: 0) {
    38	            TabChipBar(space: space, selected: tab?.id) { id in
    39	                withAnimation(.smooth(duration: 0.25)) {
    40	                    store.selectedTabBySpace[space.id] = id
    41	                    paneIndex = 0
    42	                }
    43	            }
    44	            if let tab {
    45	                if tab.panes.isEmpty {
    46	                    ContentUnavailableView("Empty tab", systemImage: "rectangle.dashed")
    47	                } else if hsc == .regular {
    48	                    ScrollView {
    49	                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 380), spacing: 14)], spacing: 14) {
    50	                            ForEach(tab.panes) { pane in
    51	                                PaneCard(pane: pane, spaceName: name).frame(height: 360)
    52	                            }
    53	                        }
    54	                        .padding(16)
    55	                    }
    56	                } else {
    57	                    TabView(selection: $paneIndex) {
    58	                        ForEach(Array(tab.panes.enumerated()), id: \.element.id) { i, pane in
    59	                            PaneCard(pane: pane, spaceName: name)
    60	                                .padding(.horizontal, 16)
    61	                                .padding(.top, 12)
    62	                                .padding(.bottom, tab.panes.count > 1 ? 44 : 16)
    63	                                .tag(i)
    64	                        }
    65	                    }
    66	                    .tabViewStyle(.page(indexDisplayMode: tab.panes.count > 1 ? .always : .never))
    67	                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
    68	                    .id(tab.id)
    69	                }
    70	            } else {
    71	                ContentUnavailableView("No tabs", systemImage: "rectangle.stack")
    72	            }
    73	        }
    74	        .toolbar {
    75	            ToolbarItem(placement: .principal) {
    76	                HStack(spacing: 8) {
    77	                    SpaceBadge(name: name.isEmpty ? "~" : name, colorKey: SpaceBadge.colorKey(for: space.id), size: 20)
    78	                    Text(name.isEmpty ? "~" : name).font(HF.ui(16, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
    79	                }
    80	            }
    81	            ToolbarItem(placement: .topBarTrailing) {
    82	                Button { showFiles = true } label: { Image(systemName: "folder") }
    83	                    .accessibilityLabel("Files")
    84	            }
    85	            ToolbarItem(placement: .topBarTrailing) {
    86	                Button { nav.newAgentSpace = space.id; nav.showNewAgent = true } label: { Image(systemName: "plus") }
    87	                    .accessibilityLabel("New agent in this space")
    88	            }
    89	        }
    90	        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
    91	        .onAppear { store.selectedSpaceID = space.id }
    92	    }
    93	}
    94	
    95	/// Horizontally scrolling glass chips, one per tab, tinted by status.
    96	struct TabChipBar: View {
    97	    @Environment(AppStore.self) private var store
    98	    var space: SpaceRef
    99	    var selected: String?
   100	    var onSelect: (String) -> Void
   101	
   102	    var body: some View {
   103	        ScrollViewReader { proxy in
   104	            ScrollView(.horizontal) {
   105	                GlassEffectContainer(spacing: 6) {
   106	                    HStack(spacing: 6) {
   107	                        ForEach(Array(space.tabs.enumerated()), id: \.element.id) { i, tab in
   108	                            chip(tab, index: i).id(tab.id)
   109	                        }
   110	                    }
   111	                    .padding(.horizontal, 16)
   112	                    .padding(.vertical, 8)
   113	                }
   114	            }
   115	            .scrollIndicators(.hidden)
   116	            .onAppear { if let selected { proxy.scrollTo(selected, anchor: .center) } }
   117	            .onChange(of: selected) { _, s in withAnimation { proxy.scrollTo(s, anchor: .center) } }
   118	        }
   119	    }
   120	
   121	    private func chip(_ tab: TabRef, index: Int) -> some View {
   122	        let att = store.attention(ofTab: tab.id)
   123	        let isSel = tab.id == selected
   124	        let firstTerminal = tab.panes.lazy.compactMap(\.terminal).first
   125	        return Button { onSelect(tab.id) } label: {
   126	            HStack(spacing: 7) {
   127	                ProgramIcon(program: firstTerminal.flatMap { store.programKey(of: $0) }, size: 14)
   128	                Text(store.tabName(tab, index: index))
   129	                    .font(HF.ui(14, isSel ? .semibold : .medium))
   130	                    .foregroundStyle(isSel ? HC.fg : HC.muted)
   131	                    .lineLimit(1)
   132	                    .frame(maxWidth: 170)
   133	                StatusMark(attention: att, compact: true)
   134	            }
   135	            .padding(.horizontal, 12)
   136	            .frame(height: 34)
   137	        }
   138	        .buttonStyle(.plain)
   139	        .contentShape(.rect(cornerRadius: HM.chipRadius))
   140	        .glassEffect(glass(att, selected: isSel), in: .rect(cornerRadius: HM.chipRadius))
   141	    }
   142	
   143	    private func glass(_ a: Attention, selected: Bool) -> Glass {
   144	        let base: Glass = .regular.interactive()
   145	        switch a {
   146	        case .blocked: return base.tint(HC.blocked.opacity(selected ? 0.35 : 0.2))
   147	        case .working: return base.tint(HC.working.opacity(selected ? 0.28 : 0.14))
   148	        case .done: return base.tint(HC.done.opacity(selected ? 0.3 : 0.16))
   149	        default: return selected ? base.tint(HC.selected) : base
   150	        }
   151	    }
   152	}
   153	
   154	/// One pane as a crisp card: header + a text preview of the screen. Tap opens the terminal.
   155	struct PaneCard: View {
   156	    @Environment(AppStore.self) private var store
   157	    @Environment(Navigator.self) private var nav
   158	    var pane: PaneRef
   159	    var spaceName: String
   160	
   161	    var body: some View {
   162	        VStack(spacing: 0) {
   163	            if let addr = pane.terminal {
   164	                Button { nav.open(.terminal(addr)) } label: {
   165	                    VStack(spacing: 0) {
   166	                        header(addr)
   167	                        Rectangle().fill(HC.border).frame(height: HM.hairline)
   168	                        TerminalPreview(address: addr)
   169	                    }
   170	                    .contentShape(.rect)
   171	                }
   172	                .buttonStyle(.plain)
   173	            } else if let mod = pane.mod {
   174	                HStack {
   175	                    Image(systemName: "puzzlepiece.extension").foregroundStyle(HC.muted)
   176	                    Text(mod).font(HF.ui(13.5, .medium)).foregroundStyle(HC.fg)
   177	                    Spacer()
   178	                }
   179	                .padding(.horizontal, 12).frame(height: 38)
   180	                Rectangle().fill(HC.border).frame(height: HM.hairline)
   181	                ModPanelView(mod: mod, props: pane.modProps.object?.mapValues(\.any))
   182	                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
   183	            } else {
   184	                Spacer()
   185	            }
   186	        }
   187	        .clipShape(.rect(cornerRadius: HM.cardRadius))
   188	        .herdrCard()
   189	    }
   190	
   191	    private func header(_ addr: String) -> some View {
   192	        let rec = store.terminals[addr]
   193	        return HStack(spacing: 8) {
   194	            ProgramIcon(program: store.programKey(of: addr), size: 16)
   195	            Text(store.displayName(of: addr)).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(1)
   196	            Text(store.tildePath(rec?.cwd ?? "")).font(HF.ui(12.5)).foregroundStyle(HC.dim).lineLimit(1)
   197	            Spacer(minLength: 4)
   198	            StatusMark(attention: store.attention(of: addr))
   199	            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(HC.dim)
   200	        }
   201	        .padding(.horizontal, 12)
   202	        .frame(height: 40)
   203	    }
   204	}
   205	
   206	/// Plain-text tail of a terminal (terminal.read), refreshed when its turn/status changes.
   207	struct TerminalPreview: View {
   208	    @Environment(AppStore.self) private var store
   209	    var address: String
   210	    @State private var text: String = ""
   211	    @State private var loaded = false
   212	
   213	    var body: some View {
   214	        let rec = store.terminals[address]
   215	        let key = "\(address)|\(rec?.turn ?? 0)|\(rec?.statusWord ?? "")|\(rec?.title ?? "")"
   216	        ZStack(alignment: .bottomLeading) {
   217	            HC.background
   218	            if text.isEmpty {
   219	                VStack(spacing: 8) {
   220	                    Image(systemName: "terminal").font(.system(size: 22, weight: .light)).foregroundStyle(HC.dim)
   221	                    Text(loaded ? "Tap to open" : "Loading…").font(HF.ui(13)).foregroundStyle(HC.dim)
   222	                }
   223	                .frame(maxWidth: .infinity, maxHeight: .infinity)
   224	            } else {
   225	                // A cropped screen: one Text per line, never soft-wrapped. In an overlay
   226	                // so lines wider than the card pin to the left edge instead of centring.
   227	                Color.clear
   228	                    .overlay(alignment: .bottomLeading) {
   229	                        VStack(alignment: .leading, spacing: 1) {
   230	                            ForEach(Array(text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { _, line in
   231	                                Text(line.isEmpty ? " " : String(line)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
   232	                            }
   233	                        }
   234	                        .font(HF.mono(10.5))
   235	                        .foregroundStyle(Color(uiColor: .herdr("terminal_foreground")))
   236	                        .padding(10)
   237	                    }
   238	                    .clipped()
   239	            }
   240	        }
   241	        .task(id: key) {
   242	            let t = (try? await store.read(address, lines: 60)) ?? ""
   243	            text = Self.trim(t)
   244	            loaded = true
   245	        }
   246	    }
   247	
   248	    /// Drop trailing blank lines so the preview hugs the bottom.
   249	    private static func trim(_ s: String) -> String {
   250	        var lines = s.split(separator: "\n", omittingEmptySubsequences: false).map { $0.replacingOccurrences(of: "\r", with: "") }
   251	        while let l = lines.last, l.trimmingCharacters(in: .whitespaces).isEmpty { lines.removeLast() }
   252	        return lines.suffix(60).joined(separator: "\n")
   253	    }
   254	}
# Herdr for iOS (unofficial)

A native iPhone and iPad client for [herdr](https://herdr.dev). See which of your coding agents need you, read and answer them, and open their live terminals. It connects over plain SSH to the `herdr-core` already running on your machine.

<p>
<img src="docs/demo.gif" width="300" alt="Demo: agents by attention, an agent's Chat, a space, starting an agent, and a 'needs you' notification" />
<img src="docs/screenshots/notification.png" width="300" alt="A time-sensitive notification: OAuth needs you, with the agent's question and options" />
</p>
<p><a href="docs/demo.mp4">Full demo video (MP4, 53 s)</a> · demo data, recorded in the iOS simulator</p>

<p>
<img src="docs/screenshots/home-dark.png" width="240" alt="Home: agents grouped by Needs you, Working and Idle, then spaces" />
<img src="docs/screenshots/chat-dark.png" width="240" alt="Chat: an agent's conversation as native messages, with folded work and a table" />
<img src="docs/screenshots/new-dark.png" width="240" alt="New agent: pick a program, a space and an optional first task" />
</p>
<p>
<img src="docs/screenshots/home-light.png" width="240" alt="Home in light mode" />
<img src="docs/screenshots/chat-light.png" width="240" alt="Chat in light mode" />
</p>

## What it does

- **Agents, sorted by who needs you.** Every agent on the machine is grouped as Needs you, Working, Done or Idle, using herdr's own status words and "done while you weren't looking" rule. Sub-agents nest under their parent.
- **Spaces and tabs.** The same spaces, tabs and panes as the desktop app, read live from the core's `herdr-app` layout document. Changes you make on one screen show up on the other.
- **Chat** (Claude Code). An agent's conversation as native messages instead of a terminal:
  - prompts appear as bubbles, replies as formatted text with tables;
  - finished turns fold behind "Worked for 5m 18s · 12 steps";
  - each tool call is one tappable line;
  - a blocked agent's dialog becomes buttons.
- **Terminal.** The real terminal (SwiftTerm), mirroring the desktop size by default with pinch-to-zoom. A "Fit to phone" toggle resizes it to the phone instead. A glass key bar adds esc, ctrl, arrows and ^C, and a compose box sends whole prompts.
- **New agents.** Start Claude Code, Codex, a shell or any program from herdr's list, in an existing space or a new folder, with an optional first task.
- **Notifications.** Get "OAuth needs you" (with the agent's question and options) or "Refactor finished", even when the app is closed; tap to open that agent. Your machine sends them straight to Apple, with no relay in between.
- **Mods.** Your own herdr mods run on the phone. A small JavaScriptCore host implements the `herdr`, `gpui-kit` and `gpui-base` APIs they use and draws their element trees in SwiftUI. Their `exec` calls run on the box.
- **herdr's look.** It uses the Graphite and Paper themes, Geist and JetBrains Mono, and herdr's status marks, with iOS 26 Liquid Glass on the chrome only.

## How it connects

The app opens an SSH exec channel to your machine and runs `herdr-core connect`. That's the same framed JSON-RPC stream the desktop app uses for remote machines (`ssh box hc connect`). Nothing else needs to be installed on the machine, and no server or relay is involved.

- **Login:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
- **Host key:** the box's host key is pinned on first connect.
- **Network:** the box has to be reachable from the phone, for example over Tailscale.
- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap.
- **Opening Chat** never attaches to the terminal, so it doesn't resize anything on your desktop.

## Notifications

iOS closes the app's SSH connection in the background, so the phone can't see an agent start waiting. Your machine sends the notification instead:
- **The notifier:** `herdr-notify` is a short Python script running as a systemd user service. It follows `hc events` and, when an agent becomes blocked or finishes a turn, pushes to Apple over HTTP/2 with your APNs key.
- **Your phone's address:** the app hands its push token to the machine over the open connection, in `~/.config/herdr-ios/devices/`.

Setup needs a paid Apple Developer account:
1. Create an APNs key at developer.apple.com → Certificates, IDs & Profiles → Keys, with Apple Push Notifications service enabled.
2. Install the notifier, either from the app (Settings → Notifications → Set up on <machine>, then choose the `.p8`) or from your Mac:
   ```sh
   scripts/install-notifier.sh <ssh host> AuthKey_XXXXXXXXXX.p8 <team id> <bundle id>
   ```
3. Open Herdr while connected and allow notifications. Settings → Notifications → Send a test.

The key stays on your machine in `~/.config/herdr-ios`, readable only by you. Sub-agents and plain shells don't notify, and you can tune what does in `~/.config/herdr-ios/notify.json` (`{"on": ["blocked", "done"]}`).

## Build and run

Requirements:
- **Mac:** macOS with Xcode 26.2+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).
- **Phone:** iOS 26.
- **Optional:** [bun](https://bun.sh), to bundle your mods.
- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat.

```sh
git clone https://github.com/zzulanas/herdr-ios && cd herdr-ios
cp Config/Local.example.xcconfig Config/Local.xcconfig   # your team id and bundle id
xcodegen generate
open Herdr.xcodeproj                                     # run the Herdr scheme
```

Command-line builds need `-skipPackagePluginValidation` (SwiftTerm ships a build plugin).

### Your mods

List the mods to bundle in `Config/mods.txt`, one per line. Each line has the folder name in `~/.config/herdr-app/mods`, plus the block id it uses in the desktop layout if that differs from the name:

```
linear
prs
my-drawer drawer
```

The pre-build step bundles them with bun into `App/Resources/Mods`. That folder is gitignored, so each person ships their own mods. Machine-specific tweaks to a mod's `exec` go in `Config/host-local.js`, also gitignored:

```js
herdrIOS.onExec((cmd, args, on) => ({ cmd, args }))
```

## Layout

```
Packages/HerdrKit     protocol and model (SwiftPM, platform-independent, unit-tested)
  HerdrClient         framing, JSON-RPC, terminal streams with credit, events
  Layout / Names      the herdr-app layout doc: parse and edit, keeping unknown fields
  herdr-probe         macOS CLI that speaks the protocol over `ssh <host>`
App/Sources
  Net                 Citadel SSH transport, Keychain key store, host-key pinning
  Store               AppStore: connection, live terminals and layout, attention, actions
  UI                  SwiftUI screens, theme, terminal (SwiftTerm)
  Chat                transcript reader and Chat view
  Mods                JavaScriptCore mod host and SwiftUI renderer
scripts/              mod bundling and a headless mod test
```

Tests:
- **Protocol and model:** `cd Packages/HerdrKit && swift test`.
- **UI:** run the `HerdrUITests` target against a real box in watch-only mode. Set `HERDR_DEBUG_KEY_PATH` and `HERDR_TEST_TERMINAL`.
- **Demo data:** `HERDR_DEMO=1` launches with fake data, which is how these screenshots were made.

## Status

This is early. It's tested against herdr-core 0.1.14 on a real Linux machine. Known gaps:
- Chat covers Claude Code only.
- Replying straight from a notification (Yes/No) isn't built yet; tapping opens the agent.
- Machines added inside herdr-core (`hc machine add`) aren't browsable yet.

## Credits

- [herdr](https://herdr.dev) and [herdr-app](https://github.com/herdrdev/herdr-app) by [ogulcancelik](https://github.com/ogulcancelik); this app's icon, themes and program icons come from herdr-app.
- The Chat view was inspired by [Heeler](https://github.com/ZingerLittleBee/Heeler).
- See [NOTICE](NOTICE) for third-party licenses.

Not affiliated with or endorsed by the herdr project.

## License

[Apache-2.0](LICENSE)

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc 'git show HEAD -- && cat AGENTS.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 6c7e200ae6bb6ec4d3cc94e86232ac2a3afa69ff
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Sun Nov 1 03:52:21 2026 +0900

    Browse a space's folder and preview its files in Quick Look
    
    The phone had no way to read what agents produce on the box: PDFs, Office
    documents, images. Files lists the space folder with the box's python3 (as
    Chat already does) and fetches a file with cat over machine.exec into a
    temporary file for Quick Look, which renders PDF, docx, xlsx and images on
    the device. Files over 12 MiB are refused for now: one exec reply must fit
    in a 16 MiB frame as base64.

diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
new file mode 100644
index 0000000..ab485c0
--- /dev/null
+++ b/App/Sources/UI/FilesView.swift
@@ -0,0 +1,158 @@
+import SwiftUI
+import QuickLook
+import HerdrKit
+
+/// A space's folder on the box: browse it and open files in Quick Look
+/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
+struct FilesView: View {
+    @Environment(AppStore.self) private var store
+    var path: String
+    var title: String
+
+    struct Entry: Identifiable, Hashable {
+        var name: String
+        var isDir: Bool
+        var size: Int
+        var id: String { name }
+    }
+
+    @State private var dir: String?
+    @State private var entries: [Entry] = []
+    @State private var error: String?
+    @State private var opening: String?
+    @State private var preview: URL?
+
+    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
+    static let maxBytes = 12 << 20
+
+    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
+    static let listScript = """
+    import json, os, sys
+    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
+    out = []
+    with os.scandir(d) as it:
+        for e in it:
+            try:
+                isdir = e.is_dir()
+                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
+            except OSError:
+                pass
+    print(json.dumps({"dir": d, "entries": out}))
+    """
+
+    var body: some View {
+        List {
+            if let error {
+                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
+            }
+            ForEach(entries) { e in
+                if e.isDir, let dir {
+                    NavigationLink(value: dir + "/" + e.name) { row(e) }
+                } else {
+                    Button { Task { await open(e) } } label: { row(e) }
+                        .disabled(opening != nil)
+                }
+            }
+        }
+        .overlay { if dir == nil && error == nil { ProgressView() } }
+        .navigationTitle(title)
+        .navigationBarTitleDisplayMode(.inline)
+        .task { await load() }
+        .refreshable { await load() }
+        .quickLookPreview($preview)
+    }
+
+    private func row(_ e: Entry) -> some View {
+        HStack(spacing: 12) {
+            Image(systemName: e.isDir ? "folder" : "doc")
+                .foregroundStyle(e.isDir ? HC.working : HC.muted)
+                .frame(width: 22)
+            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
+            Spacer(minLength: 8)
+            if opening == e.name {
+                ProgressView()
+            } else if !e.isDir {
+                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
+            }
+        }
+        .accessibilityElement(children: .combine)
+        .accessibilityLabel(e.name)
+    }
+
+    private func load() async {
+        do {
+            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
+            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
+                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
+                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
+                return
+            }
+            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
+                guard let n = a[0].string else { return nil }
+                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
+            })
+            dir = d
+            error = nil
+        } catch {
+            self.error = error.localizedDescription
+        }
+    }
+
+    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
+    static func sorted(_ entries: [Entry]) -> [Entry] {
+        entries.sorted { a, b in
+            if a.isDir != b.isDir { return a.isDir }
+            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
+            if ad != bd { return bd }
+            return a.name.localizedStandardCompare(b.name) == .orderedAscending
+        }
+    }
+
+    private func open(_ e: Entry) async {
+        guard let dir else { return }
+        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
+        guard e.size <= Self.maxBytes else {
+            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
+            return
+        }
+        opening = e.name
+        defer { opening = nil }
+        do {
+            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
+            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
+                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
+                return
+            }
+            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
+            try? FileManager.default.removeItem(at: folder)
+            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
+            let url = folder.appendingPathComponent(e.name)
+            try r.stdout.write(to: url, options: .completeFileProtection)
+            error = nil
+            preview = url
+        } catch {
+            self.error = error.localizedDescription
+        }
+    }
+}
+
+/// The Files sheet for one space: its own stack so folders push inside the sheet.
+struct FilesSheet: View {
+    @Environment(\.dismiss) private var dismiss
+    var folder: String
+    var title: String
+
+    var body: some View {
+        NavigationStack {
+            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
+                .navigationDestination(for: String.self) { p in
+                    FilesView(path: p, title: (p as NSString).lastPathComponent)
+                }
+                .toolbar {
+                    ToolbarItem(placement: .cancellationAction) {
+                        Button("Close", systemImage: "xmark") { dismiss() }
+                    }
+                }
+        }
+    }
+}
diff --git a/App/Sources/UI/SpaceView.swift b/App/Sources/UI/SpaceView.swift
index c37e929..b47a42b 100644
--- a/App/Sources/UI/SpaceView.swift
+++ b/App/Sources/UI/SpaceView.swift
@@ -9,6 +9,7 @@ struct SpaceView: View {
     @Environment(\.horizontalSizeClass) private var hsc
     var spaceID: String
     @State private var paneIndex = 0
+    @State private var showFiles = false
 
     private var space: SpaceRef? { store.spaces.first { $0.id == spaceID } }
 
@@ -77,11 +78,16 @@ struct SpaceView: View {
                     Text(name.isEmpty ? "~" : name).font(HF.ui(16, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
                 }
             }
+            ToolbarItem(placement: .topBarTrailing) {
+                Button { showFiles = true } label: { Image(systemName: "folder") }
+                    .accessibilityLabel("Files")
+            }
             ToolbarItem(placement: .topBarTrailing) {
                 Button { nav.newAgentSpace = space.id; nav.showNewAgent = true } label: { Image(systemName: "plus") }
                     .accessibilityLabel("New agent in this space")
             }
         }
+        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
         .onAppear { store.selectedSpaceID = space.id }
     }
 }
diff --git a/UITests/HerdrUITests.swift b/UITests/HerdrUITests.swift
index 5f9cfea..4b4feed 100644
--- a/UITests/HerdrUITests.swift
+++ b/UITests/HerdrUITests.swift
@@ -61,6 +61,35 @@ final class HerdrUITests: XCTestCase {
         shot(app, "home-after-approval")
     }
 
+    /// Files: from a space ($HERDR_TEST_SPACE) walk $HERDR_TEST_FILES_PATH (slash-separated folders
+    /// under the space folder) and open each of $HERDR_TEST_FILES (comma-separated) in Quick Look.
+    /// Needs a pinned host key (run testFirstConnectAsksForHostKey first).
+    func testFilesPreviewInQuickLook() throws {
+        let env = ProcessInfo.processInfo.environment
+        let app = launch(["HERDR_DEBUG_OPEN": try XCTUnwrap(env["HERDR_TEST_SPACE"])])
+        let files = app.buttons["Files"]
+        XCTAssertTrue(files.waitForExistence(timeout: 30), "no Files button in the space")
+        files.tap()
+        for folder in (env["HERDR_TEST_FILES_PATH"] ?? "").split(separator: "/") {
+            let row = app.buttons[String(folder)]
+            XCTAssertTrue(row.waitForExistence(timeout: 20), "no folder \(folder)")
+            row.tap()
+        }
+        for name in try XCTUnwrap(env["HERDR_TEST_FILES"]).split(separator: ",").map(String.init) {
+            let row = app.buttons[name]
+            XCTAssertTrue(row.waitForExistence(timeout: 20), "no file \(name)")
+            row.tap()
+            let done = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'QLOverlayDoneButton'")).firstMatch
+            // Images open full screen with the controls hidden; a tap brings them back.
+            if !done.waitForExistence(timeout: 15) { app.tap() }
+            XCTAssertTrue(done.waitForExistence(timeout: 15), "Quick Look did not open \(name)")
+            sleep(2)
+            shot(app, "preview-\(name)")
+            done.tap()
+            XCTAssertTrue(row.waitForExistence(timeout: 10), "did not return to the list after \(name)")
+        }
+    }
+
     /// Chat reads a Claude agent's transcript ($HERDR_TEST_TERMINAL); folds open on tap. Never sends anything.
     func testChatRendersAndFolds() throws {
         let app = launch(["HERDR_DEBUG_OPEN": ProcessInfo.processInfo.environment["HERDR_TEST_TERMINAL"] ?? "t1"])
# herdr-pocket

A native iPhone and iPad client for herdr-core: read and answer Claude Code and Codex sessions as chat, preview the box's files, and see every agent's state, while the desktop uses the Herdr app on the same herdr-core. The app talks to herdr-core only over SSH (an exec channel running `herdr-core connect`), with no resident server or third-party relay. It is a fork of `zzulanas/herdr-ios` (`upstream`); `origin` is `YosukeIida/herdr-pocket`. Why this base was chosen and what it lacks are in `docs/2026-11-01_existing-apps-and-orca-mobile-survey.md` and `docs/2026-11-01_herdr-ios-code-review.md`.

## Layout

- `Packages/HerdrKit`: protocol and model (SwiftPM, no external dependencies, unit tests). Run `swift test` there.
- `App/Sources`: the iOS app (SwiftUI). Net (Citadel SSH, Keychain), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore), Notify.
- `project.yml`: XcodeGen spec. `Herdr.xcodeproj` is generated (`xcodegen generate`) and not tracked.
- Requires iOS 26 or later. Develop against the iOS simulator on the Mac; the simulator reaches the Mac's own sshd at `127.0.0.1`.

## Language

Write repository files (README, AGENTS.md, everything under `docs/`, code comments, commit messages) in English unless a file says otherwise. The English file is the source of truth. Markdown documents also get a Japanese translation next to them as `<name>.ja.md` (`AGENTS.ja.md`, `docs/<name>.ja.md`), updated in the same change as the English file. Working notes overwritten every session (`docs/HANDOVER.md`, `docs/reviews/PENDING.md`) and raw reviewer output (`docs/reviews/*-codex.md`) get no translation. Files inherited from upstream (README.md) get a translation when we first change them.

## How work is done (the sandwich)

1. Design and implementation: Claude Opus 5.5 (`claude-opus-5-5`).
2. Review: Codex `gpt-6.1-sol`, effort medium, on the labteam account (`CODEX_HOME=$HOME/.codex-labteam`, or `cx labteam` before starting Codex). Review only, read-only sandbox, no edits. Raw output goes to `docs/reviews/<date>-<unit>-codex.md`.
3. Judgement: Claude Opus 5.5. For each finding, decide fix or no fix and why (`docs/reviews/<date>-<unit>-judgement.md`), and send the fixes back to step 1.

When labteam credits run out, do not switch accounts and do not skip the review: list the unit in `docs/reviews/PENDING.md` and continue with work that does not depend on it.

## Environment

The devshell (`.envrc` → `nix/flake.nix`) provides XcodeGen and bun; Swift and the iOS SDK come from Xcode. Agents get it from dotfiles' agent-switch shims, which load direnv when `claude` or `codex` starts in the repo. Command-line builds need `-skipPackagePluginValidation` (SwiftTerm ships a build plugin). `scripts/bundle-mods.sh` runs as an unsandboxed pre-build step; read any change to it before building.

## Prior art

- Upstream `zzulanas/herdr-ios` (Apache-2.0). Keep `NOTICE` and the license; changes we want upstream go as PRs from a branch, not from `main`.
- Heeler (`ZingerLittleBee/Heeler`, Apache-2.0): SSH, terminal and chat views; PR #538 has herdr-core support.
- HerdrChat (Apache-2.0): Claude and Codex transcript parsing.
- Ovis, Collie (MIT): herdr-core adapters; Collie's `docs/multiplexers.md` lists herdr-core's limits.
- Orca Mobile (`stablyai/orca`) and opencode: references for chat behaviour. Check each license before reusing code, and note the source in any file that reuses it.

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
exec
/bin/zsh -lc "nl -ba Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift | sed -n '1,260p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
     1	import Foundation
     2	
     3	/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
     4	/// JSON-RPC on channel 0, terminal and event streams on core-allocated channels.
     5	///
     6	/// Thread model: transport bytes are parsed on whatever thread the transport
     7	/// calls back on (serially), under one lock. Writes go through a single serial
     8	/// writer task. Stream and event callbacks are delivered on `callbackQueue`.
     9	public final class HerdrClient: @unchecked Sendable {
    10	    public let transport: ByteTransport
    11	    /// Where stream/event/disconnect callbacks run. Set before `connect()`.
    12	    public var callbackQueue: DispatchQueue = .main
    13	    /// No bytes on any channel for this long = the connection is dead.
    14	    public var livenessTimeout: TimeInterval = 45
    15	    /// Called once on `callbackQueue` when the connection drops unexpectedly
    16	    /// (not after `close()`).
    17	    public var onDisconnect: ((HerdrError) -> Void)? {
    18	        get { lock.withLock { _onDisconnect } }
    19	        set { lock.withLock { _onDisconnect = newValue } }
    20	    }
    21	    private var _onDisconnect: ((HerdrError) -> Void)?
    22	
    23	    public private(set) var hello: HelloInfo?
    24	    /// Remote stderr so far (capped), for failure screens.
    25	    public var stderrText: String { lock.withLock { String(decoding: stderrBuf, as: UTF8.self) } }
    26	
    27	    /// Methods the app calls; a core lacking one can't serve it.
    28	    public static let requiredMethods = ["terminal.run", "terminal.list", "terminal.get", "terminal.kill", "terminal.label",
    29	                                         "terminal.attach", "terminal.keep", "terminal.read", "terminal.send", "terminal.keys",
    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
    31	                                         "machine.list", "server.status"]
    32	    public static let minCoreVersion = "0.1.11"
    33	    public static let generation: UInt64 = 1
    34	
    35	    private enum Route { case terminal(TerminalStream), events(EventSubscription) }
    36	    private enum Mode { case idle, plain, framed, closed }
    37	
    38	    private let lock = NSLock()
    39	    private var mode = Mode.idle
    40	    private var plain = Data()
    41	    private var helloCont: CheckedContinuation<JSONValue, Error>?
    42	    private var decoder = FrameDecoder()
    43	    private var nextID: UInt64 = 0
    44	    private var pending: [UInt64: CheckedContinuation<JSONValue, Error>] = [:]
    45	    private var cancelled: Set<UInt64> = []
    46	    private var routes: [UInt32: Route] = [:]
    47	    private var early: [UInt32: [Frame]] = [:]
    48	    /// Channels we closed: drop their frames, swallow the CLOSE echo.
    49	    private var closing: Set<UInt32> = []
    50	    private var lastReceive = Date()
    51	    private var stderrBuf = Data()
    52	    private var closedByUs = false
    53	
    54	    private let outbox: AsyncStream<Data>.Continuation
    55	    private let outStream: AsyncStream<Data>
    56	    private var writerTask: Task<Void, Never>?
    57	    private var livenessTask: Task<Void, Never>?
    58	
    59	    public init(transport: ByteTransport) {
    60	        self.transport = transport
    61	        (outStream, outbox) = AsyncStream<Data>.makeStream(bufferingPolicy: .unbounded)
    62	    }
    63	
    64	    deinit {
    65	        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
    66	    }
    67	
    68	    public var isConnected: Bool { lock.withLock { mode == .framed } }
    69	
    70	    // MARK: Connect
    71	
    72	    /// Starts the transport, says hello in plain mode, then switches to frames.
    73	    public func connect(helloTimeout: TimeInterval = 20) async throws -> HelloInfo {
    74	        let started: Bool = lock.withLock {
    75	            guard mode == .idle else { return false }
    76	            mode = .plain; lastReceive = Date(); return true
    77	        }
    78	        guard started else { throw HerdrError(kind: "state", message: "Client already used; make a new one") }
    79	
    80	        writerTask = Task.detached(priority: .userInitiated) { [outStream, transport, weak self] in
    81	            for await chunk in outStream {
    82	                do { try await transport.write(chunk) } catch {
    83	                    self?.fail(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: error.localizedDescription))
    84	                    return
    85	                }
    86	            }
    87	        }
    88	
    89	        try await transport.start(
    90	            onBytes: { [weak self] in self?.receive($0) },
    91	            onStderr: { [weak self] d in self?.lock.withLock {
    92	                guard let self, self.stderrBuf.count < 16_384 else { return }
    93	                self.stderrBuf.append(d.prefix(16_384 - self.stderrBuf.count))
    94	            } },
    95	            onClose: { [weak self] err in self?.transportClosed(err) })
    96	
    97	        let reply: JSONValue = try await withCheckedThrowingContinuation { cont in
    98	            let alreadyClosed: Bool = lock.withLock {
    99	                if mode == .closed { return true }
   100	                helloCont = cont; return false
   101	            }
   102	            if alreadyClosed { cont.resume(throwing: closedError(nil)); return }
   103	            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
   104	            DispatchQueue.global().asyncAfter(deadline: .now() + helloTimeout) { [weak self] in
   105	                guard let self, let c = self.lock.withLock({ () -> CheckedContinuation<JSONValue, Error>? in
   106	                    defer { self.helloCont = nil }; return self.helloCont
   107	                }) else { return }
   108	                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
   109	                                              hint: self.stderrText.trimmed.nilIfEmpty))
   110	                self.close()
   111	            }
   112	        }
   113	        do {
   114	            let info = try Self.check(hello: reply)
   115	            lock.withLock { hello = info }
   116	            startLiveness()
   117	            return info
   118	        } catch {
   119	            close()
   120	            throw error
   121	        }
   122	    }
   123	
   124	    /// Validates a hello reply (SPEC.md §1 Compatibility checks).
   125	    public static func check(hello reply: JSONValue) throws -> HelloInfo {
   126	        if !reply["error"].isNull { throw rpcError(reply["error"]) }
   127	        let r = reply["result"]
   128	        let gen = r["generation"].uint64 ?? 0
   129	        let version = r["version"].string ?? "0"
   130	        if gen > generation {
   131	            throw HerdrError(kind: "needs_update", message: "This app is too old for herdr-core \(version)", hint: "update Herdr")
   132	        }
   133	        if gen < generation || semverLess(semver(version), semver(minCoreVersion)) {
   134	            throw HerdrError(kind: "needs_update", message: "herdr-core \(version) is too old", hint: "update it to \(minCoreVersion) or newer")
   135	        }
   136	        let methods = r["methods"].array?.compactMap(\.string) ?? []
   137	        let missing = requiredMethods.filter { !methods.contains($0) }
   138	        if !missing.isEmpty {
   139	            throw HerdrError(kind: "needs_update", message: "herdr-core lacks \(missing.joined(separator: ", "))", hint: "update herdr-core")
   140	        }
   141	        return HelloInfo(coreID: r["core"]["id"].string ?? "", coreName: r["core"]["name"].string ?? "",
   142	                         version: version, methods: methods)
   143	    }
   144	
   145	    static func semverLess(_ a: [Int], _ b: [Int]) -> Bool { a.lexicographicallyPrecedes(b) }
   146	
   147	    static func semver(_ v: String) -> [Int] {
   148	        var s = v.trimmingCharacters(in: .whitespaces)
   149	        if s.hasPrefix("hc ") { s.removeFirst(3) }
   150	        let parts = s.split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0) ?? 0 }
   151	        return (0..<3).map { $0 < parts.count ? parts[$0] : 0 }
   152	    }
   153	
   154	    /// Closes the connection. Pending calls fail with `lost`; streams get `onLost`.
   155	    public func close() {
   156	        lock.withLock { closedByUs = true }
   157	        transport.close()
   158	        fail(HerdrError(code: -1, kind: "closed", message: "Disconnected"))
   159	    }
   160	
   161	    // MARK: Calls
   162	
   163	    /// One JSON-RPC call on channel 0. Errors are `HerdrError` (message, hint,
   164	    /// kind). Cancelling the task sends `$/cancelRequest`.
   165	    @discardableResult
   166	    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
   167	        let id: UInt64 = lock.withLock { nextID += 1; return nextID }
   168	        let msg: JSONValue = ["jsonrpc": "2.0", "id": .number(Double(id)), "method": .string(method),
   169	                              "params": params.isNull ? [:] : params]
   170	        return try await withTaskCancellationHandler {
   171	            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<JSONValue, Error>) in
   172	                enum Outcome { case go, cancelled, closed }
   173	                let outcome: Outcome = lock.withLock {
   174	                    if cancelled.remove(id) != nil { return .cancelled }
   175	                    if mode != .framed { return .closed }
   176	                    pending[id] = cont; return .go
   177	                }
   178	                switch outcome {
   179	                case .cancelled: cont.resume(throwing: CancellationError()); return
   180	                case .closed: cont.resume(throwing: HerdrError.lost); return
   181	                case .go: break
   182	                }
   183	                send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
   184	                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
   185	                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
   186	                }
   187	            }
   188	        } onCancel: {
   189	            let wasPending = lock.withLock { () -> Bool in
   190	                if pending[id] != nil { return true }
   191	                cancelled.insert(id); return false
   192	            }
   193	            if wasPending {
   194	                finish(id, .failure(CancellationError()))
   195	                notify("$/cancelRequest", ["id": .number(Double(id))])
   196	            }
   197	        }
   198	    }
   199	
   200	    /// A notification (no id, no reply).
   201	    public func notify(_ method: String, _ params: JSONValue = [:]) {
   202	        let msg: JSONValue = ["jsonrpc": "2.0", "method": .string(method), "params": params]
   203	        send(Frame(channel: 0, kind: FrameKind.data, payload: msg.encoded()))
   204	    }
   205	
   206	    private func finish(_ id: UInt64, _ result: Result<JSONValue, Error>) {
   207	        guard let cont = lock.withLock({ pending.removeValue(forKey: id) }) else { return }
   208	        cont.resume(with: result)
   209	    }
   210	
   211	    static func rpcError(_ e: JSONValue) -> HerdrError {
   212	        HerdrError(code: e["code"].int ?? -32000, kind: e["data"]["kind"].string,
   213	                   message: e["message"].string ?? "core call failed", hint: e["data"]["hint"].string)
   214	    }
   215	
   216	    // MARK: Typed helpers
   217	
   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
   219	    /// exit or timeout is a result, not an error.
   220	    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
   221	        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
   222	        if let cwd, !cwd.isEmpty { p["cwd"] = .string(cwd) }
   223	        if let on, !on.isEmpty, on != hello?.coreName { p["on"] = .string(on) }
   224	        if let input { p["input"] = .string(input.base64EncodedString()) }
   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
   226	        return ExecResult(code: r["code"].int,
   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
   228	                          stderr: Data(base64Encoded: r["stderr"].string ?? "") ?? Data(),
   229	                          timedOut: r["timed_out"].bool ?? false)
   230	    }
   231	
   232	    public func docGet(_ name: String = "herdr-app") async throws -> LayoutDoc {
   233	        let r = try await call("doc.get", ["name": .string(name)])
   234	        return LayoutDoc(value: r["value"], version: r["version"].uint64 ?? 0)
   235	    }
   236	
   237	    /// CAS write; throws kind "conflict" when `version` is stale. Returns the new version.
   238	    public func docSet(_ name: String = "herdr-app", value: JSONValue, version: UInt64) async throws -> UInt64 {
   239	        let r = try await call("doc.set", ["name": .string(name), "value": value, "version": .number(Double(version))])
   240	        return r["version"].uint64 ?? version + 1
   241	    }
   242	
   243	    public func listTerminals(all: Bool = false) async throws -> [TerminalRecord] {
   244	        let r = try await call("terminal.list", ["all": .bool(all)])
   245	        return (r["terminals"].array ?? []).map(TerminalRecord.init(raw:))
   246	    }
   247	
   248	    public func read(terminal: String, lines: Int = 200) async throws -> String {
   249	        try await call("terminal.read", ["terminal": .string(terminal), "lines": .number(Double(lines))])["text"].string ?? ""
   250	    }
   251	
   252	    // MARK: Streams
   253	
   254	    /// `terminal.attach`: opens a stream channel. Data that arrives before the
   255	    /// reply (or before handlers are set) is kept and delivered in order.
   256	    public func attach(terminal: String, cols: Int, rows: Int, history: Int = 2000,
   257	                       display: JSONValue? = nil, observe: Bool = false) async throws -> TerminalStream {
   258	        var p: JSONValue = ["terminal": .string(terminal), "cols": .number(Double(max(cols, 1))),
   259	                            "rows": .number(Double(max(rows, 1))), "history": .number(Double(history)), "observe": .bool(observe)]
   260	        if let display { p["display"] = display }

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg -n 'func exec|frame|16 <<|maxPayload|cancel|timeout|stdout' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/Frame* && sed -n '66,90p' docs/2026-11-01_herdr-ios-code-review.md && nl -ba App/Sources/UI/FilesView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:3:/// Frame kinds on the framed wire (SPEC.md §1, core `wire.rs`).
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:13:/// One frame: `channel u32 LE | kind u8 | len u32 LE | payload`.
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:17:    public static let maxPayload = 16 << 20
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:45:    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:48:/// Incremental frame parser: feed it bytes as they arrive, take whole frames
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:56:    /// Bytes waiting for the rest of their frame.
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:68:    /// The next whole frame, nil if more bytes are needed. Throws on an
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:78:        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:86:    /// Every whole frame currently buffered.
App/Sources/Store/AppStore.swift:117:            backgroundTask?.cancel(); backgroundTask = nil
App/Sources/Store/AppStore.swift:127:                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
App/Sources/Store/AppStore.swift:401:            _ = try? await c.call("terminal.kill", ["terminal": .string(terminal)], timeout: 15)
App/Sources/Store/AppStore.swift:419:        _ = try await connectedClient().call("terminal.send", ["terminal": .string(address), "text": .string(text)], timeout: 15)
App/Sources/Store/AppStore.swift:425:        _ = try await connectedClient().call("terminal.interrupt", ["terminal": .string(address), "timeout": 10], timeout: 20)
App/Sources/Store/AppStore.swift:428:        _ = try await connectedClient().call("terminal.kill", ["terminal": .string(address)], timeout: 20)
App/Sources/Store/AppStore.swift:432:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
App/Sources/Store/AppStore.swift:433:        try await connectedClient().exec(argv: argv, cwd: cwd, on: on, timeout: timeout, input: input)
App/Sources/Store/AppStore.swift:470:        reconnectTask?.cancel(); reconnectTask = nil
App/Sources/Store/AppStore.swift:471:        connectTask?.cancel()
App/Sources/Store/AppStore.swift:475:        // Synchronously, so no frame shows the idle/failure screen before the task runs.
App/Sources/Store/AppStore.swift:541:        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
App/Sources/Store/AppStore.swift:564:        reconnectTask?.cancel()
App/Sources/Store/AppStore.swift:577:        connectTask?.cancel(); connectTask = nil
App/Sources/Store/AppStore.swift:578:        reconnectTask?.cancel(); reconnectTask = nil
App/Sources/Store/AppStore.swift:599:              let r = try? await c.exec(argv: ["sh", "-c", "printf %s \"$HOME\""], timeout: 10),
App/Sources/Store/AppStore.swift:601:        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
App/Sources/Store/AppStore.swift:622:                    guard gen == self.generation else { s.cancel(); return }
App/Sources/Store/AppStore.swift:768:        ], timeout: 20)
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:3:/// One framed connection to herdr-core over a `ByteTransport` (SPEC.md §1-4):
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:36:    private enum Mode { case idle, plain, framed, closed }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:45:    private var cancelled: Set<UInt64> = []
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:48:    /// Channels we closed: drop their frames, swallow the CLOSE echo.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:65:        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:68:    public var isConnected: Bool { lock.withLock { mode == .framed } }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:72:    /// Starts the transport, says hello in plain mode, then switches to frames.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:103:            outbox.yield(Data(#"{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true,"generation":1}}"#.utf8 + [0x0a]))
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:108:                c.resume(throwing: HerdrError(kind: "timeout", message: "The core didn't answer hello",
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:164:    /// kind). Cancelling the task sends `$/cancelRequest`.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:166:    public func call(_ method: String, _ params: JSONValue = [:], timeout: TimeInterval = 10) async throws -> JSONValue {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:172:                enum Outcome { case go, cancelled, closed }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:174:                    if cancelled.remove(id) != nil { return .cancelled }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:175:                    if mode != .framed { return .closed }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:179:                case .cancelled: cont.resume(throwing: CancellationError()); return
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:184:                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:185:                    self?.finish(id, .failure(HerdrError(kind: "timeout", message: "\(method) timed out after \(Int(timeout)) s")))
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:191:                cancelled.insert(id); return false
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:195:                notify("$/cancelRequest", ["id": .number(Double(id))])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:219:    /// exit or timeout is a result, not an error.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:221:        var p: JSONValue = ["argv": .array(argv.map { .string($0) }), "timeout": .number(Double(min(max(timeout, 1), 600)))]
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:227:                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:269:            guard mode == .framed else { return nil }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:271:            let frames = early.removeValue(forKey: ch) ?? []
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:272:            // Flush inside the lock so later frames queue behind these.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:273:            for f in frames { route(f, to: .terminal(stream), queue: queue) }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:274:            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:275:            return frames
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:290:            guard mode == .framed else { return false }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:292:            let frames = early.removeValue(forKey: ch) ?? []
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:293:            for f in frames { route(f, to: .events(sub), queue: callbackQueue) }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:294:            if frames.contains(where: { $0.kind == FrameKind.close }) { routes.removeValue(forKey: ch) }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:335:                mode = .framed
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:346:            case .framed:
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:365:                // A reply nobody waits for (cancelled or timed out). If it opened a
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:452:        livenessTask?.cancel()
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:528:    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }
     1	import SwiftUI
     2	import QuickLook
     3	import HerdrKit
     4	
     5	/// A space's folder on the box: browse it and open files in Quick Look
     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
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
    21	    @State private var error: String?
    22	    @State private var opening: String?
    23	    @State private var preview: URL?
    24	
    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
    26	    static let maxBytes = 12 << 20
    27	
    28	    // Prints {"dir": <absolute path>, "entries": [[name, is_dir, size], ...]}; "~" expands on the box.
    29	    static let listScript = """
    30	    import json, os, sys
    31	    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    32	    out = []
    33	    with os.scandir(d) as it:
    34	        for e in it:
    35	            try:
    36	                isdir = e.is_dir()
    37	                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
    38	            except OSError:
    39	                pass
    40	    print(json.dumps({"dir": d, "entries": out}))
    41	    """
    42	
    43	    var body: some View {
    44	        List {
    45	            if let error {
    46	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
    47	            }
    48	            ForEach(entries) { e in
    49	                if e.isDir, let dir {
    50	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
    51	                } else {
    52	                    Button { Task { await open(e) } } label: { row(e) }
    53	                        .disabled(opening != nil)
    54	                }
    55	            }
    56	        }
    57	        .overlay { if dir == nil && error == nil { ProgressView() } }
    58	        .navigationTitle(title)
    59	        .navigationBarTitleDisplayMode(.inline)
    60	        .task { await load() }
    61	        .refreshable { await load() }
    62	        .quickLookPreview($preview)
    63	    }
    64	
    65	    private func row(_ e: Entry) -> some View {
    66	        HStack(spacing: 12) {
    67	            Image(systemName: e.isDir ? "folder" : "doc")
    68	                .foregroundStyle(e.isDir ? HC.working : HC.muted)
    69	                .frame(width: 22)
    70	            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
    71	            Spacer(minLength: 8)
    72	            if opening == e.name {
    73	                ProgressView()
    74	            } else if !e.isDir {
    75	                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
    76	            }
    77	        }
    78	        .accessibilityElement(children: .combine)
    79	        .accessibilityLabel(e.name)
    80	    }
    81	
    82	    private func load() async {
    83	        do {
    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
    86	                let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    87	                error = why.isEmpty ? "Couldn't list \(path)" : String(why.suffix(300))
    88	                return
    89	            }
    90	            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
    91	                guard let n = a[0].string else { return nil }
    92	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
    93	            })
    94	            dir = d
    95	            error = nil
    96	        } catch {
    97	            self.error = error.localizedDescription
    98	        }
    99	    }
   100	
   101	    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
   102	    static func sorted(_ entries: [Entry]) -> [Entry] {
   103	        entries.sorted { a, b in
   104	            if a.isDir != b.isDir { return a.isDir }
   105	            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
   106	            if ad != bd { return bd }
   107	            return a.name.localizedStandardCompare(b.name) == .orderedAscending
   108	        }
   109	    }
   110	
   111	    private func open(_ e: Entry) async {
   112	        guard let dir else { return }
   113	        // shortcut: files over 12 MiB are refused; read them in ranges (dd/tail -c) when large files matter.
   114	        guard e.size <= Self.maxBytes else {
   115	            error = "\(e.name) is \(e.size.formatted(.byteCount(style: .file))); files over 12 MB can't be previewed yet."
   116	            return
   117	        }
   118	        opening = e.name
   119	        defer { opening = nil }
   120	        do {
   121	            let r = try await store.exec(argv: ["cat", "--", dir + "/" + e.name], cwd: nil, on: nil, timeout: 60, input: nil)
   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
   124	                return
   125	            }
   126	            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("preview", isDirectory: true)
   127	            try? FileManager.default.removeItem(at: folder)
   128	            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
   129	            let url = folder.appendingPathComponent(e.name)
   130	            try r.stdout.write(to: url, options: .completeFileProtection)
   131	            error = nil
   132	            preview = url
   133	        } catch {
   134	            self.error = error.localizedDescription
   135	        }
   136	    }
   137	}
   138	
   139	/// The Files sheet for one space: its own stack so folders push inside the sheet.
   140	struct FilesSheet: View {
   141	    @Environment(\.dismiss) private var dismiss
   142	    var folder: String
   143	    var title: String
   144	
   145	    var body: some View {
   146	        NavigationStack {
   147	            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
   148	                .navigationDestination(for: String.self) { p in
   149	                    FilesView(path: p, title: (p as NSString).lastPathComponent)
   150	                }
   151	                .toolbar {
   152	                    ToolbarItem(placement: .cancellationAction) {
   153	                        Button("Close", systemImage: "xmark") { dismiss() }
   154	                    }
   155	                }
   156	        }
   157	    }
   158	}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '310,365p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift && sed -n '410,455p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift && cat Packages/HerdrKit/Sources/HerdrKit/Frame.swift && rg -n 'machine.exec|stdout|16 MiB|output.*limit|python3' docs SPEC.md Packages/HerdrKit/Tests -g '*.md' -g '*.swift'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 exited 2 in 0ms:
            return
        }
        send(Frame(channel: ch, kind: kind, payload: payload))
    }

    private func send(_ f: Frame) {
        outbox.yield(f.encoded())
    }

    // MARK: Reading

    private func receive(_ bytes: Data) {
        var actions: [() -> Void] = []
        var protocolError: HerdrError?
        lock.withLock {
            lastReceive = Date()
            switch mode {
            case .idle, .closed:
                return
            case .plain:
                plain.append(bytes)
                guard let nl = plain.firstIndex(of: 0x0a) else { return }
                let line = plain[plain.startIndex..<nl]
                let rest = plain[plain.index(after: nl)...]
                let reply = (try? JSONValue.parse(Data(line))) ?? .null
                mode = .framed
                decoder.append(Data(rest))
                plain = Data()
                if let c = helloCont {
                    helloCont = nil
                    if reply.isNull {
                        actions.append { c.resume(throwing: HerdrError(kind: "parse_error", message: "The core's hello reply wasn't JSON")) }
                    } else {
                        actions.append { c.resume(returning: reply) }
                    }
                }
            case .framed:
                decoder.append(bytes)
            }
            do {
                while let f = try decoder.next() { handle(f, &actions) }
            } catch {
                protocolError = HerdrError(code: -32700, kind: "lost", message: "Lost the core", hint: "\(error)")
            }
        }
        for a in actions { a() }
        if let protocolError { fail(protocolError); transport.close() }
    }

    /// Called with the lock held.
    private func handle(_ f: Frame, _ actions: inout [() -> Void]) {
        if f.channel == 0 {
            guard f.kind == FrameKind.data, let msg = try? JSONValue.parse(f.payload),
                  let id = msg["id"].uint64 else { return }
            guard let cont = pending.removeValue(forKey: id) else {
                // A reply nobody waits for (cancelled or timed out). If it opened a
            case FrameKind.data:
                sub.push(f.payload)
                send(Frame.credit(f.channel, f.payload.count))
            case FrameKind.close:
                sub.ended(lost: false)
            default: break
            }
        }
    }

    // MARK: Loss

    private func transportClosed(_ err: Error?) {
        let (hint, byUs): (String?, Bool) = lock.withLock {
            (String(decoding: stderrBuf, as: UTF8.self).trimmed.nilIfEmpty, closedByUs)
        }
        if byUs { return }
        fail(closedError(err, stderr: hint))
    }

    private func closedError(_ err: Error?, stderr: String? = nil) -> HerdrError {
        let stderr = stderr ?? stderrText.trimmed.nilIfEmpty
        if let stderr, stderr.contains("not installed") {
            return HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine", hint: stderr)
        }
        return HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: stderr ?? err.map { "\($0.localizedDescription)" })
    }

    /// Fails everything once: pending calls, hello, every stream.
    private func fail(_ error: HerdrError) {
        var conts: [CheckedContinuation<JSONValue, Error>] = []
        var helloC: CheckedContinuation<JSONValue, Error>?
        var lostRoutes: [Route] = []
        let first: Bool = lock.withLock {
            guard mode != .closed else { return false }
            mode = .closed
            conts = Array(pending.values); pending.removeAll()
            helloC = helloCont; helloCont = nil
            lostRoutes = Array(routes.values); routes.removeAll(); early.removeAll(); closing.removeAll()
            return true
        }
        guard first else { return }
        livenessTask?.cancel()
        outbox.finish()
        let lost = HerdrError(code: -1, kind: error.kind ?? "lost", message: error.message, hint: error.hint)
        helloC?.resume(throwing: lost)
import Foundation

/// Frame kinds on the framed wire (SPEC.md §1, core `wire.rs`).
public enum FrameKind {
    public static let data: UInt8 = 0
    public static let credit: UInt8 = 1
    public static let close: UInt8 = 2
    public static let resize: UInt8 = 3
    public static let focus: UInt8 = 4
    public static let facts: UInt8 = 5
}

/// One frame: `channel u32 LE | kind u8 | len u32 LE | payload`.
public struct Frame: Equatable, Sendable {
    public static let headerSize = 9
    /// Largest payload the core accepts or sends (16 MiB).
    public static let maxPayload = 16 << 20

    public var channel: UInt32
    public var kind: UInt8
    public var payload: Data

    public init(channel: UInt32, kind: UInt8, payload: Data = Data()) {
        self.channel = channel; self.kind = kind; self.payload = payload
    }

    public func encoded() -> Data {
        var d = Data(capacity: Self.headerSize + payload.count)
        withUnsafeBytes(of: channel.littleEndian) { d.append(contentsOf: $0) }
        d.append(kind)
        withUnsafeBytes(of: UInt32(payload.count).littleEndian) { d.append(contentsOf: $0) }
        d.append(payload)
        return d
    }

    public static func credit(_ channel: UInt32, _ bytes: Int) -> Frame {
        Frame(channel: channel, kind: FrameKind.credit, payload: le32(UInt32(clamping: bytes)))
    }

    static func le32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
}

public struct FrameError: Error, Equatable, CustomStringConvertible {
    public var length: Int
    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
}

/// Incremental frame parser: feed it bytes as they arrive, take whole frames
/// out. Frame boundaries may fall anywhere in the input.
public struct FrameDecoder: Sendable {
    private var buffer: [UInt8] = []
    private var head = 0

    public init() {}

    /// Bytes waiting for the rest of their frame.
    public var buffered: Int { buffer.count - head }

    public mutating func append(_ data: Data) {
        if head > 0, head >= buffer.count {
            buffer.removeAll(keepingCapacity: true); head = 0
        } else if head > 65_536, head * 2 > buffer.count {
            buffer.removeSubrange(0..<head); head = 0
        }
        buffer.append(contentsOf: data)
    }

    /// The next whole frame, nil if more bytes are needed. Throws on an
    /// oversized length (a protocol error: drop the connection).
    public mutating func next() throws -> Frame? {
        guard buffer.count - head >= Frame.headerSize else { return nil }
        let (channel, kind, len) = buffer.withUnsafeBytes { raw -> (UInt32, UInt8, Int) in
            let ch = raw.loadUnaligned(fromByteOffset: head, as: UInt32.self)
            let k = raw[head + 4]
            let l = raw.loadUnaligned(fromByteOffset: head + 5, as: UInt32.self)
            return (UInt32(littleEndian: ch), k, Int(UInt32(littleEndian: l)))
        }
        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
        guard buffer.count - head >= Frame.headerSize + len else { return nil }
        let start = head + Frame.headerSize
        let payload = Data(buffer[start..<start + len])
        head = start + len
        return Frame(channel: channel, kind: kind, payload: payload)
    }

    /// Every whole frame currently buffered.
    public mutating func drain() throws -> [Frame] {
        var out: [Frame] = []
        while let f = try next() { out.append(f) }
        return out
    }
}
rg: SPEC.md: No such file or directory (os error 2)
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:277:        XCTAssertEqual(Programs.identify(app: nil, argv: ["python3", "-m", "http.server"]).key, "python")
docs/reviews/2026-11-01-fixes-codex.md:345:-                                         "terminal.keep", "doc.get", "doc.set", "events.subscribe", "machine.exec"]
docs/reviews/2026-11-01-fixes-codex.md:348:+                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
docs/reviews/2026-11-01-fixes-codex.md:361:-    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec"]}}"# + "\n").utf8)
docs/reviews/2026-11-01-fixes-codex.md:362:+    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-fixes-codex.md:663:                if !apply(r.stdout) { return }
docs/reviews/2026-11-01-fixes-codex.md:1045:                            case .stdout(let b): onBytes(Data(b.readableBytesView))
docs/reviews/2026-11-01-fixes-codex.md:2191:Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
docs/reviews/2026-11-01-fixes-codex.md:3358:43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:43:    static let helloLine = Data((#"{"id":0,"jsonrpc":"2.0","result":{"core":{"id":"abc","name":"devhub"},"framed":true,"generation":1,"version":"0.1.14","methods":["hello","terminal.run","terminal.list","terminal.kill","terminal.label","terminal.attach","terminal.keep","doc.get","doc.set","events.subscribe","machine.exec","terminal.get","terminal.read","terminal.send","terminal.keys","terminal.interrupt","machine.list","server.status"]}}"# + "\n").utf8)
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:145:        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" } }
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:146:        let id = try JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" }!.payload)["id"]
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:192:        t.reply(msg["id"].int!, ["code": 0, "stdout": .string(Data("hi\n".utf8).base64EncodedString()), "stderr": "", "timed_out": false])
Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift:194:        XCTAssertEqual(res, ExecResult(code: 0, stdout: Data("hi\n".utf8), stderr: Data(), timedOut: false))
docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:19:| 接続 | stdin・stdout の改行区切りの JSON-RPC で話せる。`hello` は generation 1、version 0.1.15 を返す | `hc connect` |
docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:26:| PDF・docx・xlsx | `file.read` は `not_text` で拒否し、「for bytes: hc exec cat」と案内する。`machine.exec {argv: ["cat", path]}` で base64 として取り出すと、PDF 3.4 MB が 18 ms、docx・xlsx が 5 ms 前後で、元のファイルと SHA-256 が一致した | `machine.exec` |
docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:38:| `machine.exec`（PDF 3.4 MB を `cat`） | 445 ms | 3394636 bytes で元のファイルと一致し、`truncated` は false |
docs/2026-11-01_herdr-core-mobile-client-spike.ja.md:57:- 送ったバイナリの大きさの上限。`machine.exec` の出力は `truncated` を返す。どの大きさで打ち切られるかは確かめていない。
docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:49:| Keep (first version) | File tree and preview (**add docx and xlsx**) | `machine.exec` (ls, and cat returned as base64). Display with QLPreviewController and WKWebView |
docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:53:| Later | Quick Commands, Source Control, creating a new workspace, resuming past sessions, diagnostics screen, photo attachments, voice input | `machine.exec` (git, gh), `terminal.run` |
docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:70:Both can run on the Mac Studio side through `machine.exec`.
docs/2026-11-01_existing-apps-and-orca-mobile-survey.md:113:- File tree and preview (retrieve with `machine.exec`, display with Quick Look)
docs/reviews/2026-11-01-files-codex.md:14:Review the last commit in this repo (git show HEAD): a Files browser with Quick Look preview for an iOS client of herdr-core. Context: AGENTS.md, docs/2026-11-01_herdr-ios-code-review.md (section on where features plug in), Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift (exec, frame limit). Review only; do not edit files. For each finding give severity (high/medium/low), file:line, a concrete failure scenario and a suggested fix. Check: path handling and injection (argv to machine.exec, names with odd characters, symlinks, '~'), the 12 MiB limit vs the actual frame/base64/JSON overhead and what happens just above it, temp file handling and data protection, SwiftUI state races (open twice, dismiss during fetch, navigation), and anything that breaks on a box without python3. Say 'no findings' where there are none. Be concise.
docs/reviews/2026-11-01-files-codex.md:45:    documents, images. Files lists the space folder with the box's python3 (as
docs/reviews/2026-11-01-files-codex.md:46:    Chat already does) and fetches a file with cat over machine.exec into a
docs/reviews/2026-11-01-files-codex.md:49:    in a 16 MiB frame as base64.
docs/reviews/2026-11-01-files-codex.md:270:| Medium (by design) | `Mods/ModHub.swift:310, 325` | Passes the command a mod specifies straight to `machine.exec` on the Mac side. The trust boundary is the same as the Herdr app | Operate by bundling only mods you wrote yourself |
docs/reviews/2026-11-01-files-codex.md:280:- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
docs/reviews/2026-11-01-files-codex.md:324:    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
docs/reviews/2026-11-01-files-codex.md:512:   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
docs/reviews/2026-11-01-files-codex.md:519:   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
docs/reviews/2026-11-01-files-codex.md:521:   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
docs/reviews/2026-11-01-files-codex.md:876:     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
docs/reviews/2026-11-01-files-codex.md:895:    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
docs/reviews/2026-11-01-files-codex.md:954:    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
docs/reviews/2026-11-01-files-codex.md:955:    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
docs/reviews/2026-11-01-files-codex.md:992:   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
docs/reviews/2026-11-01-files-codex.md:993:   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
docs/reviews/2026-11-01-files-codex.md:1000:   130	            try r.stdout.write(to: url, options: .completeFileProtection)
docs/reviews/2026-11-01-files-codex.md:1325:- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap.
docs/reviews/2026-11-01-files-codex.md:1350:- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat.
docs/reviews/2026-11-01-files-codex.md:1431:    documents, images. Files lists the space folder with the box's python3 (as
docs/reviews/2026-11-01-files-codex.md:1432:    Chat already does) and fetches a file with cat over machine.exec into a
docs/reviews/2026-11-01-files-codex.md:1435:    in a 16 MiB frame as base64.
docs/reviews/2026-11-01-files-codex.md:1448:+/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
docs/reviews/2026-11-01-files-codex.md:1467:+    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
docs/reviews/2026-11-01-files-codex.md:1526:+            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
docs/reviews/2026-11-01-files-codex.md:1527:+            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
docs/reviews/2026-11-01-files-codex.md:1564:+            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
docs/reviews/2026-11-01-files-codex.md:1565:+                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
docs/reviews/2026-11-01-files-codex.md:1572:+            try r.stdout.write(to: url, options: .completeFileProtection)
docs/reviews/2026-11-01-files-codex.md:1747:    30	                                         "terminal.interrupt", "doc.get", "doc.set", "events.subscribe", "machine.exec",
docs/reviews/2026-11-01-files-codex.md:1935:   218	    /// `machine.exec`: runs argv on the box (or `on` another machine). A nonzero
docs/reviews/2026-11-01-files-codex.md:1942:   225	        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
docs/reviews/2026-11-01-files-codex.md:1944:   227	                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
docs/reviews/2026-11-01-files-codex.md:1986:/bin/zsh -lc "rg -n 'func exec|frame|16 <<|maxPayload|cancel|timeout|stdout' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/Frame* && sed -n '66,90p' docs/2026-11-01_herdr-ios-code-review.md && nl -ba App/Sources/UI/FilesView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-files-codex.md:1991:Packages/HerdrKit/Sources/HerdrKit/Frame.swift:45:    public var description: String { "frame of \(length) bytes is over the 16 MiB limit" }
docs/reviews/2026-11-01-files-codex.md:2013:App/Sources/Store/AppStore.swift:601:        let h = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
docs/reviews/2026-11-01-files-codex.md:2038:Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:225:        let r = try await call("machine.exec", p, timeout: TimeInterval(timeout + 5))
docs/reviews/2026-11-01-files-codex.md:2039:Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:227:                          stdout: Data(base64Encoded: r["stdout"].string ?? "") ?? Data(),
docs/reviews/2026-11-01-files-codex.md:2060:     6	/// (PDF, Office, iWork, images, text). Lists with the box's python3, like Chat.
docs/reviews/2026-11-01-files-codex.md:2079:    25	    /// The largest file fetched in one machine.exec: its 16 MiB frame carries base64 (4/3) plus JSON.
docs/reviews/2026-11-01-files-codex.md:2138:    84	            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
docs/reviews/2026-11-01-files-codex.md:2139:    85	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
docs/reviews/2026-11-01-files-codex.md:2176:   122	            guard r.code == 0, !r.timedOut, r.stdout.count == e.size else {
docs/reviews/2026-11-01-files-codex.md:2177:   123	                error = "Couldn't read \(e.name)" + (r.stdout.count != e.size ? " (got \(r.stdout.count) of \(e.size) bytes)" : "")
docs/reviews/2026-11-01-files-codex.md:2184:   130	            try r.stdout.write(to: url, options: .completeFileProtection)
docs/2026-11-01_herdr-core-mobile-client-spike.md:17:| Connection | Speaks newline-delimited JSON-RPC over stdin and stdout. `hello` returns generation 1, version 0.1.15 | `hc connect` |
docs/2026-11-01_herdr-core-mobile-client-spike.md:24:| PDF, docx, xlsx | `file.read` rejects them with `not_text` and suggests "for bytes: hc exec cat". Retrieved as base64 with `machine.exec {argv: ["cat", path]}`: a 3.4 MB PDF took 18 ms, docx and xlsx about 5 ms each, and the SHA-256 matched the original files | `machine.exec` |
docs/2026-11-01_herdr-core-mobile-client-spike.md:36:| `machine.exec` (`cat` of a 3.4 MB PDF) | 445 ms | 3394636 bytes, matched the original file, `truncated` is false |
docs/2026-11-01_herdr-core-mobile-client-spike.md:55:- The size limit for transferred binaries. The output of `machine.exec` returns `truncated`. The size at which it truncates was not checked.
docs/2026-11-01_herdr-ios-code-review.md:39:| Medium (by design) | `Mods/ModHub.swift:310, 325` | Passes the command a mod specifies straight to `machine.exec` on the Mac side. The trust boundary is the same as the Herdr app | Operate by bundling only mods you wrote yourself |
docs/2026-11-01_herdr-ios-code-review.md:49:- **File tree and preview**: Put the entry point in the toolbar at `SpaceView.swift:73`, with `SpaceRef.folder` as the base folder. Get the listing with `store.exec` (`AppStore.swift:417`). Receive the content as base64 with `cat --`, write it to a temporary file, and pass it to `QLPreviewController`. The limit for one receive is about 12 MiB (the 16 MiB frame limit minus the base64 overhead). Files larger than this are read in chunks.
docs/2026-11-01_herdr-ios-code-review.ja.md:41:| 中（仕様） | `Mods/ModHub.swift:310, 325` | mod が指定したコマンドを、そのまま Mac 側で `machine.exec` に渡す。信頼の範囲は Herdr app と同じである | 自分で書いた mod だけを同梱する運用にする |
docs/2026-11-01_herdr-ios-code-review.ja.md:51:- **ファイルツリーとプレビュー**: 入口は `SpaceView.swift:73` の toolbar に置き、基準のフォルダは `SpaceRef.folder` にする。一覧は `store.exec`（`AppStore.swift:417`）で取る。本体は `cat --` で base64 として受け取り、一時ファイルに書いて `QLPreviewController` に渡す。1 回の受け取りの上限は約 12 MiB で（frame の上限 16 MiB から base64 の増加分を引いた値）、これを超えるファイルは分割して読む。
docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:51:| 残す（最初の版） | ファイルツリーとプレビュー（**docx・xlsx を足す**） | `machine.exec`（ls・cat を base64 で返す）。表示は QLPreviewController と WKWebView |
docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:55:| 後で | Quick Commands、Source Control、新しい workspace の作成、過去のセッションの再開、診断の画面、写真の添付、音声入力 | `machine.exec`（git・gh）、`terminal.run` |
docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:72:どちらも `machine.exec` で Mac Studio 側で実行できる。
docs/2026-11-01_existing-apps-and-orca-mobile-survey.ja.md:115:- ファイルツリーとプレビュー（`machine.exec` で取り出し、Quick Look で表示する）

hook: PostToolUse
hook: PostToolUse
exec
/bin/zsh -lc "sed -n '55,75p' docs/2026-11-01_herdr-ios-code-review.md && sed -n '1,55p' App/Sources/Store/AppStore.swift && sed -n '525,575p' App/Sources/Store/AppStore.swift && rg --files -g AGENTS.md -g '*SPEC*' -g '*exec*' -g '*wire*' && cat /Users/yosuke/workspace/github.com/YosukeIida/knowledge/orca-remote-file-open-and-reveal-limits.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
- The README says "mod exec runs on the Mac side", but `open` and pbcopy are handled on the smartphone side.
- The README describes the notifier only as being for systemd, but the code has an alternative path that starts it with nohup.

## What to read before building

Building runs the following 2 items without a sandbox. Their contents must be read before building.

- The pre-build `bundle-mods.sh` (`ENABLE_USER_SCRIPT_SANDBOXING: NO`)
- SwiftTerm's build plugin
import SwiftUI
import UIKit
import HerdrKit

// CONTRACT FILE (owned by the core/store builder). UI and Mods are written
// against these signatures in parallel: implement the bodies, add API freely,
// but do not rename or remove anything here.

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
    var label: String                  // SPEC §5 Names: agent row label
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
AGENTS.md
---
type: Concept
title: 'Orca で remote のファイルを開く・Finder に表示するときの制限（512 KiB の打ち切り、50MB の上限、Reveal は Local only）'
description: 'Orca の remote ランタイム上のファイルは、通常は分割読みで 50MB まで開ける。ワークスペース外の host ファイルと復元タブの経路だけ 512 KiB で打ち切られる。Reveal in Finder は remote では無効で、T3 Code も同様に未対応'
aliases: 'Remote file is too large to open in the editor, 524289 bytes, Reveal in Finder, Local only, PAGED_REMOTE_FILE_MAX_BYTES, terminal artifact, T3 Code, t3code, 復元タブ'
sources:
  - resource: https://github.com/stablyai/orca/issues/28907
    title: Orca "Reveal in Finder" in the terminal right-click menu（SSH / remote-runtime では Local only で無効にする提案）
  - resource: https://github.com/stablyai/orca/pull/29426
    title: Orca fix(remote-files) open large HTML, PDFs and images on a paired runtime
  - resource: https://github.com/stablyai/orca/pull/27165
    title: Orca fix(shell) OS open actions follow the file's owner, not the focused server
  - resource: https://github.com/stablyai/orca/blob/main/src/renderer/src/runtime/runtime-terminal-artifact-read.ts
    title: Orca runtime-terminal-artifact-read.ts（truncated で分割読みせずに失敗させる経路）
  - resource: https://github.com/stablyai/orca/blob/main/src/renderer/src/runtime/runtime-file-read-client.ts
    title: Orca runtime-file-read-client.ts（通常経路の分割読み）
  - resource: https://github.com/pingdotgg/t3code/issues/18473
    title: T3 Code 同じ Mac の saved environment で Reveal in file manager が出ない（closed、未対応の回答）
  - resource: https://github.com/pingdotgg/t3code/issues/23604
    title: T3 Code remote スレッドのファイルリンクがサーバ上で開かれる（open）
  - resource: transcript:666134d4-cb8f-4360-8c26-f57bb2d25f95#L71-L123
    title: remote の Reveal in Finder と T3 Code との比較の調査
  - resource: transcript:666134d4-cb8f-4360-8c26-f57bb2d25f95#L197-L363
    title: 「Remote file is too large to open in the editor (524289 bytes)」の原因をソースから読む
generated: { by: claude-code/claude-sonnet-5-5, at: 2026-10-27T18:15:42+09:00 }
status: draft
---

別の機械の Orca ランタイム（`orca serve` や、別の Mac の GUI の Orca）に接続して、そのファイルを手元の Orca で開くときの挙動。

## Finder 表示は remote では使えない

- ファイルエクスプローラ・エディタのタブ・Source Control の「Reveal in Finder」は、SSH／remote-runtime のファイルでは設計上 disabled（「Local only」の表示）。「Open With」サブメニューも remote のファイルでは出ない（Orca #13993）。
- remote を選択中に、ローカルのファイルまで Reveal できなくなる不具合があり、#25932 と #27165（OS の open 操作を、フォーカス中のサーバではなくファイルの所有者で判定する）が対応している。merge の有無は確かめていない。
- remote のファイルを手元に落として Reveal する機能の要望は、検索では見つからなかった。手元で扱うには、右クリックの「Download」で落とす。
- 比較: T3 Code（pingdotgg/t3code）も remote では「Open in」にファイルマネージャが出ない。#18473 は「Local 環境だけを local とみなす仕様」として closed、#23604（remote スレッドのファイルリンクが、手元ではなくサーバ上で開かれる）は open。Emdash・Zed・VS Code Remote-SSH も、remote のファイルを手元の Finder に出す機能は、公式ドキュメントでは確認できなかった。

## ファイルを開くときのサイズの扱い

ソース（stablyai/orca の main、手元は 1.4.239）を読んだ結果で、実機では確かめていない。

- 通常の remote ファイルは、512 KiB を超えると 384 KiB ずつの分割読みに入り、50MB（`PAGED_REMOTE_FILE_MAX_BYTES = 50 * 1024 * 1024`、設定では変えられない）まで開ける。分割読みは #29426（2026-10-16）で入った。
- 「Remote file is too large to open in the editor (524289 bytes)」は、ファイルの大きさではない。`524289` は、512 KiB で打ち切った内容の長さ（512 KiB + 1 バイト）を指す。ファイル自体が 1.2MB でも、この数字が出た。
- このエラー文は `runtime-terminal-artifact-read.ts` の経路にしかない。ワークスペース外の host ファイル、または再起動で復元したタブの絶対パスを開くときに使われ、`truncated` になった時点で分割読みをせずに失敗させる。
- 古い remote host（`files.stat`／`files.readChunk` を持たない版）では、別の文面「Remote file is larger than the 512 KB this Orca server can send. Update the server to open it.」で 512 KB が上限になる。サーバ側の版を上げる必要があるのは、こちらの場合である。
- クライアントを最新にしても、前者の経路には分割読みが無いので直らない。回避は、タブを閉じてファイルツリーから開き直す（通常経路に入る可能性がある）、それでも駄目なら Download で手元に落とす。
- この経路の未対応を扱う issue は、検索では見つからなかった。

前提: Orca 1.4.239（最新は 1.4.242、2026-10-27 時点）、T3 Code の issue は 2026-10 時点。経路の判定はソースの読み取りに基づく推測で、どちらの経路を通ったかは実機で確かめていない。

関連:
- [Orca の画面なしの実行環境（orca serve）を別の機械に置くと、ペアリングは loopback のトンネルで通す](./orca-serve-remote-runtime-pairing.md) - remote ランタイムへ接続する手順を読むときにたどる。
- [macOS の「Finder で表示」を新しいウィンドウでなくタブで開かせる](./macos-finder-reveal-opens-in-tab.md) - ローカルでの Reveal の挙動を読むときにたどる。

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
The 12 MiB limit leaves no room for the JSON envelope, and the read checks size only after fetching the whole file. I also found that a fetch can continue after dismissal and delete a newer preview’s shared temp directory. I’m checking the remaining path and dependency cases.
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '1,155p' Packages/HerdrKit/Sources/HerdrKit/JSONValue.swift && sed -n '135,165p' Packages/HerdrKit/Tests/HerdrKitTests/ClientTests.swift && command -v ruby && command -v swift && git diff --stat" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
import Foundation

/// Untyped JSON, as the core speaks it. Keeps unknown fields so documents
/// written back to the core lose nothing.
public enum JSONValue: Equatable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public subscript(key: String) -> JSONValue {
        get {
            if case .object(let o) = self { return o[key] ?? .null }
            return .null
        }
        set {
            var o = object ?? [:]
            o[key] = newValue
            self = .object(o)
        }
    }
    public subscript(index: Int) -> JSONValue {
        if case .array(let a) = self, a.indices.contains(index) { return a[index] }
        return .null
    }
    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var double: Double? { if case .number(let n) = self { return n }; return nil }
    public var int: Int? { double.flatMap { $0.isFinite ? Int(exactly: $0.rounded(.towardZero)) : nil } }
    public var uint64: UInt64? { double.flatMap { $0.isFinite ? UInt64(exactly: max(0, $0).rounded(.towardZero)) : nil } }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var array: [JSONValue]? { if case .array(let a) = self { return a }; return nil }
    public var object: [String: JSONValue]? { if case .object(let o) = self { return o }; return nil }
    public var isNull: Bool { self == .null }

    /// Removes `key` from an object (no-op otherwise).
    public mutating func removeValue(forKey key: String) {
        guard case .object(var o) = self else { return }
        o.removeValue(forKey: key)
        self = .object(o)
    }

    /// Compact JSON text, for logs and debugging.
    public var jsonString: String { String(decoding: encoded(), as: UTF8.self) }

    public init(any: Any?) {
        switch any {
        case nil, is NSNull: self = .null
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .bool(n.boolValue) } else { self = .number(n.doubleValue) }
        case let s as String: self = .string(s)
        case let a as [Any]: self = .array(a.map { JSONValue(any: $0) })
        case let o as [String: Any]: self = .object(o.mapValues { JSONValue(any: $0) })
        default: self = .null
        }
    }

    public var any: Any {
        switch self {
        case .null: return NSNull()
        case .bool(let b): return b
        case .number(let n): return n.rounded() == n && abs(n) < 9e15 ? Int64(n) as Any : n
        case .string(let s): return s
        case .array(let a): return a.map { $0.any }
        case .object(let o): return o.mapValues { $0.any }
        }
    }

    public static func parse(_ data: Data) throws -> JSONValue {
        JSONValue(any: try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]))
    }
    public func encoded() -> Data {
        (try? JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed, .withoutEscapingSlashes])) ?? Data("null".utf8)
    }
}

extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral,
    ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral, ExpressibleByFloatLiteral {
    public init(stringLiteral v: String) { self = .string(v) }
    public init(integerLiteral v: Int) { self = .number(Double(v)) }
    public init(floatLiteral v: Double) { self = .number(v) }
    public init(booleanLiteral v: Bool) { self = .bool(v) }
    public init(arrayLiteral e: JSONValue...) { self = .array(e) }
    public init(dictionaryLiteral e: (String, JSONValue)...) { self = .object(Dictionary(e, uniquingKeysWith: { $1 })) }
    public init(nilLiteral: ()) { self = .null }
}
        t.onClose?(nil)
        do { _ = try await pending; XCTFail() } catch let e as HerdrError { XCTAssertEqual(e.kind, "lost") }
        await fulfillment(of: [disconnected], timeout: 2)
        do { _ = try await c.call("x"); XCTFail() } catch {}
    }

    func testTimeoutAndCancel() async throws {
        let (c, t) = try await connected()
        do { _ = try await c.call("slow", timeout: 0.1); XCTFail() } catch let e as HerdrError { XCTAssertEqual(e.kind, "timeout") }
        let task = Task { try await c.exec(argv: ["sleep", "9"]) }
        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" } }
        let id = try JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "machine.exec" }!.payload)["id"]
        task.cancel()
        let r = await task.result
        XCTAssertThrowsError(try r.get())
        let all = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "$/cancelRequest" } }
        let cancel = try JSONValue.parse(all.first { (try? JSONValue.parse($0.payload))?["method"] == "$/cancelRequest" }!.payload)
        XCTAssertEqual(cancel["params"]["id"], id)
        XCTAssertEqual(cancel["id"], .null)
    }

    /// A cancelled attach whose reply arrives late: the client closes the
    /// channel it names (the core would otherwise keep a typing viewer) and
    /// drops the early frames it buffered.
    func testLateAttachReplyClosesChannel() async throws {
        let (c, t) = try await connected()
        let task = Task { try await c.attach(terminal: "t3", cols: 80, rows: 24) }
        let fr = try await t.waitFor { $0.contains { (try? JSONValue.parse($0.payload))?["method"] == "terminal.attach" } }
        let id = try XCTUnwrap(JSONValue.parse(fr.first { (try? JSONValue.parse($0.payload))?["method"] == "terminal.attach" }!.payload)["id"].int)
        task.cancel()
        _ = await task.result
/usr/bin/ruby
/usr/bin/swift
 README.md | 24 +++++++++++++++++-------
 1 file changed, 17 insertions(+), 7 deletions(-)

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
/bin/zsh -lc "/usr/bin/ruby -rjson -e 'n = 12 << 20; b64 = 4 * ((n + 2) / 3); overhead = JSON.generate({jsonrpc: \"2.0\", id: 1, result: {code: 0, stdout: \"\", stderr: \"\", timed_out: false}}).bytesize; puts \"bytes=#{n}, base64=#{b64}, minimum-example-json=#{overhead}, payload=#{b64 + overhead}, frame-limit=#{16 << 20}\"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 1735ms:
bytes=12582912, base64=16777216, minimum-example-json=86, payload=16777302, frame-limit=16777216

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "/usr/bin/osascript -l JavaScript -e 'ObjC.import(\"Foundation\"); const data = "'$.NSString.stringWithString("{'"\\\"name\\\":\\\"\\\\udcff\\\"}\").dataUsingEncoding("'$.NSUTF8StringEncoding); const err = Ref(); const result = $.NSJSONSerialization.JSONObjectWithDataOptionsError(data, 0, err); console.log(result ? "parsed" : "rejected"); if (!result) console.log(ObjC.unwrap(err[0].localizedDescription));'"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 80ms:
parsed
2026-11-01 03:53:16.961 osascript[50686:20244667] Connection Invalid error for service com.apple.hiservices-xpcservice.
2026-11-01 03:53:16.961 osascript[50686:20244665] Error received in message reply handler: Connection invalid

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "/usr/bin/osascript -l JavaScript -e 'ObjC.import(\"Foundation\"); const data = "'$.NSString.stringWithString("{'"\\\"name\\\":\\\"\\\\udcff\\\"}\").dataUsingEncoding("'$.NSUTF8StringEncoding); const err = Ref(); const result = $.NSJSONSerialization.JSONObjectWithDataOptionsError(data, 0, err); console.log(JSON.stringify(ObjC.deepUnwrap(result))); console.log(ObjC.unwrap(err[0].localizedDescription));'"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 exited 139 in 4ms:
undefined
2026-11-01 03:53:20.343 osascript[50745:20244839] Connection Invalid error for service com.apple.hiservices-xpcservice.
2026-11-01 03:53:20.343 osascript[50745:20244837] Error received in message reply handler: Connection invalid

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
Reviewed `6c7e200`. Findings:

1. **High — 12 MiB does not fit the frame.** [FilesView.swift:26](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:26)  
   Exactly 12 MiB becomes 16,777,216 base64 bytes, leaving **zero** room for JSON. An oversized reply makes `FrameDecoder` disconnect the entire client, including terminal streams. **Fix:** reserve envelope/stderr overhead and enforce a smaller transfer bound. Files listed just above 12 MiB are correctly refused before fetching.

2. **High — stale metadata does not bound the read.** [FilesView.swift:121](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:121)  
   A file listed as 1 MiB can grow—or its symlink target can change—before opening. `cat` reads everything; the size check runs after transfer, too late to prevent an oversized reply. FIFOs are also listed as files and can block. **Fix:** open and validate a regular file remotely, then read at most the safe limit plus one byte and reject overflow.

3. **Medium — abandoned fetches can destroy another preview.** [FilesView.swift:52](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:52), [FilesView.swift:126](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:126)  
   Start a slow fetch, dismiss/reopen Files or navigate into another directory, then open another file. The original unstructured task survives and can delete the shared `preview` directory beneath the newer Quick Look preview. Disabling buttons also provides no internal guard against already queued opens. **Fix:** guard concurrent opens, retain/cancel the task on disappearance, reject stale completions, and use a unique directory per preview.

4. **Low — preview copies remain after dismissal.** [FilesView.swift:130](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:130)  
   Preview a confidential document and close Files: its downloaded copy remains until another successful preview replaces it or the OS purges temporary storage. **Fix:** remove the owned preview directory after Quick Look dismissal and when the browser closes.

5. **Medium — non-UTF-8 filenames can break the entire listing.** [FilesView.swift:40](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:40)  
   A Linux filename containing byte `0xFF` becomes a Python surrogate escape; `json.dumps` emits an unpaired surrogate that Foundation cannot represent as a valid Swift string. The listing can fail rather than merely omit that entry. **Fix:** encode raw filename bytes separately from display names, or explicitly skip unsupported names with a warning.

6. **Medium — Files requires an undocumented remote dependency.** [FilesView.swift:84](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:84)  
   On a box with herdr-core but no `python3`, Files cannot list anything or reach preview. **Fix:** explicitly require Python for Files, detect its absence, and show an actionable error; alternatively remove that dependency.

**No findings:** shell injection through argv; spaces, quotes, newlines, leading hyphens and valid Unicode names; remote `~` expansion; ordinary symlink traversal, assuming the space folder is not a security boundary; `.completeFileProtection`.

Documentation discrepancies: the feature guide describes chunked reads, whereas this commit refuses large files; README names Python as a Chat dependency only.

Not checked: simulator/device behavior or herdr-core’s server-side output cap. The exact oversized-response outcome depends on whether core sends, rejects, or truncates it. No files edited.
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
59,562
Reviewed `6c7e200`. Findings:

1. **High — 12 MiB does not fit the frame.** [FilesView.swift:26](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:26)  
   Exactly 12 MiB becomes 16,777,216 base64 bytes, leaving **zero** room for JSON. An oversized reply makes `FrameDecoder` disconnect the entire client, including terminal streams. **Fix:** reserve envelope/stderr overhead and enforce a smaller transfer bound. Files listed just above 12 MiB are correctly refused before fetching.

2. **High — stale metadata does not bound the read.** [FilesView.swift:121](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:121)  
   A file listed as 1 MiB can grow—or its symlink target can change—before opening. `cat` reads everything; the size check runs after transfer, too late to prevent an oversized reply. FIFOs are also listed as files and can block. **Fix:** open and validate a regular file remotely, then read at most the safe limit plus one byte and reject overflow.

3. **Medium — abandoned fetches can destroy another preview.** [FilesView.swift:52](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:52), [FilesView.swift:126](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:126)  
   Start a slow fetch, dismiss/reopen Files or navigate into another directory, then open another file. The original unstructured task survives and can delete the shared `preview` directory beneath the newer Quick Look preview. Disabling buttons also provides no internal guard against already queued opens. **Fix:** guard concurrent opens, retain/cancel the task on disappearance, reject stale completions, and use a unique directory per preview.

4. **Low — preview copies remain after dismissal.** [FilesView.swift:130](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:130)  
   Preview a confidential document and close Files: its downloaded copy remains until another successful preview replaces it or the OS purges temporary storage. **Fix:** remove the owned preview directory after Quick Look dismissal and when the browser closes.

5. **Medium — non-UTF-8 filenames can break the entire listing.** [FilesView.swift:40](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:40)  
   A Linux filename containing byte `0xFF` becomes a Python surrogate escape; `json.dumps` emits an unpaired surrogate that Foundation cannot represent as a valid Swift string. The listing can fail rather than merely omit that entry. **Fix:** encode raw filename bytes separately from display names, or explicitly skip unsupported names with a warning.

6. **Medium — Files requires an undocumented remote dependency.** [FilesView.swift:84](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:84)  
   On a box with herdr-core but no `python3`, Files cannot list anything or reach preview. **Fix:** explicitly require Python for Files, detect its absence, and show an actionable error; alternatively remove that dependency.

**No findings:** shell injection through argv; spaces, quotes, newlines, leading hyphens and valid Unicode names; remote `~` expansion; ordinary symlink traversal, assuming the space folder is not a security boundary; `.completeFileProtection`.

Documentation discrepancies: the feature guide describes chunked reads, whereas this commit refuses large files; README names Python as a Chat dependency only.

Not checked: simulator/device behavior or herdr-core’s server-side output cap. The exact oversized-response outcome depends on whether core sends, rejects, or truncates it. No files edited.
