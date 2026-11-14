{ pkgs }:
let
  version = "1.4.6";
  src = pkgs.fetchzip {
    url = "https://github.com/epilande/ccmux/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-Hvk5jLc+ZXQdPuYr1BfZMwAnqsCeGa5tUkJe0ZIMgyo=";
  };
  dependencies = pkgs.stdenvNoCC.mkDerivation {
    pname = "ccmux-picker-dependencies";
    inherit version src;
    nativeBuildInputs = [
      pkgs.bun
      pkgs.cacert
    ];
    dontFixup = true;
    buildPhase = ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      bun install --frozen-lockfile --ignore-scripts --os '*' --cpu '*'
    '';
    installPhase = ''
      mv node_modules "$out"
    '';
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-QKQSt0eR0S+uUSXm7+JbBQehPb3cV8zE6b7mCnuIpMk=";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "ccmux-agent-picker";
  inherit version src;
  # The frozen vendor tree also contains prebuilt libraries for other hosts.
  dontStrip = true;
  dontPatchELF = pkgs.stdenv.isDarwin;
  patches = [ ./ui.patch ];
  nativeBuildInputs = [ pkgs.bun ];
  buildPhase = ''
    cp -R ${dependencies} node_modules
    cp ${./AutoApproval.ts} src/tui/AutoApproval.ts
    cp ${./picker.ts} src/dotfiles-picker.ts
    cp ${./build.ts} build-picker.ts
    cp ${./AutoApproval.test.ts} src/tui/AutoApproval.test.ts
    bun test src/tui/AutoApproval.test.ts
    bun run build-picker.ts
  '';
  installPhase = ''
    mkdir -p "$out/share/ccmux-picker" "$out/bin"
    cp -R picker-dist/* "$out/share/ccmux-picker/"
    cp -R node_modules "$out/share/ccmux-picker/node_modules"
    mkdir -p "$out/share/licenses/ccmux-agent-picker"
    cp LICENSE "$out/share/licenses/ccmux-agent-picker/LICENSE"
    cat > "$out/bin/ccmux-agent-picker" <<EOF
    #!${pkgs.runtimeShell}
    export CCMUX_CALLER_PWD="\$PWD"
    cd "$out/share/ccmux-picker"
    exec ${pkgs.bun}/bin/bun --no-env-file ./dotfiles-picker.js "\$@"
    EOF
    chmod +x "$out/bin/ccmux-agent-picker"
  '';
  meta = {
    description = "ccmux picker with per-agent auto approval controls";
    license = pkgs.lib.licenses.mit;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];
  };
}
