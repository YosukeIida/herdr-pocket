# Ovis, herdr and herdr-pocket: what each covers for a phone (2026-11-01)

Why this exists: to state, with sources, which needs of a phone client neither herdr itself nor Ovis covers today, and so why herdr-pocket is built. Both herdr and Ovis are open source, so every claim below points at code, a document, an issue or a measurement.

Versions read: herdr-core `main@568a44d` (= v0.1.15 apart from README), herdr-app `main@07ba77e`, herdr TUI `main@ee5bfb5`, Ovis `origin/main@16bdda5` (release v0.4.21 = `6c78047f`), devswha/ovis-terminal (`integration@1c21d63`). herdr-pocket at `ccaaf96`. Measurements were made on this Mac with hc 0.1.15 and an Ovis server started from `main` with `OVIS_RUNTIME=herdr-core`.

## Terms

- **herdr TUI** (`herdr`): the original terminal multiplexer for coding agents.
- **herdr-core** (`hc`): a headless resident server for terminals and agents. The **Herdr app** is its desktop client. The TUI and herdr-core do not share agents.
- **Ovis**: a Bun/TypeScript server on the PC that serves a web UI (PWA). Its phone apps are WebView shells around that UI.
- **herdr-pocket**: this repo, a native SwiftUI iOS client that talks to herdr-core over SSH (`herdr-core connect`), forked from zzulanas/herdr-ios.

## 1. Two claims checked

**"Ovis assumes a browser."** Correct. Ovis's UI is a web page served by a Bun server on the PC (`127.0.0.1:7317`). The iOS app is a Capacitor 8 WKWebView shell around that page (`app/package.json:12-18`, `docs/native-app.md:20-22`); its Swift code (about 1,150 lines) covers only a connect screen, a PC list, push and a notification extension, and imports no SSH, Quick Look or terminal code. Without the PC server it shows only a demo session (`docs/native-app.md:39-40`). The Mac app is also a WKWebView window (`app/mac/README.md`).

**"Ovis is forking herdr-core."** Incorrect.
- None of the 31 GitHub forks of herdrdev/herdr-core belongs to devswha (Ovis's author); devswha has no issue or PR on herdr-core.
- Ovis's `patches/` patch only npm packages (xterm, legendapp list); `crates/` holds only Ovis's own PTY host. CI downloads the official hc 0.1.14 by sha256 (`.github/workflows/ci.yml:190-191,214`).
- What exists is (a) an **adapter** in Ovis, `server/herdr-core/adapter.ts:11-34`, which answers herdr TUI's socket API from hc so the rest of Ovis runs unchanged, and (b) **devswha/ovis-terminal**, a separate MIT project that aims to "replace herdr underneath Ovis, not a fork" (`docs/design/ideal-state.md:3`). Its README says "Status: scaffold … The only working command is `ovis-terminal --version`."

## 2. What herdr itself provides for a phone

All of herdr TUI, herdr-core and the Herdr app are Apache-2.0 and public (herdrdev/herdr, herdrdev/herdr-core, herdrdev/herdr-app). The herdr.dev FAQ: "build your own app on top of herdr-core."

Not provided by herdr (evidence in brackets):
- An official iOS/Android client or web UI. The TUI docs say Herdr "works on your phone without a mobile app or web dashboard" through any SSH client (`how-to-work.mdx:49-58`); herdr.dev/core invites "a phone app" as your own client.
- A network listener: herdr-core listens only on a Unix socket; remote use is `ssh box hc connect` (`schema/README.md:23-26`, `docs/security.md:20-24`).
- Push notifications: no APNs, webhook or relay in core; even the desktop app has only in-app toasts (herdr-app#120, open).
- Binary file reads: `file.read` is text only, 8 MB (`hc.openrpc.json:2962`, error `not_text`). Binary content must go through `machine.exec` stdout (base64, first 8 MB, 60 s default timeout, spec:161).
- A transcript/chat API or a session id per terminal (no such method; herdr-core#15 open). Status comes only from what the program reports via OSC 7501 (README:186-189).
- A supported contract for the space/tab layout: it is the Herdr app's own `herdr-app` document (herdr-app#43, open, no maintainer reply).

## 3. Ovis on herdr-core today

- **Unreleased.** The herdr-core runtime (`server/herdr-core/`) is absent from v0.4.21 (`git ls-tree v0.4.21 server/herdr-core/` is empty). Seven PRs (#2442–#2456) merged on 2026-10-30 after that tag; release PR #2473 (0.4.22) is open and marked "Do not merge yet".
- **Installers do not support it.** install.sh, Ovis.dmg and the herdr plugin all install herdr TUI and run Ovis as its plugin (`install.sh:385,450`, `README.md:48`); none mentions `OVIS_RUNTIME` or hc. Today the only route is `main` + `bun install` + `OVIS_RUNTIME=herdr-core bun run start`, with Bun ≥ 1.4.
- **Disabled in this mode:** rename, move, split, zoom, resize and swap of workspaces/tabs/panes; worktrees; plugins; search and scrollback selection; remote machines through hc (`docs/guide.md:708-710`, PR #2451, issue #2497 open).
- **Measured: Claude Code chat falls back to terminal text.** On this Mac, `GET /api/pane/conversation?pane_id=t17` (a Claude Code terminal) returned `{"source":"scrollback","turns":[]}`; the same for t14. The likely cause, from the code: hc reports `status.app = "claude-code"`, the adapter passes it through (`server/herdr-core/snapshot.ts:72-74`), and Ovis's Claude chat and dialog readers key on `"claude"` (`conversation.ts:1084,1505`; `dialogs/claude.ts:1037-1095`).
- **Prompts are refused while the agent is blocked**, since the adapter uses `terminal.send` (`adapter.ts:24,403`).
- **Calls no `machine.*` or `file.*`**: files and diffs are read from the PC's own disk by the Ovis server (`FileViewer.tsx`, file routes).

## 4. Comparison

○ = works, △ = partial or conditional, × = not available. "Ovis/core" is Ovis `main` with `OVIS_RUNTIME=herdr-core` (unreleased). "herdr-pocket" was checked in the iOS simulator unless marked.

| Need | herdr (official) | Ovis/TUI | Ovis/core | herdr-pocket |
|---|---|---|---|---|
| Phone UI | × (TUI over any SSH app) | Web/WebView | Web/WebView | Native SwiftUI |
| Works against herdr-core / the Herdr app's agents | — | × | △ unreleased, source only | ○ |
| Resident process on the PC | — | Bun server (+ herdr TUI) | Bun server | None for chat, files, terminal; a notifier process for push |
| Network exposure of the PC | SSH | HTTP/WS (Tailscale serve, tunnel, etc.) + pairing | same | SSH only |
| Hosted third-party services | none | push relay `push.ovis.sh`; telemetry Worker, on by default after a notice | same | none (the PC pushes to APNs itself) |
| Claude Code chat from the transcript | × | ○ | × measured: terminal text | ○ |
| Codex chat | × | ○ | △ unverified | ○ |
| Other agents' chat (OpenCode, pi, omp, …) | × | ○ | △ | × (terminal only) |
| Answer a blocked dialog with buttons | × | ○ | △ (Claude reader not used, see above) | ○ Claude Code verified; Codex untested |
| Send a prompt | (type in TUI) | ○ | △ refused while blocked | ○ |
| Agent list and state | ○ in TUI | ○ | △ OSC 7501 reporters only | ○ (OSC 7501 via events) |
| Push notifications when the app is closed | × | ○ Web Push / APNs via relay | △ | △ needs a paid Apple account, an APNs key and the notifier on the PC (macOS: nohup, no launchd yet) |
| Live terminal | ○ | ○ xterm.js | ○ | ○ SwiftTerm |
| Preview PDF, images (incl. HEIC) | × | ○ (PDF in an iframe) | ○ | ○ Quick Look |
| Preview docx, xlsx, pptx | × | × "can't be previewed here" (`FileViewer.tsx:444`) | × | ○ Quick Look |
| Rendered Markdown | × | ○ | ○ | ○ |
| Files over 8 MiB | — | ○ | ○ | × not yet |
| Git diffs | × | ○ | ○ | × |
| Start an agent | ○ | ○ | △ typed into an idle shell | ○ |
| Layout editing (split, rename, …) | ○ in TUI/app | ○ | × | × (reads the layout only) |
| Multiple machines | ○ | ○ SSH bridges | △ TUI remotes only | ○ saved machines (only one tested) |
| Released and installable | ○ | ○ v0.4.21; iOS app in review, TestFlight "coming soon" | × | × (build from source; no TestFlight yet) |

## 5. Where they are the same

- Both depend on contracts herdr has not committed to: the `herdr-app` layout document (herdr-app#43) and the absence of a session id (herdr-core#15). Both match a terminal to a transcript by heuristics (Ovis: hook report or process; herdr-pocket: process tree and `~/.claude/sessions`, and for Codex open files or the state DB by title and folder).
- Both take agent status only from OSC 7501, so a program that does not report it shows no state.
- Both reach the PC over the user's own network (Tailscale or similar).

## 6. What herdr-pocket adds that neither covers

1. A native iOS client for **herdr-core** that needs **no server on the PC** for chat, files and terminal: one SSH exec channel to `herdr-core connect`, nothing exposed except sshd, no hosted relay or telemetry. herdr has no phone client; Ovis needs its Bun server and its herdr-core mode is unreleased.
2. **Claude Code and Codex chat on herdr-core** read from the transcript, including dialog buttons answered with `terminal.keys` (works while blocked). Ovis on herdr-core shows Claude Code as terminal text (measured).
3. **Office preview on the phone** (docx, xlsx, pptx) through Quick Look, by reading bytes with `machine.exec` because herdr-core's `file.read` is text only. Ovis shows "can't be previewed here" for these in any mode.
4. Host key approval before login and keys in the Keychain (herdr-pocket's own fixes; Ovis uses pairing codes and cookies instead).

## 7. Where herdr-pocket is behind

- Chat only for Claude Code and Codex; Ovis reads about 15 agents.
- No diffs, no layout editing, files over 8 MiB not previewed, HTML/SVG shown small.
- Push needs a resident notifier on the PC and a paid Apple Developer account; on macOS it runs under nohup, not launchd.
- Needs python3 on the PC for Chat and Files.
- Not yet run on a real iPhone; not distributed.

## 8. Distribution cost (TestFlight)

- TestFlight itself is free for testers (they install the free TestFlight app), but uploading builds requires the **Apple Developer Program, US$99 a year** ("TestFlightでのテスターの招待や、ベータ版ビルドの管理" is a paid-membership item; https://developer.apple.com/jp/programs/). The price in yen is shown at enrolment ("価格は地域によって異なる場合があり、登録手続きの際は現地通貨で表示されます", https://developer.apple.com/jp/programs/enroll/); the exact yen amount was not confirmed.
- Each build is testable for **90 days** after upload ("Your build becomes unavailable for testers after 90 days."). Uploading a new build restarts the 90 days; there is no extra charge per build. Up to 100 internal testers and 10,000 external testers; external testing needs Beta App Review of the first build (https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview).
- The fee waiver applies only to nonprofits, accredited educational institutions and government entities, not to individuals (https://developer.apple.com/support/membership-fee-waiver/). A university lab could qualify as an institution; an individual cannot.
- Without the paid program, Xcode can install the app on your own device with a free Apple Account, but the profile expires after 7 days (3 devices, 10 App IDs) (https://developer.apple.com/support/compare-memberships/). herdr-pocket's push notifications need an APNs key, which needs the paid program (README, "Notifications").

## Unverified

- Codex chat and dialog cards in Ovis on herdr-core (no Codex terminal was running during the measurement).
- Whether Ovis's iOS app passes App Review, and whether its push works on a device.
- The yen price of the Apple Developer Program at enrolment.
- Ovis features beyond chat on herdr-core were read from code, not exercised.

## Inconsistencies found in Ovis's documentation

- `README.md:71` and `docs/guide.md:916` say "no hosted relay of its own"; `push.ovis.sh` is a hosted push relay and `relay.ovis.sh` is being added.
- `docs/guide.md:708-709` says workspaces/tabs/panes cannot be created on herdr-core; `adapter.ts:406-448` implements it.
- `docs/guide.md:702` says `error` counts as finished; `snapshot.ts:54-67` maps it to unknown.
- `README.md:52` points to a TestFlight beta at ovis.sh/beta; the page says the link is "coming soon".

## Decision (2026-11-01)

The owner decided to finish herdr-pocket rather than adopt Ovis: Ovis cannot meet the requirements of a native client for herdr-core with no server on the PC, transcript chat for Claude Code on herdr-core, and Office preview (sections 3 and 6). Ovis remains a reference for the features herdr-pocket lacks (diffs, other agents' transcripts); its code is MIT, so reuse needs the notice and the source noted in the file.
