{
  config,
  pkgs,
  lib,
  homeDirectory,
  ...
}:

let
  codexVersion = "0.126.0-alpha.10";

  codexConfigText = ''
    # Codex user config
    # 認証情報はここに書かない
    approval_policy = "never"
    sandbox_mode = "workspace-write"

    [projects."${homeDirectory}/src/github.com/daiki.miwa"]
    trust_level = "trusted"
  '';

  codexConfigFile = pkgs.writeText "codex-config.toml" codexConfigText;

  codex-bin = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex";
    version = codexVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${codexVersion}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-pMiRQ3cQs3IstS8br1TQlwfO6dBIDNnDbfVxauGUoe4=";
    };

    nativeBuildInputs = with pkgs; [
      gzip
      gnutar
    ];

    unpackPhase = ''
      mkdir -p source
      tar -xzf $src -C source
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -m755 source/codex-x86_64-unknown-linux-musl $out/bin/codex
    '';

    meta = {
      description = "OpenAI Codex CLI";
      homepage = "https://github.com/openai/codex";
      platforms = [ "x86_64-linux" ];
    };
  };

  codexPackage = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then codex-bin else pkgs.codex;
in
{
  home.packages = [
    codexPackage
  ];

  home.activation.ensureCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.codex"

    if [ ! -e "$HOME/.codex/config.toml" ] || [ -L "$HOME/.codex/config.toml" ]; then
      $DRY_RUN_CMD rm -f "$HOME/.codex/config.toml"
      $DRY_RUN_CMD install -m 600 ${codexConfigFile} "$HOME/.codex/config.toml"
    fi
  '';
}
