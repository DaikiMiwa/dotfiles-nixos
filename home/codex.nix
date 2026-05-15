{
  lib,
  pkgs,
  homeDirectory,
  isWSL ? false,
  ...
}:

let
  codexVersion = "0.131.0-alpha.6";
  codexReleasePrefix = "rust-v";
  linuxHash = "sha256-prbx77HX+g+Lu/J8jTLZlEAZpl6lNU9hbVbmRpZJYHU=";
  aarch64DarwinHash = "sha256-wV68PpyXK6vvOJuLqHoyR3Ya+vEDZrS1upzGgSMt4fE=";
  x86DarwinHash = "sha256-YtJi+fy3sRPpXkMbvyYzf762n70CzQgqJClpRue3aO0=";

  codexTargets = {
    x86_64-linux = {
      asset = "codex-x86_64-unknown-linux-musl.tar.gz";
      binary = "codex-x86_64-unknown-linux-musl";
      hash = linuxHash;
    };
    aarch64-darwin = {
      asset = "codex-aarch64-apple-darwin.tar.gz";
      binary = "codex-aarch64-apple-darwin";
      hash = aarch64DarwinHash;
    };
    x86_64-darwin = {
      asset = "codex-x86_64-apple-darwin.tar.gz";
      binary = "codex-x86_64-apple-darwin";
      hash = x86DarwinHash;
    };
  };

  codexTarget = codexTargets.${pkgs.stdenv.hostPlatform.system} or null;

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
      url = "https://github.com/openai/codex/releases/download/rust-v${codexVersion}/${codexTarget.asset}";
      hash = codexTarget.hash;
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
      install -m755 source/${codexTarget.binary} $out/bin/codex
    '';

    meta = {
      description = "OpenAI Codex CLI";
      homepage = "https://github.com/openai/codex";
      platforms = builtins.attrNames codexTargets;
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

      linux_asset="codex-x86_64-unknown-linux-musl.tar.gz"
      aarch64_darwin_asset="codex-aarch64-apple-darwin.tar.gz"
      x86_darwin_asset="codex-x86_64-apple-darwin.tar.gz"

      release_json="$(curl -sSfL "https://api.github.com/repos/openai/codex/releases?per_page=100")"
      tag="$(
        printf '%s' "$release_json" \
          | jq -r \
              --arg release_prefix "${codexReleasePrefix}" \
              --arg linux_asset "$linux_asset" \
              --arg aarch64_darwin_asset "$aarch64_darwin_asset" \
              --arg x86_darwin_asset "$x86_darwin_asset" \
            '
              [
                .[]
                | select(.tag_name | test("^" + $release_prefix))
                | select(any(.assets[]?; .name == $linux_asset))
                | select(any(.assets[]?; .name == $aarch64_darwin_asset))
                | select(any(.assets[]?; .name == $x86_darwin_asset))
              ][0].tag_name // empty
            '
      )"

      if [ -z "$tag" ]; then
        echo "No Codex release with all expected assets was found." >&2
        exit 1
      fi

      version="''${tag#${codexReleasePrefix}}"
      prefetch_hash() {
        local asset="$1"
        local url

        url="https://github.com/openai/codex/releases/download/$tag/$asset"
        nix --extra-experimental-features 'nix-command flakes' store prefetch-file --json "$url" | jq -r '.hash'
      }

      linux_hash="$(prefetch_hash "$linux_asset")"
      aarch64_darwin_hash="$(prefetch_hash "$aarch64_darwin_asset")"
      x86_darwin_hash="$(prefetch_hash "$x86_darwin_asset")"

      sed -i -E \
        -e "s|codexVersion = \"[^\"]+\";|codexVersion = \"$version\";|" \
        -e "s|linuxHash = \"sha256-[^\"]+\";|linuxHash = \"$linux_hash\";|" \
        -e "s|aarch64DarwinHash = \"sha256-[^\"]+\";|aarch64DarwinHash = \"$aarch64_darwin_hash\";|" \
        -e "s|x86DarwinHash = \"sha256-[^\"]+\";|x86DarwinHash = \"$x86_darwin_hash\";|" \
        "$codex_file"

      echo "Updated Codex to $version"
      echo "Linux hash: $linux_hash"
      echo "aarch64-darwin hash: $aarch64_darwin_hash"
      echo "x86_64-darwin hash: $x86_darwin_hash"
      echo "File: $codex_file"
    '';
  };

  codexPackage = if codexTarget == null then pkgs.codex else codex-bin;
in
{
  home.packages = [
    codexPackage
    codex-update-version
  ];

  home.file.".codex/config.toml" = lib.mkIf isWSL {
    text = codexConfigText;
    force = true;
  };
}
