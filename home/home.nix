{
  config,
  pkgs,
  lib,
  username,
  homeDirectory,
  isWSL ? false,
  ...
}:

{
  imports = [
    ./codex.nix
    ./latex.nix
    ./nvim.nix
    ./tmux.nix
  ];

  # ===== 基本情報 =====
  home.username = username; # ← 自分のユーザー名
  home.homeDirectory = homeDirectory; # ← 同じく
  home.stateVersion = "25.11"; # 初回設定したNixOSバージョン

  # home-manager 自身を管理対象にする
  programs.home-manager.enable = true;

  # ===== ユーザー専用パッケージ =====
  # configuration.nix の environment.systemPackages から
  # 「ユーザー個人で使うもの」をこちらに移していく
  home.packages =
    with pkgs;
    [
      # 個人用のツールはここへ(後で追加)
      scowl
      lua-language-server
      stylua
      nil
      nixfmt-rfc-style
      nh
      nix-output-monitor
      nodejs_22
      python313
      gcc
      gnumake
      terraform
      terraform-ls
      tflint
      terraform-docs
      typescript
      typescript-language-server
      astro-language-server
      vscode-langservers-extracted
      prettier
      nodePackages.eslint
      tailwindcss-language-server
      emmet-language-server
      biome
      pyright
      basedpyright
      pyrefly
      uv
      python3Packages.pytest
      ruff
      bash-language-server
      sqls
      gh
      ghq
      lazygit
      awscli2
      azure-cli
      google-cloud-sdk
      gemini-cli
      (textlint.withPackages [
        textlint-rule-preset-ja-spacing
      ])
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      chromium
      bubblewrap
      xdg-dbus-proxy
    ]
    ++ lib.optionals isWSL [
      wslu
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && !isWSL) [
      wl-clipboard
      xclip
      xsel
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # macOS 専用 (Step 4 で活用)
    ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      gcc
      gnumake
      nodejs
      tree-sitter
    ];
  };

  home.file.".textlintrc.json".text = builtins.toJSON {
    rules = {
      preset-ja-spacing = {
        ja-space-between-half-and-full-width = {
          space = "always";
        };
      };
    };
  };

  # ===== zsh =====
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true; # 25.11 は単数形
    syntaxHighlighting.enable = true;
    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
    };
    shellAliases = {
      ll = "eza -la --git --icons";
      ls = "eza --icons";
      la = "eza -a --icons";
      lt = "eza --tree --level=2 --icons";
      cat = "bat";
      g = "git";
      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate";
      gq = "ghq";
      gqg = "ghq get";
      gql = "ghq list";
      gqr = "ghq root";
      dotfiles-check = "nix flake check --all-systems --no-build --show-trace ${homeDirectory}/dotfiles-nixos";
      dotfiles-fmt = "nix fmt ${homeDirectory}/dotfiles-nixos";
      expo-dev = "nix develop ${homeDirectory}/dotfiles-nixos#expo -c zsh";
      ".." = "cd ..";
      "..." = "cd ../..";
      hi = "echo 'Hello from home-manager!'"; # ← 追加
    }
    // lib.optionalAttrs isWSL {
      nixos-switch = "sudo nh os switch ${homeDirectory}/dotfiles-nixos#nixos-wsl";
    };
    initContent = ''
      # ここに自由に zsh 設定を書ける
      bindkey -e   # Emacs キーバインド
      setopt AUTO_CD

      ${lib.optionalString isWSL ''
        if [ -n "$TMUX" ]; then
        sync_wsl_interop() {
          local tmux_wsl_interop latest_wsl_interop

          if [ -n "$WSL_INTEROP" ] && [ -S "$WSL_INTEROP" ]; then
            tmux set-environment -g WSL_INTEROP "$WSL_INTEROP" 2>/dev/null || true
            return
          fi

          tmux_wsl_interop="$(tmux show-environment -g WSL_INTEROP 2>/dev/null | sed -n 's/^WSL_INTEROP=//p')"
          if [ -n "$tmux_wsl_interop" ] && [ -S "$tmux_wsl_interop" ]; then
            export WSL_INTEROP="$tmux_wsl_interop"
            return
          fi

          latest_wsl_interop="$(
            find /run/WSL -maxdepth 1 -type s -name '*_interop' -printf '%T@ %p\n' 2>/dev/null \
              | sort -rn \
              | awk 'NR == 1 { print $2 }'
          )"
          if [ -n "$latest_wsl_interop" ] && [ -S "$latest_wsl_interop" ]; then
            export WSL_INTEROP="$latest_wsl_interop"
            tmux set-environment -g WSL_INTEROP "$WSL_INTEROP" 2>/dev/null || true
          fi
        }

        sync_wsl_interop
        if (( ''${precmd_functions[(I)sync_wsl_interop]} == 0 )); then
          precmd_functions+=(sync_wsl_interop)
        fi
        fi
      ''}

      gqcd() {
        local repo
        repo="$(ghq list -p | fzf)"
        if [ -n "$repo" ]; then
          cd "$repo"
        fi
      }
    '';
  };

  # ===== git =====
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Daiki Miwa";
        email = "miwa.daiki.mllab.nit@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
      ghq.root = "~/src";
    };
  };

  # ===== SSH =====
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.local"
    ];
  };

  # ===== プロンプト: starship =====
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # ===== fzf =====
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ===== direnv (プロジェクトごとの環境切り替え。後で活躍する) =====
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ===== bat / eza / ripgrep / fd は home.packages でなく programs で管理可 =====
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.ripgrep.enable = true;
  programs.fd.enable = true;

  programs.gh = {
    # ← ここに置く
    enable = true;
    settings = {
      git_protocol = "https";
      editor = "nvim";
    };
  };
}
