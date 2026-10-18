{
  pkgs,
  lib,
  isWSL ? false,
  ...
}:
{
  home.packages =
    lib.optionals pkgs.stdenv.isLinux [
      pkgs.chromium
      pkgs.bubblewrap
      pkgs.xdg-dbus-proxy
    ]
    ++ lib.optionals isWSL [
      pkgs.wslu
      pkgs.xdg-utils
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && !isWSL) [
      pkgs.wl-clipboard
      pkgs.xclip
      pkgs.xsel
    ];
}
