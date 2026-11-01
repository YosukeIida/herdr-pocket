Reading additional input from stdin...
OpenAI Codex v0.166.0
--------
workdir: /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
model: gpt-6.1-sol
provider: openai
approval: on-request
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a197ed-bedf-7e41-b6d5-8c7d25841022
--------
user
Review commit c06c272 in this repo (git show c06c272): the pairing code now carries the Ed25519 seed extracted at offset 161 of an unencrypted OpenSSH ed25519 key, and the host key base64 only. Look for correctness and security bugs in scripts/pair.sh, Packages/HerdrKit/Sources/HerdrKit/Pairing.swift and AppStore.pair. Report findings only; do not edit.
warning: Codex could not update marketplace `impeccable`: trusted Git repository root escapes Codex home
warning: Codex could not update marketplace `ponytail`: trusted Git repository root escapes Codex home
hook: SessionStart
hook: SessionStart
hook: SessionStart
hook: SessionStart Completed
hook: SessionStart Completed
hook: SessionStart Completed
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
hook: UserPromptSubmit Completed
codex
指定コミットと鍵の生成・保存・照合の経路を読み、正確性とセキュリティ上の不具合を確認します。ponytail-review スキルを使い、変更やファイル出力は行いません。
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md; git show --stat c06c272; git status --short' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
---
name: ponytail-review
description: >
  Quality review of a change: is the logic right, is it safe, does it hold
  under real load, is risky code tested, is it fast enough, and is every line
  needed. Reads the connected code, not only the diff. Each finding is
  explained in plain English. Use for "review this", "code review", "review
  the last commit", "review my PR", "is this over-engineered", /ponytail-review.
---

Review a change like the senior developer who will be paged when it breaks.
Order of importance: correct, safe, holds under load, tested, fast, lean.
Lean still matters: every extra line must be read, tested and fixed later.
This is a report the user asked for, so give it in full.

## 1. Understand first

- Review what the user names: uncommitted or staged changes, a branch, a PR
  link, or files. Nothing named: the uncommitted changes, or the last commit
  if there are none.
- Read the diff, then the code it touches: callers of every changed function,
  the functions it calls, the tests, the README.
- Trace the real flow: where data comes in, what is stored, what goes out.
- A change can break code it does not touch. When a signature, return value
  or behavior changes, grep every caller.
- Find the expected load in the repo (README, deploy config): one person
  running a script, or many users and processes at once. Judge scale against
  that, and say which load you assumed.

## 2. Look for

1. **Bug:** wrong result, crash, missed edge case (empty, zero, last item,
   rounding, time zones), a caller broken by the change, a fix applied in one
   caller while the shared function stays broken.
2. **Risk:** security holes (injection, weak randomness, secrets, missing
   checks on input from users), data loss (errors swallowed, writes in the
   wrong order, no transaction).
3. **Scale:** fine for one user, wrong for many: check-then-write races, the
   same work done by every process, memory or lists that only grow, a query
   per item, O(n^2) on big input, per-process state that must be shared.
4. **Missing test:** risky new logic (a branch, a parser, money, security,
   data writes, a bug fix) with no test that fails when it breaks. One good
   test, not coverage.
5. **Speed:** big slowdowns are problems. Small wins (work repeated in a hot
   loop) are suggestions; some software counts every millisecond.
6. **Lean:** code that should not exist or should be smaller.
   - delete: dead code, unused options, speculative features
   - reuse: the repo already has this helper (name the path)
   - stdlib / native: the standard library or platform already does it; a
     new dependency for a few lines
   - yagni: abstraction with one implementation, config nobody sets
   - merge: near-copies that must change together
   - split: one function doing several unrelated jobs, so it is hard to read
     or test. Split by job, never by line count, and never into helpers that
     exist only to make a function shorter.

## 3. Check before you report

- Every finding needs a concrete case: "this input or situation leads to this
  wrong result". No case, no finding.
- Re-read the lines and confirm: the caller exists, the value can really be
  empty, the code really is unused.
- A shortcut marked with a `shortcut:` (or older `ponytail:`) comment that names its limit is a
  decision, not a finding, unless the expected load already crosses it.
- Propose the smallest fix that works. Prefer fixes that delete code. Never
  add layers, frameworks or config the problem does not need.
- No style taste, no "consider", no vague worries.

## 4. Output

Very simple English: short sentences, everyday words. Explain a technical
term the first time you use it. The reader may never have seen this code.

Start with `What this change does:` in two or three sentences.

Then the findings in three groups, skip empty groups:
- **Must fix:** bug, security, data loss, breaks at the expected load.
- **Should fix:** risky code without a test, real slowness, duplication, a
  function that mixes jobs, code that should not exist.
- **Nice to have:** small speed-ups, shorter forms.

Number findings across all groups, so the user can say "fix 2 and 5".
Every finding has all four parts, each one or two short sentences:

2. **Orders land on the wrong day** (`billing/close_day.py:L40-52`)
   - **What this is:** At midnight this job closes the day and bills all orders of that day.
   - **Problem:** It takes "today" from the server clock, which runs in UTC. An order placed
     at 00:30 in Berlin is billed on the day before.
   - **Fix:** Compute the day once in the shop's time zone:
     `datetime.now(ZoneInfo("Europe/Berlin")).date()`. One line, nothing else changes.
   - **If we skip it:** Late orders show the wrong date, and accounting fixes them by hand.

End with:
- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.`
- `Lean: -<N> lines possible.` when lean findings exist.
- `Not checked:` one line, if something mattered and you could not check it.

Nothing found: `What this change does:`, then `Looks good. Ship.` and one line
on what you checked.

Lists findings, changes no code.
commit c06c272b12bc1020e23d698dfc57496b66ce8aa1
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:24:53 2026 +0900

    Shrink the pairing QR code by sending the Ed25519 seed instead of an OpenSSH key file
    
    The v1 code (about 785 characters) drew a 113-column QR that did not fit a terminal.
    v2 carries only the host key's base64 and the 32-byte seed with short field names,
    about 241 characters, drawn at error-correction level L with a 2-module margin.

 App/Sources/Store/AppStore.swift                   |  3 +-
 Packages/HerdrKit/Sources/HerdrKit/Pairing.swift   | 38 +++++++++++++---------
 .../Tests/HerdrKitTests/HerdrKitTests.swift        | 18 +++++-----
 scripts/pair.sh                                    | 11 ++++---
 4 files changed, 40 insertions(+), 30 deletions(-)
?? docs/reviews/2026-11-02-pairing-v2-codex.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md; rg --files -g AGENTS.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
# 場面ごとの言い方

user が実際に直した表現から作った、場面ごとの書き方。返答でも文書でも、該当する場面ではこの書き方で書く。
1 行に 1 件。出典は `transcript:<セッション ID の先頭 8 文字>#L<行>`。
`dotfiles/claude/style-digest.sh` が会話の記録から追記する。未 commit の行は user がまだ確かめていない。

- 【報告の文】動作は定着した漢語で書く（「測って確かめた」ではなく「計測した」）。動詞を開くと AI の文章らしく読まれる。〔transcript:37759ab8#L3516〕
- 【報告の文】文頭に主語を置く（「同じ Wasm で」「1 本で」から書き出さない）。主語が後ろにあると、何の話かが文末まで分からない。〔transcript:37759ab8#L3516〕
- 【報告の見出し】何を変えて何を計測したかを見出しに書く（例:「LLM の圧縮・復元を Wasm に変更し、機種間の一致を計測」）。差分が見出しだけで分かる。〔transcript:37759ab8#L3530〕
- 【技術用語】ソースを Wasm にする操作は「コンパイル」と書く（「Wasm にビルド」ではなく）。用語はその操作を正確に指す語を使う。〔transcript:37759ab8#L3976〕
- 【予定・必要】やり直しが要ることは「再度計測が必要である」と書く（「取り直します」ではなく）。口語の予定ではなく、書き言葉で必要性を書く。〔transcript:37759ab8#L4002〕
- 【並べ方】同じ種類のものだけを並べる（「Mac の Safari と iPhone の Safari」。「iPhone と Safari」のように端末とブラウザを同列にしない）。〔transcript:37759ab8#L4030〕
- 【数値の主語】時間や速さは、何にかかるかを書く（「スマホでの速さ」ではなく「スマホで契約書 1 本を復元するのにかかる時間」）。〔transcript:37759ab8#L4058〕
- 【語の意味】満たす必要がある数値は「制約」「条件」と書く（「目標」とは書かない）。目標は届かなくてもよい値に使う。〔transcript:37759ab8#L4058〕
- 【つなぎの語】独立した作業は、関係を示す語でつながずに並べる（「並行して」を使わない）。「並行して」は、マルチスレッド化を複数の文書をまとめて処理することと読み違えさせる。〔transcript:37759ab8#L4086〕
- 【文末】「である」調の文書では、過去の状態も「であった」と書く（「だった」ではなく）。文体をそろえる。〔transcript:f8e2de53#L139〕
- 【報告の用語】研究者・オフィスワーカーが読む文書は、分野で定着した用語をそのまま使う（「各 CPU 向けにビルドした版」ではなく「ネイティブビルド」、「計算を複数のスレッドに分ける版」ではなく「マルチスレッド版」）。和語に開くと平易になりすぎ、読み手には硬さが足りなく感じられる。〔transcript:37759ab8#L3601〕
- 【報告の構成】短い文に情報を載せ、構成は単純にする（課題、実施、結果、次の作業の順）。和語に開いて説明を広げるより、用語 1 語で済ませたほうが 1 文あたりの情報量が高い。〔transcript:37759ab8#L3686〕
- 【数の単位】同じ対象を数える単位は 1 つに統一し、LLM が数える対象は「トークン」と書く（「2,033 語」と「2,033 位置」を混在させない、「2,125 語」ではなく「2,125 トークン」）。単位が揺れると、同じ数を指しているのか読み手に判別できない。〔transcript:37759ab8#L4147〕
- 【段落内の文体】同じ段落では「である」調にそろえる（「再度計測が必要。Android は未計測。」の後に「見ていません。」と続けない）。です・ます調と体言止めが混ざると、文の調子が崩れる。〔transcript:37759ab8#L4147〕
- 【作業の列挙】次にやる作業を複数挙げるときは、「次の作業は 3 つです。」の後に文を並べず、箇条書きにする。並列の項目は、箇条書きのほうが 1 件ずつ区別して読める。〔transcript:37759ab8#L4147〕
- 【文書の用語】同じ概念は 1 つの語に統一し、省略した語は初出で補う（冒頭に用語表を置き、「一致」「確率」「分布」のように表現が揺れる語を使い分けない）。省略や言い換えが混ざると、読み手が同じものを指すのか判別できず、分かりにくくなる。〔transcript:2c8f2786#L400〕
- 【進捗報告の箇条書き】各行は体言で止める（「〜しました」ではなく）。終わったことは「済み」を付けて示す。「進捗」の見出しの下に置く項目は終わったことと読めるため、文末で完了を繰り返す必要がない。〔transcript:0994b5e3#L2165〕
- 【メールへの応答の報告】メールに応じたことは「返信済み」と書く（「回答済み」ではなく）。手段が分かる語のほうが、何をしたかが正確に伝わる。〔transcript:0994b5e3#L2193〕
- 【進捗報告の項目名】項目名は対象の媒体や種類が分かる語で書く（「登録シート」ではなく「スプレッドシート変更」、「問い合わせ」ではなく「メール問い合わせ」）。同じ週の報告に別種の作業が並ぶため、媒体が分かれば項目名だけで区別できる。〔transcript:0994b5e3#L2256〕
- 【進捗報告の構成】抽象的な項目名の下に具体を置く階層で書く。読み手は項目名だけで全体をつかめ、必要な項目だけ具体を読める。〔transcript:0994b5e3#L1115〕
- 【シート変更の依頼】列は記号（O、AL など）ではなくシートの列名で指す（「O（Activity-B）」ではなく列名そのまま）。依頼を受ける側は列名で探すため、記号に置き換えると手間が増える。〔transcript:0994b5e3#L1348〕
- 【返答の言語】user への報告・説明は、途中経過も含めて日本語で書く（英語の文を混ぜず、「Comparison is done.」のような英文で報告しない）。英語で書くと、読み手が内容を確かめる前に言語を変換する手間が生じる。〔transcript:69ba1421#L2524〕
- 【依頼文の項目】複数の対象に同じ変更を頼むときは、各項目を書き出す（「宮西さんと同じ変更です」と参照しない）。受け手は項目を 1 つずつ作業するため、別の項目に戻って読む手間が生じる。〔transcript:9b9713a4#L2025〕
- 【再度の依頼】以前の依頼に触れず、現時点との差分だけを示す（「まだ対応できていません」と書かない）。過去の分を挙げると催促や指摘に読まれる。〔transcript:9b9713a4#L1928〕
- 【確認の依頼】確認を頼むときは、どのファイルのどの箇所を見て何を決めるかを 1 件ずつ書く（「23 枚の下書きの採否を教えてください」とだけ書かない）。ファイルを 1 枚ずつ開いて探す作業を、依頼する側で済ませておくと、読み手の負担が減る。〔transcript:b9a5a6de#L4377〕
- 【確認依頼の投稿】自分の見立てを先に書き、そのとおり返信してよいかを聞く形にする（「可否をご確認ください」と相手に判断を丸ごと預けない）。相手は見立てに同意するかどうかだけを答えればよい。〔transcript:6c89b59a#L686〕
- 【複数の相手への確認】相手ごとに問いを分け、各問いの末尾に「→ 宛先」を付けて誰への問いかを示す（問いをまとめて宛名だけ冒頭に並べない）。宛先を問いごとに見て、自分に向けた問いだけを読める。〔transcript:6c89b59a#L807〕
- 【未回答の問いの再掲】回答待ちの問いは、記号や番号の範囲（「B〜D」「8〜10 番」）だけで指さず、問いの中身を 1 件ずつ書く。記号だけでは、読み手がどの問いか判別できず、前の発言を遡って探す手間が生じる。〔transcript:51c7e2cb#L698〕
- 【スライドの結論の行】出典と根拠のある事実だけを書き、評価語を足さない（「本物らしい書類が安く作れるようになった」の「安く」を書かない）。出典にない評価語は AI の文章らしく読まれる。〔transcript:37759ab8#L19888〕
- 【見出し・カードの語句】何が何をするのかを省かず、対象まで書く（「本物のまま渡せる」「撮影した端末が署名」ではなく、確かめる内容や署名の対象を書く）。対象が省かれると、読み手が意味を決められない。〔transcript:37759ab8#L20059〕
- 【専門外の聞き手への資料】モデルの大きさ（270M・1B）や CPU の名称（x86）は出さず、身近な比較対象（zip）に置き換える。専門外の聞き手には、数字や名称だけでは何がすごいのか伝わらない。〔transcript:37759ab8#L20089〕
- 【スライドの本文】見出しは主張の文にし、本文は文章の箇条書きではなく図・カード・大きな数字で示す（べた書きの箇条書きにしない）。単語を拾うだけでそのページの内容が分かるようにするためである。〔transcript:37759ab8#L11820〕
- 【数字の見せ方】数字は段階で現れるだけにし、0 から数え上げる演出は付けない（「0 → 47.1%」と変化させない）。演出が強いと、内容より動きが目立つ。〔transcript:37759ab8#L20700〕
- 【アルゴリズムの説明スライド】例は記号や仮の値ではなく、実際の文字列と値で示す。実際の文字列のほうが、何が起きているかを読み手が追える。〔transcript:37759ab8#L13152〕
- 【カードの文言】口語の言い切りや略した語（「払う店に得が少ない」「サーバ保管で足りる」）を避け、対象を正式な語で書く（「導入する店舗の利益が不明」「サーバ上でのデータ管理の方が利点が多い」）。口語の短縮は AI の文章らしく読まれる。〔transcript:37759ab8#L22085〕
- 【成果物の呼び方】実行ファイルは「共通の Wasm バイナリ」と書く（「同じ Wasm 1 本」と数えない）。「1 本」は何を数えているのか分からない。〔transcript:37759ab8#L12104〕
- 【投稿・報告の確認範囲の記載】確認した範囲が一部にとどまる事実は、否定の形で書かない（「10/25・26 の通知にお名前はありません」と書かない）。読み手に、それ以前の通知を疑わせる。〔transcript:068c3505#L2904〕
- 【略語・専門用語の初出】略語は初出で正式名称を添え、CPU・GPU のどちらの話か、どの層（命令・演算器・言語・API など）の語かを付ける（「ARM の SDOT・i8mm、x86 の AVX-VNNI」とだけ書かない）。読み手がハードウェアとソフトウェアの語に詳しくない場合、語の種類が分からないと文が追えない。〔transcript:8a64ed0c#L4371〕
- 【段階分けの呼び方】段階を表す語は、その段階が何を表すかのイメージを先に決め、それを伝える語を選ぶ（積み上がっていくものと捉えるなら「レイヤー」、どれだけ大事かの尺度と捉えるなら「重要度」）。番号付きの「層」（「1 層」「層2」）は、何の尺度か、数が大きいほどどうなるのかが読み手に伝わらない。〔transcript:7fa1b5bb#L5904〕
AGENTS.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "git show c06c272; cat scripts/pair.sh; cat Packages/HerdrKit/Sources/HerdrKit/Pairing.swift; rg -n 'func pair|Pairing|privateKeySeed|seed|hostKey' App/Sources/Store/AppStore.swift App/Sources/Net Packages/HerdrKit/Tests README.md" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit c06c272b12bc1020e23d698dfc57496b66ce8aa1
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:24:53 2026 +0900

    Shrink the pairing QR code by sending the Ed25519 seed instead of an OpenSSH key file
    
    The v1 code (about 785 characters) drew a 113-column QR that did not fit a terminal.
    v2 carries only the host key's base64 and the 32-byte seed with short field names,
    about 241 characters, drawn at error-correction level L with a 2-module margin.

diff --git a/App/Sources/Store/AppStore.swift b/App/Sources/Store/AppStore.swift
index 282a4db..fdaf8c8 100644
--- a/App/Sources/Store/AppStore.swift
+++ b/App/Sources/Store/AppStore.swift
@@ -1,5 +1,6 @@
 import SwiftUI
 import UIKit
+import CryptoKit
 import HerdrKit
 
 /// Where to connect. Persisted in UserDefaults (the key lives in the Keychain).
@@ -202,7 +203,7 @@ final class AppStore {
 
     /// Adds the machine a `scripts/pair.sh` code describes, with its own key and its host key pinned, and connects.
     func pair(_ offer: PairingOffer) throws {
-        let key = try KeyStore.parseOpenSSH(offer.privateKey)
+        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: offer.seed)
         let m = machines.first { $0.host == offer.host && $0.port == offer.port && $0.user == offer.user }
             ?? MachineConfig(label: offer.host, host: offer.host, port: offer.port, user: offer.user)
         // A code never replaces a pinned host key: that is what a Mismatch guards against.
diff --git a/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift b/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift
index 47dc054..38d76df 100644
--- a/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift
+++ b/Packages/HerdrKit/Sources/HerdrKit/Pairing.swift
@@ -4,20 +4,22 @@ import Foundation
 /// on a box over SSH. The box made the key pair and authorized the public half for that command only,
 /// so nothing goes back from the phone.
 ///
-/// Text form: `herdr-pair:` + base64url(JSON `{"v":1,"host","port","user","hostKey","key"}`).
+/// Text form: `herdr-pair:` + base64url(JSON `{"v":2,"h":host,"p":port,"u":user,"k":hostKeyBase64,"s":seedBase64}`),
+/// short so the QR code fits a terminal: the host key is ed25519 (only its base64 travels) and the
+/// phone's key is its 32-byte Ed25519 seed rather than an OpenSSH file.
 public struct PairingOffer: Equatable, Sendable {
     public var host: String
     public var port: Int
     public var user: String
     /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
     public var hostKey: String
-    /// The phone's private key, unencrypted OpenSSH text.
-    public var privateKey: String
+    /// The phone's Ed25519 private key seed (32 bytes).
+    public var seed: Data
 
     public static let prefix = "herdr-pair:"
 
-    public init(host: String, port: Int, user: String, hostKey: String, privateKey: String) {
-        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.privateKey = privateKey
+    public init(host: String, port: Int, user: String, hostKey: String, seed: Data) {
+        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.seed = seed
     }
 
     public struct Invalid: LocalizedError, Equatable {
@@ -28,19 +30,23 @@ public struct PairingOffer: Equatable, Sendable {
     public static func decode(_ text: String) throws -> PairingOffer {
         let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
         guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
-        var b64 = String(s.dropFirst(prefix.count)).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
-        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
-        guard let data = Data(base64Encoded: b64), let v = try? JSONValue.parse(data) else { throw Invalid(reason: "the code is damaged") }
-        guard v["v"].int == 1 else { throw Invalid(reason: "made by a newer pair.sh") }
-        guard let host = v["host"].string, !host.isEmpty, let user = v["user"].string, !user.isEmpty else {
+        guard let data = base64url(String(s.dropFirst(prefix.count))), let v = try? JSONValue.parse(data) else {
+            throw Invalid(reason: "the code is damaged")
+        }
+        guard v["v"].int == 2 else { throw Invalid(reason: "made by a different pair.sh") }
+        guard let host = v["h"].string, !host.isEmpty, let user = v["u"].string, !user.isEmpty else {
             throw Invalid(reason: "no host or user")
         }
-        let port = v["port"].int ?? 22
+        let port = v["p"].int ?? 22
         guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
-        guard let hostKey = v["hostKey"].string, hostKey.hasPrefix("ssh-"), hostKey.split(separator: " ").count == 2 else {
-            throw Invalid(reason: "no host key")
-        }
-        guard let key = v["key"].string, key.contains("BEGIN OPENSSH PRIVATE KEY") else { throw Invalid(reason: "no key") }
-        return PairingOffer(host: host, port: port, user: user, hostKey: hostKey, privateKey: key)
+        guard let k = v["k"].string, let blob = Data(base64Encoded: k), blob.count == 51 else { throw Invalid(reason: "no ed25519 host key") }
+        guard let sb = v["s"].string, let seed = Data(base64Encoded: sb), seed.count == 32 else { throw Invalid(reason: "no key") }
+        return PairingOffer(host: host, port: port, user: user, hostKey: "ssh-ed25519 " + k, seed: seed)
+    }
+
+    private static func base64url(_ s: String) -> Data? {
+        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
+        b += String(repeating: "=", count: (4 - b.count % 4) % 4)
+        return Data(base64Encoded: b)
     }
 }
diff --git a/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift b/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
index 3a7d291..967211b 100644
--- a/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
+++ b/Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift
@@ -342,21 +342,21 @@ final class PairingTests: XCTestCase {
             .replacingOccurrences(of: "=", with: "")
         return PairingOffer.prefix + b64
     }
-    private let key = "-----BEGIN OPENSSH PRIVATE KEY-----\nabc\n-----END OPENSSH PRIVATE KEY-----\n"
-    private let hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqu"
+    private let k = Data(repeating: 7, count: 51).base64EncodedString()
+    private let s = Data(repeating: 9, count: 32).base64EncodedString()
 
     func testDecodesWhatPairShPrints() throws {
-        let o = try PairingOffer.decode(code(["v": 1, "host": "100.64.0.9", "port": 2222, "user": "me", "hostKey": hostKey, "key": key]) + "\n")
-        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: hostKey, privateKey: key))
+        let o = try PairingOffer.decode(code(["v": 2, "h": "100.64.0.9", "p": 2222, "u": "me", "k": k, "s": s]) + "\n")
+        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: "ssh-ed25519 " + k, seed: Data(repeating: 9, count: 32)))
     }
 
     func testRejectsOtherTextAndIncompleteOffers() {
         XCTAssertThrowsError(try PairingOffer.decode("orca://pair?code=abc"))
         XCTAssertThrowsError(try PairingOffer.decode(PairingOffer.prefix + "!!!"))
-        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "host": "h", "user": "u", "hostKey": hostKey, "key": key])))
-        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "", "user": "u", "hostKey": hostKey, "key": key])))
-        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "user": "u", "hostKey": "AAAA", "key": key])))
-        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "port": 0, "user": "u", "hostKey": hostKey, "key": key])))
-        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "host": "h", "user": "u", "hostKey": hostKey, "key": "nope"])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "h": "h", "u": "u", "k": k, "s": s])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "", "u": "u", "k": k, "s": s])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": "AAAA", "s": s])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "p": 0, "u": "u", "k": k, "s": s])))
+        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": k, "s": "nope"])))
     }
 }
diff --git a/scripts/pair.sh b/scripts/pair.sh
index 0932b15..c0575e6 100755
--- a/scripts/pair.sh
+++ b/scripts/pair.sh
@@ -25,10 +25,10 @@ core="$(command -v herdr-core || true)"
 [ -x "$core" ] || { echo "herdr-core is not installed here" >&2; exit 1; }
 case "$core" in *[!A-Za-z0-9/._-]*) echo "can't use herdr-core at $core (unusual characters in the path)" >&2; exit 1 ;; esac
 
-hostkey="$(awk '{print $1" "$2}' /etc/ssh/ssh_host_ed25519_key.pub)"
+hostkey="$(awk '{print $2}' /etc/ssh/ssh_host_ed25519_key.pub)"
 
-if command -v qrencode >/dev/null 2>&1; then qr() { qrencode -t ansiutf8 -l M; }
-elif command -v nix >/dev/null 2>&1; then qr() { nix run nixpkgs#qrencode -- -t ansiutf8 -l M; }
+if command -v qrencode >/dev/null 2>&1; then qr() { qrencode -t ansiutf8 -l L -m 2; }
+elif command -v nix >/dev/null 2>&1; then qr() { nix run nixpkgs#qrencode -- -t ansiutf8 -l L -m 2; }
 else echo "needs qrencode (or nix) to draw the QR code" >&2; exit 1; fi
 
 dir="$(mktemp -d)"
@@ -49,7 +49,10 @@ printf 'restrict,command="%s connect" %s\n' "$core" "$pub" >> "$auth"
 chmod 600 "$auth"
 
 json() { printf '%s' "$1" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); gsub(/\t/,"\\t"); gsub(/\r/,"\\r"); if (NR>1) print "\\n"; print}'; }
-payload="{\"v\":1,\"host\":\"$(json "$host")\",\"port\":$port,\"user\":\"$(json "$user")\",\"hostKey\":\"$(json "$hostkey")\",\"key\":\"$(json "$(cat "$dir/key")")\"}"
+# The 32-byte Ed25519 seed sits at a fixed offset in an unencrypted OpenSSH ed25519 key file (the comment comes after it).
+seed="$(sed '1d;$d' "$dir/key" | tr -d '\n' | base64 -d | dd bs=1 skip=161 count=32 2>/dev/null | base64 | tr -d '\n')"
+[ "${#seed}" -eq 44 ] || { echo "couldn't read the new key" >&2; exit 1; }
+payload="{\"v\":2,\"h\":\"$(json "$host")\",\"p\":$port,\"u\":\"$(json "$user")\",\"k\":\"$hostkey\",\"s\":\"$seed\"}"
 code="herdr-pair:$(printf '%s' "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')"
 
 if [ "${HERDR_PAIR_PRINT:-}" = 1 ]; then printf '%s\n' "$code"; exit 0; fi
#!/bin/sh
# Pairs a phone with this box for herdr-pocket, on top of herdr-core's own remote path
# (`ssh box herdr-core connect`): it makes an SSH key for the phone, authorizes it in
# ~/.ssh/authorized_keys for `herdr-core connect` only, and shows a QR code holding the key,
# this box's address and its host key. Scan it in the app (or paste the code). Nothing listens
# on the network and nothing keeps running.
#
#   scripts/pair.sh [host] [name]
#
# host: the address the phone uses (default: this box's Tailscale IPv4, else its hostname).
# name: a label for the key in authorized_keys (default: herdr-pocket-<date>).
# Unpair a phone by deleting its line from ~/.ssh/authorized_keys.
set -eu

host="${1:-$(tailscale ip -4 2>/dev/null | head -n 1 || true)}"
[ -n "$host" ] || host="$(hostname)"
name="${2:-herdr-pocket-$(date +%Y%m%d-%H%M%S)}"
# The name becomes the key's comment in authorized_keys; a newline in it would add a second, unrestricted line.
case "$name" in ""|*[!A-Za-z0-9._-]*) echo "name: letters, digits, '.', '_' and '-' only" >&2; exit 1 ;; esac
user="$(id -un)"
port=22

core="$(command -v herdr-core || true)"
[ -n "$core" ] || core="$HOME/.local/bin/herdr-core"
[ -x "$core" ] || { echo "herdr-core is not installed here" >&2; exit 1; }
case "$core" in *[!A-Za-z0-9/._-]*) echo "can't use herdr-core at $core (unusual characters in the path)" >&2; exit 1 ;; esac

hostkey="$(awk '{print $2}' /etc/ssh/ssh_host_ed25519_key.pub)"

if command -v qrencode >/dev/null 2>&1; then qr() { qrencode -t ansiutf8 -l L -m 2; }
elif command -v nix >/dev/null 2>&1; then qr() { nix run nixpkgs#qrencode -- -t ansiutf8 -l L -m 2; }
else echo "needs qrencode (or nix) to draw the QR code" >&2; exit 1; fi

dir="$(mktemp -d)"
cleanup() { rm -f "$dir/key" "$dir/key.pub"; rmdir "$dir" 2>/dev/null || true; }
trap cleanup EXIT
# EXIT alone is skipped when a signal ends sh; the private key must not outlive the script.
trap 'cleanup; exit 1' HUP INT TERM
ssh-keygen -q -t ed25519 -N "" -C "$name" -f "$dir/key"

pub="$(cat "$dir/key.pub")"
[ "$(wc -l < "$dir/key.pub")" -eq 1 ] || { echo "unexpected public key file" >&2; exit 1; }
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
auth="$HOME/.ssh/authorized_keys"
# A last line without a newline would swallow ours.
if [ -s "$auth" ] && [ -n "$(tail -c 1 "$auth")" ]; then echo >> "$auth"; fi
# restrict: no forwarding, agent or pty; command=: the key can only start herdr-core connect.
printf 'restrict,command="%s connect" %s\n' "$core" "$pub" >> "$auth"
chmod 600 "$auth"

json() { printf '%s' "$1" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); gsub(/\t/,"\\t"); gsub(/\r/,"\\r"); if (NR>1) print "\\n"; print}'; }
# The 32-byte Ed25519 seed sits at a fixed offset in an unencrypted OpenSSH ed25519 key file (the comment comes after it).
seed="$(sed '1d;$d' "$dir/key" | tr -d '\n' | base64 -d | dd bs=1 skip=161 count=32 2>/dev/null | base64 | tr -d '\n')"
[ "${#seed}" -eq 44 ] || { echo "couldn't read the new key" >&2; exit 1; }
payload="{\"v\":2,\"h\":\"$(json "$host")\",\"p\":$port,\"u\":\"$(json "$user")\",\"k\":\"$hostkey\",\"s\":\"$seed\"}"
code="herdr-pair:$(printf '%s' "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')"

if [ "${HERDR_PAIR_PRINT:-}" = 1 ]; then printf '%s\n' "$code"; exit 0; fi

printf '%s' "$code" | qr
echo "Scan this in herdr-pocket (Add machine → Scan pairing code) to reach $user@$host."
echo "Authorized as \"$name\" in ~/.ssh/authorized_keys. Anyone who photographs this code can connect;"
printf 'press Enter when the phone is paired to clear the screen. '
read -r _ || true
clear 2>/dev/null || printf '\033[2J\033[H'
import Foundation

/// What `scripts/pair.sh` puts in its QR code: everything a phone needs to reach `herdr-core connect`
/// on a box over SSH. The box made the key pair and authorized the public half for that command only,
/// so nothing goes back from the phone.
///
/// Text form: `herdr-pair:` + base64url(JSON `{"v":2,"h":host,"p":port,"u":user,"k":hostKeyBase64,"s":seedBase64}`),
/// short so the QR code fits a terminal: the host key is ed25519 (only its base64 travels) and the
/// phone's key is its 32-byte Ed25519 seed rather than an OpenSSH file.
public struct PairingOffer: Equatable, Sendable {
    public var host: String
    public var port: Int
    public var user: String
    /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
    public var hostKey: String
    /// The phone's Ed25519 private key seed (32 bytes).
    public var seed: Data

    public static let prefix = "herdr-pair:"

    public init(host: String, port: Int, user: String, hostKey: String, seed: Data) {
        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.seed = seed
    }

    public struct Invalid: LocalizedError, Equatable {
        public var reason: String
        public var errorDescription: String? { "Not a herdr pairing code: \(reason)." }
    }

    public static func decode(_ text: String) throws -> PairingOffer {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
        guard let data = base64url(String(s.dropFirst(prefix.count))), let v = try? JSONValue.parse(data) else {
            throw Invalid(reason: "the code is damaged")
        }
        guard v["v"].int == 2 else { throw Invalid(reason: "made by a different pair.sh") }
        guard let host = v["h"].string, !host.isEmpty, let user = v["u"].string, !user.isEmpty else {
            throw Invalid(reason: "no host or user")
        }
        let port = v["p"].int ?? 22
        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
        guard let k = v["k"].string, let blob = Data(base64Encoded: k), blob.count == 51 else { throw Invalid(reason: "no ed25519 host key") }
        guard let sb = v["s"].string, let seed = Data(base64Encoded: sb), seed.count == 32 else { throw Invalid(reason: "no key") }
        return PairingOffer(host: host, port: port, user: user, hostKey: "ssh-ed25519 " + k, seed: seed)
    }

    private static func base64url(_ s: String) -> Data? {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b += String(repeating: "=", count: (4 - b.count % 4) % 4)
        return Data(base64Encoded: b)
    }
}
README.md:44:- **Pairing:** on the box, run `scripts/pair.sh` (in the devshell, which has qrencode). It makes an SSH key for the phone, authorizes it in `~/.ssh/authorized_keys` for `herdr-core connect` only (`restrict,command=…`), and shows a QR code with the key, the box's address and its host key; scan it in the app (or paste the code). The host key is pinned from the code, so there is no fingerprint to compare, and nothing listens or keeps running on the box. Remove a phone by deleting its line.
README.md:46:- **Host key:** on first connect the app stops before logging in and shows the box's host key fingerprint; it is pinned in the Keychain once you approve it. Pairing skips this: the code carries the host key, and a code never replaces a key already pinned.
App/Sources/Net/HostKeys.swift:38:    static func pinned(host: String, port: Int) throws -> String? { try KeyStore.hostKey("\(host):\(port)") }
App/Sources/Net/HostKeys.swift:60:        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
App/Sources/Net/HostKeys.swift:61:            let line = String(openSSHPublicKey: hostKey)
App/Sources/Store/AppStore.swift:205:    func pair(_ offer: PairingOffer) throws {
App/Sources/Store/AppStore.swift:206:        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: offer.seed)
App/Sources/Store/AppStore.swift:210:        if let pinned = try HostKeys.pinned(host: offer.host, port: offer.port), pinned != offer.hostKey {
App/Sources/Store/AppStore.swift:212:                             message: "The code's host key (\(HostKeys.fingerprint(offer.hostKey))) differs from the one pinned for \(offer.host) (\(HostKeys.fingerprint(pinned))). If the machine was reinstalled, forget its host key in Settings first.")
App/Sources/Store/AppStore.swift:215:        try HostKeys.pin(offer.hostKey, host: offer.host, port: offer.port)
App/Sources/Store/AppStore.swift:241:    func hostKeyFingerprint(_ machine: MachineConfig) -> String? { HostKeys.pinnedFingerprint(host: machine.host, port: machine.port) }
App/Sources/Store/AppStore.swift:244:    private(set) var hostKeyMismatch = false
App/Sources/Store/AppStore.swift:546:            hostKeyMismatch = false
App/Sources/Store/AppStore.swift:567:        hostKeyMismatch = error is HostKeys.Mismatch
App/Sources/Net/KeyStore.swift:107:    static func hostKey(_ hostPort: String) throws -> String? {
App/Sources/Net/CitadelTransport.swift:40:                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:338:final class PairingTests: XCTestCase {
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:343:        return PairingOffer.prefix + b64
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:349:        let o = try PairingOffer.decode(code(["v": 2, "h": "100.64.0.9", "p": 2222, "u": "me", "k": k, "s": s]) + "\n")
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:350:        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: "ssh-ed25519 " + k, seed: Data(repeating: 9, count: 32)))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:354:        XCTAssertThrowsError(try PairingOffer.decode("orca://pair?code=abc"))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:355:        XCTAssertThrowsError(try PairingOffer.decode(PairingOffer.prefix + "!!!"))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:356:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "h": "h", "u": "u", "k": k, "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:357:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "", "u": "u", "k": k, "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:358:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": "AAAA", "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:359:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "p": 0, "u": "u", "k": k, "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:360:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": k, "s": "nope"])))

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "sed -n '1,270p' App/Sources/Store/AppStore.swift; cat App/Sources/Net/HostKeys.swift; cat App/Sources/Net/KeyStore.swift; cat App/Sources/Net/CitadelTransport.swift; rg -n 'PairingOffer|store.pair|\\.pair\\(' App Packages scripts; cat Packages/HerdrKit/Sources/HerdrKit/JSONValue.swift; cat Packages/HerdrKit/Package.swift; git log -3 --oneline" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 37ms:
import SwiftUI
import UIKit
import CryptoKit
import HerdrKit

/// Where to connect. Persisted in UserDefaults (the key lives in the Keychain).
struct MachineConfig: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String = ""
    var host: String = ""
    var port: Int = 22
    var user: String = ""
    /// Optional password; nil = use the app's Ed25519 key.
    var usePassword: Bool = false
}

enum ConnectionPhase: Equatable {
    case idle
    case connecting(String)            // human step: "Opening SSH", "Saying hello"...
    case connected
    case failed(String)                // message shown to the user, with retry
}

/// One agent row in the agents list.
struct AgentRow: Identifiable, Hashable {
    var id: String { address }
    var address: String
    var label: String                  // Names: agent row label
    var program: String?               // "claude", "codex", "shell", ...
    var attention: Attention
    var spaceID: String?
    var tabID: String?
    var parent: String?                // sub-agents are nested under parent
    var since: Date?
}

@MainActor
@Observable
final class AppStore {
    // MARK: Connection
    var machines: [MachineConfig] = [] { didSet { persistMachines() } }
    var activeMachineID: UUID? { didSet { persistMachines() } }
    var phase: ConnectionPhase = .idle
    var hello: HelloInfo?
    /// Last stderr from the remote, for the failure screen.
    var diagnostics: String = ""

    // MARK: Live state
    var terminals: [String: TerminalRecord] = [:]
    var doc: LayoutDoc = LayoutDoc(value: .null, version: 0)
    var spaces: [SpaceRef] = []
    /// Remote $HOME, learned at connect (for names).
    var home: String = "~"

    // MARK: Per-device view state
    var selectedSpaceID: String? { didSet { persistView() } }
    var selectedTabBySpace: [String: String] = [:] { didSet { persistView() } }
    /// Terminal screen currently on screen (marks it seen).
    var visibleTerminal: String? { didSet { if let v = visibleTerminal { markSeen(v) } } }

    /// Toasts (in-app notifications; mods' notify() lands here too).
    struct Toast: Identifiable, Equatable {
        var id = UUID(); var title: String; var body: String?; var level: String = "info"
        /// Terminal the toast is about: tapping it opens that terminal.
        var address: String? = nil
            /// Seconds on screen; nil = the level's default.
        var duration: Double? = nil
    }
    var toasts: [Toast] = []
    /// A terminal the UI should open (tapped alert); the navigator clears it.
    var pendingOpen: String?

    /// Attention words and seen state, persisted per machine.
    private(set) var attentionState = AttentionTracker()

    // MARK: Private connection state
    @ObservationIgnored private var client: HerdrClient?
    @ObservationIgnored private var subscription: EventSubscription?
    /// Bumped per connection attempt; callbacks from older ones are dropped.
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var connectTask: Task<Void, Never>?
    @ObservationIgnored private var reconnectTask: Task<Void, Never>?
    @ObservationIgnored private var backgroundTask: Task<Void, Never>?
    @ObservationIgnored private var attempt = 0
    /// The person wants to be connected (false after an explicit disconnect).
    @ObservationIgnored private var wantConnected = false
    @ObservationIgnored private var sceneActive = true
    /// Skip alerts until the first snapshot after a connect has been absorbed.
    @ObservationIgnored private var alertsArmed = false
    @ObservationIgnored private var docRefresh: Task<Void, Never>?
    @ObservationIgnored private var docRefreshAgain = false
    @ObservationIgnored private var docGeneration = -1
    @ObservationIgnored private var saveAttentionTask: Task<Void, Never>?
    @ObservationIgnored private var restoringView = false
    @ObservationIgnored private var cachedPublicKey: String?
    private let defaults = UserDefaults.standard

    init() {
        loadMachines()
        loadMachineState()
        #if DEBUG
        if ProcessInfo.processInfo.environment["HERDR_DEBUG_AUTOCONNECT"] == "1", let m = currentMachine() {
            connect(to: m)
        }
        #endif
    }

    // MARK: Lifecycle

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            sceneActive = true
            backgroundTask?.cancel(); backgroundTask = nil
            markSeenVisible()
            guard wantConnected, let m = currentMachine() else { return }
            if client == nil || self.phase != .connected {
                attempt = 0
                startConnect(m, reconnecting: hello != nil)
            } else {
                // The socket may have died while suspended: probe it now rather than waiting for liveness.
                let gen = generation
                Task { [weak self] in
                    do { _ = try await self?.client?.call("server.status", timeout: 4) } catch {
                        guard let self, gen == self.generation, self.wantConnected else { return }
                        self.connectionLost(HerdrError(code: -1, kind: "lost", message: "Lost the core", hint: "no answer after resuming"), gen: gen)
                    }
                }
            }
        case .background:
            sceneActive = false
            saveAttentionNow()
            guard client != nil, backgroundTask == nil else { return }
            // iOS kills sockets in the background: close cleanly after a short grace.
            let bgID = UIApplication.shared.beginBackgroundTask(withName: "herdr.disconnect")
            backgroundTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(8))
                if !Task.isCancelled, let self, !self.sceneActive { self.dropConnection(phase: .idle) }
                UIApplication.shared.endBackgroundTask(bgID)
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func connect(to machine: MachineConfig) {
        if !machines.contains(where: { $0.id == machine.id }) { machines.append(machine) }
        if activeMachineID != machine.id {
            dropConnection(phase: .idle)
            activeMachineID = machine.id
            clearLiveState()
            loadMachineState()
        }
        wantConnected = true
        attempt = 0
        startConnect(machine, reconnecting: false)
    }

    func reconnect() {
        guard let m = currentMachine() else { return }
        wantConnected = true
        attempt = 0
        startConnect(m, reconnecting: hello != nil)
    }

    func disconnect() {
        wantConnected = false
        dropConnection(phase: .idle)
    }

    func saveMachine(_ m: MachineConfig, password: String?) {
        let old = machines.first { $0.id == m.id }
        if let i = machines.firstIndex(where: { $0.id == m.id }) { machines[i] = m } else { machines.append(m) }
        if let password { KeyStore.setPassword(password, for: m.id) }
        if activeMachineID == nil { activeMachineID = m.id }
        // Changed where/how we connect: reconnect with the new settings.
        if m.id == activeMachineID, let old, old != m, wantConnected { connect(to: m) }
    }

    func removeMachine(_ id: UUID) {
        guard let m = machines.first(where: { $0.id == id }) else { return }
        if id == activeMachineID {
            disconnect()
            clearLiveState()
            activeMachineID = machines.first { $0.id != id }?.id
        }
        machines.removeAll { $0.id == id }
        KeyStore.setPassword(nil, for: id)
        try? KeyStore.setMachineKey(nil, for: id)
        HostKeys.forget(host: m.host, port: m.port)
        for k in ["attention.", "view.", "home."] { defaults.removeObject(forKey: k + id.uuidString) }
    }

    /// The app's own SSH public key, OpenSSH one-line form ("ssh-ed25519 AAAA... herdr-ios").
    func publicKeyLine() -> String {
        if let k = cachedPublicKey { return k }
        let k = KeyStore.publicKeyLine()
        if !k.isEmpty { cachedPublicKey = k }
        return k
    }

    /// Adds the machine a `scripts/pair.sh` code describes, with its own key and its host key pinned, and connects.
    func pair(_ offer: PairingOffer) throws {
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: offer.seed)
        let m = machines.first { $0.host == offer.host && $0.port == offer.port && $0.user == offer.user }
            ?? MachineConfig(label: offer.host, host: offer.host, port: offer.port, user: offer.user)
        // A code never replaces a pinned host key: that is what a Mismatch guards against.
        if let pinned = try HostKeys.pinned(host: offer.host, port: offer.port), pinned != offer.hostKey {
            throw HerdrError(code: -1, kind: "host_key_differs",
                             message: "The code's host key (\(HostKeys.fingerprint(offer.hostKey))) differs from the one pinned for \(offer.host) (\(HostKeys.fingerprint(pinned))). If the machine was reinstalled, forget its host key in Settings first.")
        }
        // Pin before the key: if the key write fails, the old key stays (Keychain updates in place).
        try HostKeys.pin(offer.hostKey, host: offer.host, port: offer.port)
        try KeyStore.setMachineKey(key, for: m.id)
        var saved = m
        saved.usePassword = false
        saveMachine(saved, password: nil)
        connect(to: saved)
    }

    /// The public key a machine is reached with: its own from pairing, else the app key.
    func publicKeyLine(for machine: UUID) -> String {
        if let k = try? KeyStore.machineKey(for: machine) { return KeyStore.publicKeyLine(for: k.publicKey, comment: "herdr-pocket-pair") }
        return publicKeyLine()
    }

    func isPaired(_ machine: UUID) -> Bool { (try? KeyStore.machineKey(for: machine)) != nil }

    /// Replace the app key with a pasted OpenSSH ed25519 private key.
    func importPrivateKey(_ text: String) throws {
        try KeyStore.importPrivateKey(text)
        cachedPublicKey = nil
    }

    /// Forget a machine's pinned host key (after a legitimate reinstall).
    func forgetHostKey(_ machine: MachineConfig) { HostKeys.forget(host: machine.host, port: machine.port) }

    /// The pinned host key fingerprint (SHA256:…), nil before the first connect.
    func hostKeyFingerprint(_ machine: MachineConfig) -> String? { HostKeys.pinnedFingerprint(host: machine.host, port: machine.port) }

    /// The last connect failed because the host key changed.
    private(set) var hostKeyMismatch = false

    /// The last connect stopped at a host seen for the first time; its key waits for approval.
    private(set) var unknownHostKey: HostKeys.Unknown?

    /// Pins the approved first-seen host key and connects again.
    func trustHostKey(_ key: HostKeys.Unknown) {
        do {
            try HostKeys.pin(key.line, host: key.host, port: key.port)
        } catch {
            phase = .failed("Couldn't save the host key: \(error.localizedDescription)")
            return
        }
        unknownHostKey = nil
        reconnect()
    }

    /// Pull-to-refresh / screens that want a step index rather than text.
    /// 0 SSH, 1 starting core, 2 hello, 3 events + layout; -1 when not connecting.
    private(set) var connectStep = -1

    // MARK: Derived views

    func spaceName(_ s: SpaceRef) -> String {
        let first = s.tabs.lazy.flatMap(\.panes).compactMap(\.terminal).first
        return Names.spaceName(s, firstTerminalCwd: first.flatMap { terminals[$0]?.cwd }.flatMap { $0.isEmpty ? nil : $0 }, home: home)
    }
import Foundation
import Crypto
import NIOCore
import NIOSSH

/// Host keys pinned per host:port in the Keychain, after the person approves the first one.
enum HostKeys {
    struct Mismatch: LocalizedError {
        var host: String
        var expected: String
        var got: String
        var errorDescription: String? {
            "\(host)'s host key changed (was \(expected), now \(got)). If the machine was reinstalled, tap Forget host key; otherwise someone may be intercepting the connection."
        }
    }

    /// A host seen for the first time. Nothing is pinned and no credentials were sent yet.
    struct Unknown: LocalizedError, Equatable {
        var host: String
        var port: Int
        var line: String
        var fingerprint: String { HostKeys.fingerprint(line) }
        /// The command that prints this key's fingerprint on the machine itself.
        var checkCommand: String {
            let type = line.hasPrefix("ssh-ed25519") ? "ed25519" : line.hasPrefix("ecdsa-") ? "ecdsa" : "rsa"
            return "ssh-keygen -lf /etc/ssh/ssh_host_\(type)_key.pub"
        }
        var errorDescription: String? {
            "First connection to \(host). Compare its host key with the machine before trusting it."
        }
    }

    /// The pinned key's fingerprint, for display.
    static func pinnedFingerprint(host: String, port: Int) -> String? {
        (try? pinned(host: host, port: port))?.map(fingerprint)
    }

    static func pinned(host: String, port: Int) throws -> String? { try KeyStore.hostKey("\(host):\(port)") }

    static func forget(host: String, port: Int) { try? KeyStore.setHostKey(nil, for: "\(host):\(port)") }

    static func pin(_ line: String, host: String, port: Int) throws {
        try KeyStore.setHostKey(line, for: "\(host):\(port)")
    }

    /// `SHA256:<base64>` like ssh-keygen -l.
    static func fingerprint(_ openSSHLine: String) -> String {
        let parts = openSSHLine.split(separator: " ")
        guard parts.count >= 2, let blob = Data(base64Encoded: String(parts[1])) else { return openSSHLine }
        let b64 = Data(SHA256.hash(data: blob)).base64EncodedString()
        return "SHA256:" + b64.replacingOccurrences(of: "=", with: "")
    }

    /// Validator for Citadel: accepts only the pinned key; an unknown host fails with `Unknown`
    /// so the app can show the fingerprint and pin it on approval.
    final class Validator: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
        let host: String, port: Int
        init(host: String, port: Int) { self.host = host; self.port = port }

        func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
            let line = String(openSSHPublicKey: hostKey)
            let known: String?
            do { known = try HostKeys.pinned(host: host, port: port) } catch {
                validationCompletePromise.fail(error); return
            }
            if let known {
                if known == line {
                    validationCompletePromise.succeed(())
                } else {
                    validationCompletePromise.fail(Mismatch(host: host, expected: HostKeys.fingerprint(known),
                                                            got: HostKeys.fingerprint(line)))
                }
            } else {
                validationCompletePromise.fail(Unknown(host: host, port: port, line: line))
            }
        }
    }
}
import Foundation
import Security
import Crypto
import Citadel

/// The app's SSH identity and saved passwords, in the Keychain
/// (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: never synced or backed up).
enum KeyStore {
    private static let service = "com.zzulanas.herdr.ssh"
    private static let keyAccount = "ed25519"

    enum KeyError: LocalizedError {
        case keychain(OSStatus)
        case badKey(String)
        var errorDescription: String? {
            switch self {
            case .keychain(let s): "Keychain error \(s)"
            case .badKey(let why): why
            }
        }
    }

    /// The signing key: a DEBUG override file, else the Keychain, else a new one (saved).
    static func signingKey() throws -> Curve25519.Signing.PrivateKey {
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment["HERDR_DEBUG_KEY_PATH"], !path.isEmpty {
            let text = try String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8)
            return try parseOpenSSH(text)
        }
        #endif
        if let raw = try read(account: keyAccount) {
            return try Curve25519.Signing.PrivateKey(rawRepresentation: raw)
        }
        let key = Curve25519.Signing.PrivateKey()
        try write(key.rawRepresentation, account: keyAccount)
        return key
    }

    /// OpenSSH one-line public key: `ssh-ed25519 AAAA… herdr-ios`.
    static func publicKeyLine() -> String {
        guard let key = try? signingKey() else { return "" }
        return publicKeyLine(for: key.publicKey)
    }

    static func publicKeyLine(for pub: Curve25519.Signing.PublicKey, comment: String = "herdr-ios") -> String {
        var blob = Data()
        func sshString(_ d: Data) {
            withUnsafeBytes(of: UInt32(d.count).bigEndian) { blob.append(contentsOf: $0) }
            blob.append(d)
        }
        sshString(Data("ssh-ed25519".utf8))
        sshString(pub.rawRepresentation)
        return "ssh-ed25519 \(blob.base64EncodedString()) \(comment)"
    }

    /// Replaces the app key with a pasted, unencrypted OpenSSH ed25519 private key.
    static func importPrivateKey(_ openSSHText: String) throws {
        let key = try parseOpenSSH(openSSHText)
        try write(key.rawRepresentation, account: keyAccount)
    }

    /// Generates a fresh key (the old one is gone for good).
    static func regenerateKey() throws {
        try write(Curve25519.Signing.PrivateKey().rawRepresentation, account: keyAccount)
    }

    /// A machine's own key, from pairing; nil when the machine uses the app key.
    static func machineKey(for machine: UUID) throws -> Curve25519.Signing.PrivateKey? {
        try read(account: "key." + machine.uuidString).map { try Curve25519.Signing.PrivateKey(rawRepresentation: $0) }
    }

    static func setMachineKey(_ key: Curve25519.Signing.PrivateKey?, for machine: UUID) throws {
        let account = "key." + machine.uuidString
        if let key { try write(key.rawRepresentation, account: account) } else { delete(account: account) }
    }

    static func parseOpenSSH(_ text: String) throws -> Curve25519.Signing.PrivateKey {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("BEGIN OPENSSH PRIVATE KEY") else {
            throw KeyError.badKey("That isn't an OpenSSH private key (it should start with -----BEGIN OPENSSH PRIVATE KEY-----)")
        }
        do {
            return try Curve25519.Signing.PrivateKey(sshEd25519: trimmed + "\n")
        } catch {
            throw KeyError.badKey("Couldn't read that key: only unencrypted ed25519 keys work (\(error))")
        }
    }

    // MARK: Passwords

    static func password(for machine: UUID) -> String? {
        (try? read(account: "pw." + machine.uuidString)).flatMap { $0.flatMap { String(data: $0, encoding: .utf8) } }
    }

    static func setPassword(_ password: String?, for machine: UUID) {
        let account = "pw." + machine.uuidString
        if let password, !password.isEmpty {
            try? write(Data(password.utf8), account: account)
        } else {
            delete(account: account)
        }
    }

    // MARK: Host keys

    /// nil only when nothing is pinned; a Keychain failure throws so it is never taken for a first connection.
    static func hostKey(_ hostPort: String) throws -> String? {
        try read(account: "hostkey." + hostPort).flatMap { String(data: $0, encoding: .utf8) }
    }

    static func setHostKey(_ line: String?, for hostPort: String) throws {
        let account = "hostkey." + hostPort
        if let line { try write(Data(line.utf8), account: account) } else { delete(account: account) }
    }

    // MARK: Keychain

    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private static func read(account: String) throws -> Data? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
        return out as? Data
    }

    /// Update in place, add only when missing: a failed write never loses the existing item.
    private static func write(_ data: Data, account: String) throws {
        let attrs: [String: Any] = [kSecValueData as String: data,
                                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        var status = SecItemUpdate(query(account) as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var q = query(account)
            for (k, v) in attrs { q[k] = v }
            status = SecItemAdd(q as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeyError.keychain(status) }
    }

    private static func delete(account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}
import Foundation
import HerdrKit
import Citadel
import Crypto
import NIOCore
import NIOSSH

/// `ByteTransport` over an SSH exec channel (no PTY) running
/// `herdrConnectCommand`, via Citadel.
final class CitadelTransport: ByteTransport, @unchecked Sendable {
    enum Auth {
        case key(Curve25519.Signing.PrivateKey)
        case password(String)
    }

    let host: String, port: Int, user: String
    private let auth: Auth
    private let lock = NSLock()
    private var client: SSHClient?
    private var writer: TTYStdinWriter?
    private var task: Task<Void, Never>?
    private var closed = false
    private var onClose: (@Sendable (Error?) -> Void)?

    init(host: String, port: Int, user: String, auth: Auth) {
        self.host = host; self.port = port; self.user = user; self.auth = auth
    }

    func start(onBytes: @escaping @Sendable (Data) -> Void,
               onStderr: @escaping @Sendable (Data) -> Void,
               onClose: @escaping @Sendable (Error?) -> Void) async throws {
        let method: SSHAuthenticationMethod = switch auth {
        case .key(let k): .ed25519(username: user, privateKey: k)
        case .password(let p): .passwordBased(username: user, password: p)
        }
        let client: SSHClient
        do {
            client = try await SSHClient.connect(
                host: host, port: port, authenticationMethod: method,
                hostKeyValidator: .custom(HostKeys.Validator(host: host, port: port)),
                reconnect: .never, connectTimeout: .seconds(12))
        } catch {
            throw Self.friendly(error, host: host, user: user)
        }
        let isClosed: Bool = lock.withLock {
            self.client = client; self.onClose = onClose; return closed
        }
        if isClosed { try? await client.close(); throw HerdrError(code: -1, kind: "closed", message: "Disconnected") }

        // The exec channel lives in this task; `start` returns once stdin is writable.
        try await withCheckedThrowingContinuation { (ready: CheckedContinuation<Void, Error>) in
            let readyOnce = Once(ready)
            let t = Task.detached { [weak self] in
                var failure: Error?
                do {
                    try await client.withExec(herdrConnectCommand) { inbound, outbound in
                        self?.lock.withLock { self?.writer = outbound }
                        readyOnce.resume(.success(()))
                        for try await out in inbound {
                            switch out {
                            case .stdout(let b): onBytes(Data(b.readableBytesView))
                            case .stderr(let b): onStderr(Data(b.readableBytesView))
                            }
                        }
                    }
                } catch let e as SSHClient.CommandFailed where e.exitCode == 127 {
                    failure = HerdrError(code: -1, kind: "not_installed", message: "herdr-core is not installed on this machine",
                                         hint: "install herdr-core in ~/.local/bin")
                } catch is CancellationError {
                } catch {
                    failure = error
                }
                readyOnce.resume(.failure(failure ?? HerdrError.lost))
                self?.finish(failure)
            }
            lock.withLock { task = t }
        }
    }

    func write(_ data: Data) async throws {
        guard let w = lock.withLock({ closed ? nil : writer }) else { throw HerdrError.lost }
        try await w.write(ByteBuffer(bytes: data))
    }

    func close() {
        let (t, c, cb): (Task<Void, Never>?, SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
            guard !closed else { return (nil, nil, nil) }
            closed = true
            defer { onClose = nil; writer = nil }
            return (task, client, onClose)
        }
        t?.cancel()
        if let c { Task.detached { try? await c.close() } }
        cb?(nil)
    }

    private func finish(_ err: Error?) {
        let (c, cb): (SSHClient?, (@Sendable (Error?) -> Void)?) = lock.withLock {
            guard !closed else { return (nil, nil) }
            closed = true
            defer { onClose = nil; writer = nil }
            return (client, onClose)
        }
        if let c { Task.detached { try? await c.close() } }
        cb?(err)
    }

    /// SSH failures in words a person can act on.
    static func friendly(_ error: Error, host: String, user: String) -> Error {
        if error is HostKeys.Mismatch || error is HostKeys.Unknown || error is KeyStore.KeyError { return error }
        if let e = error as? SSHClientError, case .allAuthenticationOptionsFailed = e {
            return HerdrError(code: -1, kind: "auth", message: "\(host) didn't accept the login for \(user)",
                              hint: "add this app's public key to ~/.ssh/authorized_keys, or use a password")
        }
        let text = String(describing: error)
        if text.contains("connectTimeout") || text.contains("timeout") || text.contains("Timeout") {
            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "is Tailscale connected?")
        }
        if text.contains("connectionRefused") || text.contains("Connection refused") {
            return HerdrError(code: -1, kind: "unreachable", message: "\(host) refused the SSH connection", hint: "is sshd running on port 22?")
        }
        if text.contains("NIOConnectionError") || text.contains("unreachable") || text.contains("resolve") {
            return HerdrError(code: -1, kind: "unreachable", message: "Couldn't reach \(host)", hint: "check the address and your network")
        }
        return HerdrError(code: -1, kind: "ssh", message: "SSH to \(host) failed", hint: text)
    }
}

/// Resumes a continuation at most once.
private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var cont: CheckedContinuation<Void, Error>?
    init(_ c: CheckedContinuation<Void, Error>) { cont = c }
    func resume(_ r: Result<Void, Error>) {
        let c: CheckedContinuation<Void, Error>? = lock.withLock { defer { cont = nil }; return cont }
        c?.resume(with: r)
    }
}
App/Sources/Store/AppStore.swift:205:    func pair(_ offer: PairingOffer) throws {
Packages/HerdrKit/Sources/HerdrKit/Pairing.swift:10:public struct PairingOffer: Equatable, Sendable {
Packages/HerdrKit/Sources/HerdrKit/Pairing.swift:30:    public static func decode(_ text: String) throws -> PairingOffer {
Packages/HerdrKit/Sources/HerdrKit/Pairing.swift:44:        return PairingOffer(host: host, port: port, user: user, hostKey: "ssh-ed25519 " + k, seed: seed)
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:343:        return PairingOffer.prefix + b64
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:349:        let o = try PairingOffer.decode(code(["v": 2, "h": "100.64.0.9", "p": 2222, "u": "me", "k": k, "s": s]) + "\n")
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:350:        XCTAssertEqual(o, PairingOffer(host: "100.64.0.9", port: 2222, user: "me", hostKey: "ssh-ed25519 " + k, seed: Data(repeating: 9, count: 32)))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:354:        XCTAssertThrowsError(try PairingOffer.decode("orca://pair?code=abc"))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:355:        XCTAssertThrowsError(try PairingOffer.decode(PairingOffer.prefix + "!!!"))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:356:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 1, "h": "h", "u": "u", "k": k, "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:357:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "", "u": "u", "k": k, "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:358:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": "AAAA", "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:359:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "p": 0, "u": "u", "k": k, "s": s])))
Packages/HerdrKit/Tests/HerdrKitTests/HerdrKitTests.swift:360:        XCTAssertThrowsError(try PairingOffer.decode(code(["v": 2, "h": "h", "u": "u", "k": k, "s": "nope"])))
App/Sources/UI/ConnectionViews.swift:381:            try store.pair(PairingOffer.decode(text))
App/Sources/UI/ConnectionViews.swift:417:                guard !done, let s = b.payloadStringValue, s.hasPrefix(PairingOffer.prefix) else { continue }
import Foundation

/// Untyped JSON, as the core speaks it. Keeps unknown fields so documents
/// written back to the core lose nothing.
public enum JSONValue: Equatable, Hashable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public subscript(key: String) -> JSONValue {
        get {
            if case .object(let o) = self { return o[key] ?? .null }
            return .null
        }
        set {
            var o = object ?? [:]
            o[key] = newValue
            self = .object(o)
        }
    }
    public subscript(index: Int) -> JSONValue {
        if case .array(let a) = self, a.indices.contains(index) { return a[index] }
        return .null
    }
    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var double: Double? { if case .number(let n) = self { return n }; return nil }
    public var int: Int? { double.flatMap { $0.isFinite ? Int(exactly: $0.rounded(.towardZero)) : nil } }
    public var uint64: UInt64? { double.flatMap { $0.isFinite ? UInt64(exactly: max(0, $0).rounded(.towardZero)) : nil } }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var array: [JSONValue]? { if case .array(let a) = self { return a }; return nil }
    public var object: [String: JSONValue]? { if case .object(let o) = self { return o }; return nil }
    public var isNull: Bool { self == .null }

    /// Removes `key` from an object (no-op otherwise).
    public mutating func removeValue(forKey key: String) {
        guard case .object(var o) = self else { return }
        o.removeValue(forKey: key)
        self = .object(o)
    }

    /// Compact JSON text, for logs and debugging.
    public var jsonString: String { String(decoding: encoded(), as: UTF8.self) }

    public init(any: Any?) {
        switch any {
        case nil, is NSNull: self = .null
        case let n as NSNumber:
            if CFGetTypeID(n) == CFBooleanGetTypeID() { self = .bool(n.boolValue) } else { self = .number(n.doubleValue) }
        case let s as String: self = .string(s)
        case let a as [Any]: self = .array(a.map { JSONValue(any: $0) })
        case let o as [String: Any]: self = .object(o.mapValues { JSONValue(any: $0) })
        default: self = .null
        }
    }

    public var any: Any {
        switch self {
        case .null: return NSNull()
        case .bool(let b): return b
        case .number(let n): return n.rounded() == n && abs(n) < 9e15 ? Int64(n) as Any : n
        case .string(let s): return s
        case .array(let a): return a.map { $0.any }
        case .object(let o): return o.mapValues { $0.any }
        }
    }

    public static func parse(_ data: Data) throws -> JSONValue {
        JSONValue(any: try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]))
    }
    public func encoded() -> Data {
        (try? JSONSerialization.data(withJSONObject: any, options: [.fragmentsAllowed, .withoutEscapingSlashes])) ?? Data("null".utf8)
    }
}

extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral,
    ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByNilLiteral, ExpressibleByFloatLiteral {
    public init(stringLiteral v: String) { self = .string(v) }
    public init(integerLiteral v: Int) { self = .number(Double(v)) }
    public init(floatLiteral v: Double) { self = .number(v) }
    public init(booleanLiteral v: Bool) { self = .bool(v) }
    public init(arrayLiteral e: JSONValue...) { self = .array(e) }
    public init(dictionaryLiteral e: (String, JSONValue)...) { self = .object(Dictionary(e, uniquingKeysWith: { $1 })) }
    public init(nilLiteral: ()) { self = .null }
}
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HerdrKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [.library(name: "HerdrKit", targets: ["HerdrKit"])],
    targets: [
        .target(name: "HerdrKit", swiftSettings: [.swiftLanguageMode(.v5)]),
        .executableTarget(name: "herdr-probe", dependencies: ["HerdrKit"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "HerdrKitTests", dependencies: ["HerdrKit"], resources: [.copy("Fixtures")], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
c06c272 Shrink the pairing QR code by sending the Ed25519 seed instead of an OpenSSH key file
9f0c383 Refuse codes that would replace a pinned host key, and harden pair.sh
2f98a3b Pair a phone by scanning a QR code from scripts/pair.sh

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
オフセット161は、スクリプトが生成する非暗号化・単一Ed25519鍵の構造と一致しています。ホスト鍵の再構成後も、既存のpinとの比較とSSH接続時の検証が維持されています。残る確認は、CryptoKitと既存のCrypto型の互換性、および入力検証の変更による影響です。
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg --files /Users/yosuke/Library/Developer/Xcode/DerivedData /Users/yosuke/Library/Caches/org.swift.swiftpm 2>/dev/null | rg '/(Crypto\\.swift|Ed25519\\.swift|Package\\.swift|PROTOCOL\\.key)"'$'"' | head -n 35; nl -ba scripts/pair.sh | sed -n '34,66p'; nl -ba Packages/HerdrKit/Sources/HerdrKit/Pairing.swift | sed -n '28,53p'; sed -n '330,430p' App/Sources/UI/ConnectionViews.swift; cat project.yml | head -n 110; git show c06c272"'^:Packages/HerdrKit/Sources/HerdrKit/Pairing.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 24ms:
    34	dir="$(mktemp -d)"
    35	cleanup() { rm -f "$dir/key" "$dir/key.pub"; rmdir "$dir" 2>/dev/null || true; }
    36	trap cleanup EXIT
    37	# EXIT alone is skipped when a signal ends sh; the private key must not outlive the script.
    38	trap 'cleanup; exit 1' HUP INT TERM
    39	ssh-keygen -q -t ed25519 -N "" -C "$name" -f "$dir/key"
    40	
    41	pub="$(cat "$dir/key.pub")"
    42	[ "$(wc -l < "$dir/key.pub")" -eq 1 ] || { echo "unexpected public key file" >&2; exit 1; }
    43	mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    44	auth="$HOME/.ssh/authorized_keys"
    45	# A last line without a newline would swallow ours.
    46	if [ -s "$auth" ] && [ -n "$(tail -c 1 "$auth")" ]; then echo >> "$auth"; fi
    47	# restrict: no forwarding, agent or pty; command=: the key can only start herdr-core connect.
    48	printf 'restrict,command="%s connect" %s\n' "$core" "$pub" >> "$auth"
    49	chmod 600 "$auth"
    50	
    51	json() { printf '%s' "$1" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); gsub(/\t/,"\\t"); gsub(/\r/,"\\r"); if (NR>1) print "\\n"; print}'; }
    52	# The 32-byte Ed25519 seed sits at a fixed offset in an unencrypted OpenSSH ed25519 key file (the comment comes after it).
    53	seed="$(sed '1d;$d' "$dir/key" | tr -d '\n' | base64 -d | dd bs=1 skip=161 count=32 2>/dev/null | base64 | tr -d '\n')"
    54	[ "${#seed}" -eq 44 ] || { echo "couldn't read the new key" >&2; exit 1; }
    55	payload="{\"v\":2,\"h\":\"$(json "$host")\",\"p\":$port,\"u\":\"$(json "$user")\",\"k\":\"$hostkey\",\"s\":\"$seed\"}"
    56	code="herdr-pair:$(printf '%s' "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')"
    57	
    58	if [ "${HERDR_PAIR_PRINT:-}" = 1 ]; then printf '%s\n' "$code"; exit 0; fi
    59	
    60	printf '%s' "$code" | qr
    61	echo "Scan this in herdr-pocket (Add machine → Scan pairing code) to reach $user@$host."
    62	echo "Authorized as \"$name\" in ~/.ssh/authorized_keys. Anyone who photographs this code can connect;"
    63	printf 'press Enter when the phone is paired to clear the screen. '
    64	read -r _ || true
    65	clear 2>/dev/null || printf '\033[2J\033[H'
    28	    }
    29	
    30	    public static func decode(_ text: String) throws -> PairingOffer {
    31	        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    32	        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
    33	        guard let data = base64url(String(s.dropFirst(prefix.count))), let v = try? JSONValue.parse(data) else {
    34	            throw Invalid(reason: "the code is damaged")
    35	        }
    36	        guard v["v"].int == 2 else { throw Invalid(reason: "made by a different pair.sh") }
    37	        guard let host = v["h"].string, !host.isEmpty, let user = v["u"].string, !user.isEmpty else {
    38	            throw Invalid(reason: "no host or user")
    39	        }
    40	        let port = v["p"].int ?? 22
    41	        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
    42	        guard let k = v["k"].string, let blob = Data(base64Encoded: k), blob.count == 51 else { throw Invalid(reason: "no ed25519 host key") }
    43	        guard let sb = v["s"].string, let seed = Data(base64Encoded: sb), seed.count == 32 else { throw Invalid(reason: "no key") }
    44	        return PairingOffer(host: host, port: port, user: user, hostKey: "ssh-ed25519 " + k, seed: seed)
    45	    }
    46	
    47	    private static func base64url(_ s: String) -> Data? {
    48	        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    49	        b += String(repeating: "=", count: (4 - b.count % 4) % 4)
    50	        return Data(base64Encoded: b)
    51	    }
    52	}
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { editing = false } } }
            }
            .presentationDetents([.large])
        }
    }
}

// MARK: Pairing

/// Adds a machine from the code `scripts/pair.sh` shows on it: scanned with the camera, or pasted.
struct PairingCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var scanning = false
    @State private var code = ""
    @State private var error: String?

    var body: some View {
        SectionLabel(title: "Pair with a code")
        VStack(alignment: .leading, spacing: 12) {
            Text("On the machine, run scripts/pair.sh from herdr-pocket. It authorizes a key for herdr-core only and shows a QR code.")
                .font(HF.ui(14)).foregroundStyle(HC.muted)
            if PairingScanner.available {
                Button { scanning = true } label: {
                    Label("Scan pairing code", systemImage: "qrcode.viewfinder").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
            HStack(spacing: 10) {
                TextField("or paste herdr-pair:…", text: $code)
                    .font(HF.mono(13)).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("pairingCode")
                Button("Pair") { use(code) }.buttonStyle(.glass).disabled(code.isEmpty)
            }
            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill").font(HF.ui(13.5)).foregroundStyle(HC.blocked)
            }
        }
        .padding(14)
        .herdrCard()
        .fullScreenCover(isPresented: $scanning) {
            PairingScanner { text in scanning = false; use(text) }
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Button("Cancel", systemImage: "xmark") { scanning = false }.buttonStyle(.glass).padding(20)
                }
        }
    }

    private func use(_ text: String) {
        do {
            try store.pair(PairingOffer.decode(text))
            error = nil
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}



/// The camera, reporting the first QR code it reads.
struct PairingScanner: UIViewControllerRepresentable {
    var onCode: (String) -> Void

    static var available: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .accurate,
                                           isHighlightingEnabled: true)
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        private var done = false
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ scanner: DataScannerViewController, didAdd items: [RecognizedItem], allItems: [RecognizedItem]) {
            for case .barcode(let b) in items {
                guard !done, let s = b.payloadStringValue, s.hasPrefix(PairingOffer.prefix) else { continue }
                done = true
                scanner.stopScanning()
                onCode(s)
            }
        }
    }
}
name: Herdr
options:
  bundleIdPrefix: dev.herdr
  deploymentTarget:
    iOS: "26.0"
  createIntermediateGroups: true
settings:
  base:
    CODE_SIGN_STYLE: Automatic
    SWIFT_VERSION: "5.0"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
packages:
  HerdrKit:
    path: Packages/HerdrKit
  Citadel:
    url: https://github.com/orlandos-nl/Citadel
    exactVersion: 0.12.1
  SwiftTerm:
    url: https://github.com/migueldeicaza/SwiftTerm
    exactVersion: 1.20.0
targets:
  Herdr:
    type: application
    platform: iOS
    configFiles:
      Debug: Config/Base.xcconfig
      Release: Config/Base.xcconfig
    sources:
      - path: App/Sources
      - path: App/Resources
        buildPhase: resources
        excludes: ["Mods/**", "Mods"]
      - path: App/Resources/Mods
        type: folder
        buildPhase: resources
    dependencies:
      - package: HerdrKit
      - package: Citadel
      - package: SwiftTerm
    info:
      path: App/Info.plist
      properties:
        CFBundleDisplayName: Herdr
        UILaunchScreen: {}
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: true
        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]
        UISupportedInterfaceOrientations~ipad: [UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]
        NSLocalNetworkUsageDescription: "Herdr connects to your machines over SSH on your network."
        NSCameraUsageDescription: "Herdr scans the pairing code that scripts/pair.sh shows on your machine."
        UIAppFonts: [Geist-Regular.ttf, Geist-Medium.ttf, Geist-SemiBold.ttf, Geist-Bold.ttf, Geist-Italic.ttf, Geist-SemiBoldItalic.ttf, JetBrainsMono-Variable.ttf, JetBrainsMono-Italic-Variable.ttf, SymbolsNerdFont-Regular.ttf]
        ITSAppUsesNonExemptEncryption: false
    preBuildScripts:
      - name: Bundle mods
        script: "\"${SRCROOT}/scripts/bundle-mods.sh\" || echo 'warning: mod bundling failed; using last bundled copies'"
        basedOnDependencyAnalysis: false
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $(HERDR_BUNDLE_ID)
        CODE_SIGN_ENTITLEMENTS: $(HERDR_ENTITLEMENTS)
        TARGETED_DEVICE_FAMILY: "1,2"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ENABLE_USER_SCRIPT_SANDBOXING: NO
  HerdrUITests:
    type: bundle.ui-testing
    platform: iOS
    configFiles:
      Debug: Config/Base.xcconfig
      Release: Config/Base.xcconfig
    sources: [UITests]
    dependencies:
      - target: Herdr
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $(HERDR_BUNDLE_ID).uitests
        TEST_TARGET_NAME: Herdr
        GENERATE_INFOPLIST_FILE: YES
schemes:
  Herdr:
    build:
      targets:
        Herdr: all
        HerdrUITests: [test]
    test:
      targets: [HerdrUITests]
import Foundation

/// What `scripts/pair.sh` puts in its QR code: everything a phone needs to reach `herdr-core connect`
/// on a box over SSH. The box made the key pair and authorized the public half for that command only,
/// so nothing goes back from the phone.
///
/// Text form: `herdr-pair:` + base64url(JSON `{"v":1,"host","port","user","hostKey","key"}`).
public struct PairingOffer: Equatable, Sendable {
    public var host: String
    public var port: Int
    public var user: String
    /// The box's host key, `ssh-ed25519 AAAA…`, pinned before the first connect.
    public var hostKey: String
    /// The phone's private key, unencrypted OpenSSH text.
    public var privateKey: String

    public static let prefix = "herdr-pair:"

    public init(host: String, port: Int, user: String, hostKey: String, privateKey: String) {
        self.host = host; self.port = port; self.user = user; self.hostKey = hostKey; self.privateKey = privateKey
    }

    public struct Invalid: LocalizedError, Equatable {
        public var reason: String
        public var errorDescription: String? { "Not a herdr pairing code: \(reason)." }
    }

    public static func decode(_ text: String) throws -> PairingOffer {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix(prefix) else { throw Invalid(reason: "it should start with \(prefix)") }
        var b64 = String(s.dropFirst(prefix.count)).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
        guard let data = Data(base64Encoded: b64), let v = try? JSONValue.parse(data) else { throw Invalid(reason: "the code is damaged") }
        guard v["v"].int == 1 else { throw Invalid(reason: "made by a newer pair.sh") }
        guard let host = v["host"].string, !host.isEmpty, let user = v["user"].string, !user.isEmpty else {
            throw Invalid(reason: "no host or user")
        }
        let port = v["port"].int ?? 22
        guard (1...65535).contains(port) else { throw Invalid(reason: "bad port") }
        guard let hostKey = v["hostKey"].string, hostKey.hasPrefix("ssh-"), hostKey.split(separator: " ").count == 2 else {
            throw Invalid(reason: "no host key")
        }
        guard let key = v["key"].string, key.contains("BEGIN OPENSSH PRIVATE KEY") else { throw Invalid(reason: "no key") }
        return PairingOffer(host: host, port: port, user: user, hostKey: hostKey, privateKey: key)
    }
}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: https://raw.githubusercontent.com/openssh/openssh-portable/master/PROTOCOL.key
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
web search: 
web search: https://raw.githubusercontent.com/apple/swift-crypto/main/Sources/Crypto/Exports.swift
hook: PostToolUse
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'sh -n scripts/pair.sh; rg --files Packages/HerdrKit/.build 2>/dev/null | head -n 12; git diff --quiet; git status --short' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
Packages/HerdrKit/.build/CACHEDIR.TAG
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/v1.1/data.v1
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/v1.1/index.v1.shared
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/v1.1/actions.v1
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/v1.1/actions.v1.shared
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/v1.1/data.v1.shared
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/v1.1/index.v1
Packages/HerdrKit/.build/out/CompilationCache.noindex/generic/lock
Packages/HerdrKit/.build/out/ModuleCache.noindex/1BG7ACTO79T0I/CoreFoundation-16SA8WK3L6MQN.pcm
Packages/HerdrKit/.build/out/ModuleCache.noindex/1BG7ACTO79T0I/DeveloperToolsSupport-3SUCMSK9ZS2JA.pcm
Packages/HerdrKit/.build/out/ModuleCache.noindex/1BG7ACTO79T0I/Spatial-1JZLH83HN83CS.pcm
Packages/HerdrKit/.build/out/ModuleCache.noindex/1BG7ACTO79T0I/_DarwinFoundation3-2NSGASPTSNBVQ.pcm
?? docs/reviews/2026-11-02-pairing-v2-codex.md

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
c06c272で導入された、報告すべき正確性・セキュリティ上の不具合は見つかりませんでした。

未確認：ビルド、テスト実行、実機でのQR読み取りからSSH接続までの動作。静的レビューの結果です。
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
50,454
c06c272で導入された、報告すべき正確性・セキュリティ上の不具合は見つかりませんでした。

未確認：ビルド、テスト実行、実機でのQR読み取りからSSH接続までの動作。静的レビューの結果です。
