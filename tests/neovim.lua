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
local lazy = require("lazy")
local setup = lazy.setup
lazy.setup = function(opts)
  opts.spec = { dofile("home/nvim/lua/plugins/treesitter.lua")[1] }
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

print("Neovim dependencies, parser, Lua syntax, and textlint boundary checks passed")
