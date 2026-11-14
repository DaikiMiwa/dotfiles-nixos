# shellcheck shell=bash
# Keep ccmux visible by default, while respecting an explicit toggle-off for
# this tmux server. Serialize attach/reload hooks so they cannot toggle it off.
command -v ccmux >/dev/null 2>&1 || exit 0
tmux wait-for -L dotfiles-agent-sidebar
trap 'tmux wait-for -U dotfiles-agent-sidebar 2>/dev/null || true' EXIT

case "${1:---ensure}" in
  --toggle)
    ccmux sidebar --toggle --position left --width 36
    if tmux list-panes -a -F '#{pane_title}' | grep -qx ccmux-sidebar; then
      tmux set-option -g @dotfiles-agent-sidebar 1
    else
      tmux set-option -g @dotfiles-agent-sidebar 0
    fi
    ;;
  --ensure)
    [ "$(tmux show-option -gqv @dotfiles-agent-sidebar)" != 0 ] || exit 0
    missing=$(tmux list-panes -a -F '#{window_id} #{pane_title}' | awk '
      { windows[$1] = 1; if ($2 == "ccmux-sidebar") sidebars[$1] = 1 }
      END { for (w in windows) if (!(w in sidebars)) print w }
    ')
    # ccmux's smart toggle fills missing windows, but closes the entire rail
    # when no windows are missing. Never call it in that second case here.
    [ -n "$missing" ] || exit 0
    ccmux sidebar --toggle --position left --width 36
    ;;
  *) echo 'Usage: tmux-agent-sidebar [--ensure|--toggle]' >&2; exit 2 ;;
esac
