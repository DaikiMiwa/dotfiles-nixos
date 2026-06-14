{ lib, pkgs, ... }:

{
  home.packages = lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.opencode) pkgs.opencode;
}
