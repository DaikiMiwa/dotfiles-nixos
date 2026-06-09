{
  lib,
  pkgs,
  ...
}:

let
  moshiVersion = "0.2.25";

  moshiTargets = {
    x86_64-linux = {
      url = "https://cdn.getmoshi.app/hook/v0.2.25/moshi-hook_Linux_x86_64.tar.gz";
      hash = "sha256-4T+OSIURlaWDAOxKbQfIFwyjk4+4MUeniLoveOTHO5o=";
    };
    aarch64-linux = {
      url = "https://cdn.getmoshi.app/hook/v0.2.25/moshi-hook_Linux_arm64.tar.gz";
      hash = "sha256-oXIZKrGa2OtoUaXp6Yv2N8vAi6FubzoTM8GBR6Uy1bg=";
    };
    aarch64-darwin = {
      url = "https://cdn.getmoshi.app/hook/v0.2.25/moshi-hook_Darwin_arm64.tar.gz";
      hash = "sha256-85D6jn5JHG6O9rCpPfjwRokaXI3raNi+kUCMOM1ZucE=";
    };
    x86_64-darwin = {
      url = "https://cdn.getmoshi.app/hook/v0.2.25/moshi-hook_Darwin_x86_64.tar.gz";
      hash = "sha256-p4K3as+rylkhvXkQ9n/V8AQssO5xBpCwbxeESOOWBKM=";
    };
  };

  target = moshiTargets.${pkgs.stdenv.hostPlatform.system} or null;

  moshi-hook =
    if target == null then
      null
    else
      pkgs.stdenv.mkDerivation {
        pname = "moshi-hook";
        version = moshiVersion;

        src = pkgs.fetchurl { inherit (target) url hash; };

        nativeBuildInputs = [
          pkgs.gzip
          pkgs.gnutar
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];

        buildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];

        unpackPhase = ''
          mkdir -p source
          tar -xzf $src -C source moshi-hook
        '';

        installPhase = ''
          mkdir -p $out/bin
          install -m755 source/moshi-hook $out/bin/moshi-hook
          ln -s moshi-hook $out/bin/moshi
        '';

        meta = {
          description = "Moshi Terminal AI Agent Hook and client";
          homepage = "https://getmoshi.app";
          platforms = builtins.attrNames moshiTargets;
        };
      };
in
{
  home.packages = lib.optional (target != null) moshi-hook;
}
