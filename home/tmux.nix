{
  pkgs,
  lib,
  isWSL ? false,
  ...
}:

let
  iconvPackage = if pkgs.stdenv.isLinux then pkgs.glibc.bin else pkgs.libiconv;

  tmux-session-manager = pkgs.writeShellApplication {
    name = "tmux-session-manager";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      gawk
      gnused
      tmux
    ];
    text = ''
            select_icon() {
              selected=$(cat <<'EOF' | fzf --prompt="Icon: " --preview-window=hidden
       : default
      󱄅 : nix
       : paw
       : key
       : fan
       : cut
       : setting
       : bug
       : db
       : tag
       : sun
       : pin
       : script
      󰐟 : poll
      󰇥 : duck
      󱗆 : bird
       : wind
       : tree
       : tint
       : tool
       : suse
       : save
       : plug
       : mask
       : leaf
       : home
       : gift
       : frog
       : fish
       : bone
       : neovim
      󰢱 : lua
       : cpp
       : typescript
       : pen
      EOF
      )

            if [ -n "$selected" ]; then
              echo "$selected" | awk '{print $1}'
            else
              echo ""
            fi
          }

            format_session_name() {
              icon="$1"
              name="$2"
              if [ -n "$icon" ]; then
                printf '%s %s\n' "$icon" "$name"
              else
                printf '%s\n' "$name"
              fi
            }

            sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | awk '
              index($0, " ") == 2 { print substr($0, 3) "|" $0; next }
              { print $0 "|" $0 }
            ' | sort | cut -d'|' -f2-)

            result=$(echo "$sessions" | \
              fzf --prompt="Session: " \
                  --preview='tmux list-windows -t {} -F "#{window_index}: #{window_name}"' \
                  --preview-window=right:20% \
                  --expect=ctrl-q,ctrl-t,ctrl-r \
                  --no-select-1 \
                  --header='Enter: switch | ^Q: kill | ^T: new | ^R: rename')

            if [ -z "$result" ]; then
              exit 0
            fi

            key=$(echo "$result" | sed -n '1p')
            session=$(echo "$result" | sed -n '2p')

            case "$key" in
              ctrl-q)
                if [ -n "$session" ]; then
                  echo -n "Kill session '$session'? (y/N): "
                  read -r answer
                  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                    current_session=$(tmux display-message -p '#S')
                    if [ "$session" = "$current_session" ]; then
                      tmux switch-client -n
                    fi
                    tmux kill-session -t "$session"
                    echo "Session '$session' killed."
                  else
                    echo "Cancelled."
                  fi
                fi
                ;;

              ctrl-t)
                echo -n "New session name: "
                read -r new_session
                if [ -n "$new_session" ]; then
                  icon=$(select_icon)
                  full_session_name=$(format_session_name "$icon" "$new_session")
                  tmux new-session -d -s "$full_session_name"
                  tmux switch-client -t "$full_session_name"
                  echo "Session '$full_session_name' created."
                else
                  echo "Cancelled."
                fi
                ;;

              ctrl-r)
                if [ -n "$session" ]; then
                  echo -n "New name for '$session': "
                  read -r new_name
                  if [ -n "$new_name" ]; then
                    icon=$(select_icon)
                    full_session_name=$(format_session_name "$icon" "$new_name")
                    tmux rename-session -t "$session" "$full_session_name"
                    echo "Session renamed to '$full_session_name'."
                  else
                    echo "Cancelled."
                  fi
                fi
                ;;

              *)
                if [ -n "$session" ]; then
                  tmux switch-client -t "$session"
                fi
                ;;
      esac
    '';
  };

  tmux-wsl-copy = pkgs.writeShellApplication {
    name = "tmux-wsl-copy";
    runtimeInputs = [
      iconvPackage
    ];
    text = ''
      iconv -f UTF-8 -t UTF-16LE | /mnt/c/Windows/System32/clip.exe
    '';
  };

  tmux-wsl-paste = pkgs.writeShellApplication {
    name = "tmux-wsl-paste";
    text = ''
      /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe \
        -NoLogo \
        -NoProfile \
        -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; \$OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::Out.Write((Get-Clipboard -Raw))"
    '';
  };

  codex-wsl-clipboard-image = pkgs.writeShellApplication {
    name = "codex-wsl-clipboard-image";
    runtimeInputs = with pkgs; [
      coreutils
    ];
    text = ''
      set -euo pipefail

      powershell=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
      if [ ! -x "$powershell" ]; then
        echo "Windows PowerShell was not found at $powershell" >&2
        exit 1
      fi

      tmp_ps="$(mktemp "''${TMPDIR:-/tmp}/codex-wsl-clipboard-image.XXXXXX.ps1")"
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

      ps_file="$(/sbin/wslpath -w "$tmp_ps")"
      win_path="$("$powershell" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "$ps_file" | tr -d '\r')"
      if [ -z "$win_path" ]; then
        echo "Windows clipboard image export produced no path." >&2
        exit 1
      fi

      /sbin/wslpath -u "$win_path"
    '';
  };

  codex-wsl-paste-image = pkgs.writeShellApplication {
    name = "codex-wsl-paste-image";
    runtimeInputs = [
      codex-wsl-clipboard-image
      pkgs.tmux
    ];
    text = ''
      set -euo pipefail

      image_path="$(codex-wsl-clipboard-image)"
      if [ -n "''${TMUX:-}" ]; then
        printf '%s' "$image_path" | tmux load-buffer -
        tmux paste-buffer
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
{
  home.packages = [
    tmux-session-manager
  ]
  ++ lib.optionals isWSL [
    codex-wsl-clipboard-image
    codex-wsl-paste-image
  ];

  programs.tmux = {
    enable = true;
    clock24 = true;
    escapeTime = 10;
    focusEvents = true;
    keyMode = "vi";
    mouse = true;
    prefix = "M-b";
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";

    extraConfig = ''
      bind-key M-b send-prefix

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind '"' split-window -v -c "#{pane_current_path}"
      bind '%' split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      set -g set-clipboard on
      set -g allow-passthrough on

      ${lib.optionalString isWSL ''
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${tmux-wsl-copy}/bin/tmux-wsl-copy"
        bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${tmux-wsl-copy}/bin/tmux-wsl-copy"
        bind-key p run-shell "${tmux-wsl-paste}/bin/tmux-wsl-paste | tmux load-buffer - && tmux paste-buffer"
        bind-key I run-shell "${codex-wsl-paste-image}/bin/codex-wsl-paste-image"
      ''}

      set -g update-environment 'DISPLAY WAYLAND_DISPLAY COLORTERM SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY PATH WSL_INTEROP'

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"

      set-option -g automatic-rename on
      set-option -g automatic-rename-format "#{b:pane_current_path}"

      bind-key o choose-tree -w "join-pane -t '%%'"

      set -g status on
      set -g status-interval 5
      set -g status-left-length 70
      set -g status-right-length 140
      set -g status-justify left
      set -g status-position bottom
      set -g status-style "bg=${palette.soil},fg=${palette.sand}"
      set -g status-left "#[fg=${palette.soil},bg=${palette.moss},bold] #S #[fg=${palette.moss},bg=${palette.bark}]#[fg=${palette.sand},bg=${palette.bark}] #{session_windows}w #[fg=${palette.ochre}]#{?client_prefix,PREFIX,}#[fg=${palette.sand}] #[fg=${palette.bark},bg=${palette.soil}]"
      set -g status-right "#[fg=${palette.muted},bg=${palette.soil}] #{?window_zoomed_flag,zoom ,}#{?pane_in_mode,copy ,}#[fg=${palette.soil},bg=${palette.bark}]#[fg=${palette.sand},bg=${palette.bark}] #{pane_current_command} #[fg=${palette.muted}]#{b:pane_current_path} #[fg=${palette.bark},bg=${palette.olive}]#[fg=${palette.soil},bg=${palette.olive},bold] #{pane_index}/#{window_panes} #[fg=${palette.olive},bg=${palette.teal}]#[fg=${palette.soil},bg=${palette.teal},bold] #H #[fg=${palette.teal},bg=${palette.ochre}]#[fg=${palette.soil},bg=${palette.ochre},bold] %a %m/%d %H:%M "

      set-window-option -g window-status-separator ""
      set-window-option -g window-status-style "fg=${palette.muted},bg=${palette.soil}"
      set-window-option -g window-status-format "#[fg=${palette.muted},bg=${palette.soil}] #I:#W#{window_flags} "
      set-window-option -g window-status-current-style "fg=${palette.soil},bg=${palette.olive},bold"
      set-window-option -g window-status-current-format "#[fg=${palette.soil},bg=${palette.olive},bold] #I:#W#{window_flags} #[fg=${palette.olive},bg=${palette.soil}]"
      set-window-option -g window-status-activity-style "fg=${palette.ochre},bg=${palette.soil},bold"
      set-window-option -g window-status-bell-style "fg=${palette.sand},bg=${palette.clay},bold"

      set -g pane-border-style "fg=${palette.bark}"
      set -g pane-active-border-style "fg=${palette.moss}"
      set -g display-panes-colour "${palette.ochre}"
      set -g display-panes-active-colour "${palette.moss}"
      set -g message-style "fg=${palette.sand},bg=${palette.bark}"
      set -g message-command-style "fg=${palette.sand},bg=${palette.bark}"
      set-window-option -g mode-style "bg=${palette.olive},fg=${palette.charcoal}"
      set-window-option -g copy-mode-selection-style "bg=${palette.olive},fg=${palette.charcoal}"
      set-window-option -g copy-mode-position-style "bg=${palette.ochre},fg=${palette.charcoal}"
      set -g popup-style "fg=${palette.sand},bg=${palette.soil}"
      set -g popup-border-style "fg=${palette.moss}"
      set -g menu-style "fg=${palette.sand},bg=${palette.soil}"
      set -g menu-selected-style "fg=${palette.charcoal},bg=${palette.ochre},bold"
      set -g clock-mode-colour "${palette.ochre}"

      set-option -sa terminal-overrides ",xterm*:Tc"

      bind-key m display-popup -E -w 80% -h 80% "${tmux-session-manager}/bin/tmux-session-manager"
    '';
  };
}
