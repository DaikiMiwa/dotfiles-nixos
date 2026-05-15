local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- [window]
-- 初期ウィンドウサイズ
config.initial_cols = 200
config.initial_rows = 60

-- パディング (x=8, y=4 を上下左右に展開)
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 4,
}

-- 透明度 (0.85)
config.window_background_opacity = 0.85

-- 装飾 (Buttonlessに相当する設定)
-- タイトルバーを消し、リサイズ可能な枠線のみ残します
config.window_decorations = "RESIZE"

-- タブが一つのときは隠す設定
config.hide_tab_bar_if_only_one_tab = true

-- [cursor]
-- カーソルスタイル (Beam -> Bar)
-- 点滅させたい場合は 'BlinkingBar'、点滅なしは 'SteadyBar'
config.default_cursor_style = "BlinkingBar"

-- [scrolling]
-- スクロールバックの行数
config.scrollback_lines = 100000
-- ※WezTermには単純なスクロール倍率(multiplier)設定がないため、デフォルト動作となります。

-- [font]
-- フォント設定
config.font = wezterm.font("PlemolJP35 Console NF")

-- フォントサイズ
config.font_size = 14.0

-- [general]
-- macOS + 日本語 IME では、Backspace は未確定文字列を消せる一方で
-- Ctrl-H はそのままだと IME ではなく terminal へ BS(^H) として送られやすい。
-- その結果、変換中の文字列ではなく確定済みの文字が消えることがあるため、
-- Ctrl 修飾付きキーも IME に渡して preedit を削除できるようにしている。
-- 副作用として Ctrl-A / Ctrl-E などの terminal shortcut に影響しうる。
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

-- 設定ファイルの自動リロードはWezTermではデフォルトで有効です
return config
