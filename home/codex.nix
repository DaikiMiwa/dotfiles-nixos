{
  pkgs,
  homeDirectory,
  ...
}:

let
  codexVersion = "0.130.0-alpha.5";
  codexAsset = "codex-x86_64-unknown-linux-musl.tar.gz";
  codexReleasePrefix = "rust-v";

  codexConfigText = ''
    # Codex user config
    # 認証情報はここに書かない
    approval_policy = "never"
    sandbox_mode = "workspace-write"

    [projects."${homeDirectory}/src/github.com/daiki.miwa"]
    trust_level = "trusted"
  '';

  codex-bin = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex";
    version = codexVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${codexVersion}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-1pJesaKsrqDF2Q53lFkR9oxC48eCFcx2zCZ2Nk0CaKI=";
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

  codex-update-version = pkgs.writeShellApplication {
    name = "codex-update-version";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      gnused
      jq
      nix
    ];
    text = ''
      set -euo pipefail

      repo_root="''${1:-}"
      if [ -z "$repo_root" ]; then
        if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" && [ -f "$repo_root/home/codex.nix" ]; then
          :
        else
          repo_root="${homeDirectory}/dotfiles-nixos"
        fi
      fi

      codex_file="$repo_root/home/codex.nix"
      if [ ! -f "$codex_file" ]; then
        echo "codex.nix not found: $codex_file" >&2
        exit 1
      fi

      release_json="$(curl -sSfL "https://api.github.com/repos/openai/codex/releases?per_page=100")"
      tag="$(
        printf '%s' "$release_json" \
          | jq -r '
              [
                .[]
                | select(.tag_name | test("^${codexReleasePrefix}"))
                | select(any(.assets[]?; .name == "${codexAsset}"))
              ][0].tag_name // empty
            '
      )"

      if [ -z "$tag" ]; then
        echo "No Codex release with ${codexAsset} was found." >&2
        exit 1
      fi

      version="''${tag#${codexReleasePrefix}}"
      url="https://github.com/openai/codex/releases/download/$tag/${codexAsset}"
      hash="$(nix store prefetch-file --json "$url" | jq -r '.hash')"

      sed -i -E \
        -e "s|codexVersion = \"[^\"]+\";|codexVersion = \"$version\";|" \
        -e "s|hash = \"sha256-[^\"]+\";|hash = \"$hash\";|" \
        "$codex_file"

      echo "Updated Codex to $version"
      echo "Hash: $hash"
      echo "File: $codex_file"
    '';
  };

  codexPackage = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then codex-bin else pkgs.codex;
in
{
  home.packages = [
    codexPackage
    codex-update-version
  ];

  home.file.".codex/config.toml" = {
    text = codexConfigText;
    force = true;
  };
}
