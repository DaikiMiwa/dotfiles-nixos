# Improvement TODO

このメモは、設定改善作業を中断後に再開するための TODO です。

## 現在の注意点

- 作業ツリーにはユーザー側の未コミット変更があります。戻さずに扱うこと。
- 確認済みの現象:
  - `nix flake check --all-systems --no-build --show-trace` は通過済み。
  - `nvim --headless +'lua print("nvim config loaded")' +qa` は通過済み。
  - `stylua --check home/nvim/lua home/nvim/after` は失敗済み。
  - tmux の実環境差分は未 switch が原因。リポジトリ側の設定を基準に見る。

## 次に潰す順番

1. Lua formatter を導入して check に入れる。
   - 対象: `.stylua.toml`, `flake.nix`, `home/nvim/lua`, `home/nvim/after`
   - 方針: 既存 Lua を `stylua` で整形し、`format-lua` check を追加する。

2. Neovim plugin 更新の再現性を改善する。
   - 対象:
     - `home/nvim/lua/config/lazy.lua`
     - `home/nvim/lua/plugins/treesitter.lua`
     - `home/nvim/lua/plugins/blink.lua`
     - `home/nvim/lua/plugins/luasnip.lua`
   - 問題: 自動 update、`:TSUpdate`、外部 binary download、runtime build が Nix 管理外の変化を作る。
   - 方針: まずは自動更新を抑制し、更新手順を明示する。余裕があれば Nix 管理へ寄せる。

3. ドキュメントのコマンドを最新化する。
   - 対象: `README.md`, `AGENTS.md`, `docs/react-native-expo-task-manager.md`
   - 方針: `nixos-rebuild` だけでなく、`nixos-switch`, `nh`, `dotfiles-check`, `dotfiles-fmt`, `expo-dev` を基準にする。
   - `docs/react-native-expo-task-manager.md` の `/home/daiki.miwa/...` は `~/dotfiles-nixos#expo` などに寄せる。

## 後で掃除する項目

- `home/home.nix` の巨大な `home.packages` を用途別 module に分割する。
- `home/nvim/lua/plugins/conform.lua` の markdown `textlint` 実行条件を project local config がある場合に絞る。
- `home/nvim/lua/plugins/fzf.lua` の `<leader>gs` / `<leader>gc` 重複 mapping を整理する。
- CI で `nix flake check` と Lua format check を回す。

## 再開時の確認コマンド

```sh
git status --short
nix flake check --all-systems --no-build --show-trace
nvim --headless +'lua print("nvim config loaded")' +qa
stylua --check home/nvim/lua home/nvim/after
```
