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
assert(config.leader.key == "phys:B" and config.leader.mods == "CTRL")
assert(not config.hide_tab_bar_if_only_one_tab)
for _, mods in ipairs({ "CTRL", "ALT", "SHIFT", "CTRL|ALT" }) do
  local resize = binding(config.keys, "LeftArrow", "LEADER|" .. mods)
  assert(resize.value[1].value == "\x02")
  assert(resize.value[2].value.mods == mods)
end
assert(binding(config.keys, "mapped:1", "LEADER|ALT").value[2].value == "\x1b1")
assert(binding(config.keys, "phys:B", "LEADER|CTRL").value[2].value == "\x02")
assert(binding(config.key_tables.tmux_copy, "phys:H", "NONE").value == "h")
assert(binding(config.key_tables.tmux_copy, "phys:V", "CTRL").value == "\x16")

local pane = { mode = "normal" }
function pane:pane_id()
  return 1
end
function pane:get_user_vars()
  return { TMUX_MODE = self.mode }
end
local window = { leader = false }
function window:active_pane()
  return pane
end
function window:active_key_table()
  return self.key_table
end
function window:perform_action(item)
  if item.kind == "ActivateKeyTable" then
    self.key_table = item.value.name
  elseif item.kind == "PopKeyTable" then
    self.key_table = nil
  else
    error("Unexpected action " .. item.kind)
  end
end
function window:leader_is_active()
  return self.leader
end
function window:set_right_status(text)
  self.status = text
end
local function mode(value)
  pane.mode = value
  events["user-var-changed"](window, pane, "TMUX_MODE", value)
end
mode("copy:%1")
assert(window.key_table == "tmux_copy" and window.status == " COPY ")
mode("prompt")
assert(window.key_table == nil and window.status == " SEARCH ")
mode("copy:%1")
assert(window.key_table == "tmux_copy")
-- A background terminal notification must not change the active key table.
local background = {
  pane_id = function()
    return 2
  end,
}
events["user-var-changed"](window, background, "TMUX_MODE", "normal")
assert(window.key_table == "tmux_copy")
mode("normal")
assert(window.key_table == nil and window.status == "")
window.leader = true
events["update-status"](window, pane)
assert(window.status == " PREFIX ")
window.leader = false
events["update-status"](window, pane)
assert(window.status == "")
-- Moving to another WezTerm pane clears copy interception on the next update.
mode("copy:%1")
pane.mode = "normal"
events["update-status"](window, pane)
assert(window.key_table == nil)
print("WezTerm bindings and input mode transitions passed")
