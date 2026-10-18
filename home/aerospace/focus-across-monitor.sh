#!/bin/bash

set -eu

case "${1:-}" in
  left|right|up|down) direction="$1" ;;
  *) echo "Usage: $0 <left|right|up|down>" >&2; exit 2 ;;
esac

# 1. 移動前のウィンドウIDを記録
prev_window_id=$(aerospace list-windows --focused --format '%{window-id}')
if [ -z "$prev_window_id" ]; then
  exec aerospace focus-monitor "$direction"
fi

# 2. 指定方向へのフォーカス移動を試みる
aerospace focus "$direction" || true

# 3. 移動後のウィンドウIDを取得
new_window_id=$(aerospace list-windows --focused --format '%{window-id}')

# 4. IDが変わっていなければ（＝端にいて移動できなかった）、モニター移動を実行
if [ "$prev_window_id" = "$new_window_id" ]; then
  exec aerospace focus-monitor "$direction"
fi
