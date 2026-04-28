{ config, pkgs, lib, isWSL ? false, ... }:

{
  # ===== 基本情報 =====
  home.username = "nixos";              # ← 自分のユーザー名
  home.homeDirectory = "/home/nixos";   # ← 同じく
  home.stateVersion = "25.11";             # 初回設定したNixOSバージョン

  # home-manager 自身を管理対象にする
  programs.home-manager.enable = true;

  # ===== ユーザー専用パッケージ =====
  # configuration.nix の environment.systemPackages から
  # 「ユーザー個人で使うもの」をこちらに移していく
  home.packages = with pkgs; [
    # 個人用のツールはここへ(後で追加)
    lua-language-server
    stylua
    nil
    nixfmt-rfc-style
    typescript
    typescript-language-server
    vscode-langservers-extracted
    prettier
    nodePackages.eslint
    pyright
    ruff
    bash-language-server
    gh
  ] ++ lib.optionals isWSL [
    wslu
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # macOS 専用 (Step 4 で活用)
  ];

   programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      gcc
      tree-sitter
    ];
  };

  # ===== zsh =====
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;       # 25.11 は単数形
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
      g  = "git";
      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate";
      ".." = "cd ..";
      "..." = "cd ../..";
      hi = "echo 'Hello from home-manager!'";   # ← 追加
    };
    initContent = ''
      # ここに自由に zsh 設定を書ける
      bindkey -e   # Emacs キーバインド
      setopt AUTO_CD
    '';
  };

  # ===== git =====
  programs.git = {
    enable = true;
    userName  = "Daiki Miwa";          # ← Git のユーザー名
    userEmail = "miwa.daiki.mllab.nit@gmail.com";    # ← メール
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
    };
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

  programs.gh = {              # ← ここに置く
    enable = true;
    settings = {
      git_protocol = "https";
      editor = "nvim";
    };
  };
}
