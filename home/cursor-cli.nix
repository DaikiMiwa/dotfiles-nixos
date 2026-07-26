{
  lib,
  pkgs,
  homeDirectory,
  ...
}:

{
  home.sessionPath = [ "${homeDirectory}/.local/bin" ];

  # Cursor CLI is distributed through Cursor's installer and updates itself.
  # Install it only when it is not already present, leaving its writable state
  # and authentication outside the Nix store.
  home.activation.installCursorCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cursor_agent="${homeDirectory}/.local/bin/cursor-agent"

    if [ ! -x "$cursor_agent" ]; then
      run ${pkgs.coreutils}/bin/env \
        PATH="${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.curl
            pkgs.gnutar
            pkgs.gzip
          ]
        }" \
        ${pkgs.bash}/bin/bash -c \
        '${pkgs.curl}/bin/curl https://cursor.com/install -fsS | ${pkgs.bash}/bin/bash'
    fi
  '';
}
