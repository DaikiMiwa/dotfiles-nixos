{
  lib,
  pkgs,
  ...
}:

let
  antigravityVersion = "1.0.8";

  antigravityTargets = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-eEJqYfkpXXUoXZzdOem53Cc2NGRoySzoam/eG8x6nW3TLHvtGQOl3qzYdKBddbq/W5B+mRoRetY/M1SBE8Ybwg==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-mCs0Te/S5jsI1KnvYIp3Cro6kumkEY0xjgCC8pdDRX6KFqrxwA98Ot51wtB671qPpdpmDkCMsZm0eod4sxIooA==";
    };
    aarch64-darwin = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-j8ZX7qOhPAZixhS6QFHwQFDLCrunVVUYqts22I2n070hKuTMbPQ5IDiyFlaJaXmuqzL4vwXIDmn8cgx2UQNGNg==";
    };
    x86_64-darwin = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-/5nMNqr6uaN73u9rosycHf7vrxMwUuIaZarsRt1almA9W0g1K8fVHUbl22PCqcBcXRImtpQAwBzKAZUhfy3OQQ==";
    };
  };

  target = antigravityTargets.${pkgs.stdenv.hostPlatform.system} or null;

  antigravity-bin =
    if target == null then
      null
    else
      pkgs.stdenv.mkDerivation {
        pname = "antigravity-cli";
        version = antigravityVersion;

        src = pkgs.fetchurl { inherit (target) url hash; };

        nativeBuildInputs = [
          pkgs.gzip
          pkgs.gnutar
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];

        buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];

        unpackPhase = ''
          mkdir -p source
          tar -xzf $src -C source
        '';

        installPhase = ''
          mkdir -p $out/bin
          if [ -f source/antigravity ]; then
            install -m755 source/antigravity $out/bin/agy
          elif [ -f source/agy ]; then
            install -m755 source/agy $out/bin/agy
          else
            echo "Error: No antigravity or agy binary found in source!" >&2
            exit 1
          fi
        '';

        meta = {
          description = "Google Antigravity CLI";
          homepage = "https://antigravity.google";
          platforms = builtins.attrNames antigravityTargets;
        };
      };
in
{
  home.packages = lib.optional (target != null) antigravity-bin;
}
