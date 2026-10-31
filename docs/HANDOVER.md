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

All five targets are met on the simulator. Commits are local on `main` (12 ahead of origin); nothing is pushed.

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
  → `DenyUsers *`), so the simulator connects to the Mac's Tailscale IP `<Tailscale IP>`, not
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
  and openpyxl via uvx; the png must be opaque). pptx is not tested.
- Chat: `testChatRendersAndFolds` passes against a live Claude Code terminal on this Mac.
- Reviews: every unit had a Codex review; the fixes made for them were reviewed once more
  (`docs/reviews/2026-11-01-review-fixes-codex.md`, no defects).

## Things on this Mac to undo when done

- `~/.ssh/authorized_keys`: the last line, comment `herdr-pocket-simulator` (the key used by the UI
  tests; private key in this session's scratchpad, gone after the session).
- `~/.ssh/known_hosts`: entries for `127.0.0.1` and `<Tailscale IP>` added while testing.
- Simulator iPhone 18 Pro: the app, its Keychain items and the saved machine.

## Next

- Codex chat: a rollout reader beside `TranscriptScript`, selected by program
  (`AgentScreen.swift:13`, `ChatModel.swift:107`). If the Chat code turns out weak to extend,
  opencode and Orca's chat are acceptable references (check licenses first).
- launchd notifier for macOS (`NotificationSettings.swift:180-205`, `scripts/install-notifier.sh`).
- Files: chunked reads above 12 MiB; pptx and HTML/md rendering checks.
- Run on a real iPhone (needs `Config/Local.xcconfig` with a team id).
- Citadel: close the channel on handshake failure (fork + upstream PR), see `docs/reviews/PENDING.md`.
