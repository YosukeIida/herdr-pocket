# Ovis・herdr・herdr-pocket の比較: スマートフォンから使う機能の対応範囲（2026-11-01）

この文書の目的: スマートフォンの client に要る機能のうち、herdr 本体も Ovis も現時点で満たしていないものを根拠付きで示し、herdr-pocket を作る理由を説明する。herdr と Ovis はどちらも OSS なので、以下の主張はすべてコード・文書・issue・計測のいずれかを根拠とする。

読んだ版: herdr-core `main@568a44d`（README 以外は v0.1.15 と同一）、herdr-app `main@07ba77e`、herdr TUI `main@ee5bfb5`、Ovis `origin/main@16bdda5`（リリース v0.4.21 は `6c78047f`）、devswha/ovis-terminal（`integration@1c21d63`）。herdr-pocket は `ccaaf96`。計測はこの Mac で、hc 0.1.15 と、`main` から `OVIS_RUNTIME=herdr-core` で起動した Ovis のサーバに対して行った。

## 用語

- **herdr TUI**（`herdr`）: コーディング agent 向けの元の端末マルチプレクサ。
- **herdr-core**（`hc`）: 画面を持たない、端末と agent の常駐サーバ。**Herdr app** はその desktop client である。TUI と herdr-core は agent を共有しない。
- **Ovis**: PC 上の Bun（TypeScript）のサーバで、Web の画面（PWA）を配信する。スマートフォンのアプリは、その画面を表示する WebView の殻である。
- **herdr-pocket**: この repo。herdr-core に SSH（`herdr-core connect`）でつなぐ、SwiftUI の native の iOS client。zzulanas/herdr-ios の fork である。

## 1. 2 つの見立ての検証

**「Ovis はブラウザで動かす前提」: 正しい。** Ovis の画面は PC 上の Bun のサーバ（`127.0.0.1:7317`）が配信する Web ページである。iOS アプリはそのページを表示する Capacitor 8 の WKWebView の殻である（`app/package.json:12-18`、`docs/native-app.md:20-22`）。Swift のコード（約 1,150 行）は、接続画面、PC の一覧、push、通知の拡張だけを持ち、SSH・Quick Look・端末のコードを含まない。PC のサーバが無いと、デモのセッションしか表示できない（`docs/native-app.md:39-40`）。Mac アプリも WKWebView の窓である（`app/mac/README.md`）。

**「Ovis は herdr-core を fork して実装中」: 誤り。**
- herdrdev/herdr-core の GitHub 上の fork 31 件に、Ovis の作者 devswha のものは無い。devswha は herdr-core に issue も PR も出していない。
- Ovis の `patches/` は npm パッケージ（xterm、legendapp list）の patch だけで、`crates/` は Ovis 自身の PTY host だけである。CI は公式の hc 0.1.14 を sha256 で固定して取得している（`.github/workflows/ci.yml:190-191,214`）。
- 実際にあるのは次の 2 つである。
  - (a) Ovis の中の **adapter**（`server/herdr-core/adapter.ts:11-34`）。herdr TUI の socket API を hc で代わりに応答し、Ovis の他の部分を変えずに動かす。
  - (b) **devswha/ovis-terminal**。MIT の別プロジェクトで、目的は「Ovis の下の herdr を置き換える。herdr の TUI の fork ではない」（`docs/design/ideal-state.md:3`）。README には「Status: scaffold … 動くコマンドは `ovis-terminal --version` だけ」とある。

## 2. herdr 本体がスマートフォン向けに提供するもの

herdr TUI、herdr-core、Herdr app はすべて Apache-2.0 で公開されている（herdrdev/herdr、herdrdev/herdr-core、herdrdev/herdr-app）。herdr.dev の FAQ には「herdr-core の上に自分のアプリを作れる」とある。

herdr が提供しないもの（括弧内は根拠）:
- 公式の iOS・Android の client と Web の画面。TUI の文書は「モバイルアプリや Web のダッシュボード無しで、任意の SSH アプリから使える」と書く（`how-to-work.mdx:49-58`）。herdr.dev/core は「スマートフォンのアプリ」を自作の client の例として挙げるだけである。
- ネットワークの待ち受け。herdr-core は Unix socket でだけ待ち受け、遠隔からは `ssh box hc connect` で使う（`schema/README.md:23-26`、`docs/security.md:20-24`）。
- push 通知。core には APNs・webhook・relay が無い。desktop の app も、アプリ内の toast しか持たない（herdr-app#120、open）。
- バイナリのファイルの読み取り。`file.read` はテキスト専用で上限 8 MB である（`hc.openrpc.json:2962`、エラー `not_text`）。バイナリは `machine.exec` の stdout（base64、先頭 8 MB、既定のタイムアウト 60 秒、spec:161）を通すしかない。
- transcript（会話）を読む API と、端末ごとのセッション ID（該当するメソッドが無い。herdr-core#15 は open）。状態は、プログラムが OSC 7501 で自己申告したものだけである（README:186-189）。
- スペース・タブの構成を外部から読むための、保証された仕様。構成は Herdr app 独自の `herdr-app` 文書にある（herdr-app#43、open、メンテナの返答なし）。

## 3. herdr-core に対する Ovis の現状

- **未リリース。** herdr-core のランタイム（`server/herdr-core/`）は v0.4.21 に無い（`git ls-tree v0.4.21 server/herdr-core/` が空）。7 本の PR（#2442〜#2456）はそのタグより後の 2026-10-30 に merge された。リリースの PR #2473（0.4.22）は open で、「まだ merge しない」とされている。
- **インストーラが対応していない。** install.sh、Ovis.dmg、herdr plugin はいずれも herdr TUI を入れ、Ovis をその plugin として動かす（`install.sh:385,450`、`README.md:48`）。どれも `OVIS_RUNTIME` や hc に触れていない。現時点の唯一の方法は、`main` を取得して `bun install` し、`OVIS_RUNTIME=herdr-core bun run start` で起動することである（Bun 1.4 以上が必要）。
- **このモードで使えない機能:** ワークスペース・タブ・ペインの名前の変更、移動、分割、zoom、resize、入れ替え。worktree。plugin。検索とスクロールバックの選択。hc の machines を使った遠隔の機体（`docs/guide.md:708-710`、PR #2451、issue #2497 は open）。
- **計測: Claude Code の会話は端末の文字列になる。** この Mac で `GET /api/pane/conversation?pane_id=t17`（Claude Code の端末）は `{"source":"scrollback","turns":[]}` を返した。t14 も同じであった。コードから推定される原因は次のとおりである。hc は `status.app = "claude-code"` を返し、adapter はそれをそのまま渡す（`server/herdr-core/snapshot.ts:72-74`）。一方、Ovis の Claude の会話とダイアログの読み取りは `"claude"` を鍵にしている（`conversation.ts:1084,1505`、`dialogs/claude.ts:1037-1095`）。
- **agent が選択待ち（blocked）の間は、prompt の送信が拒否される。** adapter が `terminal.send` を使うためである（`adapter.ts:24,403`）。
- **`machine.*` と `file.*` を呼ばない。** ファイルと diff は、Ovis のサーバが PC 自身のディスクから読む（`FileViewer.tsx`、ファイルの route）。

## 4. 比較表

○＝動く、△＝一部・条件付き、×＝無い。「Ovis/core」は Ovis の `main` を `OVIS_RUNTIME=herdr-core` で動かした場合（未リリース）。herdr-pocket は、注記が無いものは iOS simulator で確認した。

| 要件 | herdr（公式） | Ovis/TUI | Ovis/core | herdr-pocket |
|---|---|---|---|---|
| スマートフォンの画面 | ×（任意の SSH アプリで TUI） | Web・WebView | Web・WebView | native の SwiftUI |
| herdr-core（Herdr app の agent）に対応 | — | × | △ 未リリース、ソースからのみ | ○ |
| PC 上の常駐プロセス | — | Bun のサーバ（＋herdr TUI） | Bun のサーバ | チャット・ファイル・端末には不要。push には通知用のプロセスが要る |
| PC のネットワークへの露出 | SSH | HTTP・WebSocket（Tailscale serve、トンネルなど）＋ペアリング | 同左 | SSH のみ |
| 第三者がホストするサービス | 無し | push relay `push.ovis.sh`。テレメトリの Worker（通知を表示した後、既定で有効） | 同左 | 無し（PC が APNs へ直接送る） |
| transcript からの Claude Code の会話 | × | ○ | × 計測: 端末の文字列 | ○ |
| Codex の会話 | × | ○ | △ 未確認 | ○ |
| 他の agent（OpenCode、pi、omp など）の会話 | × | ○ | △ | ×（端末のみ） |
| 選択待ちのダイアログにボタンで回答 | × | ○ | △（上記のとおり Claude 用の読み取りが使われない） | ○ Claude Code で確認済み。Codex は未テスト |
| prompt の送信 | （TUI で入力） | ○ | △ 選択待ちの間は拒否 | ○ |
| agent の一覧と状態 | ○ TUI 上 | ○ | △ OSC 7501 を出すものだけ | ○（OSC 7501 をイベントで受信） |
| アプリを閉じている間の push 通知 | × | ○ Web Push、relay 経由の APNs | △ | △ 有料の Apple Developer アカウント、APNs の鍵、PC 上の通知プロセスが要る（macOS は nohup で、launchd は未対応） |
| 端末の表示 | ○ | ○ xterm.js | ○ | ○ SwiftTerm |
| PDF・画像（HEIC を含む）のプレビュー | × | ○（PDF は iframe） | ○ | ○ Quick Look |
| docx・xlsx・pptx のプレビュー | × | ×「ここではプレビューできない」（`FileViewer.tsx:444`） | × | ○ Quick Look |
| Markdown の整形表示 | × | ○ | ○ | ○ |
| 8 MiB を超えるファイル | — | ○ | ○ | × 未対応 |
| git の diff | × | ○ | ○ | × |
| agent の起動 | ○ | ○ | △ 空いた shell に入力する方式 | ○ |
| 構成の編集（分割、名前の変更など） | ○ TUI・app 上 | ○ | × | ×（構成は読むだけ） |
| 複数の機体 | ○ | ○ SSH bridge | △ TUI の機体のみ | ○ 機体の保存（1 台のみテスト） |
| リリース済みで導入できる | ○ | ○ v0.4.21。iOS アプリは審査中、TestFlight は「近日公開」 | × | ×（ソースからビルド。TestFlight は未公開） |

## 5. 共通する点

- どちらも、herdr が保証していない仕様に依存している。`herdr-app` の構成の文書（herdr-app#43）と、セッション ID が無いこと（herdr-core#15）である。端末と transcript の対応付けは、どちらも推定による（Ovis: hook の報告かプロセス。herdr-pocket: プロセスの木と `~/.claude/sessions`。Codex は開いているファイル、または状態の DB をタイトルとフォルダで照合）。
- どちらも agent の状態を OSC 7501 からだけ取る。報告しないプログラムは状態が表示されない。
- どちらも、PC には利用者自身のネットワーク（Tailscale など）を通じて到達する。

## 6. herdr-pocket だけが満たすもの

1. **herdr-core** に対する native の iOS client で、チャット・ファイル・端末に **PC 上のサーバを要さない**。`herdr-core connect` への SSH の exec channel が 1 本あるだけで、sshd 以外を公開せず、第三者がホストする relay もテレメトリも無い。herdr にはスマートフォンの client が無く、Ovis は Bun のサーバを要し、herdr-core のモードは未リリースである。
2. herdr-core 上の **Claude Code と Codex の会話を transcript から読む**。ダイアログのボタンは `terminal.keys` で回答するため、選択待ちの間も動く。herdr-core 上の Ovis は、Claude Code の会話を端末の文字列として表示する（計測済み）。
3. **Office（docx・xlsx・pptx）をスマートフォンでプレビューする。** herdr-core の `file.read` はテキスト専用なので、`machine.exec` でバイトを読み、Quick Look で表示する。Ovis はどのモードでも、これらを「ここではプレビューできない」と表示する。
4. ログイン前の host key の承認と、鍵の Keychain への保存（herdr-pocket で加えた修正。Ovis はペアリングコードと cookie で認証する）。

## 7. herdr-pocket が劣る点

- 会話を読めるのは Claude Code と Codex だけである。Ovis は約 15 種の agent を読む。
- diff と構成の編集が無い。8 MiB を超えるファイルはプレビューできない。HTML と SVG は小さく表示される。
- push には、PC 上の常駐の通知プロセスと、有料の Apple Developer アカウントが要る。macOS では nohup で動かしており、launchd には未対応である。
- チャットとファイルには、PC に python3 が要る。
- iPhone の実機では未確認で、配布もしていない。

## 8. 配布の費用（TestFlight）

- TestFlight の利用は、テスターには無料である（無料の TestFlight アプリで入れる）。ただし、ビルドを上げるには **Apple Developer Program（年 99 米ドル）** が要る。「TestFlightでのテスターの招待や、ベータ版ビルドの管理」は有料メンバーシップの項目である（https://developer.apple.com/jp/programs/）。円建ての金額は登録手続きの画面で表示される（「価格は地域によって異なる場合があり、登録手続きの際は現地通貨で表示されます」、https://developer.apple.com/jp/programs/enroll/）。正確な円の金額は確認できていない。
- 各ビルドは、アップロードから **90 日間** テストできる（「Your build becomes unavailable for testers after 90 days.」）。新しいビルドを上げれば、そのビルドの 90 日が始まる。ビルドごとの追加料金は無い。内部テスターは最大 100 人、外部テスターは最大 10,000 人である。外部テスターに配るには、最初のビルドについて Beta App Review が要る（https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview）。
- 年会費の免除は、非営利団体、認定教育機関、政府機関に限られ、個人は対象外である（https://developer.apple.com/support/membership-fee-waiver/）。大学（研究室）は機関として対象になりうるが、個人では申請できない。
- 有料の登録が無くても、無料の Apple Account で Xcode から自分の端末に入れられる。ただし、profile は 7 日で切れる（端末 3 台、App ID 10 個まで。https://developer.apple.com/support/compare-memberships/）。herdr-pocket の push 通知には APNs の鍵が要り、その鍵の発行には有料の登録が要る（README の「Notifications」）。

## 未確認の点

- herdr-core 上の Ovis での、Codex の会話とダイアログのカード（計測の時点で Codex の端末が無かった）。
- Ovis の iOS アプリが審査を通るか、実機で push が届くか。
- 登録時の Apple Developer Program の円建ての金額。
- herdr-core 上の Ovis の、会話以外の機能はコードから読んだもので、動かしてはいない。

## Ovis の文書とコードの食い違い

- `README.md:71` と `docs/guide.md:916` は「自前のホストされた relay は無い」と書く。実際には `push.ovis.sh` がホストされた push relay であり、`relay.ovis.sh` も追加中である。
- `docs/guide.md:708-709` は、herdr-core ではワークスペース・タブ・ペインを作れないと書く。実際には `adapter.ts:406-448` が実装している。
- `docs/guide.md:702` は `error` を完了として扱うと書く。実際には `snapshot.ts:54-67` が unknown に変換している。
- `README.md:52` は ovis.sh/beta に TestFlight のベータがあると書く。そのページでは、リンクは「近日公開」とされている。
