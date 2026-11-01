# agent と space の画面: Chat と Terminal の切り替え、project のファイルツリー

状態: 実装済み。決定: space のカードは Chat を表示する（提案の 1）。カード自身の切り替えは置かず、アプリ全体のモードに従う。Chat は最後の 150 件で開き、それより前は要求に応じて読む。読み込んだ後、表示は先頭（読み込んだ中で最も古いメッセージ）に留まる。

## 現在の動作

| 画面 | 入り方 | 表示 | Chat と Terminal の切り替え | Files・Changes |
|---|---|---|---|---|
| space（`SpaceView`） | space の一覧 | ペインごとのカード。カードの本文は端末の末尾のテキスト（`TerminalPreview`） | カードには無い | ツールバーのボタン。フォルダは画面に出ている端末のもの（83f9b36） |
| agent（`AgentScreen`） | agent の行、**または space のペインのカード**をタップ | Chat か、動いている端末 | ツールバーのボタン。Claude Code と Codex のみ。選択はアプリ全体で共通（`@AppStorage("agentViewMode")`） | 無い |

2 つの経路はすでに合流している。ペインのカードは、agent の一覧と同じ `AgentScreen` を切り替え付きで開く。space の画面に欠けているのはカード上の Chat であり、agent の画面に欠けているのは Files である。

## 提案

### 1. space の画面の Chat

カードの本文はアプリ全体のモードに従う。Chat モードでは、Claude Code と Codex のペインは端末の末尾の代わりに直近のメッセージを表示する。他のプログラムは端末の末尾のままとする。カードの見出しに `AgentScreen` と同じ切り替えボタンを置き、カードをタップするとそのモードで `AgentScreen` を開く。

負荷: 表示中のカードはそれぞれ、マシン上で transcript を読む（Chat のスクリプト）。iPhone は 1 枚ずつ表示するが、ページの View は隣のカードも作る。iPad のグリッドは全部を表示する。実装では、カードは Chat と同じ間隔で読み取りを繰り返す（agent の作業中は 1.5 秒、それ以外は 6 秒ごと）。最初の読み取りの後は、新しく追加されたバイトだけを受け取る。

採らない案: space の画面の中に Chat のタブを別に作る。`AgentScreen` と重複するためである。

### 2. agent の画面の Files と Changes

`AgentScreen` に Files と Changes を付ける。題名の幅を保つため、切り替えボタンの隣の `…` メニューに入れる。

起点は agent の project の root とする。agent のプロセスの作業ディレクトリで `git rev-parse --show-toplevel` を実行して得る。git の repo の外であれば、その作業ディレクトリを使う。シートを開いた時点で決め、その後の移動には追従しない。

agent のプロセスの作業ディレクトリが変わらない理由: Claude Code と Codex は、shell のコマンドを子の shell で実行する。そのため agent 自身の `cd` は agent のプロセスの作業ディレクトリを変えない。herdr-core はこれを `foreground.cwd`（アプリの `TerminalRecord.cwd`）として返す。値は agent を起動したディレクトリのままである。未確認の点: Claude Code が turn の中で `cd` を実行した後も `foreground.cwd` が変わらないことは、マシン上でまだ確かめていない。

### 3. 両方の画面で同じ規則

space の画面も同じ起点を使う。画面に出ている端末の現在のディレクトリではなく、その project の root を使う。実装では、`AppStore.projectRoot(_ folder:)` が両方の画面の Files を受け持つ。Changes はすでに自分で git の root を求めている。そのため、動作が変わるのは Files だけである。端末がサブフォルダにいても、repo の root から開く。

## 作業の順序

1. `projectRoot(_:)`、`AgentScreen` の Files と Changes、space の画面を project の root に切り替える変更。UI テスト: agent から Files を開き、repo の root が出ることを確かめる。
2. space のカードの Chat のプレビュー。
3. 各段階の Codex の review。

## 未決の問い

- 提案の 1 は求めているものに合うか。それとも、カードをタップした後の既存の切り替えで足りるか。足りるなら、手順 2 は取りやめる。
