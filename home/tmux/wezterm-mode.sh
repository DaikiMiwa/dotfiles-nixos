# shellcheck shell=bash
# Notify each outer terminal about its client's active tmux pane. Writing to the
# client tty bypasses tmux's pane renderer, including while copy mode is active.
notify() {
  local tty="$1" mode="$2" encoded
  case "$tty" in
    /dev/*) ;;
    *) return ;;
  esac
  [ -c "$tty" ] && [ -w "$tty" ] || return 0
  encoded=$(printf '%s' "$mode" | base64 | tr -d '\n')
  printf '\033]1337;SetUserVar=TMUX_MODE=%s\007' "$encoded" >"$tty" || true
}

case "${1:-}" in
  --prompt-start) tmux set-option -g "@wezterm-prompt-$2" 1 ;;
  --prompt-end) tmux set-option -gu "@wezterm-prompt-$2" ;;
  --clear)
    notify "$2" normal
    tmux set-option -gu "@wezterm-prompt-$2" 2>/dev/null || true
    exit 0
    ;;
esac

clients=$(tmux list-clients -F '#{client_tty} #{?pane_in_mode,#{pane_mode},normal} #{pane_id}' 2>/dev/null) || exit 0
while read -r tty mode pane; do
  [ -n "$tty" ] || continue
  if [ "$(tmux show-option -gqv "@wezterm-prompt-$tty")" = 1 ]; then
    notify "$tty" prompt
  elif [ "$mode" = copy-mode ]; then
    notify "$tty" "copy:$pane"
  else
    notify "$tty" normal
  fi
done <<<"$clients"
