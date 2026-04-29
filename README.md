# dotfiles-nixos

NixOS-WSL と Home Manager で管理する個人用 dotfiles です。

このリポジトリでは、WSL 上の NixOS システム設定、ユーザー環境、Neovim、tmux、Codex CLI まわりの設定を flake としてまとめています。

## 構成

- `flake.nix`: NixOS-WSL 用の flake 定義
- `nixos/configuration.nix`: NixOS-WSL のシステム設定
- `home/home.nix`: Home Manager のメイン設定
- `home/nvim.nix`: Neovim 設定ディレクトリの配置
- `home/nvim/`: Neovim の Lua 設定
- `home/tmux.nix`: tmux とセッション管理コマンド
- `home/codex.nix`: Codex CLI とユーザー設定

## 前提

- NixOS-WSL
- flakes が有効な Nix
- `sudo` を使えるユーザー

`flake.nix` の `username` は自分の Linux ユーザー名に合わせます。

```nix
username = "daiki.miwa";
```

## 適用

リポジトリのルートで次を実行します。

```bash
sudo nixos-rebuild switch --flake .#nixos-wsl
```

初回適用後は、Home Manager も NixOS モジュールとして一緒に適用されます。

## 更新

flake input を更新する場合は次を実行します。

```bash
nix flake update
sudo nixos-rebuild switch --flake .#nixos-wsl
```

## 主な設定

- shell: zsh
- prompt: starship
- editor: Neovim
- terminal multiplexer: tmux
- CLI tools: `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `gh`, `ghq`, `lazygit`
- cloud CLIs: AWS CLI, Azure CLI, Google Cloud CLI
- development tools: Node.js, Python, Terraform, Lua, TypeScript, Nix 関連ツール

Neovim の設定は `home/nvim/` に置き、Home Manager で `~/.config/nvim` にリンクします。

tmux では、`prefix + m` で fzf ベースのセッション管理ポップアップを開けます。

## 注意

- 認証情報や秘密情報はこのリポジトリに含めません。
- `home.stateVersion` と `system.stateVersion` は、既存環境では不用意に変更しません。
- WSL 前提の設定を含むため、通常の NixOS や macOS に流用する場合は条件分岐を見直します。
