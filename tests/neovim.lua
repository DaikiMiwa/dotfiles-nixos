-- Runs without a user's configuration, credentials, or network plugin install.
for _, path in ipairs(vim.fn.glob("home/**/*.lua", false, true)) do
  assert(loadfile(path), "Invalid Lua syntax: " .. path)
end

assert(vim.env.NVIM_LAZY_PATH, "Missing Home Manager wrapper")
assert(require("lazy"), "Nix lazy.nvim is unavailable")
assert(require("nvim-treesitter.configs"), "Nix Treesitter is unavailable")
assert(require("luasnip"), "Nix LuaSnip is unavailable")
assert(
  require("lazy.manage.task.plugin").docs.skip({
    dir = vim.env.NVIM_LUASNIP_PATH,
    _ = { is_local = true, dirty = false },
  }),
  "Lazy restore must not write helptags to the Nix store"
)
-- Run the real lazy configuration with only local Nix plugins: CI needs no GitHub access.
-- -u NONE disables loadplugins; lazy.setup otherwise silently skips its handlers.
vim.opt.loadplugins = true
local lazy = require("lazy")
local setup = lazy.setup
lazy.setup = function(opts)
  local conform = dofile("home/nvim/lua/plugins/conform.lua")[1]
  -- Exercise the real lazy events and save hook without a network install.
  conform.dir = assert(vim.env.NVIM_CONFORM_TEST_PATH, "Missing Nix Conform fixture")
  opts.spec = { dofile("home/nvim/lua/plugins/treesitter.lua")[1], conform }
  opts.install.missing = false
  opts.lockfile = vim.fn.stdpath("state") .. "/test-lazy-lock.json"
  setup(opts)
end
dofile("home/nvim/lua/config/lazy.lua")
lazy.setup = setup
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local answer = 42" })
assert(vim.treesitter.get_parser(0, "lua"):parse()[1], "Nix Lua parser is unavailable")
assert(vim.treesitter.query.get("lua", "highlights"), "Nix parser queries are invalid")

local formatter = dofile("home/nvim/lua/plugins/conform.lua")[1].opts.formatters.textlint
local format_on_save = dofile("home/nvim/lua/plugins/conform.lua")[1].opts.format_on_save
assert(format_on_save(0), "Formatting must be enabled by default")
vim.b.disable_autoformat = true
assert(not format_on_save(0), "Buffer toggle must disable formatting")
vim.b.disable_autoformat = nil
local base = vim.fn.tempname()
local project = base .. "/project"
local nested = project .. "/docs"
vim.fn.mkdir(nested, "p")
vim.fn.writefile({ "{}" }, project .. "/package.json")
vim.fn.writefile({ "{}" }, base .. "/.textlintrc.json")
vim.fn.mkdir(project .. "/.git")
local ctx = { filename = nested .. "/note.md" }
assert(not formatter.condition(nil, ctx), "package.json and outer config must not enable textlint")
vim.fn.writefile({ "{}" }, project .. "/.textlintrc.json")
assert(formatter.condition(nil, ctx), "Project config must enable textlint")
assert(formatter.cwd(nil, ctx) == project, "textlint must use the project config directory")
vim.fn.mkdir(nested .. "/.git")
assert(not formatter.condition(nil, ctx), "Nested Git checkout must not inherit parent config")
vim.fn.writefile({ "rules: {}" }, nested .. "/.textlintrc.yaml")
assert(formatter.cwd(nil, ctx) == nested, "Nearest project config must win")
assert(not vim.tbl_contains(formatter.args, "--config"), "Personal config must not be forced")
vim.fn.delete(base, "rf")

-- Resizing all tabs must preserve the user's current tab and window.
dofile("home/nvim/lua/config/autocmds.lua")
vim.cmd("tabnew")
vim.cmd("tabfirst")
vim.cmd("vsplit")
local original_window = vim.api.nvim_get_current_win()
vim.api.nvim_exec_autocmds("VimResized", {})
assert(vim.api.nvim_get_current_win() == original_window, "Resize changed the active tab/window")

dofile("home/nvim/lua/config/set.lua")
vim.bo.filetype = "markdown"
assert(vim.wo.wrap and vim.wo.linebreak, "Markdown should wrap at word boundaries")
assert(vim.fn.maparg("j", "n") ~= "", "Markdown should navigate display lines")
assert(vim.fn.maparg("?", "n") == "", "Backward search must retain its native binding")
assert(vim.fn.maparg("<C-k>", "i") == "", "Ctrl-K must retain native digraph input")
assert(vim.fn.maparg("<leader>sq", "n") ~= "", "Search-to-quickfix must remain available")
local snippets = dofile("home/nvim/lua/plugins/luasnip.lua")[1]
local copilot = dofile("home/nvim/lua/plugins/copilot.lua")[1]
assert(copilot.opts.suggestion.keymap.accept ~= snippets.keys[1][1], "Copilot shadows snippet expansion")

local previous_field
for _, key in ipairs(snippets.keys) do
  if key[1] == "<C-h>" then
    previous_field = key[2]
    vim.keymap.set(key.mode, key[1], key[2])
  end
end
assert(previous_field, "Missing snippet previous-field key")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ab" })
-- Esc is already queued: the fallback must delete before Esc, without recursion.
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("A<C-h><Esc>", true, false, true), "xt", false)
assert(vim.api.nvim_get_current_line() == "a", "Ctrl-H outside snippets must delete one character")
local luasnip = require("luasnip")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
luasnip.snip_expand(luasnip.snippet("", {
  luasnip.insert_node(1, "one"),
  luasnip.text_node(" "),
  luasnip.insert_node(2, "two"),
}))
luasnip.jump(1)
assert(luasnip.session.current_nodes[vim.api.nvim_get_current_buf()].pos == 2)
previous_field()
assert(luasnip.session.current_nodes[vim.api.nvim_get_current_buf()].pos == 1, "Ctrl-H must keep snippet navigation")
luasnip.unlink_current()
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

local enabled
local enable = vim.lsp.enable
vim.lsp.enable = function(servers)
  enabled = servers
end
dofile("home/nvim/lua/config/lsp.lua")
vim.lsp.enable = enable
assert(vim.tbl_contains(enabled, "nil_ls"), "Nix LSP is not enabled")
assert(vim.tbl_contains(enabled, "bashls"), "Bash LSP is not enabled")
assert(vim.tbl_contains(enabled, "ruff"), "Ruff LSP must provide Python lint diagnostics")
assert(vim.lsp.config.texlab.settings.texlab.chktex.onOpenAndSave, "texlab must run ChkTeX")

local python_project = vim.fn.tempname()
vim.fn.mkdir(python_project, "p")
vim.fn.mkdir(python_project .. "/.git")
vim.fn.writefile({ "[project]" }, python_project .. "/pyproject.toml")
local function python_servers(file)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, file)
  local decisions = {}
  for _, server in ipairs({ "basedpyright", "pyrefly" }) do
    vim.lsp.config[server].root_dir(buf, function(root)
      decisions[server] = { root = root }
    end)
  end
  vim.api.nvim_buf_delete(buf, { force = true })
  return decisions
end
local defaults = python_servers(python_project .. "/main.py")
assert(defaults.basedpyright and not defaults.pyrefly, "Python must default to Basedpyright only")
assert(defaults.basedpyright.root == python_project)
vim.fn.writefile({ "" }, python_project .. "/pyrefly.toml")
local opt_in = python_servers(python_project .. "/main.py")
assert(opt_in.pyrefly and not opt_in.basedpyright, "Pyrefly opt-in must replace Basedpyright")
assert(opt_in.pyrefly.root == python_project)
local checkout = python_project .. "/child"
vim.fn.mkdir(checkout, "p")
vim.fn.writefile({ "gitdir: elsewhere" }, checkout .. "/.git")
local child = python_servers(checkout .. "/main.py")
assert(child.basedpyright and not child.pyrefly, "A nested checkout must not inherit the parent's Pyrefly config")
vim.fn.writefile({ "" }, checkout .. "/pyrefly.toml")
local child_opt_in = python_servers(checkout .. "/main.py")
assert(child_opt_in.pyrefly and not child_opt_in.basedpyright)
assert(child_opt_in.pyrefly.root == checkout)
vim.fn.delete(python_project, "rf")

local format_file = vim.fn.tempname() .. ".nix"
vim.fn.writefile({ "{a=1;}" }, format_file)
vim.cmd("edit! " .. vim.fn.fnameescape(format_file))
vim.bo.filetype = "nix"
-- Do not require Conform or call manual formatting first: the first write must
-- load it via the file event and run the save hook on its own.
vim.cmd("write")
assert(vim.fn.readfile(format_file)[1] ~= "{a=1;}", "First save did not format the Nix file")
vim.fn.delete(format_file)

-- Lint events must not invoke a second Ruff/ChkTeX alongside the LSP route.
local requested
package.loaded.lint = {
  try_lint = function(linters)
    requested = linters
  end,
}
dofile("home/nvim/lua/plugins/lint.lua")[1].config()
for _, ft in ipairs({ "python", "tex", "plaintex" }) do
  vim.bo.filetype = ft
  requested = nil
  vim.api.nvim_exec_autocmds("InsertLeave", {})
  assert(requested and #requested == 0, "Duplicate CLI lint for " .. ft)
end

print("Neovim dependencies, editing behavior, LSP/lint routing and formatter checks passed")
