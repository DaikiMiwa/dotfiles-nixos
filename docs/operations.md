# 更新・検証・切り戻し

## 最初の適用と配置

配置先は `home/dotfiles.nix` の `dotfiles.repository` で一元管理する。
標準は `~/dotfiles-nixos`。別配置では Home Manager module に絶対パスを指定する。
Neovim の Lua 設定はこの作業ツリーへリンクされるため、その場の編集が反映される。
Nix 管理の Neovim 依存は `home-manager switch` / `nixos-switch` で反映する。

## 通常の変更

リポジトリで `git status --short` を確認し、変更後に次を実行する。

```sh
dotfiles-fmt
dotfiles-check
```

helper をまだ適用していない場合は、リポジトリのルートで次を実行する。
system は WSL: `x86_64-linux`、Apple Silicon: `aarch64-darwin`、Intel: `x86_64-darwin`。

```sh
nix fmt
nix flake check --all-systems --no-build --show-trace
nix build --no-link \
  .#checks.aarch64-darwin.format-nix \
  .#checks.aarch64-darwin.format-lua \
  .#checks.aarch64-darwin.shell-scripts \
  .#checks.aarch64-darwin.cursor-cli \
  .#checks.aarch64-darwin.dotfiles-helpers \
  .#checks.aarch64-darwin.neovim-config
```

`--no-build` は check の評価のみで、formatter やテストを実行しない。
CI は3つの native runner で評価と上記チェックを実行する。全 Home Manager / WSL
システムのビルド、ログインや GUI 操作は CI の保証範囲外なので、適用前に対象環境で build する。
commit 前に `git diff --check` と差分を確認し、意図したファイルのみ stage する。

## 依存更新

Nix input は必要なものを指定して `nix flake update nixpkgs home-manager` 等で更新し、
検証する。全 input を更新したい場合だけ `nix flake update` を使う。
設定変更と依存更新を別 commit にして切り戻せるようにする。
CI action も commit SHA を固定し、更新時にリリース内容と3 platform の結果を確認する。
個人リポジトリの方針に合わせ、自動更新 PR は作成しない。

lazy.nvim、Treesitter と parser / queries、LuaSnip と jsregexp、Cursor CLI は Nix 管理。
Neovim 内でこれらを更新・build しない。その他のプラグインは `:Lazy update` 後に
補完・ファイル検索・LaTeX 等を確認し、`lazy-lock.json` を commit する。
他のマシンや切り戻し後は `:Lazy restore` で lock の revision を再現する。
plugin 自体に手編集がある場合は復元が拒否されるので、先に差分を退避する。
plugin cache を編集するより、リポジトリ内の設定や明示した patch で変更を管理する。
Blink は Lua matcher を使用する。Rust matcher が必要になった場合は Nix で binary を
提供してから設定を変更し、起動時の download に依存しない構成を維持する。

Codex / Claude Code は既存方針どおり Homebrew で管理する。これらの更新は
`brew upgrade --cask codex claude-code` で明示的に行い、Nix の更新と別に確認する。
Homebrew の cask は `flake.lock` に固定されない。Nix の rollback では戻らない。

Intel Mac は選択した CLI にも stable Nixpkgs を使い、CI の Intel runner で検証する。
上流の対応終了後も動くと推測して input を進めない。Intel を維持する間は最後に成功した
lock を保存し、サポート対象 input を超える更新時は Linux / Apple Silicon の input と
Intel の input を分離する。OS の対応終了はこのリポジトリだけでは解消できない。

## 適用後

macOS は `home-manager build --flake .#daiki.miwa-aarch64-darwin` 成功後に同じ出力へ switch。
WSL は `sudo nixos-rebuild build --flake .#nixos-wsl` 成功後に `nixos-switch`。
Intel は macOS の出力名を `daiki.miwa-x86_64-darwin` に替える。
新しいシェルで `command -v nvim cursor-agent dotfiles-check` を確認する。
Cursor の旧 local installer が優先される場合、そのリンクを退避して PATH を再確認する。
認証設定は削除しない。

Neovim は Nix wrapper を使う。Homebrew の `nvim` が優先されている場合は
PATH を確認して Home Manager のものを使う。初回起動には残りの lazy 管理 plugin の
取得が必要。既存の lazy.nvim / Treesitter / LuaSnip の cache は、今回の構成では使わない。
tmux は設定を reload し、Herdr は再起動して確認する。

以前の WSL の自動 Docker prune timer は、設定を適用する前にユーザーとして停止する。
Home Manager のユーザー systemd manager が既に loaded な timer を保持する場合にも備える。

```sh
systemctl --user disable --now docker-prune.timer
sudo nixos-rebuild switch --flake .#nixos-wsl
systemctl --user daemon-reload
systemctl --user is-active docker-prune.timer
```

最後のコマンドが `inactive` または unit 不在なら削除自動化は停止している。
今後は `docker system df` / `docker ps -a` で確認し、必要なバックアップ後に手動で整理する。
NixOS-WSL のシステム設定が変わった場合は必要に応じて Windows 側で `wsl --shutdown` する。

## 切り戻し

WSL は `sudo nixos-rebuild switch --rollback`。Home Manager は
`home-manager generations` で直前の世代を選び、そのパスの `activate` を実行する。
作業ツリーへリンクした Lua は世代を戻すだけでは戻らないため、問題の commit を
`git revert <commit>` し、検証・適用する。必要なら `:Lazy restore` を実行する。
14 日より古い WSL の世代は GC 対象なので、適用直後に切り戻せることを確認する。

失敗を記録するときは対象 commit、実行コマンド、エラー本文、対象 platform を残す。
