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

-- PREFIX / COPY / SEARCH を常に確認できるよう、1 タブでも表示する。
config.hide_tab_bar_if_only_one_tab = false

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

-- tmux 接続中だけ prefix 待機に入り、次のキーも IME より先に処理する。
-- 未接続・デタッチ後は Ctrl-B をそのままアプリに渡す。
local function tmux_connected(mode)
  return mode == "normal" or mode == "prompt" or (mode or ""):match("^copy:") ~= nil
end
local prefix = wezterm.action_callback(function(window, pane)
  if tmux_connected(pane:get_user_vars().TMUX_MODE) then
    window:perform_action(
      wezterm.action.ActivateKeyTable({
        name = "tmux_prefix",
        one_shot = true,
        timeout_milliseconds = 2000,
      }),
      pane
    )
  else
    window:perform_action(wezterm.action.SendString("\x02"), pane)
  end
end)
config.keys = { { key = "phys:B", mods = "CTRL", action = prefix } }
config.key_tables = { tmux_prefix = {}, tmux_copy = {} }
config.status_update_interval = 100

-- prefix の後と、tmux コピーモード内で同じキー集合を扱う。
local function forward(key, mods, action)
  local leader_action = wezterm.action.Multiple({ wezterm.action.SendString("\x02"), action })
  table.insert(config.key_tables.tmux_prefix, { key = key, mods = mods, action = leader_action })
  -- Prefix handling must also work while the copy table is active.
  if not (key == "phys:B" and mods == "CTRL") then
    table.insert(config.key_tables.tmux_copy, { key = key, mods = mods, action = action })
  end
end

local function text_key(key, mods, text)
  forward(key, mods, wezterm.action.SendString(text))
end

-- 英字は物理キーで捕まえる。Ctrl / Alt の組み合わせも tmux に転送する。
for code = string.byte("a"), string.byte("z") do
  local letter = string.char(code)
  local physical = "phys:" .. letter:upper()
  for _, shift in ipairs({ false, true }) do
    local text = shift and letter:upper() or letter
    local mods = shift and "SHIFT" or "NONE"
    text_key(physical, mods, text)
    text_key(physical, shift and "SHIFT|CTRL" or "CTRL", string.char(code - 96))
    text_key(physical, shift and "SHIFT|ALT" or "ALT", "\x1b" .. text)
    text_key(physical, shift and "SHIFT|CTRL|ALT" or "CTRL|ALT", "\x1b" .. string.char(code - 96))
  end
end

-- 数字・記号の Shift の要否はキーボード配列により異なる。
for code = 32, 126 do
  local char = string.char(code)
  if not char:match("%a") then
    for _, mods in ipairs({ "NONE", "SHIFT" }) do
      text_key("mapped:" .. char, mods, char)
      text_key("mapped:" .. char, mods == "NONE" and "ALT" or "SHIFT|ALT", "\x1b" .. char)
    end
  end
end
for char, code in pairs({ [" "] = 0, ["["] = 27, ["\\"] = 28, ["]"] = 29, ["^"] = 30, ["_"] = 31, ["?"] = 127 }) do
  text_key("mapped:" .. char, "CTRL", string.char(code))
  text_key("mapped:" .. char, "CTRL|SHIFT", string.char(code))
end

local special_keys = {
  "Enter",
  "Escape",
  "Tab",
  "Backspace",
  "UpArrow",
  "DownArrow",
  "LeftArrow",
  "RightArrow",
  "PageUp",
  "PageDown",
  "Home",
  "End",
  "Insert",
  "Delete",
}
for number = 1, 12 do
  table.insert(special_keys, "F" .. number)
end
for _, key in ipairs(special_keys) do
  for _, mods in ipairs({ "NONE", "CTRL", "ALT", "SHIFT", "CTRL|ALT", "CTRL|SHIFT", "ALT|SHIFT", "CTRL|ALT|SHIFT" }) do
    forward(key, mods, wezterm.action.SendKey({ key = key, mods = mods }))
  end
end

-- tmux は mode/pane/window/session の変更を OSC 1337 で通知する。
-- COPY の間だけ英字を IME より先に処理し、検索欄と通常入力は IME に任せる。
local function sync_tmux_mode(window, pane, mode)
  mode = mode or pane:get_user_vars().TMUX_MODE or "off"
  local active = window:active_key_table()
  if not tmux_connected(mode) and active == "tmux_prefix" then
    window:perform_action(wezterm.action.PopKeyTable, pane)
    active = window:active_key_table()
  end
  if mode:match("^copy:") then
    if active == nil then
      window:perform_action(wezterm.action.ActivateKeyTable({ name = "tmux_copy", one_shot = false }), pane)
    end
  elseif active == "tmux_copy" then
    window:perform_action(wezterm.action.PopKeyTable, pane)
  end

  local label = ""
  if window:active_key_table() == "tmux_prefix" then
    label = " PREFIX "
  elseif window:active_key_table() == "tmux_copy" then
    label = " COPY "
  elseif mode == "prompt" then
    label = " SEARCH "
  end
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#17150F" } },
    { Background = { Color = "#8A9A5B" } },
    { Text = label },
  }))
end

wezterm.on("update-status", sync_tmux_mode)
wezterm.on("user-var-changed", function(window, pane, name, value)
  if name == "TMUX_MODE" and pane:pane_id() == window:active_pane():pane_id() then
    sync_tmux_mode(window, pane, value)
  end
end)

-- 設定ファイルの自動リロードはWezTermではデフォルトで有効です
return config
