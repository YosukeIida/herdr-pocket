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

## State

(filled in as the work lands)
