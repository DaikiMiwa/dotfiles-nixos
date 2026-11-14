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
assert(vim.fn.maparg("?", "n") == "", "Backward search must retain its native binding")
assert(vim.fn.maparg("<C-k>", "i") == "", "Ctrl-K must retain native digraph input")
assert(vim.fn.maparg("<leader>sq", "n") ~= "", "Search-to-quickfix must remain available")
local snippets = dofile("home/nvim/lua/plugins/luasnip.lua")[1]
local copilot = dofile("home/nvim/lua/plugins/copilot.lua")[1]
assert(copilot.opts.suggestion.keymap.accept ~= snippets.keys[1][1], "Copilot shadows snippet expansion")

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
