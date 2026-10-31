# herdr-pocket

この文書は `AGENTS.md` の日本語訳である。agent が読むのは英語版で、内容が食い違うときは英語版に従う。

herdr-core の iPhone・iPad 用のネイティブ client。Claude Code と Codex のセッションをチャットとして読み、返信し、remote の機体のファイルをプレビューし、全 agent の状態を見る。PC では同じ herdr-core を Herdr app で使う。アプリが herdr-core と話す経路は SSH だけで（exec channel で `herdr-core connect` を動かす）、常駐のサーバや第三者の relay は置かない。`zzulanas/herdr-ios`（`upstream`）の fork で、`origin` は `YosukeIida/herdr-pocket`。この土台を選んだ理由と足りないものは `docs/2026-11-01_existing-apps-and-orca-mobile-survey.md` と `docs/2026-11-01_herdr-ios-code-review.md` にある。

## 構成

- `Packages/HerdrKit`: protocol と model（SwiftPM、外部の依存なし、単体テストあり）。テストはそのディレクトリで `swift test`。
- `App/Sources`: iOS アプリ（SwiftUI）。Net（Citadel の SSH、Keychain）、Store（`AppStore`）、UI、Chat、Mods（JavaScriptCore）、Notify。
- `project.yml`: XcodeGen の定義。`Herdr.xcodeproj` は生成物（`xcodegen generate`）で、追跡しない。
- iOS 26 以上が必要。開発は Mac の iOS simulator で行い、simulator からは Mac 自身の sshd に `127.0.0.1` でつなぐ。

## 言語

repo の中のファイル（README、AGENTS.md、`docs/` の下すべて、コードのコメント、commit message）は、ファイルに別の指定がない限り英語で書く。正本は英語のファイルである。Markdown の文書には、日本語訳を `<名前>.ja.md` として隣に置き（`AGENTS.ja.md`、`docs/<名前>.ja.md`）、英語版と同じ変更で更新する。毎セッション上書きする作業用のメモ（`docs/HANDOVER.md`、`docs/reviews/PENDING.md`）と、レビュアーの出力そのもの（`docs/reviews/*-codex.md`）には日本語訳を置かない。upstream から引き継いだファイル（README.md）は、最初に手を入れるときに日本語訳を置く。

## 作業の進め方（サンドイッチ）

1. 設計・実装: Claude Opus 5.5（`claude-opus-5-5`）。
2. レビュー: Codex の `gpt-6.1-sol`、effort medium。labteam のアカウントで動かす（`CODEX_HOME=$HOME/.codex-labteam`、または Codex の起動の前に `cx labteam`）。レビューだけを頼み、sandbox は読み取り専用にし、編集はさせない。出力そのものは `docs/reviews/<日付>-<単位>-codex.md` に置く。
3. 総合判断: Claude Opus 5.5。指摘ごとに、直す・直さないとその理由を決め（`docs/reviews/<日付>-<単位>-judgement.md`）、直すものを 1 に戻す。

labteam のクレジットが切れたら、アカウントを切り替えず、レビューも省かない。その単位を `docs/reviews/PENDING.md` に載せ、レビューに依存しない作業を進める。

## 環境

devshell（`.envrc` → `nix/flake.nix`）が XcodeGen と bun を入れる。Swift と iOS の SDK は Xcode のものを使う。agent には、dotfiles の agent-switch の shim が、repo で `claude` か `codex` を起動したときに direnv を読み込んで効かせる。コマンドラインでのビルドには `-skipPackagePluginValidation` が要る（SwiftTerm が build plugin を持つ）。`scripts/bundle-mods.sh` は sandbox なしの pre-build として動くので、変更があればビルドの前に読む。

## 先行実装

- upstream の `zzulanas/herdr-ios`（Apache-2.0）。`NOTICE` と license を残す。upstream に返したい変更は、`main` ではなく branch から PR にする。
- Heeler（`ZingerLittleBee/Heeler`、Apache-2.0）: SSH、端末、チャットの表示。PR #538 に herdr-core への対応がある。
- HerdrChat（Apache-2.0）: Claude と Codex の transcript の解析。
- Ovis、Collie（MIT）: herdr-core の adapter。Collie の `docs/multiplexers.md` に herdr-core の制約がまとまっている。
- Orca Mobile（`stablyai/orca`）と opencode: チャットの振る舞いの参考。コードを流用する前に license を確かめ、流用したファイルには出典を残す。
