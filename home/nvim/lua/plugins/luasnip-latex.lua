return {
	{
		"iurimateus/luasnip-latex-snippets.nvim",
		ft = { "bib", "plaintex", "tex" },
		dependencies = {
			"L3MON4D3/LuaSnip",
			"lervag/vimtex",
		},
		config = function()
			require("luasnip-latex-snippets").setup({
				allow_on_markdown = false,
				use_treesitter = false,
			})
		end,
	},
}
