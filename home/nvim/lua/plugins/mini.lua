return {
	{
		"nvim-mini/mini.ai",
		opts = {
			n_lines = 500,
		},
	},
	{
		"nvim-mini/mini.surround",
		opts = {},
	},
	{
		"nvim-mini/mini.pairs",
		opts = {},
	},
	{
		"nvim-mini/mini.comment",
		opts = {},
	},
	{
		"nvim-mini/mini.move",
		opts = {},
	},
	{
		"nvim-mini/mini.bufremove",
		keys = {
			{
				"<leader>bd",
				function()
					require("mini.bufremove").delete(0, false)
				end,
				desc = "Delete buffer",
			},
			{
				"<leader>bD",
				function()
					require("mini.bufremove").delete(0, true)
				end,
				desc = "Force delete buffer",
			},
		},
		opts = {},
	},
}
