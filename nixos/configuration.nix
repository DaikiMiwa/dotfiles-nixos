# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{
  config,
  lib,
  pkgs,
  username,
  unfreePackageNames ? [ ],
  ...
}:

{
  imports = [
    # include NixOS-WSL modules
    # <nixos-wsl/modules> flakesで管理するため必要なし
    # <home-manager/nixos>
  ];

  wsl = {
    enable = true;
    defaultUser = username;
    interop.includePath = false;
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    linger = true;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  programs.java = {
    enable = true;
    package = pkgs.jdk21; # Java JDK
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) unfreePackageNames;

  networking.interfaces.eth0.mtu = 1280;

  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      udev-gothic
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "Noto Serif CJK JP"
          "Noto Serif"
        ];
        sansSerif = [
          "UDEV Gothic"
          "Noto Sans CJK JP"
          "Noto Sans"
        ];
        monospace = [
          "UDEV Gothic"
          "DejaVu Sans Mono"
          "Noto Sans Mono CJK JP"
        ];
        emoji = [
          "Noto Color Emoji"
        ];
      };
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  systemd.sockets.docker.socketConfig = {
    SocketGroup = "docker";
    SocketMode = "0660";
  };

  environment.systemPackages = with pkgs; [
    # 基本
    curl
    wget
    unzip

    # CLI ユーティリティ
    jq # JSON 整形
    tree
    htop

    # コンテナ
    docker-compose

    # Browser automation
    chromium
  ];

  environment.variables = {
    CHROME_BIN = "${pkgs.chromium}/bin/chromium";
    CHROMIUM_BIN = "${pkgs.chromium}/bin/chromium";
  };

  systemd.tmpfiles.rules = [
    "d /opt/google/chrome 0755 root root -"
    "L+ /opt/google/chrome/chrome - - - - ${pkgs.chromium}/bin/chromium"
  ];

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11"; # Did you read the comment?
}
