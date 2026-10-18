{ pkgs, ... }:
{
  home.packages = with pkgs; [
    scowl
    (textlint.withPackages [
      textlint-rule-preset-ja-spacing
      textlint-rule-preset-ja-technical-writing
    ])
  ];
}
