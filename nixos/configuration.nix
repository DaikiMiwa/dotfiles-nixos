# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
    # <nixos-wsl/modules> flakesで管理するため必要なし
    # <home-manager/nixos>
  ];

  wsl = {
    enable = true;
    defaultUser = "nixos";
    interop.includePath = false;
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    # 基本
    curl
    wget
    unzip

    # CLI ユーティリティ
    jq         # JSON 整形
    tree
    htop

    # エディタ (LSP 関連は後で追加)
    neovim

    # 言語ランタイム (まずは素直にシステムに入れる)
    nodejs_22       # Node.js (Web/TS用)
    python313       # Python 本体

    # ビルド系 (色々入れる時に必要になる)
    gcc
    gnumake
  ];

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11"; # Did you read the comment?
}
