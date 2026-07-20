{
  pkgs,
  lib,
  herdrPackage ? null,
  isWSL ? false,
  ...
}:

let
  cfg = pkgs.formats.toml { };
  iconvPackage = if pkgs.stdenv.isLinux then pkgs.glibc.bin else pkgs.libiconv;

  herdr-wsl-copy = pkgs.writeShellApplication {
    name = "herdr-wsl-copy";
    runtimeInputs = [
      iconvPackage
    ];
    text = ''
      iconv -f UTF-8 -t UTF-16LE | /mnt/c/Windows/System32/clip.exe
    '';
  };

  herdr-wsl-paste = pkgs.writeShellApplication {
    name = "herdr-wsl-paste";
    runtimeInputs = [
      pkgs.coreutils
      herdrPackage
    ];
    text = ''
      set -euo pipefail

      text="$(
        /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
          -NoLogo \
          -NoProfile \
          -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; \$OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::Out.Write((Get-Clipboard -Raw))" \
          | tr -d '\r'
      )"

      if [ -n "''${HERDR_ACTIVE_PANE_ID:-}" ]; then
        herdr pane send-text "$HERDR_ACTIVE_PANE_ID" "$text"
      else
        printf '%s' "$text"
      fi
    '';
  };

  codex-herdr-wsl-paste-image = pkgs.writeShellApplication {
    name = "codex-herdr-wsl-paste-image";
    runtimeInputs = [
      pkgs.coreutils
      herdrPackage
    ];
    text = ''
      set -euo pipefail

      powershell=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
      if [ ! -x "$powershell" ]; then
        echo "Windows PowerShell was not found at $powershell" >&2
        exit 1
      fi
      if ! command -v wslpath >/dev/null 2>&1; then
        echo "wslpath was not found on PATH" >&2
        exit 1
      fi

      tmp_ps="$(mktemp "''${TMPDIR:-/tmp}/codex-herdr-wsl-paste-image.XXXXXX.ps1")"
      trap 'rm -f "$tmp_ps"' EXIT

      cat >"$tmp_ps" <<'EOF'
      $ErrorActionPreference = 'Stop'
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Drawing

      if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
          $path = Join-Path $env:TEMP ("codex-clipboard-{0}.png" -f ([guid]::NewGuid().ToString("N")))
          $image = [System.Windows.Forms.Clipboard]::GetImage()
          $image.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
          [Console]::Out.Write($path)
          exit 0
      }

      if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
          $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
          foreach ($file in $files) {
              if ($file -match '\.(png|jpe?g|webp|gif)$') {
                  [Console]::Out.Write($file)
                  exit 0
              }
          }
      }

      [Console]::Error.WriteLine('No image was found in the Windows clipboard.')
      exit 1
      EOF

      ps_file="$(wslpath -w "$tmp_ps")"
      win_path="$("$powershell" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "$ps_file" | tr -d '\r')"
      if [ -z "$win_path" ]; then
        echo "Windows clipboard image export produced no path." >&2
        exit 1
      fi

      image_path="$(wslpath -u "$win_path")"
      if [ -n "''${HERDR_ACTIVE_PANE_ID:-}" ]; then
        herdr pane send-text "$HERDR_ACTIVE_PANE_ID" "$image_path"
      else
        printf '%s\n' "$image_path"
      fi
    '';
  };

  palette = {
    charcoal = "#17150F";
    soil = "#2A2418";
    bark = "#3A2F20";
    olive = "#6F7C45";
    moss = "#8A9A5B";
    ochre = "#C49A4A";
    clay = "#A75F3F";
    teal = "#4F7470";
    sand = "#D8C39B";
    muted = "#A99A7C";
  };
in
lib.mkIf (herdrPackage != null) {
  home.packages = [
    herdrPackage
  ]
  ++ lib.optionals isWSL [
    herdr-wsl-copy
    herdr-wsl-paste
    codex-herdr-wsl-paste-image
  ];

  xdg.configFile."herdr/config.toml".source = cfg.generate "herdr-config.toml" ({
    onboarding = false;

    terminal = {
      default_shell = "${pkgs.zsh}/bin/zsh";
      shell_mode = "auto";
      new_cwd = "follow";
    };

    update = {
      channel = "stable";
    };

    keys = {
      prefix = "alt+b";
      help = "prefix+?";
      settings = "prefix+s";
      new_workspace = "prefix+shift+n";
      rename_workspace = "prefix+shift+w";
      close_workspace = "prefix+shift+d";
      workspace_picker = "prefix+w";
      goto = [
        "prefix+g"
        "prefix+m"
      ];
      detach = "prefix+q";
      reload_config = "prefix+r";
      new_tab = "prefix+c";
      previous_tab = "prefix+,";
      next_tab = "prefix+n";
      switch_tab = "prefix+1..9";
      close_tab = "prefix+shift+x";
      rename_pane = "prefix+shift+p";
      edit_scrollback = "prefix+e";
      copy_mode = "prefix+[";
      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";
      navigate_pane_left = "h";
      navigate_pane_down = "j";
      navigate_pane_up = "k";
      navigate_pane_right = "l";
      navigate_workspace_up = [
        "up"
        "ctrl+p"
      ];
      navigate_workspace_down = [
        "down"
        "ctrl+n"
      ];
      swap_pane_left = "prefix+shift+h";
      swap_pane_down = "prefix+shift+j";
      swap_pane_up = "prefix+shift+k";
      swap_pane_right = "prefix+shift+l";
      cycle_pane_next = "prefix+tab";
      cycle_pane_previous = "prefix+shift+tab";
      split_vertical = [
        "prefix+v"
        "prefix+|"
        "prefix+%"
      ];
      split_horizontal = [
        "prefix+minus"
        "prefix+\""
      ];
      close_pane = "prefix+x";
      zoom = "prefix+z";
      resize_mode = "prefix+shift+r";
      toggle_sidebar = "prefix+b";
    }
    // lib.optionalAttrs isWSL {
      remote_image_paste = "ctrl+v";
      command = [
        {
          key = "prefix+p";
          type = "shell";
          command = "${herdr-wsl-paste}/bin/herdr-wsl-paste";
          description = "paste Windows clipboard into focused pane";
        }
        {
          key = "prefix+shift+i";
          type = "shell";
          command = "${codex-herdr-wsl-paste-image}/bin/codex-herdr-wsl-paste-image";
          description = "paste Windows clipboard image path into focused pane";
        }
      ];
    };

    theme = {
      name = "terminal";
      custom = {
        accent = palette.moss;
        panel_bg = palette.soil;
        surface0 = palette.bark;
        surface1 = palette.olive;
        surface_dim = palette.charcoal;
        overlay0 = palette.muted;
        overlay1 = palette.sand;
        text = palette.sand;
        subtext0 = palette.muted;
        green = palette.moss;
        yellow = palette.ochre;
        red = palette.clay;
        blue = palette.teal;
        teal = palette.teal;
        peach = palette.ochre;
      };
    };

    ui = {
      accent = palette.moss;
      mouse_capture = true;
      copy_on_select = true;
      pane_borders = true;
      pane_gaps = false;
      show_agent_labels_on_pane_borders = false;
      confirm_close = true;
      hide_tab_bar_when_single_tab = true;
      prompt_new_tab_name = false;
      sidebar_collapsed_mode = "compact";
      toast = {
        delivery = "herdr";
        delay_seconds = 1;
        herdr.position = "bottom-right";
        clipboard.position = "bottom-center";
      };
      sound.enabled = true;
      sidebar = {
        agents = {
          row_gap = 0;
          rows = [
            [
              "state_icon"
              "workspace"
              "tab"
            ]
            [ "agent" ]
          ];
        };
        spaces = {
          row_gap = 0;
          rows = [
            [
              "state_icon"
              "workspace"
            ]
            [
              "branch"
              "git_status"
            ]
          ];
        };
      };
    };

    session.resume_agents_on_restore = true;
    remote.manage_ssh_config = true;
    advanced.scrollback_limit_bytes = 10000000;
    experimental.reveal_hidden_cursor_for_cjk_ime = true;
    experimental.cjk_ime_agents = [
      "claude"
      "codex"
      "opencode"
    ];
  });
}
