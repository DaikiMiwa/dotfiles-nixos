return {
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPost", "BufNewFile" },
		cmd = {
			"TodoQuickFix",
			"TodoLocList",
			"TodoTrouble",
		},
		opts = {},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo comment",
			},
			{
				"<leader>ft",
				"<cmd>TodoQuickFix<cr>",
				desc = "Find todo comments",
			},
			{
				"<leader>xT",
				"<cmd>TodoTrouble<cr>",
				desc = "Todo comments (Trouble)",
			},
		},
	},
}
