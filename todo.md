# Repository review

## tmux / WezTerm の操作見直し

### 追加レビューで見つかった4点

- [x] WezTerm leader の Ctrl / Alt / Shift 付き操作を転送する。
- [x] 最後の1セッションの削除と fzf のキャンセル処理を修正する。
- [x] tmux のコピーモード状態を WezTerm に通知し、日本語入力中も Vim 操作を可能にする。
- [x] WezTerm に prefix 待機・コピー状態を表示する。
- [x] モード遷移・セッション削除を検証し、利用手順を更新する。

追加検証: WezTerm のキー定義と状態遷移、独立した tmux socket / PTY での
コピー・検索（日本語 UTF-8 の入力、確定・キャンセル）・ペイン移動・デタッチ・
再接続・複数/最後のセッション削除が成功。これらを既存の shell-scripts check に統合。
最終検証: `nix fmt`、全 system の flake check（no-build）、Apple Silicon の
6 checks の build、実際の WezTerm による show-keys、git diff --check が成功。
IME 自体の未確定文字を含む GUI 操作は、Home Manager 適用後に確認する。

- [x] tmux の prefix を Ctrl-B に戻す。
- [x] WezTerm の leader で日本語 IME より先に prefix 操作を処理する。
- [x] tmux の vi コピーモードに v / Ctrl-V / y を揃える。
- [x] 設定の検証と運用手順の更新。
- [ ] 適用後、日本語未確定入力中の Ctrl-B → w / m / [ とコピー・検索を実機確認。

検証: `nix fmt`、全 system の flake check（no-build）、Apple Silicon の
format-nix / format-lua / shell-scripts / cursor-cli / dotfiles-helpers /
neovim-config の build、WezTerm の show-keys、git diff --check が成功。
Home Manager の適用と IME 入力を伴う GUI 操作は未実施。

- [x] 作業ツリーが clean であることと、主要設定・既存改善メモを確認。
- [x] Neovim の配置、保存時 formatter、シェル補助コマンドの不具合を修正。
- [x] 更新・検証・切り戻し手順と残課題を文書化。
- [x] Nix 評価と変更箇所の検証を実行。
- [x] 差分を確認し、main に commit / push。

## 追加依頼: 残課題も実装する

- [x] 全 platform の CI、Lua 整形・検証を追加。
- [x] Docker の停止コンテナを自動削除しない設定へ変更。
- [x] repository パスを一元設定し、package module を用途別に分割。
- [x] Neovim bootstrap / 外部 installer の再現性を改善。
- [x] 更新経路・Intel Mac の方針を運用手順に反映。
- [x] 追加変更を検証。
- [x] commit / push 後の Linux / Apple Silicon / Intel CI を確認。

以前の dependency failure 調査メモは原因・実行結果が残っていなかったため、
今回の全出力評価で再確認する。

検証結果: 全 system の flake check（no-build）、Linux Home Manager / WSL の
drvPath 評価、Apple Silicon の format-nix build、変更 Lua の StyLua check、
textlint の境界条件確認、git diff --check が成功。以前の依存エラーは再現しない。
OS / Home Manager の switch と全パッケージの build は実行していない。

2026-10-18 最終ローカル検証:

- 全 system の flake check（no-build）、Linux Home Manager / WSL の drvPath 評価が成功。
- Apple Silicon の format-nix / format-lua / shell-scripts / cursor-cli /
  dotfiles-helpers / neovim-config の build が成功。
- 一時環境に全設定と plugin を複製し、lock 復元・Neovim 起動・Nix parser 読み込みが成功。
- lazy の runtime path リセットと read-only plugin への helptags 書き込みを修正して検証。
- 既存 Copilot cache にある手編集は保全し、検証用コピーのみ clean にして確認。

GitHub Actions は3環境とも成功:
https://github.com/DaikiMiwa/dotfiles-nixos/actions/runs/39130898829

自動更新 PR の設定は main 直接運用と合わないため除去し、今回自動生成された
PR #19 を閉じてその branch も削除した。既存のユーザー作業には変更を加えていない。
変更の適用と手動の動作確認は `docs/operations.md` に記載。

CI 実行時の Node.js 20 非推奨警告に対応し、checkout action を公式 v7.0.1 の
commit SHA に更新。main の最終 CI 結果は GitHub Actions で確認する。
