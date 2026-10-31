# 判定: Codex のチャット、Markdown のプレビュー、ダイアログの解析のレビュー（2026-11-01）

対象の commit: 1f37e96、eb6790d。レビューの原文: `2026-11-01-codex-chat-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。

| # | 指摘 | 判定 | 理由と変更 |
|---|---|---|---|
| 1 | 子孫のプロセスの rollout のうち最新のものを選ぶため、agent が実行した入れ子の `codex exec` が会話を置き換えうる | 修正 | `session_meta.source` が `exec` の rollout を除外した。既存の `thread_source == 'user'` の絞り込み（guardian と subagent のスレッドを除く）と並べて置いた。この Mac の rollout で値を確認した: `cli` と `vscode` が対話、`exec` が `codex exec` である。端末のプロセスからの距離で順位を付ける方式は採らなかった。source の値が原因を直接示すためである |
| 2 | 画面上の番号付きの一覧がダイアログのボタンになり、タップで数字が agent に送られうる | 修正 | `BlockedCard.parse` は、選択肢の行のどれかにメニューのカーソル（`❯` または `›`）がなければ nil を返す |
| 3 | 数え下げが 1 の前で止まると（説明の行が長いとき）、一部の選択肢だけを表示する | 修正 | 一覧が選択肢 1 まで届かなければ nil を返す。カードは端末で答えるよう案内する |
| 4 | 読み取りの範囲（16 MiB）より長い JSONL のレコードを無限に読み直す | 修正 | 範囲が満杯で改行を含まないとき、`next` をその先へ進める。レコードの残りは壊れた行になり、`json.loads` が読み飛ばす。両方の transcript のスクリプトに入れた |

修正後に simulator で確認した: `testBlockedDialogButtons`（説明の行が付いた AskUserQuestion で待つ Claude Code。Amber をタップすると回答され、agent は AMBER と返した）、Codex の端末での `testChatSendGetsReply` と `testChatRendersAndFolds`、`testFilesPreviewInQuickLook`（md、pdf、heic、png）。
