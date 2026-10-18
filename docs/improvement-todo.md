# レビューと運用改善（2026-10-11）

## 今回の確認・修正

主要 Nix モジュール、Neovim のロード・formatter、tmux / 開発 helper と
README を確認。実装と検証の進捗は `todo.md`、日常の手順は `docs/operations.md`。

- **高: Neovim のリンク先不整合** — 元の参照先 `~/.dotfiles` は現マシンに
  存在しなかった。`dotfiles.repository` に配置先を一元化し、リンクと helper で共有。
- **中: 保存時の意図しない文章修正** — textlint が祖先の `package.json` や
  ホームの設定でも実行され、個人設定を強制していた。ホームと Git 境界で探索を
  止め、明示したプロジェクト設定のディレクトリから実行するよう修正。
- **中: 整形コマンドの呼び出し元依存** — `dotfiles-fmt` を runtime dependencies が
  明示された `writeShellApplication` で提供し、配置先で Nix / Lua を整形。
- **中: mutable installer** — Cursor の適用時 installer を削除し、Nix 管理へ移行。
- **中: 検証と実態の説明不足** — macOS にも format check を追加し、
  README に build / switch / rollback と rootless Docker の削除対象を記載。

## 追加依頼で対応した残課題

- Nix / Lua 全体の整形とチェックを追加。Lua は2スペースに統一。
- Linux / Apple Silicon / Intel Mac の CI を追加。action は commit に固定し、
  更新も通常の main 直接運用で検証する。自動 PR は作成しない。
- 停止コンテナも削除する週次 Docker prune timer / service を削除。
- `home.packages` を `home/packages/` の用途別 module に分割。
- lazy.nvim・Treesitter/parser・LuaSnip/jsregexp を Nix 管理へ移行し、
  起動時 bootstrap、`:TSUpdate`、runtime の jsregexp build をなくした。
- Blink は Lua matcher を使い、起動時の binary download をなくした。
- AeroSpace helper の方向引数検証、quoting、window 不在時の処理を追加し ShellCheck 対象にした。
- 更新・検証・適用・切り戻しの手順を `docs/operations.md` に集約。

## リポジトリ内では解消できない制約

- Intel Mac の上流サポート終了は設定修正では解消できない。対応 input を維持する
  方針を明示し、Intel runner を加えて更新時の不具合を検出する。
- Homebrew 管理の AI CLI は Nix rollback の対象外。既存の管理方針を尊重し、
  更新を別操作にして確認する。
- GUI・WSL の再起動と全ツールの実機操作は CI の保証範囲外。

元の改善メモにあった「未コミット変更あり」は今回開始時には該当しなかった。
`checker.enabled = true` は更新通知であり自動更新ではない。
`fzf.lua` の `<leader>gs` / `<leader>gc` の重複も確認できず、不要な変更は加えていない。
