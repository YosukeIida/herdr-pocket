# Judgement: Files search, project root, Chat window (6dd9552, 83f9b36, 27db4e9)

Codex (gpt-6.1-sol, medium, read-only), raw output in `2026-11-02-files-search-chat-window-codex.md`.

| # | Finding | Decision | Why |
|---|---|---|---|
| 1 | P2: an earlier window whose output passes the core's 8 MB stdout cap loses entries and moves `start` past them | Fix | Both transcript scripts now drop the oldest entries of a fresh or earlier window until the rest fit in 4,000,000 bytes, moving `start` to match; `loadEarlier` ignores a truncated reply. Incremental reads (new bytes) are unchanged and still unguarded, as before these commits. |
| 2 | P2: Contents search follows symbolic links out of the folder or into ignored files | Fix | The search uses `lstat` and opens with `O_NOFOLLOW`, so links are skipped. Checked with a link to a file outside the search root: not matched. |
| 3 | P3: a query of spaces leaves the spinner showing | Fix | The list tests the trimmed query, as `search()` does. |
| — | README says space Files opens the terminal's current directory; the design note names `projectRoot(of:)` and says cards read only on events | Fix | README now says the project (git repository) of the terminal on screen; the note names `projectRoot(_:)`, says Changes resolves its own root, and says cards poll like Chat. |
