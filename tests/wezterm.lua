-- Exercise mode transitions without a GUI; show-keys also validates the real API.
local events = {}
local action = { PopKeyTable = { kind = "PopKeyTable" } }
for _, name in ipairs({ "SendString", "SendKey", "Multiple", "ActivateKeyTable" }) do
  action[name] = function(value)
    return { kind = name, value = value }
  end
end
package.preload.wezterm = function()
  return {
    action = action,
    action_callback = function(callback)
      return { kind = "Callback", value = callback }
    end,
    config_builder = function()
      return {}
    end,
    font = function(name)
      return name
    end,
    on = function(name, callback)
      events[name] = callback
    end,
    format = function(parts)
      return parts[#parts].Text
    end,
  }
end
local config = dofile("home/wezterm/wezterm.lua")
local function binding(keys, key, mods)
  for _, item in ipairs(keys) do
    if item.key == key and item.mods == mods then
      return item.action
    end
  end
  error("Missing binding: " .. mods .. " " .. key)
end
assert(config.leader == nil, "A global leader would also capture Ctrl-B outside tmux")
assert(not config.hide_tab_bar_if_only_one_tab)
for _, mods in ipairs({ "CTRL", "ALT", "SHIFT", "CTRL|ALT" }) do
  local resize = binding(config.key_tables.tmux_prefix, "LeftArrow", mods)
  assert(resize.value[1].value == "\x02")
  assert(resize.value[2].value.mods == mods)
end
assert(binding(config.key_tables.tmux_prefix, "mapped:1", "ALT").value[2].value == "\x1b1")
assert(binding(config.key_tables.tmux_prefix, "phys:B", "CTRL").value[2].value == "\x02")
assert(binding(config.key_tables.tmux_copy, "phys:H", "NONE").value == "h")
assert(binding(config.key_tables.tmux_copy, "phys:V", "CTRL").value == "\x16")

local pane = { mode = "off" }
function pane:pane_id()
  return 1
end
function pane:get_user_vars()
  return { TMUX_MODE = self.mode }
end
local window = { tables = {}, sent = "" }
function window:active_pane()
  return pane
end
function window:active_key_table()
  return self.tables[#self.tables]
end
function window:perform_action(item)
  if item.kind == "ActivateKeyTable" then
    table.insert(self.tables, item.value.name)
    self.last_activation = item.value
  elseif item.kind == "PopKeyTable" then
    table.remove(self.tables)
  elseif item.kind == "SendString" then
    self.sent = self.sent .. item.value
  elseif item.kind == "Multiple" then
    for _, child in ipairs(item.value) do
      self:perform_action(child)
    end
  elseif item.kind == "Callback" then
    item.value(self, pane)
  else
    error("Unexpected action " .. item.kind)
  end
end
function window:set_right_status(text)
  self.status = text
end
local function mode(value)
  pane.mode = value
  events["user-var-changed"](window, pane, "TMUX_MODE", value)
end
mode("copy:%1")
assert(window:active_key_table() == "tmux_copy" and window.status == " COPY ")
mode("prompt")
assert(window:active_key_table() == nil and window.status == " SEARCH ")
mode("copy:%1")
assert(window:active_key_table() == "tmux_copy")
-- A background terminal notification must not change the active key table.
local background = {
  pane_id = function()
    return 2
  end,
}
events["user-var-changed"](window, background, "TMUX_MODE", "normal")
assert(window:active_key_table() == "tmux_copy")
mode("normal")
assert(window:active_key_table() == nil and window.status == "")
local prefix = binding(config.keys, "phys:B", "CTRL")
mode("off")
window:perform_action(prefix)
assert(window.sent == "\x02" and window:active_key_table() == nil)
mode("normal")
window:perform_action(prefix)
events["update-status"](window, pane)
assert(window.status == " PREFIX " and window:active_key_table() == "tmux_prefix")
assert(window.last_activation.one_shot and window.last_activation.timeout_milliseconds == 2000)
-- The second Ctrl-B forwards a literal Ctrl-B through tmux.
window:perform_action(action.PopKeyTable)
window.sent = ""
window:perform_action(binding(config.key_tables.tmux_prefix, "phys:B", "CTRL"))
assert(window.sent == "\x02\x02")
-- Prefix can overlay copy mode; detaching cancels both tables.
mode("copy:%1")
window:perform_action(prefix)
assert(#window.tables == 2)
mode("off")
assert(window:active_key_table() == nil and window.status == "")
-- Moving to another WezTerm pane clears copy interception on the next update.
mode("copy:%1")
pane.mode = "normal"
events["update-status"](window, pane)
assert(window:active_key_table() == nil)
print("WezTerm bindings and input mode transitions passed")
