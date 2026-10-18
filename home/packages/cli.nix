{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nh
    nix-output-monitor
    git-remote-codecommit
    ghq
    lazygit
    delta
    jq
    yq-go
    repomix
  ];
}
