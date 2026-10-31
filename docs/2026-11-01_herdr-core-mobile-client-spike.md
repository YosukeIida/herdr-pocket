# Verifying whether a native smartphone app can be built on the herdr-core API

Run on 2026-11-01 on the Mac Studio (herdr-core 0.1.15, Claude Code 2.1.316).

## Goal

Check whether the following setup can be built with the herdr-core API alone: on the PC, agents are operated in a terminal of the Herdr app; on the smartphone, a self-built iOS app provides chat and file preview. Three points were checked.

1. Can the state of spaces, tabs and agents be read through the API?
2. Can a terminal be linked to the agent's transcript?
3. Can the files to preview on the smartphone (including PDF, docx and xlsx) be retrieved through the API?

## Results

| Point checked | Result | API used |
|---|---|---|
| Connection | Speaks newline-delimited JSON-RPC over stdin and stdout. `hello` returns generation 1, version 0.1.15 | `hc connect` |
| Space and tab layout | The Herdr app layout (spaces, tabs, splits, the terminal of each block) is available as JSON | `doc.get {name: "herdr-app"}` |
| Agent state | For each terminal: `status: {app: "claude-code", state: "working", msg: …}`, `title`, `foreground` (argv, cwd and pid of the foreground process), and the labels `herdr.space` and `herdr.tab` | `terminal.list`, `terminal.get` |
| State change notifications | Right after subscribing, a snapshot of all terminals arrives. After that, terminal start, exit and label changes arrive in order as `event` notifications | `events.subscribe` |
| Input to a terminal | Text can be pasted and Enter pressed | `terminal.send` |
| Identifying the Claude Code transcript | Links uniquely. Reading `~/.claude/sessions/<pid>.json` from the terminal's `foreground.pid` gives `sessionId` and `cwd`. The transcript is `~/.claude/projects/<name derived from cwd>/<sessionId>.jsonl`. The terminal's `title` also matched the transcript's `aiTitle` | `terminal.get` and `file.read` |
| Text files | Readable (AGENTS.md in 3 ms) | `file.read` |
| PDF, docx, xlsx | `file.read` rejects them with `not_text` and suggests "for bytes: hc exec cat". Retrieved as base64 with `machine.exec {argv: ["cat", path]}`: a 3.4 MB PDF took 18 ms, docx and xlsx about 5 ms each, and the SHA-256 matched the original files | `machine.exec` |

## Connecting over SSH

A Claude Code session on the MacBook Air (hostname: Yosukes-MacBook-Air) was asked to try 5 methods through `ssh mac-studio hc connect`. All 5 succeeded. The problem of a missing PATH in non-interactive SSH did not occur.

| Method | Time | Result |
|---|---|---|
| `hello` | 403 ms (includes SSH connection setup) | core.name is yosukes-mac-studio |
| `terminal.list` | 7 ms | Returned the terminal list |
| `doc.get {name:"herdr-app"}` | 5 ms | Returned spaces and tabs |
| `file.read` (AGENTS.md, 3 lines) | 5 ms | Returned |
| `machine.exec` (`cat` of a 3.4 MB PDF) | 445 ms | 3394636 bytes, matched the original file, `truncated` is false |

Compared with direct use inside the Mac Studio, the only additions are about 0.4 s for connection setup and about 0.4 s for the PDF transfer.

## Identifying the Codex transcript, and state change notifications

After switching with `cx labteam`, Codex 0.166.0 was started in a herdr-core terminal (t16). "Return only the answer to 1+1" was sent with `terminal.send`, and the `events.subscribe` notifications were recorded meanwhile.

- **Identifying the transcript**: The terminal's `foreground.pid` was the Codex launcher (65546), and its child process (65577) had the rollout file open. `lsof -p <child pid>` uniquely identified `~/.codex/sessions/2026/11/01/rollout-…-01a192fa-….jsonl`. However, the rollout file is not created until the first input is sent. A Codex that has just started and has received nothing yet cannot be identified.
- **State changes**: Codex also reports its state through OSC 7501. The `status` notifications delivered idle → working → done in order. At completion, a `turn` notification (`state: "done"`) and a `title` change ("計算して 1+1 | dotfiles-private") also arrived.
- **Notification volume**: While working, `title` changes with every frame of the spinner, and notifications arrive at intervals of about 0.1 s. Most of the 100-odd notifications were these. The smartphone app needs to thin out `title` notifications, or treat only `status` and `turn` as subscription targets.
- **How sent text appears**: Text sent with `terminal.send` was shown on the Codex screen wrapped in `<hc from="t14">…</hc>`. It arrives in a form that shows the sender terminal. How text sent from the smartphone app appears must be checked with a connection that has no sender.
- **Placement in a space**: The terminal started as a child was automatically placed in the parent's (t14) space as a tab named `codexspike`.

After the check, t16 was exited and deleted.

## Not checked

- **Whether an iOS SSH library can keep the stdio of `hc connect` open.**
- The size limit for transferred binaries. The output of `machine.exec` returns `truncated`. The size at which it truncates was not checked.

## Notes

- For the check, `echo spike-from-hc-send` was sent once to the zsh (t10) in the ararat space.
- The terminal started for the check (t15, `sleep 1`) was deleted. When it exited, the core notified the parent terminal (t14, the terminal of this conversation) in its input field with "t15 spike exited (exit 0)". This also confirmed that child exit notifications reach the parent.
