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
session id: 01a198a6-8d11-7722-822c-4a13ebb005e2
--------
user
Review the commits 6dd9552, 83f9b36 and 27db4e9 in this repo (git show each). They make Files and Changes follow the terminal on screen and the project root, add name/content search to Files (FilesView.searchScript), replace the Chat/Terminal picker, and change Chat loading: TranscriptScript and CodexTranscriptScript now send only the last KEEP entries of a fresh window and accept a <before> argument for earlier windows; ChatModel.loadEarlier prepends them with stable ids. Look for correctness and security bugs. Report findings only; do not edit.
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
指定された3コミットをそれぞれ `git show` で確認し、関連する呼び出し元とテストを追って、正確性・セキュリティの不具合をレビューします。`ponytail-review` の手順を使い、ファイルは変更しません。

hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.codex/plugins/cache/ponytail/ponytail/5.3.3/skills/ponytail-review/SKILL.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
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

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'git status --short; git show --stat 6dd9552; git show --stat 83f9b36; git show --stat 27db4e9' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
?? docs/reviews/2026-11-02-files-search-chat-window-codex.md
commit 6dd95522efe72edbc51222a0d9d2aaeca413df0d
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:35:58 2026 +0900

    Open Files and Changes where the space's terminal is, not where the space was created
    
    A space keeps the folder it was made with; after cd in its terminal, Files showed
    the old folder (a space named irireshi listed ararat). New tabs already start from
    the terminal's live folder, so Files and Changes now use the same rule.

 App/Sources/Store/AppStore.swift | 2 +-
 App/Sources/UI/SpaceView.swift   | 4 ++--
 README.ja.md                     | 2 +-
 README.md                        | 2 +-
 4 files changed, 5 insertions(+), 5 deletions(-)
commit 83f9b361bd4a54d2ff4e040f3069fc3a99e1c9d2
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 02:11:29 2026 +0900

    Follow the terminal on screen in Files, add name and content search, and use one button to switch Chat and Terminal
    
    Files and Changes open the folder of the pane the phone shows, as the desktop Herdr app
    follows the focused terminal. The search bar finds names or text under the current folder,
    using git's file list (so .gitignore applies) and capped at 200 results or 8 seconds.
    The segmented Chat/Terminal picker drew a second capsule inside the iOS 26 toolbar glass.

 App/Sources/Chat/AgentScreen.swift |   9 ++-
 App/Sources/UI/FilesView.swift     | 128 ++++++++++++++++++++++++++++++++++++-
 App/Sources/UI/SpaceView.swift     |  16 ++++-
 README.ja.md                       |   2 +-
 README.md                          |   2 +-
 5 files changed, 145 insertions(+), 12 deletions(-)
commit 27db4e9768c34326a25bf93c688f995432e9cf96
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 04:46:26 2026 +0900

    Open Chat with the last 150 entries, load earlier ones on request, show Chat on space cards, and add Files and Changes to the agent page
    
    Opening Chat sent up to 16 MiB of parsed transcript (about 700 KB, 930 entries here) and
    laid it all out; the box still reads 16 MiB in 0.3 s, but now sends only the last 150
    entries and fetches the 150 before them when asked. Turn ids come from entry sequence
    numbers so loading earlier entries does not renumber what is shown.
    Files and Changes open at the git root of the agent process's folder, which does not
    move when the agent runs cd in its child shells; the space page uses the same root.

 App/Sources/Chat/AgentScreen.swift                 | 13 +++++
 App/Sources/Chat/ChatModel.swift                   | 57 +++++++++++++++++-----
 App/Sources/Chat/ChatView.swift                    | 12 ++++-
 App/Sources/Chat/CodexTranscriptScript.swift       | 25 ++++++++--
 App/Sources/Chat/TranscriptScript.swift            | 32 +++++++++---
 App/Sources/Store/AppStore.swift                   | 16 ++++++
 App/Sources/UI/ChangesView.swift                   | 11 +----
 App/Sources/UI/FilesView.swift                     | 13 ++++-
 App/Sources/UI/SpaceView.swift                     | 54 +++++++++++++++++---
 README.ja.md                                       |  4 +-
 README.md                                          |  4 +-
 UITests/HerdrUITests.swift                         | 24 +++++++++
 docs/2026-11-02_agent-and-space-views-design.ja.md | 44 +++++++++++++++++
 docs/2026-11-02_agent-and-space-views-design.md    | 44 +++++++++++++++++
 14 files changed, 305 insertions(+), 48 deletions(-)

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat /Users/yosuke/.claude/skills/style-guide/references/phrasing.md' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
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

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse
hook: PreToolUse Completed
hook: PreToolUse Completed
hook: PreToolUse Completed
exec
/bin/zsh -lc 'git show 83f9b36 -- App/Sources UITests' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
exec
/bin/zsh -lc 'git show 6dd9552 -- App/Sources UITests' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 6dd95522efe72edbc51222a0d9d2aaeca413df0d
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:35:58 2026 +0900

    Open Files and Changes where the space's terminal is, not where the space was created
    
    A space keeps the folder it was made with; after cd in its terminal, Files showed
    the old folder (a space named irireshi listed ararat). New tabs already start from
    the terminal's live folder, so Files and Changes now use the same rule.

diff --git a/App/Sources/Store/AppStore.swift b/App/Sources/Store/AppStore.swift
index fdaf8c8..e9b975a 100644
--- a/App/Sources/Store/AppStore.swift
+++ b/App/Sources/Store/AppStore.swift
@@ -798,7 +798,7 @@ final class AppStore {
     }
 
     /// The selected tab's first terminal's live folder, else the space folder, else home.
-    private func startFolder(for space: SpaceRef) -> String {
+    func startFolder(for space: SpaceRef) -> String {
         let tab = selectedTabBySpace[space.id].flatMap { id in space.tabs.first { $0.id == id } } ?? space.tabs.first
         if let addr = tab?.panes.compactMap(\.terminal).first, let cwd = terminals[addr]?.cwd, !cwd.isEmpty { return cwd }
         return space.folder.isEmpty ? home : space.folder
diff --git a/App/Sources/UI/SpaceView.swift b/App/Sources/UI/SpaceView.swift
index 34189ab..3f57afa 100644
--- a/App/Sources/UI/SpaceView.swift
+++ b/App/Sources/UI/SpaceView.swift
@@ -92,8 +92,8 @@ struct SpaceView: View {
                     .accessibilityLabel("New agent in this space")
             }
         }
-        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
-        .sheet(isPresented: $showChanges) { ChangesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
+        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
+        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
         .onAppear { store.selectedSpaceID = space.id }
     }
 }

 succeeded in 0ms:
commit 83f9b361bd4a54d2ff4e040f3069fc3a99e1c9d2
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 02:11:29 2026 +0900

    Follow the terminal on screen in Files, add name and content search, and use one button to switch Chat and Terminal
    
    Files and Changes open the folder of the pane the phone shows, as the desktop Herdr app
    follows the focused terminal. The search bar finds names or text under the current folder,
    using git's file list (so .gitignore applies) and capped at 200 results or 8 seconds.
    The segmented Chat/Terminal picker drew a second capsule inside the iOS 26 toolbar glass.

diff --git a/App/Sources/Chat/AgentScreen.swift b/App/Sources/Chat/AgentScreen.swift
index 3b2a4f7..0515dac 100644
--- a/App/Sources/Chat/AgentScreen.swift
+++ b/App/Sources/Chat/AgentScreen.swift
@@ -20,13 +20,12 @@ struct AgentScreen: View {
         }
         .toolbar {
             if canChat {
+                // Why not a segmented Picker: iOS 26 draws it as a second capsule inside the toolbar's glass.
                 ToolbarItem(placement: .topBarTrailing) {
-                    Picker("View", selection: $mode.animation(.smooth(duration: 0.25))) {
-                        Image(systemName: "text.bubble").tag("chat").accessibilityLabel("Chat")
-                        Image(systemName: "terminal").tag("terminal").accessibilityLabel("Terminal")
+                    let chat = mode == "chat"
+                    Button(chat ? "Terminal" : "Chat", systemImage: chat ? "terminal" : "text.bubble") {
+                        withAnimation(.smooth(duration: 0.25)) { mode = chat ? "terminal" : "chat" }
                     }
-                    .pickerStyle(.segmented)
-                    .frame(width: 92)
                 }
             }
         }
diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
index 5644bac..55226a4 100644
--- a/App/Sources/UI/FilesView.swift
+++ b/App/Sources/UI/FilesView.swift
@@ -14,9 +14,17 @@ struct FilesView: View {
         var name: String
         var isDir: Bool
         var size: Int
+        /// A Contents search's first matching line.
+        var snippet: String? = nil
         var id: String { name }
     }
 
+    enum Scope: Hashable { case names, contents }
+
+    @State private var query = ""
+    @State private var scope = Scope.names
+    @State private var results: [Entry]?
+    @State private var partial = false
     @State private var dir: String?
     @State private var entries: [Entry] = []
     @State private var skipped = 0
@@ -78,11 +86,91 @@ struct FilesView: View {
     sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
     """
 
+    // Prints {"results": [[relative path, is_dir, size, snippet]], "partial"}: names (folders too) or text lines
+    // containing argv[2], case-insensitively, under argv[1]. Stops at 200 results or 8 seconds.
+    static let searchScript = """
+    import json, os, stat, subprocess, sys, time
+    root, q, mode = sys.argv[1], sys.argv[2].lower(), sys.argv[3]
+
+    def paths():
+        # In a git work tree, what git lists (tracked and untracked, minus .gitignore), with their folders.
+        try:
+            r = subprocess.run(["git", "-C", root, "ls-files", "-co", "--exclude-standard", "-z"], capture_output=True, timeout=10)
+        except (OSError, subprocess.TimeoutExpired):
+            r = None
+        if r is not None and r.returncode == 0:
+            seen = set()
+            for p in sorted(os.fsdecode(x) for x in r.stdout.split(b"\\0") if x):
+                parts = p.split("/")
+                for i in range(1, len(parts)):
+                    d = "/".join(parts[:i])
+                    if d not in seen:
+                        seen.add(d)
+                        yield d, True
+                yield p, False
+            return
+        # shortcut: outside git, prunes a fixed list of heavy folders; read ignore files if results get noisy.
+        skip = {".git", "node_modules", ".venv", "__pycache__", ".build", "DerivedData", ".direnv"}
+        for d, dirs, files in os.walk(root):
+            dirs[:] = sorted(x for x in dirs if x not in skip)
+            rel = os.path.relpath(d, root)
+            for n, isdir in [(x, True) for x in dirs] + [(x, False) for x in sorted(files)]:
+                yield (n if rel == "." else os.path.join(rel, n)), isdir
+
+    out, start, partial = [], time.monotonic(), False
+    for p, isdir in paths():
+        if time.monotonic() - start > 8:
+            partial = True
+            break
+        if isdir and mode != "names":
+            continue
+        try:
+            p.encode("utf-8")
+            full = os.path.join(root, p)
+            if mode == "names":
+                if q not in os.path.basename(p).lower():
+                    continue
+                out.append([p, isdir, 0 if isdir else os.lstat(full).st_size, None])
+            else:
+                st = os.stat(full)
+                if not stat.S_ISREG(st.st_mode) or st.st_size > 1 << 20:
+                    continue
+                with open(full, "rb") as f:
+                    data = f.read()
+                if b"\\0" in data[:8192]:
+                    continue
+                line = next((l for l in data.decode("utf-8", "replace").splitlines() if q in l.lower()), None)
+                if line is None:
+                    continue
+                out.append([p, False, st.st_size, line.strip()[:200]])
+        except (OSError, UnicodeEncodeError):
+            continue
+        if len(out) >= 200:
+            partial = True
+            break
+    print(json.dumps({"results": out, "partial": partial}))
+    """
+
     var body: some View {
         List {
             if let error {
                 Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
             }
+            if !query.isEmpty {
+                if let results {
+                    if results.isEmpty { Text("No matches.").font(HF.ui(14)).foregroundStyle(HC.dim) }
+                    ForEach(results) { e in
+                        if e.isDir, let dir {
+                            NavigationLink(value: dir + "/" + e.name) { row(e) }
+                        } else {
+                            Button { open(e) } label: { row(e) }.disabled(opening != nil)
+                        }
+                    }
+                    if partial { Text("Showing the first matches only.").font(HF.ui(13)).foregroundStyle(HC.dim) }
+                } else {
+                    HStack { Spacer(); ProgressView(); Spacer() }
+                }
+            } else {
             ForEach(entries) { e in
                 if e.isDir, let dir {
                     NavigationLink(value: dir + "/" + e.name) { row(e) }
@@ -95,10 +183,17 @@ struct FilesView: View {
                 Text("\(skipped) item(s) with names that can't be shown are hidden.")
                     .font(HF.ui(13)).foregroundStyle(HC.dim)
             }
+            }
         }
         .overlay { if dir == nil && error == nil { ProgressView() } }
         .navigationTitle(title)
         .navigationBarTitleDisplayMode(.inline)
+        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find files")
+        .searchScopes($scope) {
+            Text("Names").tag(Scope.names)
+            Text("Contents").tag(Scope.contents)
+        }
+        .task(id: "\(scope)\u{0}\(query)\u{0}\(dir ?? "")") { await search() }
         .task { await load() }
         .refreshable { await load() }
         .quickLookPreview($preview)
@@ -131,7 +226,10 @@ struct FilesView: View {
             Image(systemName: e.isDir ? "folder" : "doc")
                 .foregroundStyle(e.isDir ? HC.working : HC.muted)
                 .frame(width: 22)
-            Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1)
+            VStack(alignment: .leading, spacing: 2) {
+                Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1).truncationMode(.head)
+                if let s = e.snippet { Text(s).font(HF.mono(12)).foregroundStyle(HC.dim).lineLimit(2) }
+            }
             Spacer(minLength: 8)
             if opening == e.name {
                 if let progress { Text(progress).font(HF.ui(13)).foregroundStyle(HC.dim).monospacedDigit() }
@@ -168,6 +266,29 @@ struct FilesView: View {
         }
     }
 
+    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
+    private func search() async {
+        results = nil; partial = false
+        let q = query.trimmingCharacters(in: .whitespaces)
+        guard !q.isEmpty, let dir else { return }
+        try? await Task.sleep(for: .milliseconds(300))
+        guard !Task.isCancelled else { return }
+        do {
+            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
+                                         cwd: nil, on: nil, timeout: 20, input: nil)
+            guard !Task.isCancelled else { return }
+            guard r.code == 0, let v = try? JSONValue.parse(r.stdout) else { error = Self.failure(r, "Couldn't search \(dir)"); return }
+            results = (v["results"].array ?? []).compactMap { a in
+                guard let n = a[0].string else { return nil }
+                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0, snippet: a[3].string)
+            }
+            partial = v["partial"].bool ?? false
+            error = nil
+        } catch {
+            if !Task.isCancelled { self.error = Self.message(error) }
+        }
+    }
+
     /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
     private static func message(_ error: Error) -> String {
         (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
@@ -202,7 +323,8 @@ struct FilesView: View {
                     .appendingPathComponent("preview", isDirectory: true)
                     .appendingPathComponent(UUID().uuidString, isDirectory: true)
                 try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
-                let url = folder.appendingPathComponent(e.name)
+                let base = (e.name as NSString).lastPathComponent
+                let url = folder.appendingPathComponent(base)
                 error = nil
                 // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
                 switch (e.name as NSString).pathExtension.lowercased() {
@@ -212,7 +334,7 @@ struct FilesView: View {
                 case "svg":
                     try data.write(to: url, options: .completeFileProtection)
                     let page = folder.appendingPathComponent("index.html")
-                    try Self.wrapper(image: e.name).write(to: page, options: .completeFileProtection)
+                    try Self.wrapper(image: base).write(to: page, options: .completeFileProtection)
                     web = WebDoc(name: e.name, url: page)
                 default:
                     try data.write(to: url, options: .completeFileProtection)
diff --git a/App/Sources/UI/SpaceView.swift b/App/Sources/UI/SpaceView.swift
index 3f57afa..7432619 100644
--- a/App/Sources/UI/SpaceView.swift
+++ b/App/Sources/UI/SpaceView.swift
@@ -27,6 +27,18 @@ struct SpaceView: View {
         .navigationBarTitleDisplayMode(.inline)
     }
 
+    /// The folder of the terminal on screen (the page shown on a phone; on iPad, where every pane shows, the tab's first).
+    private func browseFolder(_ space: SpaceRef, _ tab: TabRef?) -> String {
+        if hsc != .regular, let tab, tab.panes.indices.contains(paneIndex), let addr = tab.panes[paneIndex].terminal,
+           let cwd = store.terminals[addr]?.cwd, !cwd.isEmpty { return cwd }
+        return store.startFolder(for: space)
+    }
+
+    private static func title(_ folder: String) -> String {
+        let n = (folder as NSString).lastPathComponent
+        return n.isEmpty ? "~" : n
+    }
+
     private func selectedTab(_ space: SpaceRef) -> TabRef? {
         let id = store.selectedTabBySpace[space.id]
         return space.tabs.first { $0.id == id } ?? space.tabs.first
@@ -92,8 +104,8 @@ struct SpaceView: View {
                     .accessibilityLabel("New agent in this space")
             }
         }
-        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
-        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
+        .sheet(isPresented: $showFiles) { let f = browseFolder(space, tab); FilesSheet(folder: f, title: Self.title(f)) }
+        .sheet(isPresented: $showChanges) { let f = browseFolder(space, tab); ChangesSheet(folder: f, title: Self.title(f)) }
         .onAppear { store.selectedSpaceID = space.id }
     }
 }

exec
/bin/zsh -lc 'git show 27db4e9 -- App/Sources UITests' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 27db4e9768c34326a25bf93c688f995432e9cf96
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 04:46:26 2026 +0900

    Open Chat with the last 150 entries, load earlier ones on request, show Chat on space cards, and add Files and Changes to the agent page
    
    Opening Chat sent up to 16 MiB of parsed transcript (about 700 KB, 930 entries here) and
    laid it all out; the box still reads 16 MiB in 0.3 s, but now sends only the last 150
    entries and fetches the 150 before them when asked. Turn ids come from entry sequence
    numbers so loading earlier entries does not renumber what is shown.
    Files and Changes open at the git root of the agent process's folder, which does not
    move when the agent runs cd in its child shells; the space page uses the same root.

diff --git a/App/Sources/Chat/AgentScreen.swift b/App/Sources/Chat/AgentScreen.swift
index 0515dac..846f968 100644
--- a/App/Sources/Chat/AgentScreen.swift
+++ b/App/Sources/Chat/AgentScreen.swift
@@ -8,6 +8,8 @@ struct AgentScreen: View {
     let address: String
     @Environment(AppStore.self) private var store
     @AppStorage("agentViewMode") private var mode = "chat"
+    @State private var showFiles = false
+    @State private var showChanges = false
 
     var body: some View {
         let canChat = ["claude", "codex"].contains(store.programKey(of: address))
@@ -28,7 +30,18 @@ struct AgentScreen: View {
                     }
                 }
             }
+            // A menu, not two more buttons: the title keeps its width.
+            ToolbarItem(placement: .topBarTrailing) {
+                Menu("More", systemImage: "ellipsis") {
+                    Button("Files", systemImage: "folder") { showFiles = true }
+                    Button("Changes", systemImage: "plusminus") { showChanges = true }
+                }
+                .accessibilityIdentifier("agentMore")
+            }
         }
+        // The agent process's folder: its own shell commands run in child shells, so it stays where the agent started.
+        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.terminals[address]?.cwd ?? "") }
+        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.terminals[address]?.cwd ?? "") }
     }
 }
 
diff --git a/App/Sources/Chat/ChatModel.swift b/App/Sources/Chat/ChatModel.swift
index 9e2d604..64877c6 100644
--- a/App/Sources/Chat/ChatModel.swift
+++ b/App/Sources/Chat/ChatModel.swift
@@ -52,11 +52,16 @@ final class ChatModel {
     private(set) var turns: [ChatTurn] = []
     /// The transcript continues above what was loaded (we only read its tail).
     private(set) var hasEarlier = false
+    private(set) var loadingEarlier = false
     private(set) var revision = 0
 
     private var entries: [ChatEntry] = []
     private var session = ""
     private var offset: Int64 = -1
+    /// Where the loaded part of the transcript begins.
+    private var start: Int64 = 0
+    /// The sequence number of `entries[0]`; earlier windows count down, so ids already shown never change.
+    private var firstSeq = 0
     private var loop: Task<Void, Never>?
     private var wake: CheckedContinuation<Void, Never>?
     private var sleeper: Task<Void, Never>?
@@ -104,16 +109,39 @@ final class ChatModel {
         }
     }
 
-    private func load() async {
-        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
-        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
+    /// The transcript script and its leading arguments for this terminal.
+    private func invocation(_ store: AppStore) -> [String]? {
+        guard let rec = store.terminals[address] else { return nil }
         let codex = store.programKey(of: address) == "codex"
-        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
         let context: JSONValue = codex ? ["title": .string(rec.title), "cwd": .string(rec.cwd)] : rec.raw["argv"]
-        let argv = String(decoding: context.encoded(), as: UTF8.self)
+        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
+                rec.raw["pid"].int.map(String.init) ?? "0", String(decoding: context.encoded(), as: UTF8.self)]
+    }
+
+    /// Reads the window above what is loaded and puts it in front.
+    func loadEarlier() async {
+        guard hasEarlier, !loadingEarlier, let store, store.phase == .connected, let call = invocation(store) else { return }
+        loadingEarlier = true
+        defer { loadingEarlier = false }
+        guard let r = try? await store.exec(argv: call + [session, "-1", String(start)], cwd: nil, on: nil, timeout: 20, input: nil),
+              r.code == 0 else { return }
+        var lines = r.stdout.split(separator: UInt8(ascii: "\n"))
+        // Anything else (the session changed meanwhile) leaves the chat as it is.
+        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())), head["earlier"].bool == true,
+              head["session"].string == session else { return }
+        let earlier = lines.compactMap { (try? JSONValue.parse(Data($0))).flatMap(Self.entry) }
+        entries = earlier + entries
+        firstSeq -= earlier.count
+        start = Int64(head["start"].double ?? 0)
+        hasEarlier = start > 0
+        rebuild()
+    }
+
+    private func load() async {
+        guard let store, store.phase == .connected, let call = invocation(store) else { return }
         for _ in 0..<4 {   // follow "more" a few times on a big backlog
             do {
-                let r = try await store.exec(argv: ["python3", "-c", script, pid, argv, session, String(offset)],
+                let r = try await store.exec(argv: call + [session, String(offset)],
                                              cwd: nil, on: nil, timeout: 20, input: nil)
                 guard r.code == 0 else {
                     let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
@@ -142,8 +170,10 @@ final class ChatModel {
         let fresh = head["fresh"].bool ?? false
         if fresh {
             entries = []
+            firstSeq = 0
             session = head["session"].string ?? ""
-            hasEarlier = (head["start"].int ?? 0) > 0
+            start = Int64(head["start"].double ?? 0)
+            hasEarlier = start > 0
         }
         offset = Int64(head["next"].double ?? Double(offset))
         var added = false
@@ -182,13 +212,16 @@ final class ChatModel {
     private func rebuild() {
         var out: [ChatTurn] = []
         var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
-        var n = 0
-        func next() -> Int { n += 1; return n }
+        // A turn takes its entry's sequence number times two, a step that number plus one: one entry makes at most one of each.
+        var seq = 0
+        func next() -> Int { seq * 2 }
+        func step() -> Int { seq * 2 + 1 }
         func current() -> Int {
             if out.isEmpty { out.append(ChatTurn(id: next())) }
             return out.count - 1
         }
-        for e in entries {
+        for (i, e) in entries.enumerated() {
+            seq = firstSeq + i
             switch e {
             case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
             case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
@@ -198,7 +231,7 @@ final class ChatModel {
                 if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
                 out.append(ChatTurn(id: next(), compacted: true))
             case .text(let s):
-                let i = current(); out[i].steps.append(.text(next(), s))
+                let i = current(); out[i].steps.append(.text(step(), s))
             case .tool(let id, let name, let sum, let detail, let at):
                 let i = current()
                 if out[i].startedAt == nil { out[i].startedAt = at }
@@ -208,7 +241,7 @@ final class ChatModel {
                     out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
                     where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
                 } else {
-                    out[i].steps.append(.tools(next(), [call]))
+                    out[i].steps.append(.tools(step(), [call]))
                     where_[id] = (i, out[i].steps.count - 1, 0)
                 }
             case .result(let id, let err, let output):
diff --git a/App/Sources/Chat/ChatView.swift b/App/Sources/Chat/ChatView.swift
index 0a803db..36e42cc 100644
--- a/App/Sources/Chat/ChatView.swift
+++ b/App/Sources/Chat/ChatView.swift
@@ -58,8 +58,16 @@ struct ChatView: View {
             emptyState("exclamationmark.triangle", "Couldn't read the conversation", hint: why)
         default:
             if model.hasEarlier {
-                Label("Earlier messages are in the terminal's history", systemImage: "clock.arrow.circlepath")
-                    .font(HF.ui(12.5)).foregroundStyle(HC.dim).frame(maxWidth: .infinity)
+                Button { Task { await model.loadEarlier() } } label: {
+                    HStack(spacing: 8) {
+                        if model.loadingEarlier { ProgressView() } else { Image(systemName: "clock.arrow.circlepath") }
+                        Text("Show earlier messages")
+                    }
+                    .font(HF.ui(13)).foregroundStyle(HC.muted).frame(maxWidth: .infinity)
+                }
+                .buttonStyle(.plain)
+                .disabled(model.loadingEarlier)
+                .accessibilityIdentifier("chatEarlier")
             }
             ForEach(model.turns) { turn in
                 TurnView(turn: turn, isLast: turn.id == model.turns.last?.id, working: working)
diff --git a/App/Sources/Chat/CodexTranscriptScript.swift b/App/Sources/Chat/CodexTranscriptScript.swift
index 22c7587..a55de81 100644
--- a/App/Sources/Chat/CodexTranscriptScript.swift
+++ b/App/Sources/Chat/CodexTranscriptScript.swift
@@ -87,11 +87,19 @@ path = max(rollouts, key=lambda f: os.path.getmtime(f))
 sid = meta(path).get('id') or os.path.basename(path)[-41:-6]
 size = os.path.getsize(path)
 fresh = sid != known or off < 0 or off > size
-if fresh:
+end = size
+# argv[5], when given: read the window that ends where the loaded part starts ("show earlier").
+before = int(sys.argv[5]) if len(sys.argv) > 5 else -1
+if before >= 0:
+    if sid != known or before > size:
+        print(json.dumps({'k': 'head', 'session': sid, 'why': 'moved'})); sys.exit(0)
+    end, off, fresh = before, max(0, before - INITIAL), True
+elif fresh:
     off = max(0, size - INITIAL)
 
 out = []
-def emit(**e): out.append(json.dumps(e, ensure_ascii=False))
+at = [0]   # where the record being read starts
+def emit(**e): out.append((at[0], json.dumps(e, ensure_ascii=False)))
 def cut(s, n): s = str(s or ''); return s if len(s) <= n else s[:n] + '…'
 def short(p):
     p = str(p or '')
@@ -110,7 +118,7 @@ def summary(i):
 
 with open(path, 'rb') as f:
     f.seek(off)
-    data = f.read(min(size - off, MAXREAD))
+    data = f.read(min(end - off, MAXREAD))
 if fresh and off > 0:
     nl = data.find(b'\n')
     data = data[nl + 1:] if nl >= 0 else b''
@@ -122,7 +130,9 @@ data = data[:end + 1] if end >= 0 else b''
 # Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
 nxt = off + (read if end < 0 and read >= MAXREAD else len(data))
 
+pos = off
 for raw in data.split(b'\n'):
+    at[0] = pos; pos += len(raw) + 1
     if not raw or (b'"item_completed"' not in raw and b'"task_complete"' not in raw): continue
     try: d = json.loads(raw)
     except Exception: continue
@@ -150,9 +160,14 @@ for raw in data.split(b'\n'):
         rest = {k: v for k, v in i.items() if k not in ('type', 'id')}
         emit(k='tool', id=i.get('id') or '', name=kind, sum=cut(summary(i), 200), detail=cut(json.dumps(rest, ensure_ascii=False, indent=1), 1200), ts=ts)
 
-print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'more': nxt < size}))
-print('\n'.join(out))
+# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
+if fresh and len(out) > KEEP:
+    start = out[-KEEP][0]
+    out = [o for o in out if o[0] >= start]
+print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
+print('\n'.join(e for _, e in out))
 """#
         .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
+        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
         .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
 }
diff --git a/App/Sources/Chat/TranscriptScript.swift b/App/Sources/Chat/TranscriptScript.swift
index 8108e5f..63a9116 100644
--- a/App/Sources/Chat/TranscriptScript.swift
+++ b/App/Sources/Chat/TranscriptScript.swift
@@ -5,12 +5,15 @@ import Foundation
 /// as compact JSON lines, one per entry the chat shows. Transcripts reach
 /// hundreds of MB, so the phone only ever reads the tail and then new bytes.
 ///
-/// argv: <terminal pid> <terminal argv JSON> <known session id or ""> <offset, -1 = tail>
-/// First line: {"k":"head","session","path","size","next","start","more"}; then entries:
+/// argv: <terminal pid> <terminal argv JSON> <known session id or ""> <offset, -1 = tail> [<before>]
+/// With <before>, reads the window that ends there instead (the part above what the phone has).
+/// First line: {"k":"head","session","path","size","next","start","earlier","more"}; then entries:
 ///   user {t, ts} · note {t} · cmd {t} · compact · text {t} · tool {id, name, sum, detail}
 ///   result {id, err, out} · dur {ms}
 enum TranscriptScript {
     static let initialTail = 16 << 20
+    /// Entries sent for a fresh or earlier window: the box reads 16 MiB fast, but sending and laying out all of it is what made Chat slow to open.
+    static let keepEntries = 150
     static let maxRead = 16 << 20
 
     static let source = #"""
@@ -78,11 +81,19 @@ if not files:
 path = max(files, key=lambda f: os.path.getmtime(f))
 size = os.path.getsize(path)
 fresh = sid != known or off < 0 or off > size
-if fresh:
+end = size
+# argv[5], when given: read the window that ends where the loaded part starts ("show earlier").
+before = int(sys.argv[5]) if len(sys.argv) > 5 else -1
+if before >= 0:
+    if sid != known or before > size:
+        print(json.dumps({'k': 'head', 'session': sid, 'why': 'moved'})); sys.exit(0)
+    end, off, fresh = before, max(0, before - INITIAL), True
+elif fresh:
     off = max(0, size - INITIAL)
 
 out = []
-def emit(**e): out.append(json.dumps(e, ensure_ascii=False))
+at = [0]   # where the record being read starts
+def emit(**e): out.append((at[0], json.dumps(e, ensure_ascii=False)))
 def cut(s, n): return s if len(s) <= n else s[:n] + '…'
 def tag(s, name):
     m = re.search('<%s>(.*?)</%s>' % (name, name), s, re.S)
@@ -120,7 +131,7 @@ def detail(name, i):
 
 with open(path, 'rb') as f:
     f.seek(off)
-    data = f.read(min(size - off, MAXREAD))
+    data = f.read(min(end - off, MAXREAD))
 if fresh and off > 0:
     nl = data.find(b'\n')
     data = data[nl + 1:] if nl >= 0 else b''
@@ -132,7 +143,9 @@ data = data[:end + 1] if end >= 0 else b''
 # Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
 nxt = off + (read if end < 0 and read >= MAXREAD else len(data))
 
+pos = off
 for raw in data.split(b'\n'):
+    at[0] = pos; pos += len(raw) + 1
     if not raw or (b'"type":"user"' not in raw and b'"type":"assistant"' not in raw and b'"subtype":"turn_duration"' not in raw and b'"subtype":"compact_boundary"' not in raw):
         continue
     try: d = json.loads(raw)
@@ -173,9 +186,14 @@ for raw in data.split(b'\n'):
                 n = b.get('name') or 'Tool'; i = b.get('input') or {}
                 emit(k='tool', id=b.get('id') or '', name=n, sum=cut(summary(n, i), 200), detail=detail(n, i), ts=ts)
 
-print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'more': nxt < size}))
-print('\n'.join(out))
+# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
+if fresh and len(out) > KEEP:
+    start = out[-KEEP][0]
+    out = [o for o in out if o[0] >= start]
+print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
+print('\n'.join(e for _, e in out))
 """#
         .replacingOccurrences(of: "INITIAL", with: String(initialTail))
+        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
         .replacingOccurrences(of: "MAXREAD", with: String(maxRead))
 }
diff --git a/App/Sources/Store/AppStore.swift b/App/Sources/Store/AppStore.swift
index e9b975a..e27adc0 100644
--- a/App/Sources/Store/AppStore.swift
+++ b/App/Sources/Store/AppStore.swift
@@ -804,6 +804,22 @@ final class AppStore {
         return space.folder.isEmpty ? home : space.folder
     }
 
+    /// A box path with "~" expanded: argv reaches programs without a shell.
+    func absolutePath(_ p: String) -> String {
+        if p.isEmpty || p == "~" { return home }
+        if p.hasPrefix("~/") { return home + p.dropFirst(1) }
+        return p
+    }
+
+    /// The git repository `folder` is in, else `folder` itself.
+    func projectRoot(_ folder: String) async -> String {
+        let dir = absolutePath(folder)
+        guard let r = try? await exec(argv: ["git", "-C", dir, "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil),
+              r.code == 0 else { return dir }
+        let top = String(decoding: r.stdout, as: UTF8.self).trimmingCharacters(in: .newlines)
+        return top.isEmpty ? dir : top
+    }
+
     /// Keeps the selection pointing at things that exist.
     private func fixSelection() {
         guard !spaces.isEmpty else { return }
diff --git a/App/Sources/UI/ChangesView.swift b/App/Sources/UI/ChangesView.swift
index 4785b20..7b25bce 100644
--- a/App/Sources/UI/ChangesView.swift
+++ b/App/Sources/UI/ChangesView.swift
@@ -7,7 +7,7 @@ struct ChangesSheet: View {
     @Environment(AppStore.self) private var store
     @Environment(\.dismiss) private var dismiss
     var folder: String
-    var title: String
+    private var title: String { ((root.isEmpty ? folder : root) as NSString).lastPathComponent }
 
     struct Change: Hashable, Identifiable {
         var code: String   // porcelain XY, e.g. " M", "A ", "??"
@@ -49,17 +49,10 @@ struct ChangesSheet: View {
         }
     }
 
-    /// The space folder as an absolute path: argv reaches git without a shell, so "~" is not expanded.
-    private var absoluteFolder: String {
-        if folder.isEmpty || folder == "~" { return store.home }
-        if folder.hasPrefix("~/") { return store.home + folder.dropFirst(1) }
-        return folder
-    }
-
     private func load() async {
         do {
             // Porcelain paths are relative to the repo root, so status and every diff run there.
-            let top = try await store.exec(argv: ["git", "-C", absoluteFolder, "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil)
+            let top = try await store.exec(argv: ["git", "-C", store.absolutePath(folder), "rev-parse", "--show-toplevel"], cwd: nil, on: nil, timeout: 20, input: nil)
             guard top.code == 0 else { error = DiffView.failure(top, "\(title) is not in a git repository."); return }
             let dir = String(decoding: top.stdout, as: UTF8.self).trimmingCharacters(in: .newlines)
             let head = try await store.exec(argv: ["git", "-C", dir, "rev-parse", "--verify", "-q", "HEAD"], cwd: nil, on: nil, timeout: 20, input: nil)
diff --git a/App/Sources/UI/FilesView.swift b/App/Sources/UI/FilesView.swift
index 55226a4..04890d1 100644
--- a/App/Sources/UI/FilesView.swift
+++ b/App/Sources/UI/FilesView.swift
@@ -431,13 +431,22 @@ private struct WebPreview: UIViewRepresentable {
 
 /// The Files sheet for one space: its own stack so folders push inside the sheet.
 struct FilesSheet: View {
+    @Environment(AppStore.self) private var store
     @Environment(\.dismiss) private var dismiss
+    /// A folder inside the project; the sheet opens at the project's root.
     var folder: String
-    var title: String
+    @State private var root: String?
 
     var body: some View {
         NavigationStack {
-            FilesView(path: folder.isEmpty ? "~" : folder, title: title)
+            Group {
+                if let root {
+                    FilesView(path: root, title: (root as NSString).lastPathComponent)
+                } else {
+                    ProgressView()
+                }
+            }
+                .task { root = await store.projectRoot(folder) }
                 .navigationDestination(for: String.self) { p in
                     FilesView(path: p, title: (p as NSString).lastPathComponent)
                 }
diff --git a/App/Sources/UI/SpaceView.swift b/App/Sources/UI/SpaceView.swift
index 7432619..8475661 100644
--- a/App/Sources/UI/SpaceView.swift
+++ b/App/Sources/UI/SpaceView.swift
@@ -34,10 +34,6 @@ struct SpaceView: View {
         return store.startFolder(for: space)
     }
 
-    private static func title(_ folder: String) -> String {
-        let n = (folder as NSString).lastPathComponent
-        return n.isEmpty ? "~" : n
-    }
 
     private func selectedTab(_ space: SpaceRef) -> TabRef? {
         let id = store.selectedTabBySpace[space.id]
@@ -104,8 +100,8 @@ struct SpaceView: View {
                     .accessibilityLabel("New agent in this space")
             }
         }
-        .sheet(isPresented: $showFiles) { let f = browseFolder(space, tab); FilesSheet(folder: f, title: Self.title(f)) }
-        .sheet(isPresented: $showChanges) { let f = browseFolder(space, tab); ChangesSheet(folder: f, title: Self.title(f)) }
+        .sheet(isPresented: $showFiles) { FilesSheet(folder: browseFolder(space, tab)) }
+        .sheet(isPresented: $showChanges) { ChangesSheet(folder: browseFolder(space, tab)) }
         .onAppear { store.selectedSpaceID = space.id }
     }
 }
@@ -173,6 +169,7 @@ struct TabChipBar: View {
 struct PaneCard: View {
     @Environment(AppStore.self) private var store
     @Environment(Navigator.self) private var nav
+    @AppStorage("agentViewMode") private var mode = "chat"
     var pane: PaneRef
     var spaceName: String
 
@@ -183,7 +180,11 @@ struct PaneCard: View {
                     VStack(spacing: 0) {
                         header(addr)
                         Rectangle().fill(HC.border).frame(height: HM.hairline)
-                        TerminalPreview(address: addr)
+                        if mode == "chat" && ["claude", "codex"].contains(store.programKey(of: addr)) {
+                            ChatPreview(address: addr)
+                        } else {
+                            TerminalPreview(address: addr)
+                        }
                     }
                     .contentShape(.rect)
                 }
@@ -221,6 +222,45 @@ struct PaneCard: View {
     }
 }
 
+/// The last turns of a Claude Code or Codex conversation, in the same mode as the agent page.
+struct ChatPreview: View {
+    @Environment(AppStore.self) private var store
+    @State private var model: ChatModel
+
+    init(address: String) { _model = State(initialValue: ChatModel(address: address)) }
+
+    var body: some View {
+        ZStack(alignment: .bottomLeading) {
+            HC.background
+            if model.turns.isEmpty {
+                VStack(spacing: 8) {
+                    Image(systemName: "text.bubble").font(.system(size: 22, weight: .light)).foregroundStyle(HC.dim)
+                    Text(model.phase == .loading ? "Loading…" : "Tap to open").font(HF.ui(13)).foregroundStyle(HC.dim)
+                }
+                .frame(maxWidth: .infinity, maxHeight: .infinity)
+            } else {
+                Color.clear
+                    .overlay(alignment: .bottomLeading) {
+                        VStack(alignment: .leading, spacing: 10) {
+                            ForEach(model.turns.suffix(3)) { t in
+                                if case .user(let s)? = t.prompt {
+                                    Text(s).font(HF.ui(13, .medium)).foregroundStyle(HC.fg).lineLimit(3)
+                                }
+                                if case .text(_, let s)? = t.steps.last {
+                                    Text(s).font(HF.ui(13)).foregroundStyle(HC.muted).lineLimit(8)
+                                }
+                            }
+                        }
+                        .padding(12)
+                    }
+                    .clipped()
+            }
+        }
+        .onAppear { model.start(store: store) }
+        .onDisappear { model.stop() }
+    }
+}
+
 /// Plain-text tail of a terminal (terminal.read), refreshed when its turn/status changes.
 struct TerminalPreview: View {
     @Environment(AppStore.self) private var store
diff --git a/UITests/HerdrUITests.swift b/UITests/HerdrUITests.swift
index 0f79411..4f52224 100644
--- a/UITests/HerdrUITests.swift
+++ b/UITests/HerdrUITests.swift
@@ -193,6 +193,30 @@ final class HerdrUITests: XCTestCase {
         if tool.exists { tool.tap(); sleep(1); shot(app, "chat-tool-open") }
     }
 
+    /// From an agent ($HERDR_TEST_TERMINAL), earlier messages load above the tail, and Files opens at the
+    /// agent's project root, listing $HERDR_TEST_ROOT_ENTRY.
+    func testAgentChatEarlierAndFiles() throws {
+        let env = ProcessInfo.processInfo.environment
+        let app = launch(["HERDR_DEBUG_OPEN": env["HERDR_TEST_TERMINAL"] ?? "t1"])
+        let earlier = app.buttons["chatEarlier"]
+        var tries = 0
+        while !(earlier.exists && earlier.isHittable) && tries < 40 { app.swipeDown(); tries += 1 }
+        app.swipeDown()   // hittable can still mean half under the navigation bar
+        XCTAssertTrue(earlier.exists, "no Show earlier messages button")
+        shot(app, "chat-before-earlier")
+        let first = app.staticTexts.allElementsBoundByIndex.filter(\.isHittable).prefix(3).map(\.label)
+        earlier.tap()
+        sleep(4)
+        shot(app, "chat-earlier")
+        // The view stays at the top, which now holds the older messages.
+        XCTAssertNotEqual(app.staticTexts.allElementsBoundByIndex.filter(\.isHittable).prefix(3).map(\.label), first, "nothing was added above")
+        app.buttons["agentMore"].tap()
+        app.buttons["Files"].tap()
+        let entry = app.buttons[try XCTUnwrap(env["HERDR_TEST_ROOT_ENTRY"])]
+        XCTAssertTrue(entry.waitForExistence(timeout: 30), "project root not listed")
+        shot(app, "agent-files")
+    }
+
     /// A scripted tour for the README video (demo data only). Run while
     /// recording; the harness sends a push with `xcrun simctl push` once
     /// the app is in the background.

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat App/Sources/Chat/ChatModel.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
import SwiftUI
import HerdrKit

/// One entry the box-side script emitted (TranscriptScript).
enum ChatEntry {
    case user(String, Date?)
    case note(String)
    case command(String)
    case compact
    case text(String)
    case tool(id: String, name: String, summary: String, detail: String, at: Date?)
    case result(id: String, isError: Bool, output: String)
    case duration(ms: Int)
}

struct ToolCall: Identifiable, Equatable {
    var id: String
    var name: String
    var summary: String
    var detail: String
    var output: String?
    var isError = false
}

enum ChatStep: Identifiable, Equatable {
    case text(Int, String)
    case tools(Int, [ToolCall])
    var id: Int { switch self { case .text(let i, _), .tools(let i, _): i } }
    var toolCount: Int { if case .tools(_, let c) = self { c.count } else { 0 } }
}

/// One prompt and everything the agent did in answer.
struct ChatTurn: Identifiable, Equatable {
    enum Prompt: Equatable { case user(String), note(String), command(String) }
    var id: Int
    var prompt: Prompt?
    var compacted = false
    var steps: [ChatStep] = []
    var durationMs: Int?
    var startedAt: Date?
}

/// Reads an agent's Claude Code or Codex transcript from the box and folds it into
/// turns. Polls quickly while the agent works, slowly otherwise; never
/// attaches to (or resizes) the terminal.
@MainActor @Observable
final class ChatModel {
    enum Phase: Equatable { case loading, ready, unavailable(String), failed(String) }

    let address: String
    private(set) var phase: Phase = .loading
    private(set) var turns: [ChatTurn] = []
    /// The transcript continues above what was loaded (we only read its tail).
    private(set) var hasEarlier = false
    private(set) var loadingEarlier = false
    private(set) var revision = 0

    private var entries: [ChatEntry] = []
    private var session = ""
    private var offset: Int64 = -1
    /// Where the loaded part of the transcript begins.
    private var start: Int64 = 0
    /// The sequence number of `entries[0]`; earlier windows count down, so ids already shown never change.
    private var firstSeq = 0
    private var loop: Task<Void, Never>?
    private var wake: CheckedContinuation<Void, Never>?
    private var sleeper: Task<Void, Never>?
    private weak var store: AppStore?

    init(address: String) { self.address = address }

    func start(store: AppStore) {
        self.store = store
        #if DEBUG
        if AppStore.isDemo { loadDemo(); return }
        #endif
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.load()
                guard !Task.isCancelled else { return }
                await self.pause()
            }
        }
    }

    func stop() {
        loop?.cancel(); loop = nil
        sleeper?.cancel(); sleeper = nil
        wake?.resume(); wake = nil
    }

    /// Something changed (status, turn): read now instead of waiting.
    func nudge() { wake?.resume(); wake = nil }

    private func pause() async {
        let busy = store.map { [.working, .blocked].contains($0.attention(of: address)) } ?? false
        let delay: Duration = busy ? .milliseconds(1500) : .seconds(6)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            wake = c
            // Cancelled so an earlier pause's timer can never end this one early.
            sleeper?.cancel()
            sleeper = Task { [weak self] in
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                self?.nudge()
            }
        }
    }

    /// The transcript script and its leading arguments for this terminal.
    private func invocation(_ store: AppStore) -> [String]? {
        guard let rec = store.terminals[address] else { return nil }
        let codex = store.programKey(of: address) == "codex"
        let context: JSONValue = codex ? ["title": .string(rec.title), "cwd": .string(rec.cwd)] : rec.raw["argv"]
        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
                rec.raw["pid"].int.map(String.init) ?? "0", String(decoding: context.encoded(), as: UTF8.self)]
    }

    /// Reads the window above what is loaded and puts it in front.
    func loadEarlier() async {
        guard hasEarlier, !loadingEarlier, let store, store.phase == .connected, let call = invocation(store) else { return }
        loadingEarlier = true
        defer { loadingEarlier = false }
        guard let r = try? await store.exec(argv: call + [session, "-1", String(start)], cwd: nil, on: nil, timeout: 20, input: nil),
              r.code == 0 else { return }
        var lines = r.stdout.split(separator: UInt8(ascii: "\n"))
        // Anything else (the session changed meanwhile) leaves the chat as it is.
        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())), head["earlier"].bool == true,
              head["session"].string == session else { return }
        let earlier = lines.compactMap { (try? JSONValue.parse(Data($0))).flatMap(Self.entry) }
        entries = earlier + entries
        firstSeq -= earlier.count
        start = Int64(head["start"].double ?? 0)
        hasEarlier = start > 0
        rebuild()
    }

    private func load() async {
        guard let store, store.phase == .connected, let call = invocation(store) else { return }
        for _ in 0..<4 {   // follow "more" a few times on a big backlog
            do {
                let r = try await store.exec(argv: call + [session, String(offset)],
                                             cwd: nil, on: nil, timeout: 20, input: nil)
                guard r.code == 0 else {
                    let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                    phase = .failed(err.isEmpty ? "Couldn't read the conversation." : String(err.suffix(300)))
                    return
                }
                if !apply(r.stdout) { return }
            } catch {
                if case .ready = phase {} else { phase = .failed(error.localizedDescription) }
                return
            }
        }
    }

    /// Returns true when the box has more to send right away.
    private func apply(_ data: Data) -> Bool {
        var lines = data.split(separator: UInt8(ascii: "\n"))
        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())) else { return false }
        if let why = head["why"].string {
            let agent = store?.programKey(of: address) == "codex" ? "Codex" : "Claude Code"
            phase = .unavailable(why == "no-session"
                ? "No \(agent) conversation found for this terminal yet."
                : "\(agent)'s transcript for this session isn't on disk yet.")
            return false
        }
        let fresh = head["fresh"].bool ?? false
        if fresh {
            entries = []
            firstSeq = 0
            session = head["session"].string ?? ""
            start = Int64(head["start"].double ?? 0)
            hasEarlier = start > 0
        }
        offset = Int64(head["next"].double ?? Double(offset))
        var added = false
        for line in lines {
            guard let e = try? JSONValue.parse(Data(line)), let entry = Self.entry(e) else { continue }
            entries.append(entry); added = true
        }
        if fresh || added { rebuild() }
        phase = .ready
        return head["more"].bool ?? false
    }

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f
    }()

    private static func entry(_ e: JSONValue) -> ChatEntry? {
        let t = e["t"].string ?? ""
        let ts = e["ts"].string.flatMap { iso.date(from: $0) }
        switch e["k"].string {
        case "user": return .user(t, ts)
        case "note": return .note(t)
        case "cmd": return .command(t)
        case "compact": return .compact
        case "text": return .text(t)
        case "tool": return .tool(id: e["id"].string ?? "", name: e["name"].string ?? "Tool",
                                  summary: e["sum"].string ?? "", detail: e["detail"].string ?? "", at: ts)
        case "result": return .result(id: e["id"].string ?? "", isError: e["err"].bool ?? false, output: e["out"].string ?? "")
        case "dur": return .duration(ms: e["ms"].int ?? 0)
        default: return nil
        }
    }

    /// Folds entries into turns: a prompt starts one; texts and tool calls
    /// follow; consecutive tool calls share a group; results attach by id.
    private func rebuild() {
        var out: [ChatTurn] = []
        var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
        // A turn takes its entry's sequence number times two, a step that number plus one: one entry makes at most one of each.
        var seq = 0
        func next() -> Int { seq * 2 }
        func step() -> Int { seq * 2 + 1 }
        func current() -> Int {
            if out.isEmpty { out.append(ChatTurn(id: next())) }
            return out.count - 1
        }
        for (i, e) in entries.enumerated() {
            seq = firstSeq + i
            switch e {
            case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
            case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
            case .command(let s): out.append(ChatTurn(id: next(), prompt: .command(s)))
            case .compact:
                // A boundary and its "continued from" summary arrive together: one marker.
                if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
                out.append(ChatTurn(id: next(), compacted: true))
            case .text(let s):
                let i = current(); out[i].steps.append(.text(step(), s))
            case .tool(let id, let name, let sum, let detail, let at):
                let i = current()
                if out[i].startedAt == nil { out[i].startedAt = at }
                let call = ToolCall(id: id, name: name, summary: sum, detail: detail)
                if case .tools(let sid, var calls)? = out[i].steps.last {
                    calls.append(call)
                    out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
                    where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
                } else {
                    out[i].steps.append(.tools(step(), [call]))
                    where_[id] = (i, out[i].steps.count - 1, 0)
                }
            case .result(let id, let err, let output):
                guard let w = where_[id], case .tools(let sid, var calls) = out[w.turn].steps[w.step] else { continue }
                calls[w.call].output = output
                calls[w.call].isError = err
                out[w.turn].steps[w.step] = .tools(sid, calls)
            case .duration(let ms):
                if !out.isEmpty { out[out.count - 1].durationMs = ms }
            }
        }
        // A trailing "continued from earlier" marker with nothing after it reads oddly; keep it, it's honest.
        turns = out
        revision += 1
    }
}

// MARK: Display helpers

enum ToolStyle {
    static func symbol(_ name: String) -> String {
        switch name {
        case "Bash", "BashOutput", "KillShell": "terminal"
        case "Read": "doc.text"
        case "Edit", "MultiEdit": "pencil"
        case "Write", "NotebookEdit": "square.and.pencil"
        case "Grep", "Glob", "ToolSearch": "magnifyingglass"
        case "WebSearch", "WebFetch": "globe"
        case "Agent", "Task", "SendMessage": "person.2"
        case "TodoWrite": "checklist"
        case "Skill": "sparkles"
        case "Workflow": "point.3.connected.trianglepath.dotted"
        default: name.hasPrefix("mcp__") ? "puzzlepiece.extension" : "wrench.and.screwdriver"
        }
    }

    /// "mcp__claude-artifacts__get_artifact" -> "claude-artifacts · get_artifact"
    static func title(_ name: String) -> String {
        guard name.hasPrefix("mcp__") else { return name }
        let parts = name.dropFirst(5).components(separatedBy: "__")
        return parts.count >= 2 ? "\(parts[0]) · \(parts.dropFirst().joined(separator: "__"))" : String(name.dropFirst(5))
    }

    static func duration(ms: Int) -> String {
        let s = ms / 1000
        if s < 60 { return "\(max(s, 1))s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \((s % 3600) / 60)m"
    }
}

#if DEBUG
// A canned conversation for screenshots (HERDR_DEMO=1).
extension ChatModel {
    fileprivate func loadDemo() {
        let now = Date()
        entries = [
            .user("Add a global time slider to the analytics dashboard so every chart shares one range", now.addingTimeInterval(-900)),
            .text("I'll start by looking at how the dashboard wires its charts together."),
            .tool(id: "a", name: "Read", summary: "~/projects/webapp/src/dashboard/Dashboard.tsx", detail: "", at: nil),
            .result(id: "a", isError: false, output: "214 lines"),
            .tool(id: "b", name: "Grep", summary: "useTimeRange", detail: "", at: nil),
            .result(id: "b", isError: false, output: "Found 7 files"),
            .tool(id: "c", name: "Edit", summary: "~/projects/webapp/src/dashboard/TimeSlider.tsx", detail: "+ export function TimeSlider({ range, onChange }: TimeSliderProps) {\n+   const [draft, setDraft] = useState(range);", at: nil),
            .result(id: "c", isError: false, output: "Updated with 48 additions and 3 removals"),
            .tool(id: "d", name: "Bash", summary: "Run the dashboard tests", detail: "npm test -- dashboard", at: nil),
            .result(id: "d", isError: false, output: "Tests: 42 passed, 42 total"),
            .text("""
            Every chart on the dashboard now follows **one shared time range**.

            **What changed**
            - A new `TimeSlider` sits in the dashboard header; dragging it updates every chart after a short debounce.
            - Charts read the range from `useTimeRange()` instead of keeping their own.

            | Chart | Before | After |
            |---|---|---|
            | Net flow | own range | shared |
            | Volume | own range | shared |
            | Latency | fixed 24h | shared |

            Tests pass (42/42). Want me to persist the range in the URL so links keep it?
            """),
            .duration(ms: 318_000),
            .user("Yes, put it in the URL", now.addingTimeInterval(-95)),
            .text("Adding a `range` query parameter and reading it on load."),
            .tool(id: "e", name: "Edit", summary: "~/projects/webapp/src/dashboard/useTimeRange.ts", detail: "", at: nil),
            .result(id: "e", isError: false, output: "Updated"),
            .tool(id: "f", name: "Bash", summary: "Type-check the project", detail: "npx tsc --noEmit", at: nil),
        ]
        rebuild()
        phase = .ready
    }
}
#endif

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat App/Sources/Chat/TranscriptScript.swift; cat App/Sources/Chat/CodexTranscriptScript.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
import Foundation

/// Runs on the box with python3 (read-only). Finds the Claude Code session
/// under a terminal's process, then prints the transcript from a byte offset
/// as compact JSON lines, one per entry the chat shows. Transcripts reach
/// hundreds of MB, so the phone only ever reads the tail and then new bytes.
///
/// argv: <terminal pid> <terminal argv JSON> <known session id or ""> <offset, -1 = tail> [<before>]
/// With <before>, reads the window that ends there instead (the part above what the phone has).
/// First line: {"k":"head","session","path","size","next","start","earlier","more"}; then entries:
///   user {t, ts} · note {t} · cmd {t} · compact · text {t} · tool {id, name, sum, detail}
///   result {id, err, out} · dur {ms}
enum TranscriptScript {
    static let initialTail = 16 << 20
    /// Entries sent for a fresh or earlier window: the box reads 16 MiB fast, but sending and laying out all of it is what made Chat slow to open.
    static let keepEntries = 150
    static let maxRead = 16 << 20

    static let source = #"""
import sys, os, json, glob, re
pid = int(sys.argv[1] or 0)
try: targv = json.loads(sys.argv[2])
except Exception: targv = []
known = sys.argv[3]
off = int(sys.argv[4])
home = os.path.expanduser('~')

PS = None
def ppid(p):
    global PS
    try:
        s = open('/proc/%d/stat' % p).read()
        return int(s[s.rindex(')') + 2:].split()[1])
    except Exception:
        pass
    if PS is None:   # macOS and others without /proc: one ps for the whole walk
        PS = {}
        try:
            import subprocess
            for line in subprocess.run(['ps', '-axo', 'pid=,ppid='], capture_output=True, text=True).stdout.splitlines():
                a = line.split()
                if len(a) == 2: PS[int(a[0])] = int(a[1])
        except Exception:
            pass
    return PS.get(p, 0)

def alive(p):
    try:
        os.kill(p, 0); return True
    except PermissionError:
        return True
    except Exception:
        return False

def under(p, root):
    n = 0
    while p > 1 and n < 64:
        if p == root: return True
        p = ppid(p); n += 1
    return False

sid = ''
if pid:
    best = None
    for f in glob.glob(home + '/.claude/sessions/*.json'):
        try: d = json.load(open(f))
        except Exception: continue
        p = int(d.get('pid') or 0)
        if p and alive(p) and under(p, pid):
            if best is None or (d.get('updatedAt') or 0) > (best.get('updatedAt') or 0): best = d
    if best: sid = best.get('sessionId') or ''
if not sid:
    m = re.search(r'(?:--resume|--session-id|-r)[ =]([0-9a-f]{8}-[0-9a-f-]{27})', ' '.join(str(a) for a in targv))
    if m: sid = m.group(1)
if not sid:
    print(json.dumps({'k': 'head', 'session': '', 'why': 'no-session'})); sys.exit(0)

files = glob.glob(home + '/.claude/projects/*/' + sid + '.jsonl')
if not files:
    print(json.dumps({'k': 'head', 'session': sid, 'why': 'no-file'})); sys.exit(0)
path = max(files, key=lambda f: os.path.getmtime(f))
size = os.path.getsize(path)
fresh = sid != known or off < 0 or off > size
end = size
# argv[5], when given: read the window that ends where the loaded part starts ("show earlier").
before = int(sys.argv[5]) if len(sys.argv) > 5 else -1
if before >= 0:
    if sid != known or before > size:
        print(json.dumps({'k': 'head', 'session': sid, 'why': 'moved'})); sys.exit(0)
    end, off, fresh = before, max(0, before - INITIAL), True
elif fresh:
    off = max(0, size - INITIAL)

out = []
at = [0]   # where the record being read starts
def emit(**e): out.append((at[0], json.dumps(e, ensure_ascii=False)))
def cut(s, n): return s if len(s) <= n else s[:n] + '…'
def tag(s, name):
    m = re.search('<%s>(.*?)</%s>' % (name, name), s, re.S)
    return m.group(1).strip() if m else ''
def blocks_text(c):
    if isinstance(c, str): return c
    parts = []
    for b in c or []:
        if isinstance(b, dict):
            if b.get('type') == 'text': parts.append(b.get('text') or '')
            elif b.get('type') == 'image': parts.append('[image]')
    return '\n'.join(parts)
def short(p):
    p = str(p or '')
    return p.replace(home, '~', 1) if p.startswith(home) else p
def summary(name, i):
    if not isinstance(i, dict): return ''
    if name == 'Bash': return i.get('description') or (i.get('command') or '').split('\n')[0]
    for k in ('file_path', 'notebook_path', 'path'):
        if i.get(k): return short(i[k])
    for k in ('pattern', 'query', 'url', 'description', 'skill', 'prompt', 'command'):
        if i.get(k): return str(i[k]).split('\n')[0]
    return ''
def detail(name, i):
    if not isinstance(i, dict): return ''
    if name == 'Bash': return cut(i.get('command') or '', 1500)
    if name in ('Edit', 'MultiEdit'):
        o, n = i.get('old_string') or '', i.get('new_string') or ''
        return cut('- ' + o.replace('\n', '\n- ') + '\n+ ' + n.replace('\n', '\n+ '), 1500)
    if name == 'Write': return cut(i.get('content') or '', 1200)
    if name == 'TodoWrite':
        return '\n'.join(('☑ ' if t.get('status') == 'completed' else '▸ ' if t.get('status') == 'in_progress' else '☐ ') + (t.get('content') or '') for t in i.get('todos') or [])
    try: return cut(json.dumps(i, ensure_ascii=False, indent=1), 1200)
    except Exception: return ''

with open(path, 'rb') as f:
    f.seek(off)
    data = f.read(min(end - off, MAXREAD))
if fresh and off > 0:
    nl = data.find(b'\n')
    data = data[nl + 1:] if nl >= 0 else b''
    off += nl + 1 if nl >= 0 else 0
start = off if fresh else -1
end = data.rfind(b'\n')
read = len(data)
data = data[:end + 1] if end >= 0 else b''
# Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
nxt = off + (read if end < 0 and read >= MAXREAD else len(data))

pos = off
for raw in data.split(b'\n'):
    at[0] = pos; pos += len(raw) + 1
    if not raw or (b'"type":"user"' not in raw and b'"type":"assistant"' not in raw and b'"subtype":"turn_duration"' not in raw and b'"subtype":"compact_boundary"' not in raw):
        continue
    try: d = json.loads(raw)
    except Exception: continue
    if d.get('isSidechain'): continue
    t = d.get('type'); ts = d.get('timestamp') or ''
    if t == 'system':
        if d.get('subtype') == 'turn_duration': emit(k='dur', ms=d.get('durationMs') or 0, ts=ts)
        elif d.get('subtype') == 'compact_boundary': emit(k='compact', ts=ts)
        continue
    m = d.get('message') or {}
    c = m.get('content')
    if t == 'user':
        if isinstance(c, list) and any(isinstance(b, dict) and b.get('type') == 'tool_result' for b in c):
            for b in c:
                if isinstance(b, dict) and b.get('type') == 'tool_result':
                    emit(k='result', id=b.get('tool_use_id') or '', err=bool(b.get('is_error')), out=cut(blocks_text(b.get('content')), 2000))
            continue
        if d.get('isMeta'): continue
        s = blocks_text(c)
        if d.get('isCompactSummary') or s.startswith('This session is being continued from a previous conversation'):
            emit(k='compact', ts=ts); continue
        if s.startswith('<task-notification>'):
            emit(k='note', t=tag(s, 'summary') or 'Background task finished', ts=ts); continue
        if '<command-name>' in s:
            name = tag(s, 'command-name'); args = tag(s, 'command-args')
            emit(k='cmd', t=(name + ' ' + args).strip(), ts=ts); continue
        if s.startswith('<local-command-stdout>') or s.startswith('<local-command-caveat>') or s.startswith('Caveat:'): continue
        s = re.sub(r'<system-reminder>.*?</system-reminder>', '', s, flags=re.S).strip()
        s = re.sub(r'^<hc from="[^"]*">(.*)</hc>$', r'\1', s, flags=re.S).strip()   # text sent with hc send
        if s: emit(k='user', t=cut(s, 8000), ts=ts)
    elif t == 'assistant':
        for b in c if isinstance(c, list) else []:
            if not isinstance(b, dict): continue
            if b.get('type') == 'text' and (b.get('text') or '').strip():
                emit(k='text', t=cut(b['text'], 20000), ts=ts)
            elif b.get('type') == 'tool_use':
                n = b.get('name') or 'Tool'; i = b.get('input') or {}
                emit(k='tool', id=b.get('id') or '', name=n, sum=cut(summary(n, i), 200), detail=detail(n, i), ts=ts)

# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
if fresh and len(out) > KEEP:
    start = out[-KEEP][0]
    out = [o for o in out if o[0] >= start]
print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
print('\n'.join(e for _, e in out))
"""#
        .replacingOccurrences(of: "INITIAL", with: String(initialTail))
        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
        .replacingOccurrences(of: "MAXREAD", with: String(maxRead))
}
import Foundation

/// Runs on the box with python3 (read-only). Finds the Codex rollout a terminal's
/// processes have open, then prints it from a byte offset in the same JSON lines as
/// `TranscriptScript`, so `ChatModel` folds both the same way.
///
/// The rollout is found from the open files of the terminal's process tree (lsof, or
/// /proc on Linux), not guessed from the folder: Codex opens it only after the first
/// message, and a Codex attached to a shared app-server has none open itself.
/// Guardian (auto-review) rollouts are skipped by their `thread_source`.
///
/// argv and output: as `TranscriptScript`. Entries come from the rollout's
/// `item_completed` events (UserMessage, AgentMessage, CommandExecution, other items as
/// generic tools) and `task_complete` (turn duration).
enum CodexTranscriptScript {
    static let source = #"""
import sys, os, json, re, subprocess
pid = int(sys.argv[1] or 0)
known = sys.argv[3]
off = int(sys.argv[4])
home = os.path.expanduser('~')

def tree(root):
    kids = {}
    try:
        for line in subprocess.run(['ps', '-axo', 'pid=,ppid='], capture_output=True, text=True).stdout.splitlines():
            a = line.split()
            if len(a) == 2: kids.setdefault(int(a[1]), []).append(int(a[0]))
    except Exception:
        pass
    out, todo = [], [root]
    while todo and len(out) < 256:
        p = todo.pop(); out.append(p); todo.extend(kids.get(p, []))
    return out

def open_paths(pids):
    paths = []
    for p in pids:
        try: paths += [os.readlink('/proc/%d/fd/%s' % (p, fd)) for fd in os.listdir('/proc/%d/fd' % p)]
        except Exception: pass
    if paths or not pids: return paths
    try:
        r = subprocess.run(['lsof', '-Fn', '-p', ','.join(str(p) for p in pids)], capture_output=True, text=True)
        return [l[1:] for l in r.stdout.splitlines() if l.startswith('n')]
    except Exception:
        return []

def meta(path):
    try:
        with open(path, 'rb') as f: d = json.loads(f.readline())
        return (d.get('payload') or {}) if d.get('type') == 'session_meta' else {}
    except Exception:
        return {}

rollouts = set(p for p in open_paths(tree(pid) if pid else []) if re.search(r'/sessions/.+/rollout-[^/]+\.jsonl$', p))
# A nested `codex exec` run by the agent writes its own user rollout; it is not this conversation.
rollouts = [p for p in rollouts if meta(p).get('thread_source', 'user') == 'user' and meta(p).get('source') != 'exec']

def by_title():
    # A Codex on the shared app-server holds no rollout itself; its terminal title is
    # "<thread name> | <folder>", and the state DB maps that name and the cwd to the rollout.
    # shortcut: two threads with the same name in the same folder are told apart only by
    # recency; upgrade when Codex exposes the thread id to the terminal.
    try: ctx = json.loads(sys.argv[2])
    except Exception: return []
    if not isinstance(ctx, dict): return []
    title = re.sub(r'^[⠀-⣿\s]+', '', str(ctx.get('title') or ''))
    name = title.rsplit(' | ', 1)[0].strip()
    cwd = str(ctx.get('cwd') or '')
    if not name or not cwd: return []
    import sqlite3, glob
    best = None
    for db in glob.glob(home + '/.codex*/state_*.sqlite'):
        try:
            con = sqlite3.connect('file:%s?mode=ro' % db, uri=True)
            for rp, at in con.execute("select rollout_path, updated_at_ms from threads where name = ? and cwd = ? and coalesce(thread_source, 'user') = 'user' and coalesce(archived, 0) = 0", (name, cwd)):
                if rp and os.path.exists(rp) and (best is None or (at or 0) > best[1]): best = (rp, at or 0)
            con.close()
        except Exception:
            pass
    return [best[0]] if best else []

if not rollouts: rollouts = by_title()
if not rollouts:
    print(json.dumps({'k': 'head', 'session': '', 'why': 'no-session'})); sys.exit(0)
path = max(rollouts, key=lambda f: os.path.getmtime(f))
sid = meta(path).get('id') or os.path.basename(path)[-41:-6]
size = os.path.getsize(path)
fresh = sid != known or off < 0 or off > size
end = size
# argv[5], when given: read the window that ends where the loaded part starts ("show earlier").
before = int(sys.argv[5]) if len(sys.argv) > 5 else -1
if before >= 0:
    if sid != known or before > size:
        print(json.dumps({'k': 'head', 'session': sid, 'why': 'moved'})); sys.exit(0)
    end, off, fresh = before, max(0, before - INITIAL), True
elif fresh:
    off = max(0, size - INITIAL)

out = []
at = [0]   # where the record being read starts
def emit(**e): out.append((at[0], json.dumps(e, ensure_ascii=False)))
def cut(s, n): s = str(s or ''); return s if len(s) <= n else s[:n] + '…'
def short(p):
    p = str(p or '')
    return p.replace(home, '~', 1) if p.startswith(home) else p
def texts(c):
    if isinstance(c, str): return c
    return '\n'.join(b.get('text') or '' for b in c or [] if isinstance(b, dict))
def shell(cmd):
    if isinstance(cmd, list):
        return cmd[2] if len(cmd) >= 3 and cmd[1] in ('-lc', '-c') else ' '.join(str(a) for a in cmd)
    return str(cmd or '')
def summary(i):
    for k in ('path', 'file_path', 'query', 'url', 'server', 'tool', 'name'):
        if i.get(k): return short(i[k]) if 'path' in k else str(i[k]).split('\n')[0]
    return ''

with open(path, 'rb') as f:
    f.seek(off)
    data = f.read(min(end - off, MAXREAD))
if fresh and off > 0:
    nl = data.find(b'\n')
    data = data[nl + 1:] if nl >= 0 else b''
    off += nl + 1 if nl >= 0 else 0
start = off if fresh else -1
end = data.rfind(b'\n')
read = len(data)
data = data[:end + 1] if end >= 0 else b''
# Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
nxt = off + (read if end < 0 and read >= MAXREAD else len(data))

pos = off
for raw in data.split(b'\n'):
    at[0] = pos; pos += len(raw) + 1
    if not raw or (b'"item_completed"' not in raw and b'"task_complete"' not in raw): continue
    try: d = json.loads(raw)
    except Exception: continue
    if d.get('type') != 'event_msg': continue
    p = d.get('payload') or {}; ts = d.get('timestamp') or ''
    if p.get('type') == 'task_complete':
        emit(k='dur', ms=int(p.get('duration_ms') or 0), ts=ts); continue
    if p.get('type') != 'item_completed': continue
    i = p.get('item') or {}; kind = i.get('type') or ''
    if kind == 'UserMessage':
        # Text sent with hc send arrives wrapped as <hc from="t7">…</hc>; show what was said.
        s = re.sub(r'^<hc from="[^"]*">(.*)</hc>$', r'\1', texts(i.get('content')).strip(), flags=re.S).strip()
        if s: emit(k='user', t=cut(s, 8000), ts=ts)
    elif kind == 'AgentMessage':
        s = texts(i.get('content')).strip()
        if s: emit(k='text', t=cut(s, 20000), ts=ts)
    elif kind == 'CommandExecution':
        cmd = shell(i.get('command'))
        emit(k='tool', id=i.get('id') or '', name='Shell', sum=cut(cmd.split('\n')[0], 200), detail=cut(cmd, 1500), ts=ts)
        code = i.get('exit_code')
        emit(k='result', id=i.get('id') or '', err=code not in (0, None), out=cut(i.get('aggregated_output'), 2000))
    elif kind in ('Reasoning', 'Plan', 'ContextCompaction'):
        if kind == 'ContextCompaction': emit(k='compact', ts=ts)
    elif kind:
        rest = {k: v for k, v in i.items() if k not in ('type', 'id')}
        emit(k='tool', id=i.get('id') or '', name=kind, sum=cut(summary(i), 200), detail=cut(json.dumps(rest, ensure_ascii=False, indent=1), 1200), ts=ts)

# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
if fresh and len(out) > KEEP:
    start = out[-KEEP][0]
    out = [o for o in out if o[0] >= start]
print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
print('\n'.join(e for _, e in out))
"""#
        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc 'cat App/Sources/UI/FilesView.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
import SwiftUI
import QuickLook
import WebKit
import HerdrKit

/// A space's folder on the box: browse it and open files in Quick Look
/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
struct FilesView: View {
    @Environment(AppStore.self) private var store
    var path: String
    var title: String

    struct Entry: Identifiable, Hashable {
        var name: String
        var isDir: Bool
        var size: Int
        /// A Contents search's first matching line.
        var snippet: String? = nil
        var id: String { name }
    }

    enum Scope: Hashable { case names, contents }

    @State private var query = ""
    @State private var scope = Scope.names
    @State private var results: [Entry]?
    @State private var partial = false
    @State private var dir: String?
    @State private var entries: [Entry] = []
    @State private var skipped = 0
    @State private var error: String?
    @State private var opening: String?
    @State private var fetch: Task<Void, Never>?
    @State private var preview: URL?
    @State private var markdown: MarkdownDoc?
    @State private var progress: String?
    @State private var web: WebDoc?

    struct WebDoc: Identifiable { var name: String; var url: URL; var id: URL { url } }

    struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }

    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
    /// and the reply is base64 inside one `Frame.maxPayload` (16 MiB) frame, so half of 8 MB is safe for both.
    static let chunkBytes = 4_000_000
    /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
    static let maxBytes = 256 << 20

    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
    static let listScript = """
    import json, os, sys
    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    out, skipped = [], 0
    with os.scandir(d) as it:
        for e in it:
            try:
                e.name.encode("utf-8")
                isdir = e.is_dir()
                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
            except (OSError, UnicodeEncodeError):
                skipped += 1
    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
    """

    // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
    // exits 1 when it is not a regular file, 4 when its size or mtime changed during this read.
    // O_NONBLOCK so a FIFO listed as a file cannot hang the read.
    static let readScript = """
    import os, stat, sys
    off, limit = int(sys.argv[2]), int(sys.argv[3])
    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
    st = os.fstat(fd)
    if not stat.S_ISREG(st.st_mode):
        sys.exit("not a regular file")
    os.lseek(fd, off, os.SEEK_SET)
    data = b""
    while len(data) < limit:
        chunk = os.read(fd, min(1 << 20, limit - len(data)))
        if not chunk:
            break
        data += chunk
    after = os.fstat(fd)
    if (after.st_size, after.st_mtime_ns) != (st.st_size, st.st_mtime_ns):
        sys.exit(4)
    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
    """

    // Prints {"results": [[relative path, is_dir, size, snippet]], "partial"}: names (folders too) or text lines
    // containing argv[2], case-insensitively, under argv[1]. Stops at 200 results or 8 seconds.
    static let searchScript = """
    import json, os, stat, subprocess, sys, time
    root, q, mode = sys.argv[1], sys.argv[2].lower(), sys.argv[3]

    def paths():
        # In a git work tree, what git lists (tracked and untracked, minus .gitignore), with their folders.
        try:
            r = subprocess.run(["git", "-C", root, "ls-files", "-co", "--exclude-standard", "-z"], capture_output=True, timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            r = None
        if r is not None and r.returncode == 0:
            seen = set()
            for p in sorted(os.fsdecode(x) for x in r.stdout.split(b"\\0") if x):
                parts = p.split("/")
                for i in range(1, len(parts)):
                    d = "/".join(parts[:i])
                    if d not in seen:
                        seen.add(d)
                        yield d, True
                yield p, False
            return
        # shortcut: outside git, prunes a fixed list of heavy folders; read ignore files if results get noisy.
        skip = {".git", "node_modules", ".venv", "__pycache__", ".build", "DerivedData", ".direnv"}
        for d, dirs, files in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in skip)
            rel = os.path.relpath(d, root)
            for n, isdir in [(x, True) for x in dirs] + [(x, False) for x in sorted(files)]:
                yield (n if rel == "." else os.path.join(rel, n)), isdir

    out, start, partial = [], time.monotonic(), False
    for p, isdir in paths():
        if time.monotonic() - start > 8:
            partial = True
            break
        if isdir and mode != "names":
            continue
        try:
            p.encode("utf-8")
            full = os.path.join(root, p)
            if mode == "names":
                if q not in os.path.basename(p).lower():
                    continue
                out.append([p, isdir, 0 if isdir else os.lstat(full).st_size, None])
            else:
                st = os.stat(full)
                if not stat.S_ISREG(st.st_mode) or st.st_size > 1 << 20:
                    continue
                with open(full, "rb") as f:
                    data = f.read()
                if b"\\0" in data[:8192]:
                    continue
                line = next((l for l in data.decode("utf-8", "replace").splitlines() if q in l.lower()), None)
                if line is None:
                    continue
                out.append([p, False, st.st_size, line.strip()[:200]])
        except (OSError, UnicodeEncodeError):
            continue
        if len(out) >= 200:
            partial = True
            break
    print(json.dumps({"results": out, "partial": partial}))
    """

    var body: some View {
        List {
            if let error {
                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
            }
            if !query.isEmpty {
                if let results {
                    if results.isEmpty { Text("No matches.").font(HF.ui(14)).foregroundStyle(HC.dim) }
                    ForEach(results) { e in
                        if e.isDir, let dir {
                            NavigationLink(value: dir + "/" + e.name) { row(e) }
                        } else {
                            Button { open(e) } label: { row(e) }.disabled(opening != nil)
                        }
                    }
                    if partial { Text("Showing the first matches only.").font(HF.ui(13)).foregroundStyle(HC.dim) }
                } else {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            } else {
            ForEach(entries) { e in
                if e.isDir, let dir {
                    NavigationLink(value: dir + "/" + e.name) { row(e) }
                } else {
                    Button { open(e) } label: { row(e) }
                        .disabled(opening != nil)
                }
            }
            if skipped > 0 {
                Text("\(skipped) item(s) with names that can't be shown are hidden.")
                    .font(HF.ui(13)).foregroundStyle(HC.dim)
            }
            }
        }
        .overlay { if dir == nil && error == nil { ProgressView() } }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find files")
        .searchScopes($scope) {
            Text("Names").tag(Scope.names)
            Text("Contents").tag(Scope.contents)
        }
        .task(id: "\(scope)\u{0}\(query)\u{0}\(dir ?? "")") { await search() }
        .task { await load() }
        .refreshable { await load() }
        .quickLookPreview($preview)
        .sheet(item: $markdown) { doc in
            NavigationStack {
                ScrollView { ChatMarkdown(text: doc.text).padding(16).frame(maxWidth: .infinity, alignment: .leading) }
                    .background(HC.canvas)
                    .navigationTitle(doc.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { markdown = nil }.accessibilityIdentifier("markdownClose") } }
            }
        }
        .sheet(item: $web, onDismiss: nil) { doc in
            NavigationStack {
                WebPreview(url: doc.url)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle(doc.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { web = nil }.accessibilityIdentifier("webClose") } }
            }
        }
        .onChange(of: web?.url) { old, new in if new == nil, let old { Self.discard(old) } }
        .onChange(of: preview) { old, new in if new == nil, let old { Self.discard(old) } }
        // Why not discard the preview here as well: presenting Quick Look can fire onDisappear while it shows the file.
        .onDisappear { fetch?.cancel(); fetch = nil; opening = nil; progress = nil }
    }

    private func row(_ e: Entry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: e.isDir ? "folder" : "doc")
                .foregroundStyle(e.isDir ? HC.working : HC.muted)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(e.name).font(HF.ui(15.5)).foregroundStyle(HC.fg).lineLimit(1).truncationMode(.head)
                if let s = e.snippet { Text(s).font(HF.mono(12)).foregroundStyle(HC.dim).lineLimit(2) }
            }
            Spacer(minLength: 8)
            if opening == e.name {
                if let progress { Text(progress).font(HF.ui(13)).foregroundStyle(HC.dim).monospacedDigit() }
                ProgressView()
            } else if !e.isDir {
                Text(e.size.formatted(.byteCount(style: .file))).font(HF.ui(13)).foregroundStyle(HC.dim)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(e.name)
    }

    private static func failure(_ r: ExecResult, _ fallback: String) -> String {
        let why = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return why.isEmpty ? fallback : String(why.suffix(300))
    }

    private func load() async {
        do {
            let r = try await store.exec(argv: ["python3", "-c", Self.listScript, path], cwd: nil, on: nil, timeout: 20, input: nil)
            guard r.code == 0, let v = try? JSONValue.parse(r.stdout), let d = v["dir"].string else {
                error = Self.failure(r, "Couldn't list \(path)")
                return
            }
            entries = Self.sorted((v["entries"].array ?? []).compactMap { a in
                guard let n = a[0].string else { return nil }
                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0)
            })
            skipped = v["skipped"].int ?? 0
            dir = d
            error = nil
        } catch {
            self.error = Self.message(error)
        }
    }

    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
    private func search() async {
        results = nil; partial = false
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, let dir else { return }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        do {
            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
                                         cwd: nil, on: nil, timeout: 20, input: nil)
            guard !Task.isCancelled else { return }
            guard r.code == 0, let v = try? JSONValue.parse(r.stdout) else { error = Self.failure(r, "Couldn't search \(dir)"); return }
            results = (v["results"].array ?? []).compactMap { a in
                guard let n = a[0].string else { return nil }
                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0, snippet: a[3].string)
            }
            partial = v["partial"].bool ?? false
            error = nil
        } catch {
            if !Task.isCancelled { self.error = Self.message(error) }
        }
    }

    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
    private static func message(_ error: Error) -> String {
        (error as? HerdrError)?.kind == "spawn_failed" ? "Files needs python3 on the box." : error.localizedDescription
    }

    /// Folders first, then files; dotfiles after the rest; each by name as Finder sorts.
    static func sorted(_ entries: [Entry]) -> [Entry] {
        entries.sorted { a, b in
            if a.isDir != b.isDir { return a.isDir }
            let ad = a.name.hasPrefix("."), bd = b.name.hasPrefix(".")
            if ad != bd { return bd }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    private func open(_ e: Entry) {
        guard let dir, opening == nil else { return }
        guard e.size <= Self.maxBytes else { error = Self.tooLarge(e.name, e.size); return }
        opening = e.name
        fetch = Task {
            defer { if !Task.isCancelled { opening = nil; fetch = nil; progress = nil } }
            do {
                guard let data = try await read(dir + "/" + e.name, e.name) else { return }
                // Why not Quick Look for Markdown: it shows the raw source; Chat's renderer formats it.
                if ["md", "markdown"].contains((e.name as NSString).pathExtension.lowercased()), let s = String(data: data, encoding: .utf8) {
                    error = nil
                    markdown = MarkdownDoc(name: e.name, text: s)
                    return
                }
                // A folder per preview, so a slow earlier fetch can never replace or delete this one.
                let folder = FileManager.default.temporaryDirectory
                    .appendingPathComponent("preview", isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let base = (e.name as NSString).lastPathComponent
                let url = folder.appendingPathComponent(base)
                error = nil
                // Why not Quick Look for HTML and SVG: it lays HTML out at desktop width and SVG at its own size.
                switch (e.name as NSString).pathExtension.lowercased() {
                case "html", "htm":
                    try Self.fitted(html: data).write(to: url, options: .completeFileProtection)
                    web = WebDoc(name: e.name, url: url)
                case "svg":
                    try data.write(to: url, options: .completeFileProtection)
                    let page = folder.appendingPathComponent("index.html")
                    try Self.wrapper(image: base).write(to: page, options: .completeFileProtection)
                    web = WebDoc(name: e.name, url: page)
                default:
                    try data.write(to: url, options: .completeFileProtection)
                    preview = url
                }
            } catch {
                if !Task.isCancelled { self.error = Self.message(error) }
            }
        }
    }

    /// The page with a phone-width viewport when it declares none.
    static func fitted(html: Data) -> Data {
        let head = String(decoding: html.prefix(8192), as: UTF8.self).lowercased()
        if head.contains("name=\"viewport\"") || head.contains("name=viewport") || head.contains("name='viewport'") { return html }
        return Data(#"<meta name="viewport" content="width=device-width, initial-scale=1">"#.utf8) + html
    }

    /// A page showing one vector image at the screen width.
    static func wrapper(image name: String) -> Data {
        let src = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return Data(#"<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1"><body style="margin:0;background:#fff"><img src="\#(src)" style="display:block;width:100%;height:auto">"#.utf8)
    }

    private static func tooLarge(_ name: String, _ size: Int) -> String {
        "\(name) is \(size.formatted(.byteCount(style: .file))); files over \(maxBytes.formatted(.byteCount(style: .file))) can't be previewed."
    }

    /// Reads the file `chunkBytes` at a time. Nil, with `error` set unless cancelled, when a read fails,
    /// the file changes size or mtime during or between chunks, a chunk comes back short, or it is over `maxBytes`.
    private func read(_ path: String, _ name: String) async throws -> Data? {
        var data = Data(), stamp: String?
        while true {
            let r = try await store.exec(argv: ["python3", "-c", Self.readScript, path, String(data.count), String(Self.chunkBytes)],
                                         cwd: nil, on: nil, timeout: 60, input: nil)
            guard !Task.isCancelled else { return nil }
            guard r.code != 4 else { error = "\(name) changed while it was being read."; return nil }
            guard r.code == 0, !r.timedOut, !r.truncated, let nl = r.stdout.firstIndex(of: 10) else {
                error = Self.failure(r, "Couldn't read \(name)"); return nil
            }
            let head = String(decoding: r.stdout[r.stdout.startIndex..<nl], as: UTF8.self)
            let size = Int(head.split(separator: " ").first ?? "") ?? 0
            guard stamp == nil || stamp == head else { error = "\(name) changed while it was being read."; return nil }
            guard size <= Self.maxBytes else { error = Self.tooLarge(name, size); return nil }
            stamp = head
            let body = r.stdout[(nl + 1)...]
            guard body.count == min(Self.chunkBytes, max(size - data.count, 0)) else { error = "\(name) changed while it was being read."; return nil }
            data.append(body)
            if size > Self.chunkBytes { progress = "\(data.count * 100 / size)%" }
            if data.count >= size { return data }
        }
    }

    /// Deletes a closed preview's downloaded copy (its own folder).
    private static func discard(_ url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}

/// A downloaded HTML page or SVG, with scripts off and file access limited to its own folder.
private struct WebPreview: UIViewRepresentable {
    let url: URL

    /// Blocks every load that is not a local file, so a page from the box can't reach the network.
    static let localOnly = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}},{"trigger":{"url-filter":"^file:"},"action":{"type":"ignore-previous-rules"}}]"#

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        let url = url
        Task { @MainActor in
            // Nothing loads until the block list is in place.
            guard let rules = try? await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "herdr-local-only", encodedContentRuleList: Self.localOnly) else { return }
            view.configuration.userContentController.add(rules)
            view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Links and redirects stay inside local files.
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            action.request.url?.isFileURL == true ? .allow : .cancel
        }
    }
}

/// The Files sheet for one space: its own stack so folders push inside the sheet.
struct FilesSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// A folder inside the project; the sheet opens at the project's root.
    var folder: String
    @State private var root: String?

    var body: some View {
        NavigationStack {
            Group {
                if let root {
                    FilesView(path: root, title: (root as NSString).lastPathComponent)
                } else {
                    ProgressView()
                }
            }
                .task { root = await store.projectRoot(folder) }
                .navigationDestination(for: String.self) { p in
                    FilesView(path: p, title: (p as NSString).lastPathComponent)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", systemImage: "xmark") { dismiss() }
                    }
                }
        }
        // Copies left by a preview that was never closed (the app quit) go when Files opens again.
        .onAppear { try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory.appendingPathComponent("preview")) }
    }
}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "nl -ba App/Sources/Chat/TranscriptScript.swift | sed -n '125,210p'; nl -ba App/Sources/Chat/CodexTranscriptScript.swift | sed -n '1,195p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
   125	        return cut('- ' + o.replace('\n', '\n- ') + '\n+ ' + n.replace('\n', '\n+ '), 1500)
   126	    if name == 'Write': return cut(i.get('content') or '', 1200)
   127	    if name == 'TodoWrite':
   128	        return '\n'.join(('☑ ' if t.get('status') == 'completed' else '▸ ' if t.get('status') == 'in_progress' else '☐ ') + (t.get('content') or '') for t in i.get('todos') or [])
   129	    try: return cut(json.dumps(i, ensure_ascii=False, indent=1), 1200)
   130	    except Exception: return ''
   131	
   132	with open(path, 'rb') as f:
   133	    f.seek(off)
   134	    data = f.read(min(end - off, MAXREAD))
   135	if fresh and off > 0:
   136	    nl = data.find(b'\n')
   137	    data = data[nl + 1:] if nl >= 0 else b''
   138	    off += nl + 1 if nl >= 0 else 0
   139	start = off if fresh else -1
   140	end = data.rfind(b'\n')
   141	read = len(data)
   142	data = data[:end + 1] if end >= 0 else b''
   143	# Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
   144	nxt = off + (read if end < 0 and read >= MAXREAD else len(data))
   145	
   146	pos = off
   147	for raw in data.split(b'\n'):
   148	    at[0] = pos; pos += len(raw) + 1
   149	    if not raw or (b'"type":"user"' not in raw and b'"type":"assistant"' not in raw and b'"subtype":"turn_duration"' not in raw and b'"subtype":"compact_boundary"' not in raw):
   150	        continue
   151	    try: d = json.loads(raw)
   152	    except Exception: continue
   153	    if d.get('isSidechain'): continue
   154	    t = d.get('type'); ts = d.get('timestamp') or ''
   155	    if t == 'system':
   156	        if d.get('subtype') == 'turn_duration': emit(k='dur', ms=d.get('durationMs') or 0, ts=ts)
   157	        elif d.get('subtype') == 'compact_boundary': emit(k='compact', ts=ts)
   158	        continue
   159	    m = d.get('message') or {}
   160	    c = m.get('content')
   161	    if t == 'user':
   162	        if isinstance(c, list) and any(isinstance(b, dict) and b.get('type') == 'tool_result' for b in c):
   163	            for b in c:
   164	                if isinstance(b, dict) and b.get('type') == 'tool_result':
   165	                    emit(k='result', id=b.get('tool_use_id') or '', err=bool(b.get('is_error')), out=cut(blocks_text(b.get('content')), 2000))
   166	            continue
   167	        if d.get('isMeta'): continue
   168	        s = blocks_text(c)
   169	        if d.get('isCompactSummary') or s.startswith('This session is being continued from a previous conversation'):
   170	            emit(k='compact', ts=ts); continue
   171	        if s.startswith('<task-notification>'):
   172	            emit(k='note', t=tag(s, 'summary') or 'Background task finished', ts=ts); continue
   173	        if '<command-name>' in s:
   174	            name = tag(s, 'command-name'); args = tag(s, 'command-args')
   175	            emit(k='cmd', t=(name + ' ' + args).strip(), ts=ts); continue
   176	        if s.startswith('<local-command-stdout>') or s.startswith('<local-command-caveat>') or s.startswith('Caveat:'): continue
   177	        s = re.sub(r'<system-reminder>.*?</system-reminder>', '', s, flags=re.S).strip()
   178	        s = re.sub(r'^<hc from="[^"]*">(.*)</hc>$', r'\1', s, flags=re.S).strip()   # text sent with hc send
   179	        if s: emit(k='user', t=cut(s, 8000), ts=ts)
   180	    elif t == 'assistant':
   181	        for b in c if isinstance(c, list) else []:
   182	            if not isinstance(b, dict): continue
   183	            if b.get('type') == 'text' and (b.get('text') or '').strip():
   184	                emit(k='text', t=cut(b['text'], 20000), ts=ts)
   185	            elif b.get('type') == 'tool_use':
   186	                n = b.get('name') or 'Tool'; i = b.get('input') or {}
   187	                emit(k='tool', id=b.get('id') or '', name=n, sum=cut(summary(n, i), 200), detail=detail(n, i), ts=ts)
   188	
   189	# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
   190	if fresh and len(out) > KEEP:
   191	    start = out[-KEEP][0]
   192	    out = [o for o in out if o[0] >= start]
   193	print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
   194	print('\n'.join(e for _, e in out))
   195	"""#
   196	        .replacingOccurrences(of: "INITIAL", with: String(initialTail))
   197	        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
   198	        .replacingOccurrences(of: "MAXREAD", with: String(maxRead))
   199	}
     1	import Foundation
     2	
     3	/// Runs on the box with python3 (read-only). Finds the Codex rollout a terminal's
     4	/// processes have open, then prints it from a byte offset in the same JSON lines as
     5	/// `TranscriptScript`, so `ChatModel` folds both the same way.
     6	///
     7	/// The rollout is found from the open files of the terminal's process tree (lsof, or
     8	/// /proc on Linux), not guessed from the folder: Codex opens it only after the first
     9	/// message, and a Codex attached to a shared app-server has none open itself.
    10	/// Guardian (auto-review) rollouts are skipped by their `thread_source`.
    11	///
    12	/// argv and output: as `TranscriptScript`. Entries come from the rollout's
    13	/// `item_completed` events (UserMessage, AgentMessage, CommandExecution, other items as
    14	/// generic tools) and `task_complete` (turn duration).
    15	enum CodexTranscriptScript {
    16	    static let source = #"""
    17	import sys, os, json, re, subprocess
    18	pid = int(sys.argv[1] or 0)
    19	known = sys.argv[3]
    20	off = int(sys.argv[4])
    21	home = os.path.expanduser('~')
    22	
    23	def tree(root):
    24	    kids = {}
    25	    try:
    26	        for line in subprocess.run(['ps', '-axo', 'pid=,ppid='], capture_output=True, text=True).stdout.splitlines():
    27	            a = line.split()
    28	            if len(a) == 2: kids.setdefault(int(a[1]), []).append(int(a[0]))
    29	    except Exception:
    30	        pass
    31	    out, todo = [], [root]
    32	    while todo and len(out) < 256:
    33	        p = todo.pop(); out.append(p); todo.extend(kids.get(p, []))
    34	    return out
    35	
    36	def open_paths(pids):
    37	    paths = []
    38	    for p in pids:
    39	        try: paths += [os.readlink('/proc/%d/fd/%s' % (p, fd)) for fd in os.listdir('/proc/%d/fd' % p)]
    40	        except Exception: pass
    41	    if paths or not pids: return paths
    42	    try:
    43	        r = subprocess.run(['lsof', '-Fn', '-p', ','.join(str(p) for p in pids)], capture_output=True, text=True)
    44	        return [l[1:] for l in r.stdout.splitlines() if l.startswith('n')]
    45	    except Exception:
    46	        return []
    47	
    48	def meta(path):
    49	    try:
    50	        with open(path, 'rb') as f: d = json.loads(f.readline())
    51	        return (d.get('payload') or {}) if d.get('type') == 'session_meta' else {}
    52	    except Exception:
    53	        return {}
    54	
    55	rollouts = set(p for p in open_paths(tree(pid) if pid else []) if re.search(r'/sessions/.+/rollout-[^/]+\.jsonl$', p))
    56	# A nested `codex exec` run by the agent writes its own user rollout; it is not this conversation.
    57	rollouts = [p for p in rollouts if meta(p).get('thread_source', 'user') == 'user' and meta(p).get('source') != 'exec']
    58	
    59	def by_title():
    60	    # A Codex on the shared app-server holds no rollout itself; its terminal title is
    61	    # "<thread name> | <folder>", and the state DB maps that name and the cwd to the rollout.
    62	    # shortcut: two threads with the same name in the same folder are told apart only by
    63	    # recency; upgrade when Codex exposes the thread id to the terminal.
    64	    try: ctx = json.loads(sys.argv[2])
    65	    except Exception: return []
    66	    if not isinstance(ctx, dict): return []
    67	    title = re.sub(r'^[⠀-⣿\s]+', '', str(ctx.get('title') or ''))
    68	    name = title.rsplit(' | ', 1)[0].strip()
    69	    cwd = str(ctx.get('cwd') or '')
    70	    if not name or not cwd: return []
    71	    import sqlite3, glob
    72	    best = None
    73	    for db in glob.glob(home + '/.codex*/state_*.sqlite'):
    74	        try:
    75	            con = sqlite3.connect('file:%s?mode=ro' % db, uri=True)
    76	            for rp, at in con.execute("select rollout_path, updated_at_ms from threads where name = ? and cwd = ? and coalesce(thread_source, 'user') = 'user' and coalesce(archived, 0) = 0", (name, cwd)):
    77	                if rp and os.path.exists(rp) and (best is None or (at or 0) > best[1]): best = (rp, at or 0)
    78	            con.close()
    79	        except Exception:
    80	            pass
    81	    return [best[0]] if best else []
    82	
    83	if not rollouts: rollouts = by_title()
    84	if not rollouts:
    85	    print(json.dumps({'k': 'head', 'session': '', 'why': 'no-session'})); sys.exit(0)
    86	path = max(rollouts, key=lambda f: os.path.getmtime(f))
    87	sid = meta(path).get('id') or os.path.basename(path)[-41:-6]
    88	size = os.path.getsize(path)
    89	fresh = sid != known or off < 0 or off > size
    90	end = size
    91	# argv[5], when given: read the window that ends where the loaded part starts ("show earlier").
    92	before = int(sys.argv[5]) if len(sys.argv) > 5 else -1
    93	if before >= 0:
    94	    if sid != known or before > size:
    95	        print(json.dumps({'k': 'head', 'session': sid, 'why': 'moved'})); sys.exit(0)
    96	    end, off, fresh = before, max(0, before - INITIAL), True
    97	elif fresh:
    98	    off = max(0, size - INITIAL)
    99	
   100	out = []
   101	at = [0]   # where the record being read starts
   102	def emit(**e): out.append((at[0], json.dumps(e, ensure_ascii=False)))
   103	def cut(s, n): s = str(s or ''); return s if len(s) <= n else s[:n] + '…'
   104	def short(p):
   105	    p = str(p or '')
   106	    return p.replace(home, '~', 1) if p.startswith(home) else p
   107	def texts(c):
   108	    if isinstance(c, str): return c
   109	    return '\n'.join(b.get('text') or '' for b in c or [] if isinstance(b, dict))
   110	def shell(cmd):
   111	    if isinstance(cmd, list):
   112	        return cmd[2] if len(cmd) >= 3 and cmd[1] in ('-lc', '-c') else ' '.join(str(a) for a in cmd)
   113	    return str(cmd or '')
   114	def summary(i):
   115	    for k in ('path', 'file_path', 'query', 'url', 'server', 'tool', 'name'):
   116	        if i.get(k): return short(i[k]) if 'path' in k else str(i[k]).split('\n')[0]
   117	    return ''
   118	
   119	with open(path, 'rb') as f:
   120	    f.seek(off)
   121	    data = f.read(min(end - off, MAXREAD))
   122	if fresh and off > 0:
   123	    nl = data.find(b'\n')
   124	    data = data[nl + 1:] if nl >= 0 else b''
   125	    off += nl + 1 if nl >= 0 else 0
   126	start = off if fresh else -1
   127	end = data.rfind(b'\n')
   128	read = len(data)
   129	data = data[:end + 1] if end >= 0 else b''
   130	# Waiting for the newline of a record longer than MAXREAD would reread the same window forever.
   131	nxt = off + (read if end < 0 and read >= MAXREAD else len(data))
   132	
   133	pos = off
   134	for raw in data.split(b'\n'):
   135	    at[0] = pos; pos += len(raw) + 1
   136	    if not raw or (b'"item_completed"' not in raw and b'"task_complete"' not in raw): continue
   137	    try: d = json.loads(raw)
   138	    except Exception: continue
   139	    if d.get('type') != 'event_msg': continue
   140	    p = d.get('payload') or {}; ts = d.get('timestamp') or ''
   141	    if p.get('type') == 'task_complete':
   142	        emit(k='dur', ms=int(p.get('duration_ms') or 0), ts=ts); continue
   143	    if p.get('type') != 'item_completed': continue
   144	    i = p.get('item') or {}; kind = i.get('type') or ''
   145	    if kind == 'UserMessage':
   146	        # Text sent with hc send arrives wrapped as <hc from="t7">…</hc>; show what was said.
   147	        s = re.sub(r'^<hc from="[^"]*">(.*)</hc>$', r'\1', texts(i.get('content')).strip(), flags=re.S).strip()
   148	        if s: emit(k='user', t=cut(s, 8000), ts=ts)
   149	    elif kind == 'AgentMessage':
   150	        s = texts(i.get('content')).strip()
   151	        if s: emit(k='text', t=cut(s, 20000), ts=ts)
   152	    elif kind == 'CommandExecution':
   153	        cmd = shell(i.get('command'))
   154	        emit(k='tool', id=i.get('id') or '', name='Shell', sum=cut(cmd.split('\n')[0], 200), detail=cut(cmd, 1500), ts=ts)
   155	        code = i.get('exit_code')
   156	        emit(k='result', id=i.get('id') or '', err=code not in (0, None), out=cut(i.get('aggregated_output'), 2000))
   157	    elif kind in ('Reasoning', 'Plan', 'ContextCompaction'):
   158	        if kind == 'ContextCompaction': emit(k='compact', ts=ts)
   159	    elif kind:
   160	        rest = {k: v for k, v in i.items() if k not in ('type', 'id')}
   161	        emit(k='tool', id=i.get('id') or '', name=kind, sum=cut(summary(i), 200), detail=cut(json.dumps(rest, ensure_ascii=False, indent=1), 1200), ts=ts)
   162	
   163	# A fresh or earlier window sends only its last KEEP entries; the phone asks for the rest with <before> = start.
   164	if fresh and len(out) > KEEP:
   165	    start = out[-KEEP][0]
   166	    out = [o for o in out if o[0] >= start]
   167	print(json.dumps({'k': 'head', 'session': sid, 'path': short(path), 'size': size, 'next': nxt, 'start': start, 'fresh': fresh, 'earlier': before >= 0, 'more': nxt < size}))
   168	print('\n'.join(e for _, e in out))
   169	"""#
   170	        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
   171	        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
   172	        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
   173	}

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg -n 'searchScript|loadEarlier|keepEntries|TranscriptScript|projectRoot|FilesSheet|startFolder' --glob '"'!*.ja.md'"'; cat App/Sources/Chat/ChatView.swift | head -100; cat App/Sources/UI/SpaceView.swift | head -110; head -90 App/Sources/UI/FilesView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
App/Sources/Store/AppStore.swift:382:        let addr = try await run(c, argv: argv, task: task, cwd: folder.isEmpty ? startFolder(for: space) : folder, space: spaceID, tab: tabID)
App/Sources/Store/AppStore.swift:801:    func startFolder(for space: SpaceRef) -> String {
App/Sources/Store/AppStore.swift:815:    func projectRoot(_ folder: String) async -> String {
App/Sources/Chat/TranscriptScript.swift:13:enum TranscriptScript {
App/Sources/Chat/TranscriptScript.swift:16:    static let keepEntries = 150
App/Sources/Chat/TranscriptScript.swift:197:        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
App/Sources/Chat/AgentScreen.swift:43:        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.terminals[address]?.cwd ?? "") }
App/Sources/Chat/ChatModel.swift:4:/// One entry the box-side script emitted (TranscriptScript).
App/Sources/Chat/ChatModel.swift:117:        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
App/Sources/Chat/ChatModel.swift:122:    func loadEarlier() async {
docs/2026-11-02_agent-and-space-views-design.md:34:The space page uses the same root: the project root of the terminal on screen, instead of its current directory. One function, `AppStore.projectRoot(of: address)`, serves Files and Changes on both pages. Changes already resolves the git root itself, so only Files changes behaviour: a terminal sitting in a subfolder opens at the repository root.
docs/2026-11-02_agent-and-space-views-design.md:38:1. `projectRoot(of:)`, Files and Changes on `AgentScreen`, the space page switched to the project root. UI test: open Files from an agent and see the repository root.
App/Sources/Chat/ChatView.swift:61:                Button { Task { await model.loadEarlier() } } label: {
docs/reviews/2026-11-02-pairing-codex.md:1737:App/Sources/Chat/CodexTranscriptScript.swift:102:def shell(cmd):
docs/reviews/2026-11-02-pairing-codex.md:1738:App/Sources/Chat/CodexTranscriptScript.swift:143:        cmd = shell(i.get('command'))
App/Sources/Chat/CodexTranscriptScript.swift:5:/// `TranscriptScript`, so `ChatModel` folds both the same way.
App/Sources/Chat/CodexTranscriptScript.swift:12:/// argv and output: as `TranscriptScript`. Entries come from the rollout's
App/Sources/Chat/CodexTranscriptScript.swift:15:enum CodexTranscriptScript {
App/Sources/Chat/CodexTranscriptScript.swift:170:        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
App/Sources/Chat/CodexTranscriptScript.swift:171:        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
App/Sources/Chat/CodexTranscriptScript.swift:172:        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/reviews/2026-11-01-fixes-codex.md:548:/// One entry the box-side script emitted (TranscriptScript).
docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
App/Sources/UI/FilesView.swift:91:    static let searchScript = """
App/Sources/UI/FilesView.swift:269:    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
App/Sources/UI/FilesView.swift:277:            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
App/Sources/UI/FilesView.swift:433:struct FilesSheet: View {
App/Sources/UI/FilesView.swift:449:                .task { root = await store.projectRoot(folder) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:14:Review the commits 6dd9552, 83f9b36 and 27db4e9 in this repo (git show each). They make Files and Changes follow the terminal on screen and the project root, add name/content search to Files (FilesView.searchScript), replace the Chat/Terminal picker, and change Chat loading: TranscriptScript and CodexTranscriptScript now send only the last KEEP entries of a fresh window and accept a <before> argument for earlier windows; ChatModel.loadEarlier prepends them with stable ids. Look for correctness and security bugs. Report findings only; do not edit.
docs/reviews/2026-11-02-files-search-chat-window-codex.md:197: App/Sources/Chat/CodexTranscriptScript.swift       | 25 ++++++++--
docs/reviews/2026-11-02-files-search-chat-window-codex.md:198: App/Sources/Chat/TranscriptScript.swift            | 32 +++++++++---
docs/reviews/2026-11-02-files-search-chat-window-codex.md:298:-    private func startFolder(for space: SpaceRef) -> String {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:299:+    func startFolder(for space: SpaceRef) -> String {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:311:-        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:313:+        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:314:+        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:381:+    static let searchScript = """
docs/reviews/2026-11-02-files-search-chat-window-codex.md:501:+    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
docs/reviews/2026-11-02-files-search-chat-window-codex.md:509:+            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
docs/reviews/2026-11-02-files-search-chat-window-codex.md:558:+        return store.startFolder(for: space)
docs/reviews/2026-11-02-files-search-chat-window-codex.md:573:-        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:574:-        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.startFolder(for: space), title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:575:+        .sheet(isPresented: $showFiles) { let f = browseFolder(space, tab); FilesSheet(folder: f, title: Self.title(f)) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:624:+        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.terminals[address]?.cwd ?? "") }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:661:-        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
docs/reviews/2026-11-02-files-search-chat-window-codex.md:664:+        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
docs/reviews/2026-11-02-files-search-chat-window-codex.md:669:+    func loadEarlier() async {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:756:+                Button { Task { await model.loadEarlier() } } label: {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:769:diff --git a/App/Sources/Chat/CodexTranscriptScript.swift b/App/Sources/Chat/CodexTranscriptScript.swift
docs/reviews/2026-11-02-files-search-chat-window-codex.md:771:--- a/App/Sources/Chat/CodexTranscriptScript.swift
docs/reviews/2026-11-02-files-search-chat-window-codex.md:772:+++ b/App/Sources/Chat/CodexTranscriptScript.swift
docs/reviews/2026-11-02-files-search-chat-window-codex.md:827:         .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:828:+        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:829:         .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:831:diff --git a/App/Sources/Chat/TranscriptScript.swift b/App/Sources/Chat/TranscriptScript.swift
docs/reviews/2026-11-02-files-search-chat-window-codex.md:833:--- a/App/Sources/Chat/TranscriptScript.swift
docs/reviews/2026-11-02-files-search-chat-window-codex.md:834:+++ b/App/Sources/Chat/TranscriptScript.swift
docs/reviews/2026-11-02-files-search-chat-window-codex.md:846: enum TranscriptScript {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:849:+    static let keepEntries = 150
docs/reviews/2026-11-02-files-search-chat-window-codex.md:908:+        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:927:+    func projectRoot(_ folder: String) async -> String {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:977: struct FilesSheet: View {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:995:+                .task { root = await store.projectRoot(folder) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1004:         return store.startFolder(for: space)
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1018:-        .sheet(isPresented: $showFiles) { let f = browseFolder(space, tab); FilesSheet(folder: f, title: Self.title(f)) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1020:+        .sheet(isPresented: $showFiles) { FilesSheet(folder: browseFolder(space, tab)) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1148:/// One entry the box-side script emitted (TranscriptScript).
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1261:        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1266:    func loadEarlier() async {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1491:/bin/zsh -lc 'cat App/Sources/Chat/TranscriptScript.swift; cat App/Sources/Chat/CodexTranscriptScript.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1505:enum TranscriptScript {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1508:    static let keepEntries = 150
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1689:        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1696:/// `TranscriptScript`, so `ChatModel` folds both the same way.
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1703:/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1706:enum CodexTranscriptScript {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1861:        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1862:        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1863:        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:1965:    static let searchScript = """
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2143:    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2151:            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2307:struct FilesSheet: View {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2323:                .task { root = await store.projectRoot(folder) }
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2345:/bin/zsh -lc "nl -ba App/Sources/Chat/TranscriptScript.swift | sed -n '125,210p'; nl -ba App/Sources/Chat/CodexTranscriptScript.swift | sed -n '1,195p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2419:   197	        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2426:     5	/// `TranscriptScript`, so `ChatModel` folds both the same way.
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2433:    12	/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2436:    15	enum CodexTranscriptScript {
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2591:   170	        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2592:   171	        .replacingOccurrences(of: "KEEP", with: String(TranscriptScript.keepEntries))
docs/reviews/2026-11-02-files-search-chat-window-codex.md:2593:   172	        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/HANDOVER.md:64:  `~/.codex*/state_*.sqlite` (a `shortcut:` in `CodexTranscriptScript.swift`).
App/Sources/UI/SpaceView.swift:34:        return store.startFolder(for: space)
App/Sources/UI/SpaceView.swift:103:        .sheet(isPresented: $showFiles) { FilesSheet(folder: browseFolder(space, tab)) }
docs/reviews/2026-11-01-files-changes-notifier-codex.md:530: struct FilesSheet: View {
docs/reviews/2026-11-01-files-changes-notifier-codex.md:558:         .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-files-changes-notifier-codex.md:1142:   285	struct FilesSheet: View {
docs/reviews/2026-11-01-files-changes-notifier-codex.md: WARNING: stopped searching binary file after match (found "\0" byte around offset 109759)
docs/reviews/2026-11-01-files-changes-notifier-fixes-codex.md:1063:+ struct FilesSheet: View {
docs/reviews/2026-11-01-files-changes-notifier-fixes-codex.md:1091:+         .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-files-changes-notifier-fixes-codex.md:1675:+   285	struct FilesSheet: View {
docs/reviews/2026-11-01-files-changes-notifier-fixes-codex.md: WARNING: stopped searching binary file after match (found "\0" byte around offset 140745)
docs/reviews/2026-11-01-review-fixes-codex.md:872:+/// One entry the box-side script emitted (TranscriptScript).
docs/reviews/2026-11-01-review-fixes-codex.md:980:+                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-review-fixes-codex.md:4113:@@ -154,5 +203,7 @@ struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:5136:+   140	struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:5244:+    90	        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-review-fixes-codex.md:5708:++struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:5752:++        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-review-fixes-codex.md:6320:+   140	struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:6551:+docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-review-fixes-codex.md:7341:@@ -154,5 +203,7 @@ struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:7549:   189	struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:7792:     4	/// One entry the box-side script emitted (TranscriptScript).
docs/reviews/2026-11-01-review-fixes-codex.md:7901:   113	                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-review-fixes-codex.md:8384:struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:8454:/bin/zsh -lc "rg -n 'hostKey\\(|pinned\\(|pinnedFingerprint|FilesSheet|func exec|func request|cancel|stdout|output.*limit' App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift App/Sources/Net App/Sources/UI/RootView.swift App/Sources/UI/MainView.swift UITests/HerdrUITests.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-review-fixes-codex.md:8608:/bin/zsh -lc "sed -n '155,235p' Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; sed -n '190,225p' App/Sources/Store/AppStore.swift; sed -n '428,444p' App/Sources/Store/AppStore.swift; sed -n '480,582p' App/Sources/Store/AppStore.swift; rg -n 'FilesSheet|filesSheet|showFiles' App/Sources" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-review-fixes-codex.md:8849:App/Sources/UI/SpaceView.swift:90:        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-review-fixes-codex.md:8850:App/Sources/UI/FilesView.swift:189:struct FilesSheet: View {
docs/reviews/2026-11-01-review-fixes-codex.md:8905:struct FilesSheet: View {
docs/reviews/2026-11-01-codex-chat-codex.md:14:Review commits 1f37e96 and eb6790d in this repo (git show 1f37e96 eb6790d): Codex conversations in Chat (App/Sources/Chat/CodexTranscriptScript.swift, ChatModel.swift, AgentScreen.swift), Markdown file preview (App/Sources/UI/FilesView.swift), the dialog parser BlockedCard.parse in App/Sources/Chat/ChatView.swift, and the <hc from> unwrap in both transcript scripts. Compare with App/Sources/Chat/TranscriptScript.swift, which the Codex script mirrors. Review only; do not edit files. For each finding: severity, file:line, concrete failure scenario, suggested fix. Check: the rollout lookup (process tree + lsof or /proc, guardian filtering, the title/cwd fallback against Codex's state_*.sqlite: wrong thread picked, spinner/title formats, sqlite read-only with WAL, cost of running it every 1.5 s), offset/tail handling, parsing of item_completed/task_complete, the parser's countdown across gaps (false positives from numbered lists in agent output while blocked, permission dialogs 1. Yes / 2. ... / 3. No), and the Markdown sheet's state handling. Say 'no findings' where none. Be concise.
docs/reviews/2026-11-01-codex-chat-codex.md:163: App/Sources/Chat/CodexTranscriptScript.swift | 155 +++++++++++++++++++++++++++
docs/reviews/2026-11-01-codex-chat-codex.md:181: App/Sources/Chat/TranscriptScript.swift |  1 +
docs/reviews/2026-11-01-codex-chat-codex.md:251:/bin/zsh -lc 'git show 1f37e96 eb6790d -- App/Sources; nl -ba App/Sources/Chat/CodexTranscriptScript.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-codex-chat-codex.md:308:+        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
docs/reviews/2026-11-01-codex-chat-codex.md:313:-                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-codex-chat-codex.md:331:diff --git a/App/Sources/Chat/CodexTranscriptScript.swift b/App/Sources/Chat/CodexTranscriptScript.swift
docs/reviews/2026-11-01-codex-chat-codex.md:335:+++ b/App/Sources/Chat/CodexTranscriptScript.swift
docs/reviews/2026-11-01-codex-chat-codex.md:341:+/// `TranscriptScript`, so `ChatModel` folds both the same way.
docs/reviews/2026-11-01-codex-chat-codex.md:348:+/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-01-codex-chat-codex.md:351:+enum CodexTranscriptScript {
docs/reviews/2026-11-01-codex-chat-codex.md:489:+        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
docs/reviews/2026-11-01-codex-chat-codex.md:490:+        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/reviews/2026-11-01-codex-chat-codex.md:582:diff --git a/App/Sources/Chat/TranscriptScript.swift b/App/Sources/Chat/TranscriptScript.swift
docs/reviews/2026-11-01-codex-chat-codex.md:584:--- a/App/Sources/Chat/TranscriptScript.swift
docs/reviews/2026-11-01-codex-chat-codex.md:585:+++ b/App/Sources/Chat/TranscriptScript.swift
docs/reviews/2026-11-01-codex-chat-codex.md:598:     5	/// `TranscriptScript`, so `ChatModel` folds both the same way.
docs/reviews/2026-11-01-codex-chat-codex.md:605:    12	/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-01-codex-chat-codex.md:608:    15	enum CodexTranscriptScript {
docs/reviews/2026-11-01-codex-chat-codex.md:746:   153	        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
docs/reviews/2026-11-01-codex-chat-codex.md:747:   154	        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/reviews/2026-11-01-codex-chat-codex.md:757:/bin/zsh -lc 'nl -ba App/Sources/Chat/TranscriptScript.swift; nl -ba App/Sources/Chat/ChatModel.swift' in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-codex-chat-codex.md:770:    12	enum TranscriptScript {
docs/reviews/2026-11-01-codex-chat-codex.md:941:     4	/// One entry the box-side script emitted (TranscriptScript).
docs/reviews/2026-11-01-codex-chat-codex.md:1048:   111	        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
docs/reviews/2026-11-01-codex-chat-codex.md:1253:/bin/zsh -lc "nl -ba App/Sources/Chat/CodexTranscriptScript.swift; nl -ba App/Sources/Chat/ChatView.swift | sed -n '420,570p'; nl -ba App/Sources/UI/FilesView.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-codex-chat-codex.md:1259:     5	/// `TranscriptScript`, so `ChatModel` folds both the same way.
docs/reviews/2026-11-01-codex-chat-codex.md:1266:    12	/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-01-codex-chat-codex.md:1269:    15	enum CodexTranscriptScript {
docs/reviews/2026-11-01-codex-chat-codex.md:1407:   153	        .replacingOccurrences(of: "INITIAL", with: String(TranscriptScript.initialTail))
docs/reviews/2026-11-01-codex-chat-codex.md:1408:   154	        .replacingOccurrences(of: "MAXREAD", with: String(TranscriptScript.maxRead))
docs/reviews/2026-11-01-codex-chat-codex.md:1767:   207	struct FilesSheet: View {
docs/reviews/2026-11-01-codex-chat-codex.md:1792:/bin/zsh -lc "rg -n 'BlockedCard|parse\\(|codex|rollout|thread_source|item_completed|task_complete' UITests scripts docs/reviews README.md App/Sources/Store App/Sources/Chat/AgentScreen.swift; sed -n '1,100p' App/Sources/Chat/TranscriptScript.swift; git log -3 --oneline" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
docs/reviews/2026-11-01-codex-chat-codex.md:1828:docs/reviews/2026-11-01-files-codex.md:2425:docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-codex-chat-codex.md:1926:docs/reviews/2026-11-01-review-fixes-codex.md:6551:+docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
docs/reviews/2026-11-01-codex-chat-codex.md:2002:docs/reviews/2026-11-01-codex-chat-codex.md:14:Review commits 1f37e96 and eb6790d in this repo (git show 1f37e96 eb6790d): Codex conversations in Chat (App/Sources/Chat/CodexTranscriptScript.swift, ChatModel.swift, AgentScreen.swift), Markdown file preview (App/Sources/UI/FilesView.swift), the dialog parser BlockedCard.parse in App/Sources/Chat/ChatView.swift, and the <hc from> unwrap in both transcript scripts. Compare with App/Sources/Chat/TranscriptScript.swift, which the Codex script mirrors. Review only; do not edit files. For each finding: severity, file:line, concrete failure scenario, suggested fix. Check: the rollout lookup (process tree + lsof or /proc, guardian filtering, the title/cwd fallback against Codex's state_*.sqlite: wrong thread picked, spinner/title formats, sqlite read-only with WAL, cost of running it every 1.5 s), offset/tail handling, parsing of item_completed/task_complete, the parser's countdown across gaps (false positives from numbered lists in agent output while blocked, permission dialogs 1. Yes / 2. ... / 3. No), and the Markdown sheet's state handling. Say 'no findings' where none. Be concise.
docs/reviews/2026-11-01-codex-chat-codex.md:2012:docs/reviews/2026-11-01-codex-chat-codex.md:308:+        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
docs/reviews/2026-11-01-codex-chat-codex.md:2019:docs/reviews/2026-11-01-codex-chat-codex.md:348:+/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-01-codex-chat-codex.md:2040:docs/reviews/2026-11-01-codex-chat-codex.md:605:    12	/// argv and output: as `TranscriptScript`. Entries come from the rollout's
docs/reviews/2026-11-01-codex-chat-codex.md:2056:docs/reviews/2026-11-01-codex-chat-codex.md:1048:   111	        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
docs/reviews/2026-11-01-codex-chat-codex.md:2074:enum TranscriptScript {
docs/reviews/2026-11-01-codex-chat-codex.md:2395:struct FilesSheet: View {
docs/reviews/2026-11-01-codex-chat-codex.md:2743:docs/HANDOVER.md:64:  `~/.codex*/state_*.sqlite` (a `shortcut:` in `CodexTranscriptScript.swift`).
docs/reviews/2026-11-01-codex-chat-codex.md:2821:  `~/.codex*/state_*.sqlite` (a `shortcut:` in `CodexTranscriptScript.swift`).
docs/reviews/2026-11-01-codex-chat-codex.md:2839:App/Sources/Store/AppStore.swift:353:        let addr = try await run(c, argv: argv, task: task, cwd: folder.isEmpty ? startFolder(for: space) : folder, space: spaceID, tab: tabID)
docs/reviews/2026-11-01-codex-chat-codex.md:2953:1. **High — Another conversation can replace the selected terminal’s Chat.** [CodexTranscriptScript.swift:55](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/CodexTranscriptScript.swift:55), line 85. Lookup collects rollouts from every descendant and selects the most recently modified. If the agent launches a separate `codex exec`, its user rollout can win; guardian filtering does not exclude it. **Fix:** associate candidates with their owning process and prefer the terminal’s primary Codex process over nested sessions.
docs/reviews/2026-11-01-codex-chat-codex.md:2959:4. **Medium — A large JSONL record permanently stalls incremental reading.** [CodexTranscriptScript.swift:112](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/CodexTranscriptScript.swift:112). A complete record exceeding `maxRead` (16 MiB) contains no newline within the read window. `next` remains unchanged, so every poll rereads the same bytes and later messages never appear. This is inherited from the Claude script. **Fix:** advance through oversized records to their terminating newline, with bounded memory.
docs/reviews/2026-11-01-codex-chat-codex.md:2974:1. **High — Another conversation can replace the selected terminal’s Chat.** [CodexTranscriptScript.swift:55](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/CodexTranscriptScript.swift:55), line 85. Lookup collects rollouts from every descendant and selects the most recently modified. If the agent launches a separate `codex exec`, its user rollout can win; guardian filtering does not exclude it. **Fix:** associate candidates with their owning process and prefer the terminal’s primary Codex process over nested sessions.
docs/reviews/2026-11-01-codex-chat-codex.md:2980:4. **Medium — A large JSONL record permanently stalls incremental reading.** [CodexTranscriptScript.swift:112](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/CodexTranscriptScript.swift:112). A complete record exceeding `maxRead` (16 MiB) contains no newline within the read window. `next` remains unchanged, so every poll rereads the same bytes and later messages never appear. This is inherited from the Claude script. **Fix:** advance through oversized records to their terminating newline, with bounded memory.
docs/reviews/2026-11-01-files-codex.md:1010:   140	struct FilesSheet: View {
docs/reviews/2026-11-01-files-codex.md:1118:    90	        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-files-codex.md:1582:+struct FilesSheet: View {
docs/reviews/2026-11-01-files-codex.md:1626:+        .sheet(isPresented: $showFiles) { FilesSheet(folder: space.folder, title: name.isEmpty ? "~" : name) }
docs/reviews/2026-11-01-files-codex.md:2194:   140	struct FilesSheet: View {
docs/reviews/2026-11-01-files-codex.md:2425:docs/reviews/2026-11-01-fixes-codex.md:656:                let r = try await store.exec(argv: ["python3", "-c", TranscriptScript.source, pid, argv, session, String(offset)],
import SwiftUI
import HerdrKit

/// An agent's conversation as native messages, read from its transcript.
/// Holds no terminal attach: nothing here types into or resizes the program
/// except Send, Stop and the blocked card's choices.
struct ChatView: View {
    let address: String
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ChatModel

    init(address: String) {
        self.address = address
        _model = State(initialValue: ChatModel(address: address))
    }

    var body: some View {
        let att = store.attention(of: address)
        let rec = store.terminals[address]
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                content(working: att == .working)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .scrollEdgeEffectStyle(.hard, for: .top)
        .scrollDismissesKeyboard(.interactively)
        .background(HC.canvas)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if att == .blocked { BlockedCard(address: address) }
                ChatComposer(address: address, working: att == .working)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
        .onAppear { model.start(store: store) }
        .onDisappear { model.stop() }
        .onChange(of: rec?.statusWord) { _, _ in model.nudge() }
        .onChange(of: rec?.turn) { _, _ in model.nudge() }
        .onChange(of: store.phase) { _, p in if p == .connected { model.nudge() } }
        .onChange(of: scenePhase) { _, p in if p == .active { model.nudge() } }
    }

    @ViewBuilder private func content(working: Bool) -> some View {
        switch model.phase {
        case .loading where model.turns.isEmpty:
            HStack(spacing: 10) { ProgressView(); Text("Reading the conversation…").foregroundStyle(HC.muted) }
                .font(HF.ui(14)).frame(maxWidth: .infinity).padding(.top, 60)
        case .unavailable(let why):
            emptyState("text.bubble", why, hint: "Switch to Terminal to see the screen.")
        case .failed(let why) where model.turns.isEmpty:
            emptyState("exclamationmark.triangle", "Couldn't read the conversation", hint: why)
        default:
            if model.hasEarlier {
                Button { Task { await model.loadEarlier() } } label: {
                    HStack(spacing: 8) {
                        if model.loadingEarlier { ProgressView() } else { Image(systemName: "clock.arrow.circlepath") }
                        Text("Show earlier messages")
                    }
                    .font(HF.ui(13)).foregroundStyle(HC.muted).frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(model.loadingEarlier)
                .accessibilityIdentifier("chatEarlier")
            }
            ForEach(model.turns) { turn in
                TurnView(turn: turn, isLast: turn.id == model.turns.last?.id, working: working)
            }
            if working { WorkingRow(since: model.turns.last?.startedAt) }
        }
    }

    private func emptyState(_ symbol: String, _ title: String, hint: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 28, weight: .light)).foregroundStyle(HC.dim)
            Text(title).font(HF.ui(15, .medium)).foregroundStyle(HC.fg).multilineTextAlignment(.center)
            Text(hint).font(HF.ui(13)).foregroundStyle(HC.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 80).padding(.horizontal, 24)
    }
}

// MARK: Turn

private struct TurnView: View {
    let turn: ChatTurn
    let isLast: Bool
    let working: Bool
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if turn.compacted {
                divider("Conversation compacted")
import SwiftUI
import HerdrKit

/// One space: a glass chip bar of tabs, then the selected tab's panes.
/// Phone: one pane at a time, paged. iPad: a grid of pane cards.
struct SpaceView: View {
    @Environment(AppStore.self) private var store
    @Environment(Navigator.self) private var nav
    @Environment(\.horizontalSizeClass) private var hsc
    var spaceID: String
    @State private var paneIndex = 0
    @State private var showFiles = false
    @State private var showChanges = false

    private var space: SpaceRef? { store.spaces.first { $0.id == spaceID } }

    var body: some View {
        Group {
            if let space {
                content(space)
            } else {
                ContentUnavailableView("Space closed", systemImage: "square.dashed",
                                       description: Text("This space is no longer in the layout."))
            }
        }
        .background(HC.canvas)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The folder of the terminal on screen (the page shown on a phone; on iPad, where every pane shows, the tab's first).
    private func browseFolder(_ space: SpaceRef, _ tab: TabRef?) -> String {
        if hsc != .regular, let tab, tab.panes.indices.contains(paneIndex), let addr = tab.panes[paneIndex].terminal,
           let cwd = store.terminals[addr]?.cwd, !cwd.isEmpty { return cwd }
        return store.startFolder(for: space)
    }


    private func selectedTab(_ space: SpaceRef) -> TabRef? {
        let id = store.selectedTabBySpace[space.id]
        return space.tabs.first { $0.id == id } ?? space.tabs.first
    }

    @ViewBuilder private func content(_ space: SpaceRef) -> some View {
        let name = store.spaceName(space)
        let tab = selectedTab(space)
        VStack(spacing: 0) {
            TabChipBar(space: space, selected: tab?.id) { id in
                withAnimation(.smooth(duration: 0.25)) {
                    store.selectedTabBySpace[space.id] = id
                    paneIndex = 0
                }
            }
            if let tab {
                if tab.panes.isEmpty {
                    ContentUnavailableView("Empty tab", systemImage: "rectangle.dashed")
                } else if hsc == .regular {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 380), spacing: 14)], spacing: 14) {
                            ForEach(tab.panes) { pane in
                                PaneCard(pane: pane, spaceName: name).frame(height: 360)
                            }
                        }
                        .padding(16)
                    }
                } else {
                    TabView(selection: $paneIndex) {
                        ForEach(Array(tab.panes.enumerated()), id: \.element.id) { i, pane in
                            PaneCard(pane: pane, spaceName: name)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, tab.panes.count > 1 ? 44 : 16)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: tab.panes.count > 1 ? .always : .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .id(tab.id)
                }
            } else {
                ContentUnavailableView("No tabs", systemImage: "rectangle.stack")
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    SpaceBadge(name: name.isEmpty ? "~" : name, colorKey: SpaceBadge.colorKey(for: space.id), size: 20)
                    Text(name.isEmpty ? "~" : name).font(HF.ui(16, .semibold)).foregroundStyle(HC.fg).lineLimit(1)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showChanges = true } label: { Image(systemName: "plusminus") }
                    .accessibilityLabel("Changes")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFiles = true } label: { Image(systemName: "folder") }
                    .accessibilityLabel("Files")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { nav.newAgentSpace = space.id; nav.showNewAgent = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("New agent in this space")
            }
        }
        .sheet(isPresented: $showFiles) { FilesSheet(folder: browseFolder(space, tab)) }
        .sheet(isPresented: $showChanges) { ChangesSheet(folder: browseFolder(space, tab)) }
        .onAppear { store.selectedSpaceID = space.id }
    }
}

/// Horizontally scrolling glass chips, one per tab, tinted by status.
struct TabChipBar: View {
import SwiftUI
import QuickLook
import WebKit
import HerdrKit

/// A space's folder on the box: browse it and open files in Quick Look
/// (PDF, Office, images, text). Lists and reads with the box's python3, like Chat.
struct FilesView: View {
    @Environment(AppStore.self) private var store
    var path: String
    var title: String

    struct Entry: Identifiable, Hashable {
        var name: String
        var isDir: Bool
        var size: Int
        /// A Contents search's first matching line.
        var snippet: String? = nil
        var id: String { name }
    }

    enum Scope: Hashable { case names, contents }

    @State private var query = ""
    @State private var scope = Scope.names
    @State private var results: [Entry]?
    @State private var partial = false
    @State private var dir: String?
    @State private var entries: [Entry] = []
    @State private var skipped = 0
    @State private var error: String?
    @State private var opening: String?
    @State private var fetch: Task<Void, Never>?
    @State private var preview: URL?
    @State private var markdown: MarkdownDoc?
    @State private var progress: String?
    @State private var web: WebDoc?

    struct WebDoc: Identifiable { var name: String; var url: URL; var id: URL { url } }

    struct MarkdownDoc: Identifiable { var name: String; var text: String; var id: String { name } }

    /// The most read in one machine.exec: the core keeps the first "8 MB" of stdout (read as 8,000,000 bytes),
    /// and the reply is base64 inside one `Frame.maxPayload` (16 MiB) frame, so half of 8 MB is safe for both.
    static let chunkBytes = 4_000_000
    /// The largest file previewed; the copy lives on the phone while Quick Look shows it.
    static let maxBytes = 256 << 20

    // Prints {"dir", "entries": [[name, is_dir, size]], "skipped"}; "~" expands on the box.
    // Names that are not valid UTF-8 are skipped: JSON could not carry them back intact.
    static let listScript = """
    import json, os, sys
    d = os.path.realpath(os.path.expanduser(sys.argv[1]))
    out, skipped = [], 0
    with os.scandir(d) as it:
        for e in it:
            try:
                e.name.encode("utf-8")
                isdir = e.is_dir()
                out.append([e.name, isdir, 0 if isdir else e.stat().st_size])
            except (OSError, UnicodeEncodeError):
                skipped += 1
    print(json.dumps({"dir": d, "entries": out, "skipped": skipped}))
    """

    // Writes "<size> <mtime_ns>\n", then at most argv[3] bytes of the regular file argv[1] from offset argv[2];
    // exits 1 when it is not a regular file, 4 when its size or mtime changed during this read.
    // O_NONBLOCK so a FIFO listed as a file cannot hang the read.
    static let readScript = """
    import os, stat, sys
    off, limit = int(sys.argv[2]), int(sys.argv[3])
    fd = os.open(sys.argv[1], os.O_RDONLY | os.O_NONBLOCK)
    st = os.fstat(fd)
    if not stat.S_ISREG(st.st_mode):
        sys.exit("not a regular file")
    os.lseek(fd, off, os.SEEK_SET)
    data = b""
    while len(data) < limit:
        chunk = os.read(fd, min(1 << 20, limit - len(data)))
        if not chunk:
            break
        data += chunk
    after = os.fstat(fd)
    if (after.st_size, after.st_mtime_ns) != (st.st_size, st.st_mtime_ns):
        sys.exit(4)
    sys.stdout.buffer.write(b"%d %d\\n" % (st.st_size, st.st_mtime_ns) + data)
    """

    // Prints {"results": [[relative path, is_dir, size, snippet]], "partial"}: names (folders too) or text lines
    // containing argv[2], case-insensitively, under argv[1]. Stops at 200 results or 8 seconds.

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
Files の検索処理と Chat のページ境界を確認しています。検索対象の重複と読み取り上限、古い履歴を取得した際の欠落を、再現条件を絞って検証します。

hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "rg -n 'test|search|Files|earlier|150|16 MiB' README.md docs/2026-11-02_agent-and-space-views-design.md project.yml scripts --glob '"'!*.ja.md'"'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
project.yml:26:    configFiles:
project.yml:66:    type: bundle.ui-testing
project.yml:68:    configFiles:
project.yml:76:        PRODUCT_BUNDLE_IDENTIFIER: $(HERDR_BUNDLE_ID).uitests
project.yml:84:        HerdrUITests: [test]
project.yml:85:    test:
README.md:32:- **Files.** Browse the folder of the terminal on screen (its current directory, not the folder the space was created with) and search it by file name or by contents (in a git repository, .gitignore applies). An agent page opens Files and Changes at the agent's project root (its git repository) and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
README.md:48:- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads the last 16 MiB of the transcript but sends the phone only the last 150 entries, then new bytes; "Show earlier messages" fetches the 150 before those. Space cards show the last turns too. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
README.md:63:3. Open Herdr while connected and allow notifications. Settings → Notifications → Send a test.
README.md:73:- **Your machine:** herdr-core 0.1.11+, reachable over SSH; python3 for Chat and Files.
README.md:110:Packages/HerdrKit     protocol and model (SwiftPM, platform-independent, unit-tested)
README.md:120:scripts/              mod bundling and a headless mod test
README.md:124:- **Protocol and model:** `cd Packages/HerdrKit && swift test`.
README.md:125:- **UI:** run the `HerdrUITests` target against a real box in watch-only mode. Pass settings to the test runner with the `TEST_RUNNER_` prefix (e.g. `TEST_RUNNER_HERDR_DEBUG_KEY_PATH`): `HERDR_DEBUG_KEY_PATH` always; `HERDR_TEST_HOST`, `HERDR_TEST_USER`, `HERDR_TEST_HOST_FP` for first-connect approval; `HERDR_TEST_SPACE`, `HERDR_TEST_FILES_PATH`, `HERDR_TEST_FILES` for Files; `HERDR_TEST_TERMINAL` for Chat.
README.md:130:This is early. It's tested against herdr-core 0.1.14 on a real Linux machine. Known gaps:
docs/2026-11-02_agent-and-space-views-design.md:3:Status: implemented. Decided: space cards show Chat (item 1) without their own switch, following the app-wide mode; Chat opens with the last 150 entries and loads earlier ones on request; after loading, the view stays at the top, at the oldest loaded message.
docs/2026-11-02_agent-and-space-views-design.md:7:| Screen | How it is reached | What it shows | Chat/Terminal switch | Files / Changes |
docs/2026-11-02_agent-and-space-views-design.md:12:So the two paths already meet: a pane card opens the same `AgentScreen` as the agent list, with the switch. What the space page lacks is Chat on the card itself, and what the agent page lacks is Files.
docs/2026-11-02_agent-and-space-views-design.md:24:### 2. Files and Changes on the agent page
docs/2026-11-02_agent-and-space-views-design.md:26:`AgentScreen` gets Files and Changes, in a `…` menu next to the switch so the title keeps its width.
docs/2026-11-02_agent-and-space-views-design.md:34:The space page uses the same root: the project root of the terminal on screen, instead of its current directory. One function, `AppStore.projectRoot(of: address)`, serves Files and Changes on both pages. Changes already resolves the git root itself, so only Files changes behaviour: a terminal sitting in a subfolder opens at the repository root.
docs/2026-11-02_agent-and-space-views-design.md:38:1. `projectRoot(of:)`, Files and Changes on `AgentScreen`, the space page switched to the project root. UI test: open Files from an agent and see the repository root.
scripts/mods-test/main.swift:1:// Headless mod test: runs the app's own ModEngine (JavaScriptCore) with the
scripts/mods-test/main.swift:7:// Build + run: scripts/mods-test/run.sh
scripts/mods-test/main.swift:17:let testHome = env["MODS_TEST_HOME"] ?? "~"
scripts/mods-test/main.swift:25:        func deny(_ why: String) -> ModFailure { ModFailure("blocked by test safety policy (\(why)): \(([cmd] + args).joined(separator: " "))") }
scripts/mods-test/main.swift:186:        "spaces": [["id": "sptest", "index": 0, "name": "demo", "named": true, "folder": "\(testHome)/projects/demo",
scripts/mods-test/main.swift:188:        "focused": ["space": "sptest", "tab": NSNull(), "pane": NSNull(), "terminal": NSNull(), "shown": NSNull(), "agent": NSNull(), "cwd": NSNull()],
scripts/mods-test/main.swift:193:        "home": testHome,
scripts/mods-test/run.sh:2:# Headless mod test: compiles the app's Foundation-only mod host files with a
scripts/mods-test/run.sh:3:# macOS test harness and runs every bundled mod against live data from
scripts/mods-test/run.sh:6:#   scripts/mods-test/run.sh                 # all mods
scripts/mods-test/run.sh:7:#   MODS_TEST_ONLY=prs scripts/mods-test/run.sh
scripts/mods-test/run.sh:12:OUT="$ROOT/build/mods-test"
scripts/mods-test/run.sh:20:  "$ROOT/scripts/mods-test/main.swift" \
scripts/mods-test/run.sh:21:  -o "$OUT/mods-test"
scripts/mods-test/run.sh:22:exec "$OUT/mods-test" "$ROOT"
scripts/mods-transform.mjs:29:    if (/;\s*$/.test(line) || /from\s*["'][^"']+["']\s*;?\s*$/.test(line)) {
scripts/mods-transform.mjs:40:  if (/^import[\s{*"']/.test(trimmed)) {
scripts/mods-transform.mjs:41:    if (/from\s*["'][^"']+["']\s*;?\s*$/.test(trimmed) || /^import\s*["'][^"']+["']\s*;?$/.test(trimmed)) {
scripts/mods-transform.mjs:59:  if (/^export\s*\{/.test(lines[j].trim())) {
scripts/mods-transform.mjs:87:  if (/^import\s*[{*\w]/.test(line)) {
scripts/mods-transform.mjs:90:    while (!extFrom.test(stmt) && k + 1 < exportStart && k - j < 20 && !/;\s*$/.test(lines[k])) {
scripts/mods-transform.mjs:94:    if (extFrom.test(stmt)) {
scripts/mods-transform.mjs:104:if (body.some((l) => /^export\s/.test(l))) throw new Error("unexpected export inside the body of " + input);
scripts/install-notifier.sh:32:echo "done. Open Herdr on the phone (connected) and allow notifications; then Settings → Notifications → Send a test."

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "git show 27db4e9 -- App/Sources/Chat/ChatModel.swift; rg -n 'func exec|cancel|timedOut|truncated' App/Sources/Store/AppStore.swift Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift; command -v uv; git ls-files -co --exclude-standard -z App/Sources/UI | xargs -0 -n 1" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 27db4e9768c34326a25bf93c688f995432e9cf96
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 04:46:26 2026 +0900

    Open Chat with the last 150 entries, load earlier ones on request, show Chat on space cards, and add Files and Changes to the agent page
    
    Opening Chat sent up to 16 MiB of parsed transcript (about 700 KB, 930 entries here) and
    laid it all out; the box still reads 16 MiB in 0.3 s, but now sends only the last 150
    entries and fetches the 150 before them when asked. Turn ids come from entry sequence
    numbers so loading earlier entries does not renumber what is shown.
    Files and Changes open at the git root of the agent process's folder, which does not
    move when the agent runs cd in its child shells; the space page uses the same root.

diff --git a/App/Sources/Chat/ChatModel.swift b/App/Sources/Chat/ChatModel.swift
index 9e2d604..64877c6 100644
--- a/App/Sources/Chat/ChatModel.swift
+++ b/App/Sources/Chat/ChatModel.swift
@@ -52,11 +52,16 @@ final class ChatModel {
     private(set) var turns: [ChatTurn] = []
     /// The transcript continues above what was loaded (we only read its tail).
     private(set) var hasEarlier = false
+    private(set) var loadingEarlier = false
     private(set) var revision = 0
 
     private var entries: [ChatEntry] = []
     private var session = ""
     private var offset: Int64 = -1
+    /// Where the loaded part of the transcript begins.
+    private var start: Int64 = 0
+    /// The sequence number of `entries[0]`; earlier windows count down, so ids already shown never change.
+    private var firstSeq = 0
     private var loop: Task<Void, Never>?
     private var wake: CheckedContinuation<Void, Never>?
     private var sleeper: Task<Void, Never>?
@@ -104,16 +109,39 @@ final class ChatModel {
         }
     }
 
-    private func load() async {
-        guard let store, store.phase == .connected, let rec = store.terminals[address] else { return }
-        let pid = rec.raw["pid"].int.map(String.init) ?? "0"
+    /// The transcript script and its leading arguments for this terminal.
+    private func invocation(_ store: AppStore) -> [String]? {
+        guard let rec = store.terminals[address] else { return nil }
         let codex = store.programKey(of: address) == "codex"
-        let script = codex ? CodexTranscriptScript.source : TranscriptScript.source
         let context: JSONValue = codex ? ["title": .string(rec.title), "cwd": .string(rec.cwd)] : rec.raw["argv"]
-        let argv = String(decoding: context.encoded(), as: UTF8.self)
+        return ["python3", "-c", codex ? CodexTranscriptScript.source : TranscriptScript.source,
+                rec.raw["pid"].int.map(String.init) ?? "0", String(decoding: context.encoded(), as: UTF8.self)]
+    }
+
+    /// Reads the window above what is loaded and puts it in front.
+    func loadEarlier() async {
+        guard hasEarlier, !loadingEarlier, let store, store.phase == .connected, let call = invocation(store) else { return }
+        loadingEarlier = true
+        defer { loadingEarlier = false }
+        guard let r = try? await store.exec(argv: call + [session, "-1", String(start)], cwd: nil, on: nil, timeout: 20, input: nil),
+              r.code == 0 else { return }
+        var lines = r.stdout.split(separator: UInt8(ascii: "\n"))
+        // Anything else (the session changed meanwhile) leaves the chat as it is.
+        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())), head["earlier"].bool == true,
+              head["session"].string == session else { return }
+        let earlier = lines.compactMap { (try? JSONValue.parse(Data($0))).flatMap(Self.entry) }
+        entries = earlier + entries
+        firstSeq -= earlier.count
+        start = Int64(head["start"].double ?? 0)
+        hasEarlier = start > 0
+        rebuild()
+    }
+
+    private func load() async {
+        guard let store, store.phase == .connected, let call = invocation(store) else { return }
         for _ in 0..<4 {   // follow "more" a few times on a big backlog
             do {
-                let r = try await store.exec(argv: ["python3", "-c", script, pid, argv, session, String(offset)],
+                let r = try await store.exec(argv: call + [session, String(offset)],
                                              cwd: nil, on: nil, timeout: 20, input: nil)
                 guard r.code == 0 else {
                     let err = String(decoding: r.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
@@ -142,8 +170,10 @@ final class ChatModel {
         let fresh = head["fresh"].bool ?? false
         if fresh {
             entries = []
+            firstSeq = 0
             session = head["session"].string ?? ""
-            hasEarlier = (head["start"].int ?? 0) > 0
+            start = Int64(head["start"].double ?? 0)
+            hasEarlier = start > 0
         }
         offset = Int64(head["next"].double ?? Double(offset))
         var added = false
@@ -182,13 +212,16 @@ final class ChatModel {
     private func rebuild() {
         var out: [ChatTurn] = []
         var where_: [String: (turn: Int, step: Int, call: Int)] = [:]
-        var n = 0
-        func next() -> Int { n += 1; return n }
+        // A turn takes its entry's sequence number times two, a step that number plus one: one entry makes at most one of each.
+        var seq = 0
+        func next() -> Int { seq * 2 }
+        func step() -> Int { seq * 2 + 1 }
         func current() -> Int {
             if out.isEmpty { out.append(ChatTurn(id: next())) }
             return out.count - 1
         }
-        for e in entries {
+        for (i, e) in entries.enumerated() {
+            seq = firstSeq + i
             switch e {
             case .user(let s, let at): out.append(ChatTurn(id: next(), prompt: .user(s), startedAt: at))
             case .note(let s): out.append(ChatTurn(id: next(), prompt: .note(s)))
@@ -198,7 +231,7 @@ final class ChatModel {
                 if let last = out.last, last.compacted, last.prompt == nil, last.steps.isEmpty { continue }
                 out.append(ChatTurn(id: next(), compacted: true))
             case .text(let s):
-                let i = current(); out[i].steps.append(.text(next(), s))
+                let i = current(); out[i].steps.append(.text(step(), s))
             case .tool(let id, let name, let sum, let detail, let at):
                 let i = current()
                 if out[i].startedAt == nil { out[i].startedAt = at }
@@ -208,7 +241,7 @@ final class ChatModel {
                     out[i].steps[out[i].steps.count - 1] = .tools(sid, calls)
                     where_[id] = (i, out[i].steps.count - 1, calls.count - 1)
                 } else {
-                    out[i].steps.append(.tools(next(), [call]))
+                    out[i].steps.append(.tools(step(), [call]))
                     where_[id] = (i, out[i].steps.count - 1, 0)
                 }
             case .result(let id, let err, let output):
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:45:    private var cancelled: Set<UInt64> = []
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:65:        writerTask?.cancel(); livenessTask?.cancel(); outbox.finish()
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:164:    /// kind). Cancelling the task sends `$/cancelRequest`.
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:172:                enum Outcome { case go, cancelled, closed }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:174:                    if cancelled.remove(id) != nil { return .cancelled }
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:179:                case .cancelled: cont.resume(throwing: CancellationError()); return
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:191:                cancelled.insert(id); return false
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:195:                notify("$/cancelRequest", ["id": .number(Double(id))])
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:220:    public func exec(argv: [String], cwd: String? = nil, on: String? = nil, timeout: Int = 30, input: Data? = nil) async throws -> ExecResult {
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:229:                          timedOut: r["timed_out"].bool ?? false,
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:230:                          truncated: r["truncated"].bool ?? false)
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:366:                // A reply nobody waits for (cancelled or timed out). If it opened a
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:453:        livenessTask?.cancel()
Packages/HerdrKit/Sources/HerdrKit/HerdrClient.swift:529:    public func cancel() { onUpdate = nil; onClose = nil; onLost = nil; closer?(); closer = nil }
App/Sources/Store/AppStore.swift:114:            backgroundTask?.cancel(); backgroundTask = nil
App/Sources/Store/AppStore.swift:457:    func exec(argv: [String], cwd: String?, on: String?, timeout: Int, input: Data?) async throws -> ExecResult {
App/Sources/Store/AppStore.swift:495:        reconnectTask?.cancel(); reconnectTask = nil
App/Sources/Store/AppStore.swift:496:        connectTask?.cancel()
App/Sources/Store/AppStore.swift:566:        if !retry { reconnectTask?.cancel(); reconnectTask = nil }
App/Sources/Store/AppStore.swift:589:        reconnectTask?.cancel()
App/Sources/Store/AppStore.swift:602:        connectTask?.cancel(); connectTask = nil
App/Sources/Store/AppStore.swift:603:        reconnectTask?.cancel(); reconnectTask = nil
App/Sources/Store/AppStore.swift:647:                    guard gen == self.generation else { s.cancel(); return }
/etc/profiles/per-user/yosuke/bin/uv
App/Sources/UI/ChangesView.swift
App/Sources/UI/Components.swift
App/Sources/UI/ConnectionViews.swift
App/Sources/UI/DemoData.swift
App/Sources/UI/FilesView.swift
App/Sources/UI/MainView.swift
App/Sources/UI/NewAgentSheet.swift
App/Sources/UI/Programs.swift
App/Sources/UI/RootView.swift
App/Sources/UI/SettingsView.swift
App/Sources/UI/SpaceView.swift
App/Sources/UI/TerminalEngine.swift
App/Sources/UI/TerminalScreen.swift
App/Sources/UI/Theme.swift

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "cat App/Sources/Chat/AgentScreen.swift; sed -n '166,230p' App/Sources/UI/SpaceView.swift; rg -n 'struct TerminalRecord|var cwd|foreground' Packages/HerdrKit/Sources/HerdrKit App/Sources/Store --glob '*.swift'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
import SwiftUI
import HerdrKit

/// An agent's page: its conversation (Chat) or its live terminal. Chat is
/// offered for Claude Code and Codex, whose transcripts the box can read; the choice is
/// app-wide and remembered.
struct AgentScreen: View {
    let address: String
    @Environment(AppStore.self) private var store
    @AppStorage("agentViewMode") private var mode = "chat"
    @State private var showFiles = false
    @State private var showChanges = false

    var body: some View {
        let canChat = ["claude", "codex"].contains(store.programKey(of: address))
        Group {
            if canChat && mode == "chat" {
                ChatScreen(address: address)
            } else {
                TerminalScreen(address: address)
            }
        }
        .toolbar {
            if canChat {
                // Why not a segmented Picker: iOS 26 draws it as a second capsule inside the toolbar's glass.
                ToolbarItem(placement: .topBarTrailing) {
                    let chat = mode == "chat"
                    Button(chat ? "Terminal" : "Chat", systemImage: chat ? "terminal" : "text.bubble") {
                        withAnimation(.smooth(duration: 0.25)) { mode = chat ? "terminal" : "chat" }
                    }
                }
            }
            // A menu, not two more buttons: the title keeps its width.
            ToolbarItem(placement: .topBarTrailing) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Files", systemImage: "folder") { showFiles = true }
                    Button("Changes", systemImage: "plusminus") { showChanges = true }
                }
                .accessibilityIdentifier("agentMore")
            }
        }
        // The agent process's folder: its own shell commands run in child shells, so it stays where the agent started.
        .sheet(isPresented: $showFiles) { FilesSheet(folder: store.terminals[address]?.cwd ?? "") }
        .sheet(isPresented: $showChanges) { ChangesSheet(folder: store.terminals[address]?.cwd ?? "") }
    }
}

private struct ChatScreen: View {
    let address: String
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ChatView(address: address)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { TerminalTitle(address: address) } }
            .onAppear {
                store.visibleTerminal = address
                store.markSeen(address)
            }
            .onDisappear { if store.visibleTerminal == address { store.visibleTerminal = nil } }
            .onChange(of: store.terminals[address]?.statusWord) { _, _ in store.markSeen(address) }
            .onChange(of: scenePhase) { _, p in if p == .active { store.markSeen(address) } }
    }
}
}

/// One pane as a crisp card: header + a text preview of the screen. Tap opens the terminal.
struct PaneCard: View {
    @Environment(AppStore.self) private var store
    @Environment(Navigator.self) private var nav
    @AppStorage("agentViewMode") private var mode = "chat"
    var pane: PaneRef
    var spaceName: String

    var body: some View {
        VStack(spacing: 0) {
            if let addr = pane.terminal {
                Button { nav.open(.terminal(addr)) } label: {
                    VStack(spacing: 0) {
                        header(addr)
                        Rectangle().fill(HC.border).frame(height: HM.hairline)
                        if mode == "chat" && ["claude", "codex"].contains(store.programKey(of: addr)) {
                            ChatPreview(address: addr)
                        } else {
                            TerminalPreview(address: addr)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            } else if let mod = pane.mod {
                HStack {
                    Image(systemName: "puzzlepiece.extension").foregroundStyle(HC.muted)
                    Text(mod).font(HF.ui(13.5, .medium)).foregroundStyle(HC.fg)
                    Spacer()
                }
                .padding(.horizontal, 12).frame(height: 38)
                Rectangle().fill(HC.border).frame(height: HM.hairline)
                ModPanelView(mod: mod, props: pane.modProps.object?.mapValues(\.any))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                Spacer()
            }
        }
        .clipShape(.rect(cornerRadius: HM.cardRadius))
        .herdrCard()
    }

    private func header(_ addr: String) -> some View {
        let rec = store.terminals[addr]
        return HStack(spacing: 8) {
            ProgramIcon(program: store.programKey(of: addr), size: 16)
            Text(store.displayName(of: addr)).font(HF.ui(14, .medium)).foregroundStyle(HC.fg).lineLimit(1)
            Text(store.tildePath(rec?.cwd ?? "")).font(HF.ui(12.5)).foregroundStyle(HC.dim).lineLimit(1)
            Spacer(minLength: 4)
            StatusMark(attention: store.attention(of: addr))
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(HC.dim)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }
}

/// The last turns of a Claude Code or Codex conversation, in the same mode as the agent page.
struct ChatPreview: View {
    @Environment(AppStore.self) private var store
    @State private var model: ChatModel

    init(address: String) { _model = State(initialValue: ChatModel(address: address)) }
App/Sources/Store/AppStore.swift:349:        if let fg = tok["terminal_foreground"] { display["fg"] = .string(fg) }
Packages/HerdrKit/Sources/HerdrKit/Programs.swift:47:    /// Identity from the status app (if any) and argv (`foreground.argv` when non-empty, else `argv`).
Packages/HerdrKit/Sources/HerdrKit/ProgramTable.swift:7:    /// key, display name, aliases (`match`), tile color, icon foreground, icon tinted
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:58:public struct TerminalRecord: Identifiable, Equatable, Sendable {
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:65:    public var cwd: String { raw["foreground"]["cwd"].string ?? raw["cwd"].string ?? "" }
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:75:    public var argv: [String] { (raw["foreground"]["argv"].array ?? raw["argv"].array ?? []).compactMap { $0.string } }
Packages/HerdrKit/Sources/HerdrKit/EventLines.swift:128:            t.removeValue(forKey: "foreground")
Packages/HerdrKit/Sources/HerdrKit/EventLines.swift:135:        case "foreground": t["foreground"] = data

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "git show 6dd9552 -- README.md README.ja.md; git show 83f9b36 -- README.md README.ja.md; git show 27db4e9 -- README.md README.ja.md docs/2026-11-02_agent-and-space-views-design.md; rg -n 'maxPayload|stdout|8_000_000|8000000|truncated' Packages/HerdrKit/Sources/HerdrKit/Frame.swift Packages/HerdrKit/Sources/HerdrKit/Contracts.swift" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
commit 6dd95522efe72edbc51222a0d9d2aaeca413df0d
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 01:35:58 2026 +0900

    Open Files and Changes where the space's terminal is, not where the space was created
    
    A space keeps the folder it was made with; after cd in its terminal, Files showed
    the old folder (a space named irireshi listed ararat). New tabs already start from
    the terminal's live folder, so Files and Changes now use the same rule.

diff --git a/README.ja.md b/README.ja.md
index ee0dec1..b354f58 100644
--- a/README.ja.md
+++ b/README.ja.md
@@ -31,7 +31,7 @@
   - 終わったターンは「Worked for 5m 18s · 12 steps」の下に折りたたむ。
   - 各ツール呼び出しは、タップできる 1 行で表示する。
   - ブロックされた agent のダイアログはボタンになる。
-- **Files。** マシン上の space のフォルダを閲覧し、PDF、Word・Excel・PowerPoint の文書、画像（HEIC を含む）、テキストを iPhone 上の Quick Look で開く。Markdown は整形して表示する。HTML と SVG は、スクリプトとネットワークの読み込みを止めたうえで、画面の幅で表示する。256 MiB までのファイルを分割して読む。
+- **Files。** マシン上で、space の端末がいるフォルダ（space を作ったときのフォルダではなく、端末の現在のディレクトリ）を閲覧し、PDF、Word・Excel・PowerPoint の文書、画像（HEIC を含む）、テキストを iPhone 上の Quick Look で開く。Markdown は整形して表示する。HTML と SVG は、スクリプトとネットワークの読み込みを止めたうえで、画面の幅で表示する。256 MiB までのファイルを分割して読む。
 - **Changes。** space の git の未 commit の変更を一覧にし、ファイルごとの diff を色分けして表示する。git はマシン上で読み取り専用で実行する。
 - **Terminal。** 本物の terminal（SwiftTerm）である。既定ではデスクトップと同じサイズを映し、ピンチでズームできる。「Fit to phone」のトグルを使うと、代わりに iPhone の画面に合わせてサイズを変える。ガラス調のキーバーが esc、ctrl、矢印キー、^C を加え、入力欄からプロンプト全体を送れる。
 - **新しい agent。** Claude Code、Codex、shell、または herdr の一覧にある任意のプログラムを起動する。起動先は既存の space か新しいフォルダで、最初のタスクを任意で指定できる。
diff --git a/README.md b/README.md
index 9596d39..6d9b45a 100644
--- a/README.md
+++ b/README.md
@@ -29,7 +29,7 @@ A native iPhone and iPad client for [herdr](https://herdr.dev). See which of you
   - finished turns fold behind "Worked for 5m 18s · 12 steps";
   - each tool call is one tappable line;
   - a blocked agent's dialog becomes buttons.
-- **Files.** Browse a space's folder on the box and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
+- **Files.** Browse the folder a space's terminal is in on the box (its current directory, not the folder the space was created with) and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
 - **Changes.** A space's uncommitted git changes, and each file's diff coloured by line, from the box's git (read-only).
 - **Terminal.** The real terminal (SwiftTerm), mirroring the desktop size by default with pinch-to-zoom. A "Fit to phone" toggle resizes it to the phone instead. A glass key bar adds esc, ctrl, arrows and ^C, and a compose box sends whole prompts.
 - **New agents.** Start Claude Code, Codex, a shell or any program from herdr's list, in an existing space or a new folder, with an optional first task.
commit 83f9b361bd4a54d2ff4e040f3069fc3a99e1c9d2
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 02:11:29 2026 +0900

    Follow the terminal on screen in Files, add name and content search, and use one button to switch Chat and Terminal
    
    Files and Changes open the folder of the pane the phone shows, as the desktop Herdr app
    follows the focused terminal. The search bar finds names or text under the current folder,
    using git's file list (so .gitignore applies) and capped at 200 results or 8 seconds.
    The segmented Chat/Terminal picker drew a second capsule inside the iOS 26 toolbar glass.

diff --git a/README.ja.md b/README.ja.md
index b354f58..4e757cc 100644
--- a/README.ja.md
+++ b/README.ja.md
@@ -31,7 +31,7 @@
   - 終わったターンは「Worked for 5m 18s · 12 steps」の下に折りたたむ。
   - 各ツール呼び出しは、タップできる 1 行で表示する。
   - ブロックされた agent のダイアログはボタンになる。
-- **Files。** マシン上で、space の端末がいるフォルダ（space を作ったときのフォルダではなく、端末の現在のディレクトリ）を閲覧し、PDF、Word・Excel・PowerPoint の文書、画像（HEIC を含む）、テキストを iPhone 上の Quick Look で開く。Markdown は整形して表示する。HTML と SVG は、スクリプトとネットワークの読み込みを止めたうえで、画面の幅で表示する。256 MiB までのファイルを分割して読む。
+- **Files。** 画面に出ている端末のフォルダ（space を作ったときのフォルダではなく、端末の現在のディレクトリ）を閲覧し、ファイル名または中身で検索し（git の repo の中では .gitignore に従う）、PDF、Word・Excel・PowerPoint の文書、画像（HEIC を含む）、テキストを iPhone 上の Quick Look で開く。Markdown は整形して表示する。HTML と SVG は、スクリプトとネットワークの読み込みを止めたうえで、画面の幅で表示する。256 MiB までのファイルを分割して読む。
 - **Changes。** space の git の未 commit の変更を一覧にし、ファイルごとの diff を色分けして表示する。git はマシン上で読み取り専用で実行する。
 - **Terminal。** 本物の terminal（SwiftTerm）である。既定ではデスクトップと同じサイズを映し、ピンチでズームできる。「Fit to phone」のトグルを使うと、代わりに iPhone の画面に合わせてサイズを変える。ガラス調のキーバーが esc、ctrl、矢印キー、^C を加え、入力欄からプロンプト全体を送れる。
 - **新しい agent。** Claude Code、Codex、shell、または herdr の一覧にある任意のプログラムを起動する。起動先は既存の space か新しいフォルダで、最初のタスクを任意で指定できる。
diff --git a/README.md b/README.md
index 6d9b45a..f309bb4 100644
--- a/README.md
+++ b/README.md
@@ -29,7 +29,7 @@ A native iPhone and iPad client for [herdr](https://herdr.dev). See which of you
   - finished turns fold behind "Worked for 5m 18s · 12 steps";
   - each tool call is one tappable line;
   - a blocked agent's dialog becomes buttons.
-- **Files.** Browse the folder a space's terminal is in on the box (its current directory, not the folder the space was created with) and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
+- **Files.** Browse the folder of the terminal on screen (its current directory, not the folder the space was created with) and search it by file name or by contents (in a git repository, .gitignore applies) and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
 - **Changes.** A space's uncommitted git changes, and each file's diff coloured by line, from the box's git (read-only).
 - **Terminal.** The real terminal (SwiftTerm), mirroring the desktop size by default with pinch-to-zoom. A "Fit to phone" toggle resizes it to the phone instead. A glass key bar adds esc, ctrl, arrows and ^C, and a compose box sends whole prompts.
 - **New agents.** Start Claude Code, Codex, a shell or any program from herdr's list, in an existing space or a new folder, with an optional first task.
commit 27db4e9768c34326a25bf93c688f995432e9cf96
Author: i2 <95607264+YosukeIida@users.noreply.github.com>
Date:   Mon Nov 2 04:46:26 2026 +0900

    Open Chat with the last 150 entries, load earlier ones on request, show Chat on space cards, and add Files and Changes to the agent page
    
    Opening Chat sent up to 16 MiB of parsed transcript (about 700 KB, 930 entries here) and
    laid it all out; the box still reads 16 MiB in 0.3 s, but now sends only the last 150
    entries and fetches the 150 before them when asked. Turn ids come from entry sequence
    numbers so loading earlier entries does not renumber what is shown.
    Files and Changes open at the git root of the agent process's folder, which does not
    move when the agent runs cd in its child shells; the space page uses the same root.

diff --git a/README.ja.md b/README.ja.md
index 4e757cc..5143b0a 100644
--- a/README.ja.md
+++ b/README.ja.md
@@ -31,7 +31,7 @@
   - 終わったターンは「Worked for 5m 18s · 12 steps」の下に折りたたむ。
   - 各ツール呼び出しは、タップできる 1 行で表示する。
   - ブロックされた agent のダイアログはボタンになる。
-- **Files。** 画面に出ている端末のフォルダ（space を作ったときのフォルダではなく、端末の現在のディレクトリ）を閲覧し、ファイル名または中身で検索し（git の repo の中では .gitignore に従う）、PDF、Word・Excel・PowerPoint の文書、画像（HEIC を含む）、テキストを iPhone 上の Quick Look で開く。Markdown は整形して表示する。HTML と SVG は、スクリプトとネットワークの読み込みを止めたうえで、画面の幅で表示する。256 MiB までのファイルを分割して読む。
+- **Files。** 画面に出ている端末のフォルダ（space を作ったときのフォルダではなく、端末の現在のディレクトリ）を閲覧し、ファイル名または中身で検索し（git の repo の中では .gitignore に従う）。agent の画面からは、agent の project の root（git の repo）で Files と Changes を開く。、PDF、Word・Excel・PowerPoint の文書、画像（HEIC を含む）、テキストを iPhone 上の Quick Look で開く。Markdown は整形して表示する。HTML と SVG は、スクリプトとネットワークの読み込みを止めたうえで、画面の幅で表示する。256 MiB までのファイルを分割して読む。
 - **Changes。** space の git の未 commit の変更を一覧にし、ファイルごとの diff を色分けして表示する。git はマシン上で読み取り専用で実行する。
 - **Terminal。** 本物の terminal（SwiftTerm）である。既定ではデスクトップと同じサイズを映し、ピンチでズームできる。「Fit to phone」のトグルを使うと、代わりに iPhone の画面に合わせてサイズを変える。ガラス調のキーバーが esc、ctrl、矢印キー、^C を加え、入力欄からプロンプト全体を送れる。
 - **新しい agent。** Claude Code、Codex、shell、または herdr の一覧にある任意のプログラムを起動する。起動先は既存の space か新しいフォルダで、最初のタスクを任意で指定できる。
@@ -47,7 +47,7 @@
 - **ペアリングを使わないログイン:** アプリは Ed25519 の鍵を Keychain の中に生成する。その公開鍵をマシンの `~/.ssh/authorized_keys` に追加する。オンボーディングの画面に、コピーできる 1 行のコマンドが表示される。パスワードや、貼り付けた秘密鍵でもログインできる。
 - **host key:** 初回の接続では、アプリはログインの前に止まり、マシンの host key の fingerprint を表示する。user が承認すると、その host key を Keychain に pin する。ペアリングではこの手順を省く。コードが host key を持つためである。すでに pin された host key を、コードで置き換えることはない。
 - **ネットワーク:** マシンは iPhone から到達できる必要がある。たとえば Tailscale を経由する。
-- **Chat:** マシン上の Claude Code の transcript を、読み取り専用の短い `python3` スクリプトで読む。スクリプトは herdr-core の `machine.exec` を通して実行する。セッションは、terminal のプロセスツリーから `~/.claude/sessions` を介して特定する。transcript は末尾だけを読み、その後は新しく追加されたバイトだけを読む。そのため、大きな transcript でも負荷は小さい。 Codex では、terminal のプロセスが開いている rollout を読む。共有の app-server につながった Codex は rollout を開いていないので、terminal の title（thread の名前）とフォルダから、Codex の state のデータベースで thread を引く。起動したばかりの Codex は、最初のメッセージを送るまで rollout を持たない。
+- **Chat:** マシン上の Claude Code の transcript を、読み取り専用の短い `python3` スクリプトで読む。スクリプトは herdr-core の `machine.exec` を通して実行する。セッションは、terminal のプロセスツリーから `~/.claude/sessions` を介して特定する。transcript は末尾の 16 MiB を読むが、iPhone へ送るのは最後の 150 件だけで、その後は新しく追加されたバイトだけを読む。「Show earlier messages」で、その前の 150 件を取得する。space のカードにも直近の turn を表示する。 Codex では、terminal のプロセスが開いている rollout を読む。共有の app-server につながった Codex は rollout を開いていないので、terminal の title（thread の名前）とフォルダから、Codex の state のデータベースで thread を引く。起動したばかりの Codex は、最初のメッセージを送るまで rollout を持たない。
 - **Chat を開くとき**は terminal に attach しない。そのため、デスクトップ側のサイズは何も変わらない。
 
 ## 通知
diff --git a/README.md b/README.md
index f309bb4..d316e13 100644
--- a/README.md
+++ b/README.md
@@ -29,7 +29,7 @@ A native iPhone and iPad client for [herdr](https://herdr.dev). See which of you
   - finished turns fold behind "Worked for 5m 18s · 12 steps";
   - each tool call is one tappable line;
   - a blocked agent's dialog becomes buttons.
-- **Files.** Browse the folder of the terminal on screen (its current directory, not the folder the space was created with) and search it by file name or by contents (in a git repository, .gitignore applies) and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
+- **Files.** Browse the folder of the terminal on screen (its current directory, not the folder the space was created with) and search it by file name or by contents (in a git repository, .gitignore applies). An agent page opens Files and Changes at the agent's project root (its git repository) and open PDFs, Word, Excel and PowerPoint documents, images (including HEIC) and text in Quick Look, on the phone; Markdown is rendered as formatted text. HTML and SVG open at phone width with scripts and network loads off. Files up to 256 MiB are read in chunks.
 - **Changes.** A space's uncommitted git changes, and each file's diff coloured by line, from the box's git (read-only).
 - **Terminal.** The real terminal (SwiftTerm), mirroring the desktop size by default with pinch-to-zoom. A "Fit to phone" toggle resizes it to the phone instead. A glass key bar adds esc, ctrl, arrows and ^C, and a compose box sends whole prompts.
 - **New agents.** Start Claude Code, Codex, a shell or any program from herdr's list, in an existing space or a new folder, with an optional first task.
@@ -45,7 +45,7 @@ The app opens an SSH exec channel to your machine and runs `herdr-core connect`.
 - **Login without pairing:** the app generates an Ed25519 key in the Keychain. Add its public key to the box's `~/.ssh/authorized_keys`; onboarding shows a copyable one-liner. A password or a pasted private key also works.
 - **Host key:** on first connect the app stops before logging in and shows the box's host key fingerprint; it is pinned in the Keychain once you approve it. Pairing skips this: the code carries the host key, and a code never replaces a key already pinned.
 - **Network:** the box has to be reachable from the phone, for example over Tailscale.
-- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads only the tail of the transcript, then new bytes, so large transcripts stay cheap. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
+- **Chat:** reads Claude Code's transcript on the box with a short read-only `python3` script, run through the core's `machine.exec`. It finds the session from the terminal's process tree via `~/.claude/sessions`. It reads the last 16 MiB of the transcript but sends the phone only the last 150 entries, then new bytes; "Show earlier messages" fetches the 150 before those. Space cards show the last turns too. For Codex it reads the rollout the terminal's processes have open; a Codex on the shared app-server has none open, so its thread is looked up by the terminal title (the thread name) and folder in Codex's state database. A new Codex has no rollout until the first message.
 - **Opening Chat** never attaches to the terminal, so it doesn't resize anything on your desktop.
 
 ## Notifications
diff --git a/docs/2026-11-02_agent-and-space-views-design.md b/docs/2026-11-02_agent-and-space-views-design.md
new file mode 100644
index 0000000..0dc502f
--- /dev/null
+++ b/docs/2026-11-02_agent-and-space-views-design.md
@@ -0,0 +1,44 @@
+# Agent and space views: Chat/Terminal switching and the project file tree
+
+Status: implemented. Decided: space cards show Chat (item 1) without their own switch, following the app-wide mode; Chat opens with the last 150 entries and loads earlier ones on request; after loading, the view stays at the top, at the oldest loaded message.
+
+## What the app does now
+
+| Screen | How it is reached | What it shows | Chat/Terminal switch | Files / Changes |
+|---|---|---|---|---|
+| Space (`SpaceView`) | the space list | one card per pane; the card body is the terminal's plain-text tail (`TerminalPreview`) | none on the card | toolbar buttons; folder = the terminal on screen (83f9b36) |
+| Agent (`AgentScreen`) | tapping an agent row **or a pane card in a space** | Chat or the live terminal | toolbar button, Claude Code and Codex only; the choice is app-wide (`@AppStorage("agentViewMode")`) | none |
+
+So the two paths already meet: a pane card opens the same `AgentScreen` as the agent list, with the switch. What the space page lacks is Chat on the card itself, and what the agent page lacks is Files.
+
+## Proposal
+
+### 1. Chat on the space page
+
+The card body follows the app-wide mode: in Chat mode a Claude Code or Codex pane shows the last few messages instead of the terminal tail; other programs keep the terminal tail. The card header gets the same switch button as `AgentScreen`, and tapping the card opens `AgentScreen` in that mode.
+
+Cost: each visible card reads its transcript on the box (the Chat script). A phone shows one card at a time, but the page view builds its neighbours too; an iPad grid shows all of them. Reads happen when the turn or status changes, as `TerminalPreview` does now.
+
+Rejected: a separate Chat tab inside the space page. It would duplicate `AgentScreen`.
+
+### 2. Files and Changes on the agent page
+
+`AgentScreen` gets Files and Changes, in a `…` menu next to the switch so the title keeps its width.
+
+The root is the agent's project root: `git rev-parse --show-toplevel` run in the agent process's working directory, else that directory when it is not in a git repository. It is resolved when the sheet opens and does not follow later moves.
+
+Why the agent process's directory is stable: Claude Code and Codex run their shell commands in child shells, so their own `cd` does not change the agent process's working directory, which herdr-core reports as `foreground.cwd` (the app's `TerminalRecord.cwd`). It stays the directory the agent was started in. Not checked on the box yet: that `foreground.cwd` is unchanged after Claude Code runs `cd` in a turn.
+
+### 3. One rule for both pages
+
+The space page uses the same root: the project root of the terminal on screen, instead of its current directory. One function, `AppStore.projectRoot(of: address)`, serves Files and Changes on both pages. Changes already resolves the git root itself, so only Files changes behaviour: a terminal sitting in a subfolder opens at the repository root.
+
+## Order of work
+
+1. `projectRoot(of:)`, Files and Changes on `AgentScreen`, the space page switched to the project root. UI test: open Files from an agent and see the repository root.
+2. Chat preview on the space cards.
+3. Codex review of each step.
+
+## Open question
+
+- Does item 1 of the proposal match what is wanted, or is the existing switch after tapping a card enough? If it is enough, step 2 is dropped.
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:17:    public static let maxPayload = 16 << 20
Packages/HerdrKit/Sources/HerdrKit/Frame.swift:78:        guard len <= Frame.maxPayload else { throw FrameError(length: len) }
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:8:    /// Start the process/channel. `onBytes` gets stdout in order; `onClose`
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:46:    public var stdout: Data
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:49:    public var truncated: Bool   // it wrote more than the core kept (stdout 8 MB, stderr 1 MB)
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:50:    public init(code: Int?, stdout: Data, stderr: Data, timedOut: Bool, truncated: Bool = false) {
Packages/HerdrKit/Sources/HerdrKit/Contracts.swift:51:        self.code = code; self.stdout = stdout; self.stderr = stderr; self.timedOut = timedOut; self.truncated = truncated

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
hook: PermissionRequest
hook: PermissionRequest Completed
exec
/bin/zsh -lc "uv run --offline --no-project --no-cache python - <<'PY'
from pathlib import Path
import io,json,contextlib,sys

def run(name, records, before=None):
    src=Path('App/Sources/Chat/'+name+'.swift').read_text().split('#\"\"\"\\n',1)[1].split('\\n\"\"\"#',1)[0]
    src=src[src.index('size = os.path.getsize(path)'):]
    src=src.replace('INITIAL',str(16<<20)).replace('MAXREAD',str(16<<20)).replace('KEEP','150')
    data=b''.join(json.dumps(r,separators=(',',':'),ensure_ascii=False).encode()+b'\\n' for r in records)
    class OS:
        class path:
            @staticmethod
            def getsize(path): return len(data)
    args=['script','0','[]','sid','-1']+([] if before is None else [str(before)])
    env=dict(sys=type('Sys',(),{'argv':args})(),os=OS,json=json,re=__import__('re'),path='fixture',sid='sid',known='sid',off=-1,home='/home/test',open=lambda *a:io.BytesIO(data))
    out=io.StringIO()
    with contextlib.redirect_stdout(out): exec(src,env)
    return out.getvalue().encode()

# 150 normal-sized entries within a 16 MiB input window can exceed the core's 8 MB output limit.
records=[{'type':'assistant','message':{'content':[{'type':'text','text':'😀'*20000}]}} for _ in range(150)]
out=run('TranscriptScript',records)
head=json.loads(out.splitlines()[0]); kept=out[:8_000_000].splitlines()[1:]; valid=0
for line in kept:
    try: json.loads(line); valid+=1
    except ValueError: pass
print('fresh emoji page:', 'bytes',len(out),'next',head['next'],'start',head['start'],'entries surviving transport cap',valid)
# Confirm ordinary pagination does retain all records.
records=[{'type':'assistant','message':{'content':[{'type':'text','text':str(i)}]}} for i in range(330)]
seen=[]; before=None
while True:
    out=run('TranscriptScript',records,before); lines=out.splitlines(); head=json.loads(lines[0]); seen=[json.loads(x)['t'] for x in lines[1:]]+seen
    if not head['start']: break
    before=head['start']
print('ordinary pagination:',len(seen),'unique',len(set(seen)))
PY" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 44ms:
fresh emoji page: bytes 12005097 next 12010650 start 0 entries surviving transport cap 99
ordinary pagination: 330 unique 330

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
通常のページ分割では、330件を重複・欠落なく取得できました。一方、1ページの出力が herdr-core の8 MB上限を超える場合の欠落を確認しました。続けて、Contents 検索がシンボリックリンク先を読む経路と、空白だけの検索で表示が停止する条件を確認します。

hook: PreToolUse
hook: PreToolUse Completed
hook: PermissionRequest
hook: PermissionRequest Completed
exec
/bin/zsh -lc "uv run --offline --no-project --no-cache python - <<'PY'
from pathlib import Path
import io,json,contextlib,types,os,stat
from unittest.mock import patch
# Run the actual search source against a virtual tracked symlink into an ignored secret.
s=Path('App/Sources/UI/FilesView.swift').read_text().split('static let searchScript = \"\"\"\\n',1)[1].split('\\n    \"\"\"',1)[0]
import textwrap
s=textwrap.dedent(s).replace('\\\\\\\\','\\\\')
opened=[]
def virtual_open(path,mode):
    opened.append(path)
    return io.BytesIO(b'API_TOKEN=private-value\\n')
with patch('sys.argv',['script','/repo','API_TOKEN','contents']), patch('subprocess.run',return_value=types.SimpleNamespace(returncode=0,stdout=b'public-link\\0')), patch('os.stat',return_value=types.SimpleNamespace(st_mode=stat.S_IFREG,st_size=24)), patch('builtins.open',side_effect=virtual_open):
    out=io.StringIO()
    with contextlib.redirect_stdout(out): exec(s,{})
print('Contents symlink target is opened without lstat/containment:',out.getvalue().strip())
# Exercise an earlier page that exceeds the core output cap, using the real parser code.
src=Path('App/Sources/Chat/TranscriptScript.swift').read_text().split('#\"\"\"\\n',1)[1].split('\\n\"\"\"#',1)[0]
src=src[src.index('size = os.path.getsize(path)'):].replace('INITIAL',str(16<<20)).replace('MAXREAD',str(16<<20)).replace('KEEP','150')
rows=[{'type':'assistant','message':{'content':[{'type':'text','text':'😀'*20000}]}} for _ in range(150)]
data=b''.join(json.dumps(r,separators=(',',':'),ensure_ascii=False).encode()+b'\\n' for r in rows)
before=len(data)
data+=b'{\"type\":\"assistant\",\"message\":{\"content\":[{\"type\":\"text\",\"text\":\"current\"}]}}\\n'*150
class OS:
    class path:
        @staticmethod
        def getsize(path): return len(data)
env=dict(sys=types.SimpleNamespace(argv=['script','0','[]','sid','-1',str(before)]),os=OS,json=json,re=__import__('re'),path='fixture',sid='sid',known='sid',off=-1,home='/home/test',open=lambda *a:io.BytesIO(data))
out=io.StringIO()
with contextlib.redirect_stdout(out):exec(src,env)
encoded=out.getvalue().encode(); lines=encoded[:8_000_000].splitlines(); head=json.loads(lines[0]); valid=0
for line in lines[1:]:
    try:json.loads(line);valid+=1
    except ValueError:pass
print('Earlier page: intended=150 parsed='+str(valid)+' start='+str(head['start'])+' earlier='+str(head['earlier'])+' bytes='+str(len(encoded)))
PY" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 82ms:
Contents symlink target is opened without lstat/containment: {"results": [["public-link", false, 24, "API_TOKEN=private-value"]], "partial": false}
Earlier page: intended=150 parsed=99 start=0 earlier=True bytes=12005095

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
hook: PreToolUse
hook: PreToolUse Completed
exec
/bin/zsh -lc "nl -ba App/Sources/UI/FilesView.swift | sed -n '125,154p;157,178p;267,293p'; nl -ba App/Sources/Chat/ChatModel.swift | sed -n '120,142p'; nl -ba App/Sources/UI/SpaceView.swift | sed -n '247,267p'" in /Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket
 succeeded in 0ms:
   125	        if isdir and mode != "names":
   126	            continue
   127	        try:
   128	            p.encode("utf-8")
   129	            full = os.path.join(root, p)
   130	            if mode == "names":
   131	                if q not in os.path.basename(p).lower():
   132	                    continue
   133	                out.append([p, isdir, 0 if isdir else os.lstat(full).st_size, None])
   134	            else:
   135	                st = os.stat(full)
   136	                if not stat.S_ISREG(st.st_mode) or st.st_size > 1 << 20:
   137	                    continue
   138	                with open(full, "rb") as f:
   139	                    data = f.read()
   140	                if b"\\0" in data[:8192]:
   141	                    continue
   142	                line = next((l for l in data.decode("utf-8", "replace").splitlines() if q in l.lower()), None)
   143	                if line is None:
   144	                    continue
   145	                out.append([p, False, st.st_size, line.strip()[:200]])
   146	        except (OSError, UnicodeEncodeError):
   147	            continue
   148	        if len(out) >= 200:
   149	            partial = True
   150	            break
   151	    print(json.dumps({"results": out, "partial": partial}))
   152	    """
   153	
   154	    var body: some View {
   157	                Text(error).font(HF.ui(14)).foregroundStyle(HC.blocked)
   158	            }
   159	            if !query.isEmpty {
   160	                if let results {
   161	                    if results.isEmpty { Text("No matches.").font(HF.ui(14)).foregroundStyle(HC.dim) }
   162	                    ForEach(results) { e in
   163	                        if e.isDir, let dir {
   164	                            NavigationLink(value: dir + "/" + e.name) { row(e) }
   165	                        } else {
   166	                            Button { open(e) } label: { row(e) }.disabled(opening != nil)
   167	                        }
   168	                    }
   169	                    if partial { Text("Showing the first matches only.").font(HF.ui(13)).foregroundStyle(HC.dim) }
   170	                } else {
   171	                    HStack { Spacer(); ProgressView(); Spacer() }
   172	                }
   173	            } else {
   174	            ForEach(entries) { e in
   175	                if e.isDir, let dir {
   176	                    NavigationLink(value: dir + "/" + e.name) { row(e) }
   177	                } else {
   178	                    Button { open(e) } label: { row(e) }
   267	    }
   268	
   269	    /// Runs `searchScript` under the current folder once typing pauses; a newer query cancels this one.
   270	    private func search() async {
   271	        results = nil; partial = false
   272	        let q = query.trimmingCharacters(in: .whitespaces)
   273	        guard !q.isEmpty, let dir else { return }
   274	        try? await Task.sleep(for: .milliseconds(300))
   275	        guard !Task.isCancelled else { return }
   276	        do {
   277	            let r = try await store.exec(argv: ["python3", "-c", Self.searchScript, dir, q, scope == .names ? "names" : "contents"],
   278	                                         cwd: nil, on: nil, timeout: 20, input: nil)
   279	            guard !Task.isCancelled else { return }
   280	            guard r.code == 0, let v = try? JSONValue.parse(r.stdout) else { error = Self.failure(r, "Couldn't search \(dir)"); return }
   281	            results = (v["results"].array ?? []).compactMap { a in
   282	                guard let n = a[0].string else { return nil }
   283	                return Entry(name: n, isDir: a[1].bool ?? false, size: a[2].int ?? 0, snippet: a[3].string)
   284	            }
   285	            partial = v["partial"].bool ?? false
   286	            error = nil
   287	        } catch {
   288	            if !Task.isCancelled { self.error = Self.message(error) }
   289	        }
   290	    }
   291	
   292	    /// herdr-core answers a missing program with kind "spawn_failed" (checked against 0.1.15).
   293	    private static func message(_ error: Error) -> String {
   120	
   121	    /// Reads the window above what is loaded and puts it in front.
   122	    func loadEarlier() async {
   123	        guard hasEarlier, !loadingEarlier, let store, store.phase == .connected, let call = invocation(store) else { return }
   124	        loadingEarlier = true
   125	        defer { loadingEarlier = false }
   126	        guard let r = try? await store.exec(argv: call + [session, "-1", String(start)], cwd: nil, on: nil, timeout: 20, input: nil),
   127	              r.code == 0 else { return }
   128	        var lines = r.stdout.split(separator: UInt8(ascii: "\n"))
   129	        // Anything else (the session changed meanwhile) leaves the chat as it is.
   130	        guard !lines.isEmpty, let head = try? JSONValue.parse(Data(lines.removeFirst())), head["earlier"].bool == true,
   131	              head["session"].string == session else { return }
   132	        let earlier = lines.compactMap { (try? JSONValue.parse(Data($0))).flatMap(Self.entry) }
   133	        entries = earlier + entries
   134	        firstSeq -= earlier.count
   135	        start = Int64(head["start"].double ?? 0)
   136	        hasEarlier = start > 0
   137	        rebuild()
   138	    }
   139	
   140	    private func load() async {
   141	        guard let store, store.phase == .connected, let call = invocation(store) else { return }
   142	        for _ in 0..<4 {   // follow "more" a few times on a big backlog
   247	                                    Text(s).font(HF.ui(13, .medium)).foregroundStyle(HC.fg).lineLimit(3)
   248	                                }
   249	                                if case .text(_, let s)? = t.steps.last {
   250	                                    Text(s).font(HF.ui(13)).foregroundStyle(HC.muted).lineLimit(8)
   251	                                }
   252	                            }
   253	                        }
   254	                        .padding(12)
   255	                    }
   256	                    .clipped()
   257	            }
   258	        }
   259	        .onAppear { model.start(store: store) }
   260	        .onDisappear { model.stop() }
   261	    }
   262	}
   263	
   264	/// Plain-text tail of a terminal (terminal.read), refreshed when its turn/status changes.
   265	struct TerminalPreview: View {
   266	    @Environment(AppStore.self) private var store
   267	    var address: String

hook: PostToolUse
hook: PostToolUse
hook: PostToolUse Completed
hook: PostToolUse Completed
codex
1. **[P2] 古い履歴の応答が打ち切られると、未取得のメッセージを失います。** [ChatModel.swift:126](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/ChatModel.swift:126)  
   `loadEarlier()` は `r.truncated` を確認せず、解析できた行だけを追加して `start` を更新します。150件でも各本文が20,000文字の絵文字なら出力は約12 MBとなり、core の8 MB上限では99件しか復元できません。再現では `start = 0` となり、残る51件を取得するボタンも消えました。出力をバイト数でも制限し、打ち切られた応答ではカーソルを進めるべきです。

2. **[P2] Contents 検索がシンボリックリンク経由で検索範囲外のファイルを読みます。** [FilesView.swift:135](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:135)  
   git が列挙したパスに対して `os.stat()` と `open()` がリンク先を辿ります。例えば、追跡対象のリンクが repo 外の秘密ファイルや無視対象の `.env` を指すと、その内容が検索結果の snippet に入ります。検索ルート内であることと ignore 条件をリンク先にも適用するか、検索ではリンクを除外する必要があります。

3. **[P3] 空白だけの検索でローディング表示が終了しません。** [FilesView.swift:270](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:270)  
   `search()` は `results = nil` にした後、trim 後の検索語が空なら戻ります。一方、表示側は trim 前の `query.isEmpty` を判定するため、スペースを入力すると一覧が消え、スピナーだけが残ります。表示と検索で空文字の判定を統一してください。

文書にも不一致があります。README は space の Files を「現在のディレクトリ」と説明していますが、実装は git root に移動します。設計文書の「共通の `projectRoot(of:)`」は存在せず、Changes は独自に解決しています。また、同文書のイベント時だけ読む説明に対し、ChatPreview は定期ポーリングします。

実機・Simulator は未検証です。ページ分割と応答打ち切りはメモリ上の入力で検証しました。
hook: Stop
hook: Stop
hook: Stop Completed
hook: Stop Completed
tokens used
84,012
1. **[P2] 古い履歴の応答が打ち切られると、未取得のメッセージを失います。** [ChatModel.swift:126](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/Chat/ChatModel.swift:126)  
   `loadEarlier()` は `r.truncated` を確認せず、解析できた行だけを追加して `start` を更新します。150件でも各本文が20,000文字の絵文字なら出力は約12 MBとなり、core の8 MB上限では99件しか復元できません。再現では `start = 0` となり、残る51件を取得するボタンも消えました。出力をバイト数でも制限し、打ち切られた応答ではカーソルを進めるべきです。

2. **[P2] Contents 検索がシンボリックリンク経由で検索範囲外のファイルを読みます。** [FilesView.swift:135](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:135)  
   git が列挙したパスに対して `os.stat()` と `open()` がリンク先を辿ります。例えば、追跡対象のリンクが repo 外の秘密ファイルや無視対象の `.env` を指すと、その内容が検索結果の snippet に入ります。検索ルート内であることと ignore 条件をリンク先にも適用するか、検索ではリンクを除外する必要があります。

3. **[P3] 空白だけの検索でローディング表示が終了しません。** [FilesView.swift:270](/Users/yosuke/workspace/github.com/YosukeIida/herdr-pocket/App/Sources/UI/FilesView.swift:270)  
   `search()` は `results = nil` にした後、trim 後の検索語が空なら戻ります。一方、表示側は trim 前の `query.isEmpty` を判定するため、スペースを入力すると一覧が消え、スピナーだけが残ります。表示と検索で空文字の判定を統一してください。

文書にも不一致があります。README は space の Files を「現在のディレクトリ」と説明していますが、実装は git root に移動します。設計文書の「共通の `projectRoot(of:)`」は存在せず、Changes は独自に解決しています。また、同文書のイベント時だけ読む説明に対し、ChatPreview は定期ポーリングします。

実機・Simulator は未検証です。ページ分割と応答打ち切りはメモリ上の入力で検証しました。
