-- Home Manager provides the plugin manager from the locked Nix input.
local lazypath = vim.env.NVIM_LAZY_PATH
if not lazypath or not vim.uv.fs_stat(lazypath) then
  error("Use the Home Manager Neovim wrapper (NVIM_LAZY_PATH is missing).")
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- Updates are explicit; startup should not query GitHub for new versions.
  checker = { enabled = false },
  -- Keep the Nix wrapper's parser and Lua dependency paths when lazy starts.
  performance = { reset_packpath = false, rtp = { reset = false } },
  rocks = { enabled = false },
})
