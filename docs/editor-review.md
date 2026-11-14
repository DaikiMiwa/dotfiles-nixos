# Neovim・tmux・WezTerm 追加レビュー

## 対応内容

以下のレビュー項目を修正した。

- zsh の editor package の PATH と Git / GitHub CLI / EDITOR / VISUAL を Nix wrapper に統一。
- リサイズ後のアクティブウィンドウを維持。
- nil_ls / bashls / nixfmt を接続し、Ruff / ChkTeX の CLI 二重実行を除去。
- Conform を BufReadPre / BufNewFile で読み込み、最初の保存から自動整形を有効化。
- Copilot の確定を Ctrl-G Ctrl-Y、破棄を Ctrl-G Ctrl-E に分離。
- `?` / Ctrl-K を標準操作に戻し、quickfix 作成は leader + s q、辞書補完は Ctrl-X Ctrl-K。
- tmux 履歴を50000行にし、tmux-continuum で15分ごとにセッションを保存。
- WezTerm の prefix を tmux 接続中のみ有効にし、未接続・デタッチ後は Ctrl-B を直接送信。

回帰検証を `tests/neovim.lua`・`tests/wezterm.lua`・`tests/tmux.py` に追加した。
macOS の適用状態と最終検証結果は `todo.md` に記録する。

## 修正前のレビュー記録

2026-11-14、`b98818b` の設定と macOS の適用状態を確認。
このレビューでは設定の変更・適用は行っていない。

## 優先して直したい点

### 1. 通常の nvim コマンドでは設定を読み込めない（高）

新しいログインシェルでも `command -v nvim` は `/opt/homebrew/bin/nvim`。
一方、`home/nvim/lua/config/lazy.lua` は Nix wrapper が設定する
`NVIM_LAZY_PATH` を必須にしている。Homebrew 版からこの設定を読み込むと、
`Use the Home Manager Neovim wrapper (NVIM_LAZY_PATH is missing).` で失敗する。

確認コマンド:

```sh
zsh -lic 'command -v nvim'
/opt/homebrew/bin/nvim --headless -u NONE -i NONE \
  '+lua local ok, err = pcall(dofile, "home/nvim/lua/config/lazy.lua"); print(ok, err)' +qa
```

Nix wrapper の実体は `~/.nix-profile/bin/nvim` にある。
Homebrew 管理の Codex / Claude Code を維持しつつ、通常の nvim 起動先を
Nix wrapper に揃える必要がある。PATH とエディタ起動経路を合わせて確認する。

### 2. リサイズ時に表示タブが切り替わる（中）

`home/nvim/lua/config/autocmds.lua` の `VimResized` は
`tabdo wincmd =` を実行する。2タブを作り1番目を表示した状態からイベントを
発火すると、処理後は2番目へ移動した。
全タブの分割を整えた後、元のタブ・ウィンドウを復元する処理が必要。

### 3. Nix 用の LSP・保存時整形が未接続（中）

`home/packages/development.nix` には `nil` と `nixfmt-rfc-style` があるが、
`home/nvim/lua/config/lsp.lua` の有効化一覧に `nil_ls` がなく、
`home/nvim/lua/plugins/conform.lua` にも `nix` の formatter がない。
このリポジトリの `.nix` 編集を支援するなら、両方を接続するのが有効。
同様に `bash-language-server` もインストール済みだが `bashls` は未有効化。

### 4. 診断の担当が重複している（中）

- Python: `config/lsp.lua` で Ruff LSP、`plugins/lint.lua` で Ruff CLI を有効化。
- LaTeX: texlab の `chktex.onOpenAndSave` と nvim-lint の ChkTeX を有効化。

同じツールが別経路で診断を出す構成で、重複表示や余分な実行につながる。
診断を LSP と CLI のどちらに担当させるか整理するとよい。
これは構成上の重複を確認したもので、実際のバッファでの診断二重表示は未検証。
[Ruff の公式セットアップ](https://docs.astral.sh/ruff/editors/setup/)も両方の導入方法を案内している。

## 操作の好みに応じて見直したい点

- **Ctrl+l の優先順位**: LuaSnip の展開・移動と Copilot の候補受け入れに同じ
  Insert-mode キーを使用している。別キーにするか、候補と snippet の優先順位を
  一つの関数にまとめると操作を説明しやすい。両方が完全に使えないと断定はしない。
- **Vim 標準キー**: `config/set.lua` の `?` は逆方向検索ではなく quickfix 作成、
  Insert-mode の Ctrl+k は digraph 入力ではなく辞書補完になっている。
  標準操作を残したい場合は leader 配下などへ移動する。
- **tmux の履歴**: 実環境の `history-limit` は2000行。WezTerm の100000行とは
  別管理なので、tmux ペインのログを長く遡りたい場合は tmux 側を増やす。
- **tmux 外の Ctrl+b**: WezTerm の leader は全ペインで有効。
  tmux を起動していないシェルでも Ctrl+b が2秒待機になり、単独ではアプリへ
  届かない。tmux 接続中だけ有効にする余地がある。
  [WezTerm leader の仕様](https://wezterm.org/config/keys.html#leader-key)。
- **セッションの自動保存**: 現在の tmux-resurrect は手動保存・復元。
  再起動前の保存忘れを防ぎたい場合だけ自動保存を検討する。
  [tmux-resurrect の公式説明](https://github.com/tmux-plugins/tmux-resurrect)。

## 確認できた範囲

- Nix / Lua 設定、既存テスト、インストール済みプラグインの関連処理を読んだ。
- 新しいシェルの実行ファイル選択と、Homebrew 版での設定読み込み失敗を再現。
- Nix 版 Neovim の headless 実行でリサイズ後のタブ移動を再現。
- 実際の tmux の `history-limit` を読み取った。
- Blink の capabilities はインストール済み plugin が自動で登録している。
  そのため「手動登録がない」ことは修正項目に含めない。
- 全プラグインを使う実機編集・補完・IME 操作は未検証。

まず起動先、リサイズ、Nix 編集支援、診断の重複の順で修正するのがよい。
