# Judgement: review of the notifier service, large files, HTML/SVG and Changes (2026-11-01)

Reviewed commit: 282034e. Raw review: `2026-11-01-files-changes-notifier-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | The size/mtime line pushes an 8 MiB chunk past the core's 8 MB stdout cap; the short chunk is taken as the end of the file | Fix | A real bug: the 15 MB test PNG showed only a band. Chunks are 4,000,000 bytes; every chunk must be exactly `min(chunk, size - offset)` long and the reply must not be `truncated` (now read from `machine.exec` into `ExecResult`) |
| 2 | JavaScript off does not stop images, CSS, iframes or redirects from reaching the network | Fix | A content rule list blocks every non-`file:` load before the page loads; the navigation delegate cancels non-file navigations; non-persistent data store |
| 3 | A change during the last chunk, or a truncation, passes as a good file | Fix | The script `fstat`s again after reading and exits 4 when size or mtime moved; the app checks each chunk's length (finding 1) |
| 4 | PATH or home with `&` or `<` breaks the plist, after the running notifier was stopped | Fix | Values are XML-escaped; the plist is written to a temporary file and `plutil -lint`ed before it replaces the old one and the job is restarted |
| 5 | Porcelain paths are relative to the repo root, but diffs ran in the space folder | Fix | `git rev-parse --show-toplevel` first; status and diffs run at the root |
| 6 | `~` and `~/x` are not expanded in argv | Fix | Expanded with the box's home before calling git |
| 7 | A rename drops its source and shows as an added file | Fix | The source is kept and both paths are passed with `-M` |
| 8 | Staged files before the first commit cannot be diffed (no HEAD) | Fix | `rev-parse --verify HEAD`; without HEAD the diff is `--cached` |
| 9 | A status or diff over 8 MB is cut without notice | Fix | A truncated status is refused; a truncated diff ends with a line saying so |
| 10 | An unquoted python path with spaces breaks the systemd unit | Fix | `ExecStart="…" "…"` |
| 11 | File names are pathspecs (`*.txt`) | Fix | `--literal-pathspecs` |

Codex also noted that `docs/HANDOVER.md` still described chunked reads and HTML/SVG as not built; updated.

Checked: HerdrKit tests (new `testExecReportsTruncatedOutput`), the read script reassembling a 15 MB file in 4,000,000-byte chunks byte for byte, the service script dry-run with `&` and `<` in PATH (plist lints, PATH round-trips), the git argv on a scratch repo (rename shown as rename, `*.txt` literal, `--cached` before the first commit, root from a subfolder), and a device build of the app and UI tests. In the simulator (Xcode 27.2) after the fixes: `testFilesPreviewInQuickLook` opened a 15 MB PNG (2400×2400, red band at the bottom shown, so read to the end), HTML, SVG, Markdown and PDF; a page loading `http://127.0.0.1:8765/…` made no request to that server, while Safari in the same simulator reached it (4 requests); `testChangesShowDiff` listed an untracked file and showed its diff.

## Re-review of fa92895

Raw review: `2026-11-01-files-changes-notifier-fixes-codex.md`. No other remaining or new defects were found.

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | A python path containing `"`, `\` or `%` still breaks the quoted systemd `ExecStart` | Fix | `unit()` escapes `\` and `"` and doubles `%` (checked on `/home/a b/My "T"\x/100%/python3`) |
| 2 | The truncation line sits after the 5,000-line cap and disappears on long diffs | Fix | Truncation is kept apart and shown after the lines whatever their count |
| — | README still said files over 8 MiB are not previewed | Fix | README (EN, JA) describes chunked reads, HTML/SVG and the new Changes screen |
