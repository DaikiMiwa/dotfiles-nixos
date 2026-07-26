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
- `home/opencode.nix`: opencode CLI

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

## Cursor / VS Code から WSL を使う

`nixos/configuration.nix` では、Cursor Server と VS Code Server の
ビルド済み Node.js を NixOS-WSL 上で実行するために `programs.nix-ld` を
有効化しています。サーバーの取得に必要な `wget` と `curl` も
システム環境に含まれます。

まず WSL 側へ設定を適用します。

```bash
cd ~/dotfiles-nixos
sudo nixos-rebuild switch --flake .#nixos-wsl
```

適用後、Windows の PowerShell から WSL を完全に停止して起動し直します。

```powershell
wsl --shutdown
wsl -d NixOS
```

Windows 側には
[Cursor](https://cursor.com/download) と
[VS Code](https://code.visualstudio.com/download) をインストールします。
それぞれ別のユーザー設定と拡張機能を持つため、両方を併用できます。

- Cursor: 内蔵の Anysphere 製 `anysphere.remote-wsl` を使います。
  Cursor には Microsoft 製 `ms-vscode-remote.remote-wsl` を追加しません。
- VS Code: Extensions から Microsoft 製 `WSL`
  (`ms-vscode-remote.remote-wsl`) をインストールします。

各エディタでコマンドパレットを開き、`WSL: Connect to WSL using Distro...`
から `NixOS` を選択してください。接続後は `File: Open Folder...` で
`/home/daiki.miwa/dotfiles-nixos` を開けます。左下のリモート接続表示が
`WSL: NixOS` になれば接続完了です。

接続できない場合は、WSL 側で次を確認します。

```bash
test -e /lib64/ld-linux-x86-64.so.2
command -v wget
echo "$WSL_DISTRO_NAME"
```

古いリモートサーバーが残っている場合に限り、両方のエディタを完全に閉じて
該当ディレクトリを退避し、再接続してサーバーを再導入します。

```bash
mv ~/.cursor-server ~/.cursor-server.backup
mv ~/.vscode-server ~/.vscode-server.backup
```

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
- AI coding CLIs: Codex CLI, opencode
- cloud CLIs: AWS CLI, Azure CLI, Google Cloud CLI
- development tools: Node.js, Python, Terraform, Lua, TypeScript, Nix 関連ツール
- writing tools: LaTeX, BibLaTeX/Biber, Pandoc, Poppler utilities
- devShells: React Native / Expo, Astro / Playwright

Neovim の設定は `home/nvim/` に置き、Home Manager で `~/.config/nvim` にリンクします。

tmux では、`prefix + m` で fzf ベースのセッション管理ポップアップを開けます。

WSL の tmux では、`prefix + I` で Windows クリップボード内の画像を PNG に保存し、その WSL パスを現在のペインへ貼り付けます。Codex CLI の画像貼り付けが Windows クリップボードを直接読めない場合は、このキーで画像パスを入力欄へ貼り付けて添付します。コマンド単体では `codex-wsl-clipboard-image` が保存後の WSL パスを出力し、`codex-wsl-paste-image` が tmux ペインへ貼り付けます。

Docker は NixOS の `virtualisation.docker` で有効化し、ユーザーを `docker` グループに追加します。初回適用後は、グループ反映のために WSL セッションへ入り直します。

## LaTeX / 論文執筆

LaTeX は Home Manager の通常環境に入り、LuaLaTeX / pdfLaTeX / pLaTeX / upLaTeX を使えます。新しい論文プロジェクトは次で作成できます。

```bash
paper-new my-paper
paper-new --platex --conference domestic-paper
cd my-paper
latexmk-lualatex main.tex
```

`paper-new` は `--engine <lualatex|pdflatex|platex|uplatex>` と `--template <article|conference|minimal>` を選べます。補助コマンドとして、`paper-check`、`paper-count`、`paper-diff`、`paper-bib-sort`、`paper-bib-check`、`paper-fig` も入ります。

Neovim では `.tex` を開いた時だけ VimTeX と LaTeX snippets が読み込まれます。`<leader>ll` で自動ビルド、`<leader>lv` で PDF 表示、`<leader>lb` で `.bib` から citation、`<leader>lp` / `<leader>la` で `\parencite{}` / `\textcite{}`、`<leader>lr` で `\label{}` から `\cref{}` を挿入します。`<leader>lF`、`<leader>lT`、`<leader>lE` で図・表・数式ラベルに絞り込めます。`<leader>ld` は論文 dashboard、`<leader>lo` は TODO picker、`<leader>lw` は word/page count、`<leader>lC` は `paper-check` です。

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
