#!/bin/bash

set -eu

case "${1:-}" in
  left|right|up|down) direction="$1" ;;
  *) echo "Usage: $0 <left|right|up|down>" >&2; exit 2 ;;
esac

# 1. 現在のウィンドウIDを取得
orig_id=$(aerospace list-windows --focused --format '%{window-id}')
if [ -z "$orig_id" ]; then
  echo "No focused window to move." >&2
  exit 1
fi

# 2. 指定方向にフォーカスしてみる（隣があるかチェック）
aerospace focus "$direction" || true

# 3. 移動後のウィンドウIDを取得
new_id=$(aerospace list-windows --focused --format '%{window-id}')

# 4. 判定ロジック
if [ "$orig_id" != "$new_id" ]; then
    # 【ケースA: 隣にウィンドウがあった】
    # フォーカスが移動してしまったので、元のウィンドウにフォーカスを戻す
  aerospace focus --window-id "$orig_id"

    # モニター内での移動 (Swap) を実行
  exec aerospace move "$direction"
else
    # 【ケースB: 隣にウィンドウがなかった（端にいる）】
    # モニターを超えてウィンドウを移動させる
  exec aerospace move-node-to-monitor "$direction" --focus-follows-window
fi
