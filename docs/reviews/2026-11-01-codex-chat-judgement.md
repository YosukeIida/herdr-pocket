# Judgement: review of Codex chat, Markdown preview and the dialog parser (2026-11-01)

Reviewed commits: 1f37e96, eb6790d. Raw review: `2026-11-01-codex-chat-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | The newest rollout among all descendants wins, so a nested `codex exec` run by the agent can replace the conversation | Fix | Rollouts whose `session_meta.source` is `exec` are dropped, next to the existing `thread_source == 'user'` filter (which already drops guardian and subagent threads). Checked against the rollouts on this Mac: `cli` and `vscode` are interactive, `exec` is `codex exec`. Not done: ranking by distance from the terminal's process, since the source field names the cause directly |
| 2 | Any numbered list on screen can become dialog buttons, and a tap sends a digit to the agent | Fix | `BlockedCard.parse` returns nil unless one option line carries the menu cursor (`❯` or `›`) |
| 3 | When the countdown stops before 1 (long descriptions), a partial list is shown | Fix | The list must reach option 1, else nil; the card then says to answer in Terminal |
| 4 | A JSONL record longer than the read window (16 MiB) is reread forever | Fix | When the window holds no newline and is full, `next` moves past it; the remainder of that record is a broken line that `json.loads` skips. Applied to both transcript scripts |

Verified on the simulator after the fixes: `testBlockedDialogButtons` (Claude Code waiting on AskUserQuestion with description lines; tapping Amber answered it and the agent replied AMBER), `testChatSendGetsReply` and `testChatRendersAndFolds` on a Codex terminal, `testFilesPreviewInQuickLook` (md, pdf, heic, png).
