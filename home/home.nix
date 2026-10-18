{
  config,
  pkgs,
  lib,
  username,
  homeDirectory,
  isWSL ? false,
  ...
}:

let
  pnpmRc = ''
    only-built-dependencies[]=esbuild
    only-built-dependencies[]=sharp
    only-built-dependencies[]=workerd
  '';
in
{
  imports = [
    ./aerospace.nix
    ./antigravity.nix
    ./cursor-cli.nix
    ./dotfiles.nix
    ./latex.nix
    ./moshi.nix
    ./nvim.nix
    ./opencode.nix
    ./herdr.nix
    ./tmux.nix
    ./wezterm.nix
    ./packages/cli.nix
    ./packages/cloud.nix
    ./packages/development.nix
    ./packages/desktop.nix
    ./packages/writing.nix
  ];

  # ===== 基本情報 =====
  home.username = username; # ← 自分のユーザー名
  home.homeDirectory = homeDirectory; # ← 同じく
  home.stateVersion = "25.11"; # 初回設定したNixOSバージョン
  home.sessionVariables = {
    PNPM_HOME = "${homeDirectory}/.local/share/pnpm";
  }
  // lib.optionalAttrs isWSL {
    BROWSER = "wslview";
  };
  home.sessionPath = [
    "$PNPM_HOME"
  ]
  ++ lib.optionals isWSL [
    "/mnt/c/Windows"
    "/mnt/c/Windows/System32"
  ];

  # home-manager 自身を管理対象にする
  programs.home-manager.enable = true;

  home.file = {
    ".textlintrc.json".text = builtins.toJSON {
      rules = {
        preset-ja-spacing = {
          ja-space-between-half-and-full-width = {
            space = "always";
          };
        };
        preset-ja-technical-writing = {
          sentence-length = {
            max = 120;
          };
          max-kanji-continuous-len = {
            max = 8;
          };
          no-mix-dearu-desumasu = true;
        };
      };
    };

    ".config/pnpm/rc".text = pnpmRc;
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "Library/Preferences/pnpm/rc" = {
      text = pnpmRc;
      force = true;
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
      expo-dev = "nix develop ${lib.escapeShellArg "${config.dotfiles.repository}#expo"} -c zsh";
      ".." = "cd ..";
      "..." = "cd ../..";
      hi = "echo 'Hello from home-manager!'"; # ← 追加
    }
    // lib.optionalAttrs isWSL {
      open = "wslview";
      explorer = "explorer.exe";
      nixos-switch = "sudo nh os switch ${lib.escapeShellArg "${config.dotfiles.repository}#nixos-wsl"}";
    };
    initContent = ''
      # ここに自由に zsh 設定を書ける
      bindkey -e   # Emacs キーバインド
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[OH' beginning-of-line
      bindkey '^[OF' end-of-line
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
        # このマシン (WSL の nixos-wsl 構成) だけ仕事用メール、他は個人 gmail
        email = if isWSL then "daiki.miwa@accenture.com" else "miwa.daiki.mllab.nit@gmail.com";
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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ===== direnv (プロジェクトごとの環境切り替え。後で活躍する) =====
  programs.direnv = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin then
        pkgs.direnv.overrideAttrs (_old: {
          doCheck = false;
          doInstallCheck = false;
        })
      else
        pkgs.direnv;
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
