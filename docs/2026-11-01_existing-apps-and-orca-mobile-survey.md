# Survey of existing apps and inventory of Orca Mobile features

Investigated on 2026-11-01. The investigation had two parts.

1. Survey of existing apps: public information and GitHub.
2. Inventory of Orca Mobile features: the docs, code and issues on the main branch of stablyai/orca.

The behavior of each app on a real device was not checked.

## Requirements

1. Read and send in real Claude Code and Codex CLI sessions (with CLAUDE.md, hooks and skills in effect) from a chat screen on the smartphone.
2. Browse a file tree per space and preview files on the remote machine (PDF, docx, xlsx, png, HTML, md).
3. List the state of agents in all spaces (working, blocked, done) and receive notifications.
4. Keep a single environment. The app looks at the same herdr-core as the Herdr app on the PC, and adds no resident process and no third-party relay.

## Conclusion

No existing app meets all of requirements 1–4. We build our own.

- iOS apps that connect directly over SSH without a resident process include HerdrChat, Melta and Heeler. All of them assume the Herdr TUI and do not support herdr-core. Heeler's herdr-core support is at the stage of issue #541 and PR #538 (open) and is not released yet.
- Only Ovis, Collie and Shepherdr support herdr-core. All three are web apps (PWA) that run a resident Bun server on the Mac, so they do not meet requirement 4. Even Ovis, the closest one, has not released herdr-core support (issue #2439 closed on 10/31, not included in v0.4.21), and cannot preview docx or xlsx.
- There is no sign of an official herdr plan to ship an iOS client (checked herdr.dev, the herdr-app issues and the herdr-core README; Discord was not checked). "Herdr Mobile" on Google Play is not official (the developer is 北京野核桃科技有限公司).

## Comparison of existing apps

○ means met, △ means partly met, × means not met.

| App | 1 Chat | 2 Preview | 3 State, notifications | 4 herdr-core, setup |
|---|---|---|---|---|
| HerdrChat (iOS, Apache-2.0) | ○ | × | ○ | × (assumes TUI) |
| Heeler (iOS, Apache-2.0) | ○ | × (attachments via SFTP only) | ○ | △ (herdr-core support unreleased) |
| Melta | ○ | × | ○ (push goes through Melta's server) | × (assumes TUI) |
| Moshi | △ (Chat View is Pro only) | △ (images, video, PDF) | ○ | × (assumes TUI, needs moshi-hook) |
| Shahi | ○ | △ (text, images, PDF) | ○ | × (TUI plugin) |
| Ovis (PWA, MIT) | ○ | △ (no Office) | ○ (web push) | △ (unreleased; needs a resident server) |
| Collie (PWA, MIT) | △ | △ (read-only) | ○ | △ (experimental; needs a resident server) |
| Secure ShellFish | × | ○ (Quick Look in the Files app) | × | ○ (SSH only) |
| Orca Mobile | ○ | △ (no docx, xlsx) | ○ | × (Orca's server) |

In addition, HerdrGo, Drover, carsol/herdr-mobile, herdrup, Herdi and Corral all assume the Herdr TUI.

## Orca Mobile features to keep and to drop

| Decision | Feature | How to implement on herdr-core |
|---|---|---|
| Keep (first version) | List of the state of all agents | `terminal.list`, `events.subscribe` (handle only `status` and `turn`) |
| Keep (first version) | Chat (show transcript, reply) | Read the transcript. Send with `terminal.send` |
| Keep (first version) | File tree and preview (**add docx and xlsx**) | `machine.exec` (ls, and cat returned as base64). Display with QLPreviewController and WKWebView |
| Keep (first version) | Editing connection targets | App settings |
| Keep | Terminal view (with extra keys) | `terminal.attach`, `terminal.keys` |
| Keep | Notifications | Choose the method under "Decisions" below |
| Later | Quick Commands, Source Control, creating a new workspace, resuming past sessions, diagnostics screen, photo attachments, voice input | `machine.exec` (git, gh), `terminal.run` |
| Drop | Tasks and Automations (herdr-core has no matching API), browser, account switching (replaced by `cx`), bulk tab operations | — |

### What to avoid, based on Orca Mobile's weaknesses

- The most common complaint in the issues is slow reconnection when returning from the background (#13354 and others). Reconnect immediately on return to the foreground, and show a cached copy of the last screen first.
- When run headless, chat shows "Can't find this conversation yet" (#32134 and others). Look up the terminal-to-transcript mapping with a reliable method, not by guessing (see "Mapping terminals to transcripts" below).
- There are screen flicker, sluggishness, and the web bundle being refetched on every launch. Orca Mobile is presumably built mainly on WebView. herdr-pocket is written in SwiftUI.
- Exchange the connection protocol version first, and stop the connection if the combination does not match (the same idea as Orca's `status.get`). On herdr-core, `generation` and `version` from `hello` can be used.

## Mapping terminals to transcripts (correction to the survey report)

The survey report on existing apps said: "herdr-core does not hold the agent's session ID, so hooks must be added or the session guessed from cwd." However, the check (`2026-11-01_herdr-core-mobile-client-spike.md`) looked it up uniquely without adding hooks.

- Claude Code: reading `~/.claude/sessions/<pid>.json` from the terminal's `foreground.pid` gives `sessionId`.
- Codex: use `lsof` to identify the rollout file opened by a child process of the foreground process. The rollout file does not exist until the first input is sent.

Both can run on the Mac Studio side through `machine.exec`.

## OSS worth considering for reuse

- **Heeler** (Swift, Apache-2.0): has SSH communication, terminal display with libghostty, and a chat view. PR #538 contains code for herdr-core support. Its architecture is the closest.
- **HerdrChat** (React Native, Apache-2.0): its parsing of Claude and Codex transcripts is a useful reference.
- **Ovis** (TypeScript, MIT): has a herdr-core adapter and a file viewer.
- **Collie** (MIT): the herdr-core section of `docs/multiplexers.md` lists herdr-core's constraints as measured.

## Additional survey: better foundations than Heeler

Searched again with GitHub search (`herdr ios`, `herdr mobile`, `herdr-core`) and Exa. As foundation candidates, Heeler and zzulanas/herdr-ios are compared.

| Aspect | Heeler (ZingerLittleBee/Heeler) | zzulanas/herdr-ios |
|---|---|---|
| Maturity | 715 stars, distributed on the App Store, developed since 2026-07 | 1 star, published 2026-10-30 (3 commits), one author |
| herdr-core | Not supported (external PR #538 open, +5281 lines) | **herdr-core only from the start**. Runs `herdr-core connect` over an SSH exec channel (the same method as this check) |
| Spaces and tabs | Herdr TUI layout | Reads and writes the Herdr app's `herdr-app` document. PC and smartphone share the same layout |
| Chat | 6 kinds, including Claude Code, Codex and Pi | Claude Code only. Identified from `~/.claude/sessions` (the same method as this check) |
| File preview | None (attachments via SFTP only) | None |
| Notifications | Through its own relay (E2E encrypted). Has Live Activity | **Sent directly to APNs from your own machine on the Mac side** (no relay). However, the notifier is for systemd; there is none for macOS launchd |
| Herdr app mods | — | **Your own mods also run on the smartphone** (implements the herdr and gpui-kit APIs in JavaScriptCore and renders with SwiftUI; `exec` runs on the Mac side) |
| Size and structure | Large amount of Swift code, includes relay, plugin and docs-site | 49 Swift files. Split into `HerdrKit` (protocol and model, SwiftPM, with tests) and `App` (Citadel SSH, SwiftTerm) |
| License | Apache-2.0 | Apache-2.0 |
| Runs on | iOS 18 or later | **iOS 26 or later**, Xcode 26.2 or later |

Other herdr clients found are as follows.

- With a resident process (gateway, daemon): BrianBal/herdr-ios (Bun gateway), monotykamary/reflex
- Assume the Herdr TUI: lucasscariot/herdie, Volpestyle/herdr-ios
- ServerCC (App Store, closed source): its herdr integration targets 0.8 (TUI) and does not touch herdr-core. File preview covers md, images and PDF

### Recommendation

We recommend **a fork of zzulanas/herdr-ios** as the foundation, for three reasons.

1. Its design matches requirement 4. It connects directly to herdr-core over SSH, uses no relay, and sends notifications from your own machine.
2. Herdr app mods also run on the smartphone. The PC UI can be carried over to the smartphone, which fits the aim of "a native app, so the UI can be polished".
3. It is small, its structure is split, and it is readable.

Three things are missing. The method for each was confirmed in the check, and adding them is expected to be straightforward.

- Codex chat (identify the rollout with `lsof`)
- File tree and preview (retrieve with `machine.exec`, display with Quick Look)
- A notifier for macOS (resident under launchd)

There are three risks.

- The repo is two days old and has one author. We fork on the assumption that we can maintain it ourselves if upstream stops.
- It requires iOS 26 or later.
- The code itself has not been read yet. Before forking, `HerdrKit` and `Chat` must be read to check their quality.

## Decisions

1. **How to build**: Fork Heeler and add herdr-core support, or write from scratch in SwiftUI.
2. **Notifications**: Receiving notifications while the app is closed requires something that sends to APNs. Choose one of the following.
   - Run a script resident under launchd on the Mac Studio that subscribes to `hc events` and sends to APNs (requires a paid Apple Developer membership).
   - Use a relay such as ntfy.
   - In the first version, show state only while the app is open.
3. **Distribution**: Install only on your own devices (free provisioning expires after 7 days), or distribute through TestFlight.
