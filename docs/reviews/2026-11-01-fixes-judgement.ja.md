# 判断: 使い始める前の 3 つの修正へのレビュー（2026-11-01）

この文書は `2026-11-01-fixes-judgement.md` の日本語訳である。内容が食い違うときは英語版に従う。

対象の commit: 407eccd（Chat の nudge）、362b8bc（host key の承認と Keychain）、1b740be（requiredMethods）。
レビューの出力そのもの: `2026-11-01-fixes-codex.md`（Codex gpt-6.1-sol、medium、labteam、読み取り専用）。

| # | 指摘 | 判断 | 理由 |
|---|---|---|---|
| 1 | `ChatModel`: `load()` の最中に `stop()`・`start()` すると、止めたループも `pause()` に進んで `wake` を上書きし、continuation が 1 つ再開されずに残る | 直す | `load()` の後に guard を 1 行足すだけで済む。残った continuation は、その task を永久に止める |
| 2 | Citadel 0.12.1 は、host key を拒否したとき handshake の promise を失敗させるだけで、TCP の channel を閉じない | 今は直さない | `Citadel/Sources/Citadel/ClientSession.swift` で確認した（handshake handler は promise を失敗させるだけ）。鍵を拒否する経路は `Mismatch` で以前からあった。`Unknown` は自動で再試行せず、sshd は認証されない接続を `LoginGraceTime`（既定 120 秒）で切るので、接続は積み上がらない。直す場所は Citadel（handshake の失敗で channel を閉じる）で、upstream への PR にする。`PENDING.md` に載せた |
| 3 | Keychain の読み取りの失敗を「未登録」と読むので、登録済みのホストが初回に見え、pin を置き換えられうる | 直す | `KeyStore.hostKey` を throw にし、validator は Keychain のエラーで接続を失敗させる |
| 4 | 照合のコマンドが、ホストが別の種類の鍵を出しても ed25519 の鍵のファイルを指す | 直す | `HostKeys.Unknown.checkCommand` が、提示された鍵の種類のファイルを指す |
| 5 | Settings の Forget の確認文が、次の鍵を自動で信頼すると書いている | 直す | 次の鍵には承認が要る、という文に直した |

修正後に確かめたこと: `HerdrUITests.testFirstConnectAsksForHostKey` が、iOS 27.1 の simulator から、この Mac の herdr-core に SSH でつないで通る（ログインの前に fingerprint を表示し、その値が host key の `ssh-keygen -lf` と一致し、承認した後にだけホームに進む）。HerdrKit の単体テスト 33 件が通る。
