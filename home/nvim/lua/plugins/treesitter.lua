return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		lazy = false,
		build = ":TSUpdate",
		opts = {
			-- LazyVim config for treesitter
			indent = { enable = true }, ---@type lazyvim.TSFeat
			highlight = { enable = true }, ---@type lazyvim.TSFeat
			folds = { enable = true }, ---@type lazyvim.TSFeat
			ensure_installed = {
				"astro",
				"bash",
				"c",
				"css",
				"diff",
				"html",
				"javascript",
				"jsdoc",
				"json",
				"jsonc",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"scss",
				"printf",
				"python",
				"query",
				"regex",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},
		},
	},
}
