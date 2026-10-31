# herdr-pocket

A native iPhone and iPad client for herdr-core: read and answer Claude Code and Codex sessions as chat, preview the box's files, and see every agent's state, while the desktop uses the Herdr app on the same herdr-core. The app talks to herdr-core only over SSH (an exec channel running `herdr-core connect`), with no resident server or third-party relay. It is a fork of `zzulanas/herdr-ios` (`upstream`); `origin` is `YosukeIida/herdr-pocket`. Why this base was chosen and what it lacks are in `docs/2026-11-01_existing-apps-and-orca-mobile-survey.md` and `docs/2026-11-01_herdr-ios-code-review.md`.

## Layout

- `Packages/HerdrKit`: protocol and model (SwiftPM, no external dependencies, unit tests). Run `swift test` there.
- `App/Sources`: the iOS app (SwiftUI). Net (Citadel SSH, Keychain), Store (`AppStore`), UI, Chat, Mods (JavaScriptCore), Notify.
- `project.yml`: XcodeGen spec. `Herdr.xcodeproj` is generated (`xcodegen generate`) and not tracked, except its `Package.resolved`, which pins the package versions.
- Requires iOS 26 or later. Develop against the iOS simulator on the Mac. The simulator reaches the Mac's own sshd; when sshd admits only Tailscale addresses, connect to the Mac's Tailscale IP rather than `127.0.0.1`. The build command (Metal Toolchain, ad-hoc signing) is in README, "Build and run".

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
