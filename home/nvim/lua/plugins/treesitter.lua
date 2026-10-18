return {
  {
    "nvim-treesitter/nvim-treesitter",
    dir = vim.env.NVIM_TREESITTER_PATH,
    lazy = false,
    main = "nvim-treesitter.configs",
    opts = {
      indent = { enable = true },
      highlight = { enable = true },
      -- Parsers and queries are supplied together by Nix.
      ensure_installed = {},
      auto_install = false,
    },
  },
}
