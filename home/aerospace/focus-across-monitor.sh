#!/bin/bash

# 移動方向を引数で受け取る (left, right, up, down)
DIRECTION=$1

# 1. 移動前のウィンドウIDを記録
PREV_WINDOW_ID=$(aerospace list-windows --focused --format %{window-id})

# 2. 指定方向へのフォーカス移動を試みる
aerospace focus $DIRECTION

# 3. 移動後のウィンドウIDを取得
NEW_WINDOW_ID=$(aerospace list-windows --focused --format %{window-id})

# 4. IDが変わっていなければ（＝端にいて移動できなかった）、モニター移動を実行
if [ "$PREV_WINDOW_ID" == "$NEW_WINDOW_ID" ]; then
    aerospace focus-monitor $DIRECTION
fi
