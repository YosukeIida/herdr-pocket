# 既存アプリの調査と Orca Mobile の機能の棚卸し

この文書は `2026-11-01_existing-apps-and-orca-mobile-survey.md` の日本語訳である。内容が食い違うときは英語版に従う。

2026-11-01 に調べた。調査は 2 つに分けて行った。

1. 既存のアプリの調査: 公開情報と GitHub を調べた。
2. Orca Mobile の機能の棚卸し: stablyai/orca の main ブランチの docs・コード・issue を読んだ。

各アプリの実機での動作は確かめていない。

## 要件

1. Claude Code と Codex の本物の CLI セッション（CLAUDE.md・hooks・skills が効くもの）を、スマホのチャットの画面で読み、送れる。
2. space ごとのファイルツリーを見て、remote の機体のファイル（PDF・docx・xlsx・png・HTML・md）をプレビューできる。
3. 全 space の agent の状態（working・blocked・done）を一覧でき、通知を受け取れる。
4. 環境を 1 つにまとめる。PC の Herdr app と同じ herdr-core を見る構成にし、常駐のプロセスや第三者の relay を足さない。

## 結論

要件 1〜4 をすべて満たす既存のアプリは無い。自作する。

- 常駐のプロセスを置かずに SSH で直接つなぐ iOS アプリは、HerdrChat・Melta・Heeler などがある。いずれも Herdr TUI を前提にしており、herdr-core には対応していない。Heeler は herdr-core への対応が issue #541 と PR #538（open）の段階で、まだリリースされていない。
- herdr-core に対応しているのは Ovis・Collie・Shepherdr だけである。3 つとも Mac に Bun のサーバを常駐させる Web アプリ（PWA）で、要件 4 を満たさない。最も近い Ovis も、herdr-core への対応は未リリースであり（issue #2439 は 10/31 に close、v0.4.21 には未収録）、docx・xlsx をプレビューできない。
- herdr の公式に、iOS client を出す予定は見当たらない（herdr.dev、herdr-app の issue、herdr-core の README を確認した。Discord は確認していない）。Google Play の「Herdr Mobile」は公式ではない（開発者は北京野核桃科技有限公司）。

## 既存のアプリの比較

○ は満たす、△ は一部を満たす、× は満たさないことを表す。

| アプリ | 1 チャット | 2 プレビュー | 3 状態・通知 | 4 herdr-core・構成 |
|---|---|---|---|---|
| HerdrChat（iOS、Apache-2.0） | ○ | × | ○ | ×（TUI 前提） |
| Heeler（iOS、Apache-2.0） | ○ | ×（SFTP での添付だけ） | ○ | △（herdr-core 対応は未リリース） |
| Melta | ○ | × | ○（push は Melta のサーバを経由する） | ×（TUI 前提） |
| Moshi | △（Chat View は Pro 限定） | △（画像・動画・PDF） | ○ | ×（TUI 前提で、moshi-hook が要る） |
| Shahi | ○ | △（テキスト・画像・PDF） | ○ | ×（TUI の plugin） |
| Ovis（PWA、MIT） | ○ | △（Office は無い） | ○（web push） | △（未リリース。サーバの常駐が要る） |
| Collie（PWA、MIT） | △ | △（読み取り専用） | ○ | △（experimental。サーバの常駐が要る） |
| Secure ShellFish | × | ○（ファイル App の Quick Look） | × | ○（SSH だけ） |
| Orca Mobile | ○ | △（docx・xlsx が無い） | ○ | ×（Orca のサーバ） |

このほか、HerdrGo、Drover、carsol/herdr-mobile、herdrup、Herdi、Corral は、いずれも Herdr TUI を前提にしている。

## Orca Mobile から残す機能と省く機能

| 判定 | 機能 | herdr-core での実現方法 |
|---|---|---|
| 残す（最初の版） | 全 agent の状態の一覧 | `terminal.list`、`events.subscribe`（扱うのは `status` と `turn` だけ） |
| 残す（最初の版） | チャット（transcript の表示、返信） | transcript を読む。送るのは `terminal.send` |
| 残す（最初の版） | ファイルツリーとプレビュー（**docx・xlsx を足す**） | `machine.exec`（ls・cat を base64 で返す）。表示は QLPreviewController と WKWebView |
| 残す（最初の版） | 接続先の編集 | アプリの設定 |
| 残す | 端末の表示（補助キー付き） | `terminal.attach`、`terminal.keys` |
| 残す | 通知 | 方式は下の「決める点」で選ぶ |
| 後で | Quick Commands、Source Control、新しい workspace の作成、過去のセッションの再開、診断の画面、写真の添付、音声入力 | `machine.exec`（git・gh）、`terminal.run` |
| 省く | Tasks・Automations（herdr-core に対応する API が無い）、ブラウザ、アカウントの切り替え（`cx` で代える）、tab の一括操作 | — |

### Orca Mobile の弱点から避けること

- issue で最も多い不満は、バックグラウンドから戻ったときに再接続が遅いことである（#13354 ほか）。フォアグラウンドに戻った時点ですぐ再接続し、最後の画面をキャッシュして先に表示する。
- headless で動かしたとき、チャットが「Can't find this conversation yet」になる（#32134 ほか）。端末と transcript の対応は、推測ではなく確実な方法で引く（下の「端末と transcript の対応」）。
- 画面のちらつき、重さ、起動のたびに web bundle を取り直す問題がある。Orca Mobile は WebView 中心の作りと推測される。herdr-pocket は SwiftUI で書く。
- 接続のプロトコルの版を最初に交換し、組み合わせが合わなければ接続を止める（Orca の `status.get` と同じ考え方）。herdr-core では `hello` の `generation` と `version` が使える。

## 端末と transcript の対応（調査の報告の訂正）

既存のアプリの調査の報告には「herdr-core は agent のセッション ID を持たないので、hooks を足すか、cwd から推測する必要がある」とあった。しかし、検証（`2026-11-01_herdr-core-mobile-client-spike.md`）では、hooks を足さずに一意に引けた。

- Claude Code: 端末の `foreground.pid` から `~/.claude/sessions/<pid>.json` を読むと `sessionId` がある。
- Codex: 前面のプロセスの子プロセスが開いている rollout のファイルを、`lsof` で特定する。最初の入力を送るまでは、rollout のファイルが無い。

どちらも `machine.exec` で Mac Studio 側で実行できる。

## 流用を検討できる OSS

- **Heeler**（Swift、Apache-2.0）: SSH の通信、libghostty による端末の表示、チャットの表示を持つ。PR #538 には herdr-core への対応のコードがある。構成が最も近い。
- **HerdrChat**（React Native、Apache-2.0）: Claude と Codex の transcript の解析が参考になる。
- **Ovis**（TypeScript、MIT）: herdr-core の adapter とファイルビューアがある。
- **Collie**（MIT）: `docs/multiplexers.md` の herdr-core の節に、herdr-core の制約が実測で整理されている。

## 追加の調査: Heeler より土台に向くもの

GitHub の検索（`herdr ios`、`herdr mobile`、`herdr-core`）と Exa で探し直した。土台の候補として、Heeler と zzulanas/herdr-ios を比べる。

| 観点 | Heeler（ZingerLittleBee/Heeler） | zzulanas/herdr-ios |
|---|---|---|
| 成熟度 | 715 stars、App Store で配布中、2026-07 から開発 | 1 star、2026-10-30 に公開（3 commit）、作者は 1 人 |
| herdr-core | 未対応（外部からの PR #538 が open。+5281 行） | **最初から herdr-core 専用**。SSH の exec channel で `herdr-core connect` を動かす（この検証と同じ方式） |
| space・tab | herdr TUI の構成 | Herdr app の `herdr-app` の文書を読み書きする。PC とスマホで同じ構成になる |
| チャット | Claude Code、Codex、Pi など 6 種類 | Claude Code だけ。`~/.claude/sessions` から特定する（この検証と同じ方式） |
| ファイルのプレビュー | 無い（SFTP で添付するだけ） | 無い |
| 通知 | 自前の relay を経由する（E2E で暗号化）。Live Activity あり | **Mac 側の自分の機体から APNs へ直接送る**（relay なし）。ただし notifier は systemd 用で、macOS の launchd 用は無い |
| Herdr app の mod | — | **自分の mod がスマホでも動く**（JavaScriptCore で herdr・gpui-kit の API を実装し、SwiftUI で描く。`exec` は Mac 側で動く） |
| 規模・構成 | Swift のコードが多く、relay・plugin・docs-site を含む | Swift のファイルが 49 個。`HerdrKit`（protocol と model、SwiftPM、テストあり）と `App`（Citadel の SSH、SwiftTerm）に分かれる |
| license | Apache-2.0 | Apache-2.0 |
| 動く環境 | iOS 18 以上 | **iOS 26 以上**、Xcode 26.2 以上 |

このほかに見つかった herdr 向けの client は、次のとおりである。

- 常駐のプロセス（gateway・daemon）を置く: BrianBal/herdr-ios（Bun の gateway）、monotykamary/reflex
- Herdr TUI 前提: lucasscariot/herdie、Volpestyle/herdr-ios
- ServerCC（App Store、ソース非公開）: herdr は 0.8（TUI）向けの統合で、herdr-core には触れていない。ファイルのプレビューは md・画像・PDF まで

### 推奨

土台は **zzulanas/herdr-ios の fork** を推奨する。理由は 3 つある。

1. 設計が要件 4 と一致している。herdr-core に SSH で直接つなぎ、relay を使わず、通知も自分の機体から送る。
2. Herdr app の mod がスマホでも動く。PC の UI をスマホに持っていけるので、「native app だから UI を作り込める」という狙いに合う。
3. 規模が小さく、構成が分かれていて読める。

足りないのは、次の 3 つである。どれも検証で方式を確かめたもので、足すのは難しくない見込みである。

- Codex のチャット（`lsof` で rollout を特定する）
- ファイルツリーとプレビュー（`machine.exec` で取り出し、Quick Look で表示する）
- macOS 用の notifier（launchd で常駐させる）

リスクは 3 つある。

- 公開から 2 日の、作者 1 人の repo である。upstream が止まっても自分で保守できる前提で fork する。
- iOS 26 以上が必要である。
- コードの中身はまだ読んでいない。fork する前に `HerdrKit` と `Chat` を読み、品質を確かめる必要がある。

## 決める点

1. **作り方**: Heeler を fork して herdr-core への対応を足すか、SwiftUI で最初から書くか。
2. **通知**: アプリを閉じている間も通知を受けるには、APNs に送る仕組みが要る。次のどれかを選ぶ。
   - Mac Studio で `hc events` を購読し、APNs に送るスクリプトを launchd で常駐させる（Apple Developer の有料の登録が要る）。
   - ntfy などの中継を使う。
   - 最初の版では、アプリを開いている間だけ状態を見る。
3. **配布**: 自分の端末だけに入れるか（無料の provisioning は 7 日で切れる）、TestFlight で配るか。
