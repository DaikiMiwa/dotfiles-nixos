# dotfiles-nixos

NixOS-WSL と Home Manager で管理する個人用 dotfiles です。

このリポジトリでは、WSL 上の NixOS システム設定、macOS/Linux 共通の Home Manager ユーザー環境、Neovim、tmux、Codex CLI まわりの設定を flake としてまとめています。

## 構成

- `flake.nix`: NixOS-WSL / Home Manager / devShell の flake 定義
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

### NixOS-WSL

リポジトリのルートで次を実行します。

```bash
sudo nixos-rebuild switch --flake .#nixos-wsl
```

初回適用後は、Home Manager も NixOS モジュールとして一緒に適用されます。

### macOS

macOS では Nix と Home Manager を用意したうえで、CPU に合わせて次を実行します。

```bash
home-manager switch --flake .#daiki.miwa-aarch64-darwin
```

Intel Mac の場合は次を使います。

```bash
home-manager switch --flake .#daiki.miwa-x86_64-darwin
```

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
- containers: Docker, Docker Compose
- CLI tools: `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `gh`, `ghq`, `lazygit`
- cloud CLIs: AWS CLI, Azure CLI, Google Cloud CLI
- development tools: Node.js, Python, Terraform, Lua, TypeScript, Nix 関連ツール
- devShells: React Native / Expo, Astro / Playwright

Neovim の設定は `home/nvim/` に置き、Home Manager で `~/.config/nvim` にリンクします。

tmux では、`prefix + m` で fzf ベースのセッション管理ポップアップを開けます。

Docker は NixOS の `virtualisation.docker` で有効化し、ユーザーを `docker` グループに追加します。初回適用後は、グループ反映のために WSL セッションへ入り直します。

## React Native / Expo

React Native / Expo 用のツールは通常環境には入れず、devShell の中だけで使います。手順は [React Native / Expo Task Manager チュートリアル](docs/react-native-expo-task-manager.md) にまとめています。

```bash
nix develop .#expo -c zsh
```

`nix develop`は通常bashを起動するため、zsh/starshipを使う場合は`-c zsh`を付けます。Home Manager適用後は、任意のプロジェクトで`expo-dev`を実行しても同じdevShellに入れます。direnvも有効化しているので、Expoプロジェクトでは`.envrc`に`use flake ~/dotfiles-nixos#expo`を書いておくと自動でdevShellへ入れます。

devShell には Node.js 22, pnpm, Yarn, Bun, JDK 21, Watchman, Git, Android platform-tools (`adb`), EAS CLI が入ります。`expo-env`, `expo-new`, `expo-start`, `expo-doctor`, `eas-latest` も使えます。Expo プロジェクトは次のように作成できます。

```bash
expo-new my-app
cd my-app
expo-start
```

Expo CLI はプロジェクトローカルのものを `pnpm expo ...` で実行する想定です。EAS Build / Submit はグローバルに入る `eas` を使えます。

```bash
eas login
eas build --platform android
```

この環境は NixOS-WSL 前提なので、Android の実機確認は Expo Go か `adb` 接続を使います。Android エミュレータや Android Studio は Windows 側に入れて、WSL 側から `adb` で接続する構成が扱いやすいです。iOS のローカルビルドは Linux/WSL ではできないため、Expo Go または EAS Build を使います。

## Astro / Playwright

Astro 用の devShell には Node.js 22, pnpm, Bun, Wrangler, Playwright が入ります。

```bash
nix develop .#astro -c zsh
```

NixOS-WSL では Chromium を system package として入れ、Chrome DevTools が期待する `/opt/google/chrome/chrome` から Chromium を起動できるようにしています。macOS では Nixpkgs の Chromium は使わず、Playwright の Nix 管理ブラウザを使います。

## 注意

- 認証情報や秘密情報はこのリポジトリに含めません。
- `home.stateVersion` と `system.stateVersion` は、既存環境では不用意に変更しません。
- macOS では OS 全体の設定は管理せず、Home Manager のユーザー環境だけを管理します。
