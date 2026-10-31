# 判断: Files と Quick Look のプレビューへのレビュー（2026-11-01）

この文書は `2026-11-01-files-judgement.md` の日本語訳である。内容が食い違うときは英語版に従う。

対象の commit: 6c7e200。レビューの出力そのもの: `2026-11-01-files-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。

| # | 指摘 | 判断 | 理由・変更 |
|---|---|---|---|
| 1 | 12 MiB を base64 にすると 16 MiB の frame を使い切り、それより大きい応答で接続が切れる | 直す | 上限を `Frame.maxPayload / 2`（8 MiB、base64 で約 11 MB）にし、JSON と stderr の分を残した |
| 2 | 一覧で得た大きさは読む時点では古く、`cat` は全部を読み、FIFO では止まる | 直す | 読み取りを python3 のスクリプトに移した。`O_NONBLOCK` で開き、通常のファイルだけを受け付け（`fstat`）、上限 + 1 バイトまでしか読まず、上限を超えたら終了コード 3 で終わる |
| 3 | 放置された取得が、新しいプレビューの下のフォルダを消しうる。重ねて開く操作を防いでいない | 直す | プレビューごとにフォルダを分け（UUID）、取得中は `open` が何もせず戻る。取得の task を保持し、画面が消えたら cancel し、cancel された結果は捨てる |
| 4 | プレビューを閉じても、取り出した複製が残る | 直す | Quick Look を閉じたときに複製のフォルダを消す。プレビュー中にアプリが終わって残った分は、次に Files を開いたときに消す。`onDisappear` では消さない。Quick Look を出すと、ファイルを表示している間に `onDisappear` が呼ばれうるため |
| 5 | UTF-8 でないファイル名があると、一覧全体が壊れうる | 直す | そうした名前は飛ばして数え、隠した件数を一覧に出す。APFS はその名前を作らせないので Mac では再現できない。Linux の機体で効く |
| 6 | Files が機体の python3 に依存することを書いていない | 直す | README に、Chat と Files には python3 が要ると書いた。python3 が無い場合（herdr-core 0.1.15 は `spawn_failed` を返すことを確かめた）は「Files needs python3 on the box.」と出す |

修正後に確かめたこと: `testFilesPreviewInQuickLook` が、iOS 27.1 の simulator で PDF・docx・xlsx・png を開く。読み取りのスクリプトを Mac で直接動かし、13 KB の PDF（読めた）、ちょうど 8 MiB（読めた）、8 MiB + 1 バイトと 9 MiB（拒否）、FIFO とディレクトリ（拒否）を確かめた。
