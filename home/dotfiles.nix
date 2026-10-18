{
  config,
  lib,
  pkgs,
  ...
}:

let
  repo = lib.escapeShellArg config.dotfiles.repository;
  system = pkgs.stdenv.hostPlatform.system;
  dotfiles-check = pkgs.writeShellApplication {
    name = "dotfiles-check";
    runtimeInputs = [ pkgs.nix ];
    text = ''
      cd ${repo}
      nix flake check --all-systems --no-build --show-trace
      nix build --no-link \
        '.#checks.${system}.format-nix' \
        '.#checks.${system}.format-lua' \
        '.#checks.${system}.shell-scripts' \
        '.#checks.${system}.cursor-cli' \
        '.#checks.${system}.dotfiles-helpers' \
        '.#checks.${system}.neovim-config'
    '';
  };
  dotfiles-fmt = pkgs.writeShellApplication {
    name = "dotfiles-fmt";
    runtimeInputs = [ pkgs.nix ];
    text = ''
      cd ${repo}
      nix fmt
    '';
  };
in
{
  options.dotfiles.repository = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dotfiles-nixos";
    description = "Absolute path to the writable dotfiles checkout.";
  };

  config = {
    assertions = [
      {
        assertion = lib.hasPrefix "/" config.dotfiles.repository;
        message = "dotfiles.repository must be an absolute path.";
      }
    ];
    home.packages = [
      dotfiles-check
      dotfiles-fmt
    ];
  };
}
