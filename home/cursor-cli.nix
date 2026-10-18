{
  pkgs,
  cursorCliPackage ? pkgs.cursor-cli,
  ...
}:

{
  home.packages = [ cursorCliPackage ];
}
