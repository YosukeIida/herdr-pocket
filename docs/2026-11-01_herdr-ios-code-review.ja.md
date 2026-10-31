# zzulanas/herdr-ios のコードの品質の確認

この文書は `2026-11-01_herdr-ios-code-review.md` の日本語訳である。内容が食い違うときは英語版に従う。

2026-11-01 に、commit `a030501`（2026-10-30）を確かめた。

確かめ方は 2 つである。

- HerdrKit の単体テストを実行した（Swift 6.4、macOS）。33 件がすべて通った。
- 別の agent にコードを読ませ、所見を集めた。重大度が高い 2 件は、原文で確かめた。

ビルドと実機での動作は確かめていない。

## 結論

土台にしてよい。ただし、使い始める前に、重大度が高い 2 件と依存の版の固定を直す必要がある。

- HerdrKit（framing、JSON-RPC、イベント、Layout の文書）は作りが堅く、テストで守られている。
- 問題は App 層に集まっており、どれも局所的に直せる。

## 規模と構成

| 部分 | 中身 |
|---|---|
| `Packages/HerdrKit` | protocol と model（SwiftPM、外部の依存なし、テスト 33 件）、`herdr-probe`（macOS の CLI） |
| `App/Sources` | Net（Citadel の SSH、Keychain、host key）、Store（`AppStore`）、UI、Chat、Mods（JavaScriptCore の mod host）、Notify |
| 外部の依存 | Citadel `from: 0.12.1`、SwiftTerm `exactVersion: 1.20.0` |
| 規模 | Swift で約 11,500 行 |

## 所見

| 重大度 | 箇所 | 内容 | 直し方 |
|---|---|---|---|
| 高（原文で確認） | `App/Sources/Chat/ChatView.swift:46`、`ChatModel.swift:91-97` | `title` が変わるたびに `model.nudge()` を呼ぶ。`title` は作業中に 0.1 秒ごとに変わるので、Chat を開いている間、Mac 側で transcript を読む python がほぼ切れ目なく起動される。前の待機の sleep が終わったとき、次の待機まで解いてしまう競合もある | `title` での nudge を外し、`status` と `turn` だけにする。sleep する Task をトークンで区別する |
| 高（原文で確認） | `App/Sources/Net/HostKeys.swift:58-60` | 初回の接続で host key を確認なしに固定し、fingerprint は固定した後にしか見せない。初回に中間者攻撃を受けると、password 認証では password がそのまま渡る。保存先は Keychain ではなく UserDefaults である | 初回は fingerprint を見せて承認させる。保存先を Keychain にする |
| 中 | `AppStore.swift:138-143, 486-508` | バックグラウンドに入ってから 8 秒で接続を閉じる。復帰のときは、SSH、hello、subscribe、docGet を順に待つ。最後の画面はメモリにしか残らず、プロセスが終わると接続画面から始まる | subscribe と docGet を並べて待つ。snapshot をディスクに保存し、復帰したらすぐ表示する |
| 中 | `EventLines.swift:131` → `AppStore.swift:629-642` | `title` の通知のたびに端末の一覧全体を置き換え、全画面が再評価される | `title` だけの更新は別の経路にするか、間引く |
| 中 | `HerdrClient.swift:28-29` | `requiredMethods` に、使っている `terminal.read/send/keys/interrupt` と `server.status` が入っていない | 配列に足す |
| 中 | `project.yml:14-19` | Citadel の版が固定されておらず、`Package.resolved` も gitignore されている。`__pycache__/*.pyc` が追跡され、アプリに同梱される | `exactVersion` にし、resolved を commit する。pyc を消す |
| 中 | `Package.swift`、`project.yml` | Swift の language mode が v5 で、手書きの lock に頼っている。lock の外で読む箇所がある（`HerdrClient.swift:113` と `221`） | まず HerdrKit を v6 へ移す |
| 中（仕様） | `Mods/ModHub.swift:310, 325` | mod が指定したコマンドを、そのまま Mac 側で `machine.exec` に渡す。信頼の範囲は Herdr app と同じである | 自分で書いた mod だけを同梱する運用にする |
| 低 | `herdr-notify.py:87, 91`、`Push.swift:78` | APNs の JWT を curl の引数に載せている（`ps` で見える）。device token を検証していない。devices のファイルを umask 077 で作っていない | JWT は標準入力で渡す。token の形式を確かめる。umask 077 で作る |
| 低 | `herdr-notify.py:184-191` | blocked から error に変わると「finished」を送る。アプリ側の判定と違う | 判定を `AttentionTracker` にそろえる |
| 低 | App 全体 | App 側に unit test が無い | `ChatModel.rebuild`（純粋関数）から test を書く |

shell injection の余地は、確認した範囲では無かった。`sh -c` に渡す値は、すべて位置引数で渡しており、session ID は正規表現で形式を固定している。Layout の文書は、未知のフィールドを保ったまま編集し、version の競合は比較して交換する方式（CAS）で扱っている。

## 足す機能の差し込み位置

- **Codex のチャット**: Mac 側の script は、種類を表す共通の形式（user・text・tool・result）で出力し、Swift 側はそれを畳むだけである。Claude Code への依存は `AgentScreen.swift:13` と `ChatModel.swift:107` の 2 箇所だけである。rollout を同じ形式で出力する script を足し、program で選ぶ。
- **ファイルツリーとプレビュー**: 入口は `SpaceView.swift:73` の toolbar に置き、基準のフォルダは `SpaceRef.folder` にする。一覧は `store.exec`（`AppStore.swift:417`）で取る。本体は `cat --` で base64 として受け取り、一時ファイルに書いて `QLPreviewController` に渡す。1 回の受け取りの上限は約 12 MiB で（frame の上限 16 MiB から base64 の増加分を引いた値）、これを超えるファイルは分割して読む。
- **launchd の notifier**: `NotificationSettings.swift:180-205` と `scripts/install-notifier.sh` で、macOS のときは `~/Library/LaunchAgents` に plist を置いて `launchctl bootstrap` する。`herdr-notify.py:21` の `hc` の探索先に、Homebrew と nix の場所を足す。

## 文書とコードの食い違い

- コードのコメントが `SPEC.md` を参照しているが、`SPEC.md` は repo に無い。
- README は「mod の exec は Mac 側で動く」と書いているが、`open` と pbcopy はスマホの側で処理している。
- README は notifier を systemd 用とだけ書いているが、コードには nohup で起動する代わりの経路がある。

## ビルドの前に読むもの

ビルドすると、次の 2 つが sandbox なしで実行される。ビルドの前に中身を読む必要がある。

- pre-build の `bundle-mods.sh`（`ENABLE_USER_SCRIPT_SANDBOXING: NO`）
- SwiftTerm の build plugin
