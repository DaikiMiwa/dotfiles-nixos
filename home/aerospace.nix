{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = [
    pkgs.aerospace
  ];

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace/aerospace.toml;
  xdg.configFile."aerospace/focus-across-monitor.sh" = {
    source = ./aerospace/focus-across-monitor.sh;
    executable = true;
  };
  xdg.configFile."aerospace/move-across-monitor.sh" = {
    source = ./aerospace/move-across-monitor.sh;
    executable = true;
  };

  home.file.".aerospace.toml".source = ./aerospace/aerospace.toml;
}
