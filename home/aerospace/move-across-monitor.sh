#!/bin/bash

# 方向を受け取る (left, right, up, down)
DIRECTION=$1

# 1. 現在のウィンドウIDを取得
ORIG_ID=$(aerospace list-windows --focused --format %{window-id})

# 2. 指定方向にフォーカスしてみる（隣があるかチェック）
aerospace focus $DIRECTION

# 3. 移動後のウィンドウIDを取得
NEW_ID=$(aerospace list-windows --focused --format %{window-id})

# 4. 判定ロジック
if [ "$ORIG_ID" != "$NEW_ID" ]; then
    # 【ケースA: 隣にウィンドウがあった】
    # フォーカスが移動してしまったので、元のウィンドウにフォーカスを戻す
    aerospace focus --window-id $ORIG_ID

    # モニター内での移動 (Swap) を実行
    aerospace move $DIRECTION
else
    # 【ケースB: 隣にウィンドウがなかった（端にいる）】
    # モニターを超えてウィンドウを移動させる
    aerospace move-node-to-monitor $DIRECTION --focus-follows-window
fi
