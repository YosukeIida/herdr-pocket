# Judgement: review of Files and Quick Look preview (2026-11-01)

Reviewed commit: 6c7e200. Raw review: `2026-11-01-files-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | 12 MiB as base64 fills the whole 16 MiB frame; a larger reply drops the connection | Fix | Limit is `Frame.maxPayload / 2` (8 MiB, about 11 MB as base64), leaving room for JSON and stderr |
| 2 | The listed size is stale by the time of the read; `cat` reads everything; FIFOs hang | Fix | Reading moved to a python3 script that opens with `O_NONBLOCK`, accepts only regular files (`fstat`), reads at most limit + 1 bytes and exits 3 above the limit |
| 3 | An abandoned fetch can delete the folder under a newer preview; queued opens are not guarded | Fix | One folder per preview (UUID), `open` returns while another runs, the fetch task is kept and cancelled when the view goes away, cancelled results are dropped |
| 4 | Downloaded copies stay after the preview closes | Fix | The copy's folder is deleted when Quick Look closes; leftovers (app quit mid-preview) are deleted when Files opens. Not deleted on `onDisappear`, since presenting Quick Look can fire it while the file is shown |
| 5 | A non-UTF-8 file name can break the whole listing | Fix | Such names are skipped and counted; the list says how many are hidden. Not reproducible on APFS, which refuses those names; applies to Linux boxes |
| 6 | Files depends on python3 on the box without saying so | Fix | README lists python3 for Chat and Files; a missing python3 (herdr-core 0.1.15 answers `spawn_failed`, checked) shows "Files needs python3 on the box." |

Verified after the fixes: `testFilesPreviewInQuickLook` opens PDF, docx, xlsx and png on the iOS 27.1 simulator. The read script was run on the Mac against a 13 KB PDF (read), exactly 8 MiB (read), 8 MiB + 1 byte and 9 MiB (refused), a FIFO and a directory (refused).
