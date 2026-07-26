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

let
  dockerPackage = pkgs.docker_29;
in
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
    extraGroups = [ "wheel" ];
    linger = true;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  programs.java = {
    enable = true;
    package = pkgs.jdk21; # Java JDK
  };

  # Cursor / VS Code の WSL サーバー（ビルド済み Node.js）を NixOS で動かすため。
  # /lib64/ld-linux-x86-64.so.2 を提供し NIX_LD をシステム全体に設定するので
  # wsl.exe --exec 経由でサーバが起動されても動く。wget は systemPackages に既にあり。
  programs.nix-ld.enable = true;

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
    package = dockerPackage;
    rootless = {
      enable = true;
      package = dockerPackage;
      setSocketVariable = true;
    };
  };

  systemd.user.services.docker-prune = {
    description = "Prune Docker resources (Rootless)";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    environment.DOCKER_HOST = "unix://%t/docker.sock";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe dockerPackage} system prune -f";
    };
  };

  systemd.user.timers.docker-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # 基本
    bashInteractive
    curl
    wget
    unzip

    # CLI ユーティリティ
    bubblewrap
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
    "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash"
    "d /usr/bin 0755 root root -"
    # Cursor の WSL インストーラーはログインシェルを通さず、
    # /usr/bin と /bin だけの PATH で基本コマンドを呼び出す。
    "L+ /usr/bin/awk - - - - ${pkgs.gawk}/bin/awk"
    "L+ /usr/bin/basename - - - - ${pkgs.coreutils}/bin/basename"
    "L+ /usr/bin/bash - - - - ${pkgs.bashInteractive}/bin/bash"
    "L+ /usr/bin/cat - - - - ${pkgs.coreutils}/bin/cat"
    "L+ /usr/bin/chmod - - - - ${pkgs.coreutils}/bin/chmod"
    "L+ /usr/bin/cp - - - - ${pkgs.coreutils}/bin/cp"
    "L+ /usr/bin/cut - - - - ${pkgs.coreutils}/bin/cut"
    "L+ /usr/bin/date - - - - ${pkgs.coreutils}/bin/date"
    "L+ /usr/bin/dirname - - - - ${pkgs.coreutils}/bin/dirname"
    "L+ /usr/bin/env - - - - ${pkgs.coreutils}/bin/env"
    "L+ /usr/bin/find - - - - ${pkgs.findutils}/bin/find"
    "L+ /usr/bin/grep - - - - ${pkgs.gnugrep}/bin/grep"
    "L+ /usr/bin/gzip - - - - ${pkgs.gzip}/bin/gzip"
    "L+ /usr/bin/head - - - - ${pkgs.coreutils}/bin/head"
    "L+ /usr/bin/id - - - - ${pkgs.coreutils}/bin/id"
    "L+ /usr/bin/ln - - - - ${pkgs.coreutils}/bin/ln"
    "L+ /usr/bin/ls - - - - ${pkgs.coreutils}/bin/ls"
    "L+ /usr/bin/mkdir - - - - ${pkgs.coreutils}/bin/mkdir"
    "L+ /usr/bin/mktemp - - - - ${pkgs.coreutils}/bin/mktemp"
    "L+ /usr/bin/mv - - - - ${pkgs.coreutils}/bin/mv"
    "L+ /usr/bin/ps - - - - ${pkgs.procps}/bin/ps"
    "L+ /usr/bin/readlink - - - - ${pkgs.coreutils}/bin/readlink"
    "L+ /usr/bin/rm - - - - ${pkgs.coreutils}/bin/rm"
    "L+ /usr/bin/sed - - - - ${pkgs.gnused}/bin/sed"
    "L+ /usr/bin/setsid - - - - ${pkgs.util-linux}/bin/setsid"
    "L+ /usr/bin/sleep - - - - ${pkgs.coreutils}/bin/sleep"
    "L+ /usr/bin/tail - - - - ${pkgs.coreutils}/bin/tail"
    "L+ /usr/bin/tar - - - - ${pkgs.gnutar}/bin/tar"
    "L+ /usr/bin/touch - - - - ${pkgs.coreutils}/bin/touch"
    "L+ /usr/bin/tr - - - - ${pkgs.coreutils}/bin/tr"
    "L+ /usr/bin/uname - - - - ${pkgs.coreutils}/bin/uname"
    "L+ /usr/bin/wc - - - - ${pkgs.coreutils}/bin/wc"
    "L+ /usr/bin/whoami - - - - ${pkgs.coreutils}/bin/whoami"
    "d /opt/google/chrome 0755 root root -"
    "L+ /opt/google/chrome/chrome - - - - ${pkgs.chromium}/bin/chromium"
  ];

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.11"; # Did you read the comment?
}
