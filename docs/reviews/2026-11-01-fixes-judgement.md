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
