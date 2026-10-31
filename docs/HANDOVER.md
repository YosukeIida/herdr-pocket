# Handover

Session handover for herdr-pocket. Overwritten each time; history lives in git.
Read `AGENTS.md` and the three `docs/2026-11-01_*.md` documents first.

## Target for the morning of 2026-11-02 (hypothesis set on 2026-11-01)

The owner asked for the state the repo should be in by morning, then for the work up to it.
The hypothesis: the fork is a foundation the owner can start building on without first
re-checking it. Concretely:

1. Repo conventions in place: `AGENTS.md` + `AGENTS.ja.md`, English docs with `.ja.md`
   translations, nix devshell (`.envrc`, `nix/flake.nix`), Xcode MCP (`.mcp.json`).
2. The three fixes from the code review are made and committed:
   - Chat no longer re-reads the transcript on every terminal `title` change.
   - The host key is shown and approved before it is pinned, and pins live in the Keychain.
   - Citadel is pinned to an exact version; the tracked `.pyc` is gone.
3. The scripts that run unsandboxed at build time have been read.
4. The app builds and runs in the iOS simulator and connects to this Mac's herdr-core over SSH
   (simulator → 127.0.0.1:22 → `herdr-core connect`), which also answers the spike's open
   question about Citadel keeping the `hc connect` stdio alive (on the simulator, not a device).
5. One missing feature: a file tree per space with Quick Look preview (PDF, docx, xlsx, images).

Out of scope tonight: Codex chat, the launchd notifier, push (no APNs on the simulator),
anything on a real iPhone, pushing to origin.

## State (2026-11-01, night)

All five targets are met on the simulator. Commits are local on `main`; nothing is pushed.

- Conventions: `AGENTS.md`/`AGENTS.ja.md`, the three 2026-11-01 documents in English with `.ja.md`
  translations, devshell (`nix develop ./nix` gives XcodeGen 2.44.1 and bun 1.3.13; Swift comes
  from Xcode), `.mcp.json` (Xcode MCP). README updated for the fork; `README.ja.md` added.
- Fixes: Chat nudge (407eccd), host key approval + Keychain (362b8bc), `requiredMethods` (1b740be),
  Citadel pinned and `Package.resolved` tracked (2357d77). Codex reviewed them; four findings fixed,
  one deferred (`docs/reviews/2026-11-01-fixes-judgement.md`, `PENDING.md`).
- Build-time scripts read: `bundle-mods.sh` and `mods-transform.mjs` only read the local mod
  sources and write into `App/Resources/Mods` (no network, deletes only its temp dir and
  `_local.js`). SwiftTerm 1.20.0's build plugin runs read-only `git` on its own checkout and
  writes one generated Swift file.
- Simulator (iPhone 18 Pro, iOS 27.1): builds with ad-hoc signing; unsigned builds
  (`CODE_SIGNING_ALLOWED=NO`) cannot use the Keychain (error -34018). Needs Xcode's Metal
  Toolchain (installed tonight with `xcodebuild -downloadComponent MetalToolchain`).
- Connection: the Mac's sshd admits only Tailscale addresses (`Match Address *,!100.64.0.0/10`
  → `DenyUsers *`), so the simulator connects to the Mac's Tailscale IP (in `docs/private/machine.md`), not
  127.0.0.1. `HerdrUITests.testFirstConnectAsksForHostKey` passes: fingerprint shown before login,
  equal to `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`, home with live agents only after
  approval. This answers the spike's open question for the simulator: Citadel keeps the
  `herdr-core connect` stdio open. Not yet confirmed on a device.
- Files (this repo's first feature, 6c7e200 + 95acd13 after Codex's review,
  `docs/reviews/2026-11-01-files-judgement.md`): `App/Sources/UI/FilesView.swift`, folder button in
  a space's toolbar. Lists and reads with python3 on the box; reads are capped at 8 MiB on the box
  (`Frame.maxPayload / 2`), larger files are refused (`shortcut:` in the code; the code-review
  document's "read in chunks" is not built yet). `testFilesPreviewInQuickLook` opens a PDF, docx,
  xlsx and png from `build/preview-fixtures/` (gitignored; recreate with textutil, cupsfilter, sips
  and openpyxl via uvx; the png must be opaque; md, html, json, csv, swift, svg, jpg, gif, heic and
  pptx were added by hand). All of them open; Markdown opens in Chat's renderer instead of Quick Look,
  which shows the raw source. HTML without a viewport and SVG show small (desktop scale, intrinsic size).
- Chat (1f37e96): Claude Code and Codex. `testChatRendersAndFolds` and `testChatSendGetsReply` pass
  against throwaway terminals (`hc run --bg --name claude-chat-test claude --strict-mcp-config`,
  and `CODEX_HOME=$HOME/.codex-labteam hc run --bg --name codex-chat-test codex`, both in this repo):
  the message sent from the phone reaches the agent and its reply shows. A Codex on the shared
  app-server holds no rollout; its thread is matched by terminal title and folder in
  `~/.codex*/state_*.sqlite` (a `shortcut:` in `CodexTranscriptScript.swift`).
- Blocked dialogs (BlockedCard): `testBlockedDialogButtons` passes. A throwaway Claude Code was asked
  to use AskUserQuestion; tapping "Teal" in Chat answered it and the agent replied TEAL. Fixed on the
  way: options separated by description lines were not read (only the last one was).
  After the review (`docs/reviews/2026-11-01-codex-chat-judgement.md`) the card needs the menu cursor
  and option 1, nested `codex exec` rollouts are ignored, and oversized transcript records are skipped;
  the blocked (Amber), Codex send and read, and Files tests pass again.
- Transcript reads while a Claude agent works: 7 runs of the read script in a 150 s window (sampled
  with `pgrep -f "import sys, os, json, glob, re"`; macOS python3 re-execs as `Python`, so
  `pgrep -f "python3 -c"` sees none). Before 407eccd every title change (about every 0.1 s) woke it.
- Reviews: every unit had a Codex review; the fixes made for them were reviewed once more
  (`docs/reviews/2026-11-01-review-fixes-codex.md`, no defects).

## Things on this Mac to undo when done

- `~/.ssh/authorized_keys`: the last line, comment `herdr-pocket-simulator` (the key used by the UI
  tests). Its private key is `docs/private/sim_key` (gitignored); delete both together.
- `~/.ssh/known_hosts`: entries for `127.0.0.1` and the Tailscale IP added while testing
  (`ssh-keygen -R 127.0.0.1`, `ssh-keygen -R $TS_IP`).
- Simulator iPhone 18 Pro: the app, its Keychain items and the saved machine
  (`xcrun simctl uninstall <udid> dev.herdr.ios.unofficial`, `xcrun simctl keychain <udid> reset`).
- Xcode's Metal Toolchain component (needed to build; keep it).

## Rerunning the UI tests

From the repo root, after `nix develop ./nix -c xcodegen generate`. `D` is the simulator's UDID
(`xcrun simctl list devices`); `B` holds the shared flags.

```sh
B=(-project Herdr.xcodeproj -scheme Herdr -destination "platform=iOS Simulator,id=$D" -derivedDataPath build/dd
   -skipPackagePluginValidation CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=)
export TEST_RUNNER_HERDR_DEBUG_KEY_PATH=$PWD/docs/private/sim_key
export TS_IP=...   # from docs/private/machine.md

# First connect (fresh install and keychain first)
xcrun simctl uninstall $D dev.herdr.ios.unofficial; xcrun simctl keychain $D reset
TEST_RUNNER_HERDR_TEST_HOST=$TS_IP TEST_RUNNER_HERDR_TEST_USER=yosuke \
TEST_RUNNER_HERDR_TEST_HOST_FP=$(ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | awk '{print $2}') \
  xcodebuild test "${B[@]}" -only-testing:HerdrUITests/HerdrUITests/testFirstConnectAsksForHostKey

# Files (needs build/preview-fixtures)
TEST_RUNNER_HERDR_TEST_SPACE=herdr-pocket TEST_RUNNER_HERDR_TEST_FILES_PATH=build/preview-fixtures \
TEST_RUNNER_HERDR_TEST_FILES=sample.pdf,sample.docx,sample.xlsx,sample.png \
  xcodebuild test "${B[@]}" -only-testing:HerdrUITests/HerdrUITests/testFilesPreviewInQuickLook

# Chat: read (a Claude Code or Codex terminal address from `hc ls`)
TEST_RUNNER_HERDR_TEST_TERMINAL=t17 xcodebuild test "${B[@]}" -only-testing:HerdrUITests/HerdrUITests/testChatRendersAndFolds

# Chat: send to a throwaway agent and wait for the reply (the reply must not occur in the prompt)
TEST_RUNNER_HERDR_TEST_SEND_TERMINAL=<address> TEST_RUNNER_HERDR_TEST_SEND_EXPECT="ONE TWO THREE" \
TEST_RUNNER_HERDR_TEST_SEND_TEXT="Write the English words for the numbers one to three in capital letters on one line, separated by single spaces, and nothing else." \
  xcodebuild test "${B[@]}" -only-testing:HerdrUITests/HerdrUITests/testChatSendGetsReply

# Blocked dialog: leave a throwaway Claude Code waiting on AskUserQuestion first
TEST_RUNNER_HERDR_TEST_BLOCKED_TERMINAL=<address> TEST_RUNNER_HERDR_TEST_BLOCKED_OPTION=Teal \
  xcodebuild test "${B[@]}" -only-testing:HerdrUITests/HerdrUITests/testBlockedDialogButtons
```

## Next

- Chat: Codex thread matching would be exact if Codex exposed its thread id to the terminal. If the Chat code turns out weak to extend,
  opencode and Orca's chat are acceptable references (check licenses first).
- launchd notifier for macOS (`NotificationSettings.swift:180-205`, `scripts/install-notifier.sh`).
- Files: chunked reads above 8 MiB; HTML/SVG scaled to the screen (WKWebView) if that matters.
- Run on a real iPhone (needs `Config/Local.xcconfig` with a team id).
- Citadel: close the channel on handshake failure (fork + upstream PR), see `docs/reviews/PENDING.md`.
