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
