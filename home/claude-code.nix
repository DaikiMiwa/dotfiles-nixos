{
  lib,
  pkgs,
  homeDirectory,
  claudeCodePackage ? pkgs.claude-code,
  ...
}:

let
  claudeSettingsText = builtins.toJSON { };
in
{
  home.packages = [ claudeCodePackage ];

  # Claude Code writes project trust and other runtime state to ~/.claude.json.
  # Keep that file, and settings.json, writable instead of linking them to the
  # immutable Nix store.
  home.activation.initializeClaudeCodeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings_dir="${homeDirectory}/.claude"
    settings_file="$settings_dir/settings.json"

    run mkdir -p "$settings_dir"

    if [ ! -e "$settings_file" ]; then
      run install -m 600 ${pkgs.writeText "claude-code-settings.json" claudeSettingsText} "$settings_file"
    fi
  '';
}
