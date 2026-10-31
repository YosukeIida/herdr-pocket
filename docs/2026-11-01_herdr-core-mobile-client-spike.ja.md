# herdr-core の API でスマホ用のネイティブアプリを作れるかの検証

この文書は `2026-11-01_herdr-core-mobile-client-spike.md` の日本語訳である。内容が食い違うときは英語版に従う。

2026-11-01、Mac Studio（herdr-core 0.1.15、Claude Code 2.1.316）で実施した。

## 目的

PC では Herdr app の端末で agent を操作し、スマホでは自作の iOS アプリでチャットとファイルのプレビューを使う構成が、herdr-core の API だけで作れるかを確かめる。確かめる点は次の 3 つである。

1. space・tab・agent の状態を API で取れるか
2. 端末と agent の transcript を結び付けられるか
3. スマホでプレビューするファイル（PDF・docx・xlsx を含む）を API で取り出せるか

## 結果

| 確かめた点 | 結果 | 使う API |
|---|---|---|
| 接続 | stdin・stdout の改行区切りの JSON-RPC で話せる。`hello` は generation 1、version 0.1.15 を返す | `hc connect` |
| space と tab の構成 | Herdr app の構成（space・tab・分割・各 block の端末）を JSON で取れる | `doc.get {name: "herdr-app"}` |
| agent の状態 | 端末ごとに `status: {app: "claude-code", state: "working", msg: …}`・`title`・`foreground`（前面のプロセスの argv・cwd・pid）・ラベル `herdr.space`・`herdr.tab` を取れる | `terminal.list`・`terminal.get` |
| 状態の変化の通知 | 購読の直後に全端末の snapshot が届き、その後は端末の起動・終了・ラベルの変化が `event` の通知で順に届く | `events.subscribe` |
| 端末への入力 | 文を貼り付けて Enter を押せる | `terminal.send` |
| Claude Code の transcript の特定 | 一意に結び付く。端末の `foreground.pid` から `~/.claude/sessions/<pid>.json` を読むと `sessionId` と `cwd` がある。transcript は `~/.claude/projects/<cwd を変換した名前>/<sessionId>.jsonl` である。端末の `title` も transcript の `aiTitle` と一致した | `terminal.get` と `file.read` |
| テキストのファイル | 読める（AGENTS.md で 3 ms） | `file.read` |
| PDF・docx・xlsx | `file.read` は `not_text` で拒否し、「for bytes: hc exec cat」と案内する。`machine.exec {argv: ["cat", path]}` で base64 として取り出すと、PDF 3.4 MB が 18 ms、docx・xlsx が 5 ms 前後で、元のファイルと SHA-256 が一致した | `machine.exec` |

## SSH を経由した接続

MacBook Air（hostname: Yosukes-MacBook-Air）の Claude Code のセッションに依頼し、`ssh mac-studio hc connect` で 5 つのメソッドを試した。5 つとも成功した。非対話の SSH で PATH が足りない問題は起きなかった。

| メソッド | 所要時間 | 結果 |
|---|---|---|
| `hello` | 403 ms（SSH の接続の確立を含む） | core.name は yosukes-mac-studio |
| `terminal.list` | 7 ms | 端末の一覧を返した |
| `doc.get {name:"herdr-app"}` | 5 ms | space と tab を返した |
| `file.read`（AGENTS.md、3 行） | 5 ms | 返した |
| `machine.exec`（PDF 3.4 MB を `cat`） | 445 ms | 3394636 bytes で元のファイルと一致し、`truncated` は false |

Mac Studio の中で直接使った結果と比べると、増えたのは接続の確立の約 0.4 秒と、PDF の転送の約 0.4 秒だけである。

## Codex の transcript の特定と、状態の変化の通知

`cx labteam` に切り替えてから、Codex 0.166.0 を herdr-core の端末（t16）で起動した。「1+1 の答えだけを返して」を `terminal.send` で送り、その間 `events.subscribe` の通知を記録した。

- **transcript の特定**: 端末の `foreground.pid` は Codex のランチャー（65546）で、その子プロセス（65577）が rollout のファイルを開いていた。`lsof -p <子の pid>` で `~/.codex/sessions/2026/11/01/rollout-…-01a192fa-….jsonl` を一意に特定できた。ただし、rollout のファイルは最初の入力を送るまで作られない。起動した直後の、まだ何も送っていない Codex は特定できない。
- **状態の変化**: Codex も OSC 7501 で状態を報告する。`status` の通知で、idle → working → done の変化を順に受け取った。終わった時点で `turn` の通知（`state: "done"`）と、`title` の変化（「計算して 1+1 | dotfiles-private」）も届いた。
- **通知の量**: 作業中は、`title` がスピナーの 1 コマごとに変わり、0.1 秒ほどの間隔で通知が届く。100 件あまりの通知の大半がこれであった。スマホのアプリでは、`title` の通知を間引くか、`status` と `turn` だけを購読の対象として扱う必要がある。
- **送った文の見え方**: `terminal.send` で送った文は、Codex の画面では `<hc from="t14">…</hc>` に包まれて表示された。送り手の端末が分かる形で入る。スマホのアプリから送る場合の見え方は、送り手を持たない接続で確かめる必要がある。
- **space への配置**: 子として起動した端末は、親（t14）の space に `codexspike` という tab として自動で入った。

検証の後、t16 は終了して削除した。

## 確かめていないこと

- **iOS の SSH のライブラリで `hc connect` の stdio を保てるか。**
- 送ったバイナリの大きさの上限。`machine.exec` の出力は `truncated` を返す。どの大きさで打ち切られるかは確かめていない。

## 補足

- 検証のため、ararat の space の zsh（t10）に `echo spike-from-hc-send` を 1 回送った。
- 検証のために起動した端末（t15、`sleep 1`）は削除した。終了したとき、core は親の端末（この会話の t14）の入力欄に「t15 spike exited (exit 0)」と知らせた。子の終了の通知が親に届くことも、あわせて確かめられた。
