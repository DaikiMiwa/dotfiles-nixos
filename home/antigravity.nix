{
  lib,
  pkgs,
  ...
}:

let
  antigravityVersion = "1.0.6";

  antigravityTargets = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-G1eXe+CDmLA0TvUBkIloPAqumClUXN8wVsmh0CuUnqmNtuZD75bvT2h3ZU9NSNUmcDXviidlKo4CP2W5HAbfdg==";
    };
    aarch64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-+ZZ/qMMYwx94vML4E8dU4Ob3usgDAURWHVswMVVyDajKBIXspLbIFCmRcFJqHozJ3J7CCR/Mwem9uGTduWEHVw==";
    };
    aarch64-darwin = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-3k/XXkeDPPHxRYu492NI49zD+GKjvGHxgb+MRNlQPImAy2m2hxUfgOIveaVc/AfqeUq1T2ZY2XqsKzk6OCKiuw==";
    };
    x86_64-darwin = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-qFMu84KRak5pJlCpQyOvyAo1Mh0tyrHTe/JfZL3SDIoGF0B1Y1ppKy8AM6C4igJ9cgxyLi036pInf/iBq6MFvw==";
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
