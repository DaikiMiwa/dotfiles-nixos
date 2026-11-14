# tmux 内の AI エージェント監視

調査日: 2026-11-14。CLI エージェントを tmux のペインで動かす構成が対象。
今回は一次資料と現在の設定の比較のみ。候補のインストール・実機検証は未実施。

## 要件と推奨

- 現在の tmux / WezTerm の操作、Ctrl+b、日本語入力対策、vi コピーを維持する。
- 実行中・入力待ち・承認待ちと、そのエージェントの場所を確認する。
- 一覧を必要なときに表示し、不要なら隠せる。
- 一覧から対象ペインへ移動できる。

第一候補は **既存 tmux に ccmux を追加する構成**。
常時表示は待機件数とウィンドウの印だけにして、詳細はポップアップで開く。
必要ならサイドバーも切り替える。承認操作はまず対象ペインへ移動して行う構成とする。

## 比較

| 候補 | 一覧の表示・非表示 | 現在の tmux との関係 | 判断 |
| --- | --- | --- | --- |
| [ccmux](https://github.com/epilande/ccmux) | ポップアップ。サイドバーは `ccmux sidebar --toggle` | 既存ペインを検出 | 今回の第一候補 |
| [tend](https://github.com/spadin/tend) | `tend --popup` を tmux ポップアップで開く | 既存ペインを検出 | 軽量だが画面判定の調整が必要 |
| [Agent Deck](https://github.com/asheshgoplani/agent-deck) | 管理 TUI を開いて選択 | tmux ベースで自身の `agentdeck_*` セッションを作成 | 起動・プロジェクト管理もまとめたい場合 |
| [Herdr](https://herdr.dev/tui/docs/keyboard/) | Goto picker、サイドバー切り替え | Herdr 自身が端末を管理 | tmux から移行する場合 |

ccmux の公式 README は、ポップアップで選択後に閉じて対象へ移動する構成と、
サイドバーのトグルを案内している。状態件数・ウィンドウ印は tmux の user option に公開され、
表示書式をツール側で書き換えないため、現在のバーに組み込みやすい。
[導入・表示方法](https://github.com/epilande/ccmux#-quick-start)

tend はプロセス名と画面内容・出力変化から判定する。作者も CLI のバージョンに合わせた
ルール調整を前提にしており、承認待ちを見逃さないことを優先する今回は補欠とする。
[検出方式](https://github.com/spadin/tend#how-it-works)

Agent Deck は監視以外にセッションや worktree の管理も行う。既存セッションは維持されるが、
既存ペインをそのまま監視したい今回より管理範囲が広い。
Codex のターン状態には専用 notify hook の設定が必要と記載されている。
[公式 README](https://github.com/asheshgoplani/agent-deck)

## 状態判定で確認すること

画面判定は CLI の表示変更によって承認待ちを idle と誤認し得る。
Herdr も未知の待機画面でこの問題が起こることを明記している。
hook / integration が状態を報告する場合と、画面から推定する場合を区別して確認する。
[Herdr の状態判定](https://herdr.dev/tui/docs/agents/)

ccmux は対応エージェントの hook を利用できる。
README によれば Codex の承認検出は `PermissionRequest` を利用し、Codex 0.122 以上が必要。
導入時は実際の CLI バージョン、hook の設定、各種待機画面を確認する。
hook が存在することだけで、全種類の質問・承認を検出できるとは判断しない。
[エージェント別設定](https://github.com/epilande/ccmux#-session-matching-with-hooks)

## 現在の設定に合わせた導入案

未実装の案:

- `Ctrl+b a`: 一覧をポップアップで表示し、選択して対象ペインへ移動。
- `Ctrl+b S`: サイドバーを表示・非表示。
- 閉じている間も、既存ステータスバーに待機件数とウィンドウの印を表示。
- 最初は Codex / Claude Code / OpenCode の実際に使うものだけを接続。

キー割当は既存定義との衝突確認後に決定する。WezTerm の prefix key table も合わせて確認し、
日本語入力中の新しいキーが届くことを実機で確認する。
現在の `status-right` に表示を追加する場合は、tmux-continuum を後から読み込む順序を維持する。
hook はリポジトリ管理外の `~/.codex` などに関わるため、既存内容を保持して導入する。

Herdr はすでにリポジトリに定義されているが、固定版は v0.7.4、prefix は Alt+b。
上記の Herdr 機能は最新ドキュメントに基づくため、固定版での対応確認が必要。
移行するなら現在の日本語入力・コピー操作も再検証する。

公開状況の参考として GitHub API で確認した stars は Herdr 50,903、Agent Deck 1,256、
ccmux 243、tend 1。利用者数や動作保証を意味しない。
Herdr の注目度は高いが、現在の操作感を保つという条件では ccmux を優先する。
