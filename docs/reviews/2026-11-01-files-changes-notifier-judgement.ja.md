# 判定: 通知のサービス、大きなファイル、HTML・SVG、Changes のレビュー（2026-11-01）

対象の commit: 282034e。レビューの原文: `2026-11-01-files-changes-notifier-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。

| # | 指摘 | 判定 | 理由と変更 |
|---|---|---|---|
| 1 | サイズと mtime の行が加わると、8 MiB のチャンクが core の stdout の上限（8 MB）を超える。短くなったチャンクをファイルの終わりと判定する | 修正 | 実際の不具合であった。15 MB のテスト用 PNG が帯状にしか表示されなかった。チャンクを 4,000,000 バイトにした。各チャンクの長さが `min(チャンク, サイズ - offset)` と一致し、応答が `truncated` でないことを確かめる（`machine.exec` の `truncated` を `ExecResult` で読むようにした） |
| 2 | JavaScript を無効にしても、画像・CSS・iframe・リダイレクトによる外部通信は止まらない | 修正 | ページを読み込む前に content rule list で `file:` 以外の読み込みをすべて遮断した。navigation delegate も `file:` 以外への遷移を取り消す。データの保存先は永続しないものにした |
| 3 | 最後のチャンクを読む間の変更や切り詰めを、正常なファイルとして受け入れる | 修正 | スクリプトが読み終えた後にもう一度 `fstat` し、サイズか mtime が変わっていれば終了コード 4 で終わる。アプリは各チャンクの長さを確かめる（指摘 1） |
| 4 | PATH やホームに `&`・`<` があると plist が壊れ、動いていた通知プロセスを止めた後に起動に失敗する | 修正 | 値を XML 用にエスケープした。plist を一時ファイルに書き、`plutil -lint` で検証してから置き換え、ジョブを起動し直す |
| 5 | porcelain のパスは repo のルートからの相対パスだが、diff をスペースのフォルダで実行していた | 修正 | 先に `git rev-parse --show-toplevel` を実行し、status と diff をルートで実行する |
| 6 | argv では `~` と `~/x` が展開されない | 修正 | git を呼ぶ前に、box のホームで展開する |
| 7 | rename の元のパスを捨て、新規ファイルとして表示する | 修正 | 元のパスを保持し、`-M` を付けて両方のパスを渡す |
| 8 | 最初の commit の前に staged したファイルの diff を取れない（HEAD が無い） | 修正 | `rev-parse --verify HEAD` で確かめ、HEAD が無ければ `--cached` で diff を取る |
| 9 | 8 MB を超える status や diff を、切り詰めたことを示さずに表示する | 修正 | 切り詰められた status は表示しない。切り詰められた diff は、その旨の行を末尾に付ける |
| 10 | python のパスに空白があると、引用していない systemd の unit が壊れる | 修正 | `ExecStart="…" "…"` |
| 11 | ファイル名を pathspec（`*.txt`）として解釈する | 修正 | `--literal-pathspecs` |

Codex は、`docs/HANDOVER.md` が分割読みと HTML・SVG を未実装と書いたままである点も指摘した。更新した。

確認したこと:
- HerdrKit のテスト（`testExecReportsTruncatedOutput` を追加）。
- 読み取りのスクリプトで、15 MB のファイルを 4,000,000 バイトずつ読み、元のファイルとバイト単位で一致すること。
- サービスのスクリプトの dry run。PATH に `&` と `<` を含めても plist の検証が通り、PATH がそのまま保たれる。
- 一時 repo での git の argv。rename は rename として表示され、`*.txt` は文字どおりに扱われ、最初の commit の前は `--cached` で表示され、サブフォルダからルートを取得できる。
- アプリと UI テストの実機向けのビルド。

修正後に simulator（Xcode 27.2）で確認したこと:
- `testFilesPreviewInQuickLook` で、15 MB の PNG（2400×2400）、HTML、SVG、Markdown、PDF が開いた。PNG は下端の赤い帯まで表示され、最後まで読めていた。
- `http://127.0.0.1:8765/…` を読み込む HTML を開いても、そのサーバへの要求は 0 件であった。同じ simulator の Safari からは 4 件届いたので、遮断が効いている。
- `testChangesShowDiff` で、追跡されていないファイルが一覧に出て、その diff が表示された。
