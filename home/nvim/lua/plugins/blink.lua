return {
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets", -- スニペット集
			"L3MON4D3/LuaSnip", -- スニペットエンジン
		},
		version = "*", -- バイナリをダウンロードする場合
		opts = {
			keymap = {
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-n>"] = { "show", "select_next" },
				["<C-p>"] = { "show", "select_prev" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
			completion = {
				list = {
					selection = {
						preselect = true,
						auto_insert = false,
					},
				},
				menu = {
					auto_show = true,
					border = "single",
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 300,
					window = { border = "single" },
				},
			},
			signature = { window = { border = "single" } },
			cmdline = {
				keymap = {
					["<C-n>"] = { "show", "select_next", "fallback" },
					["<C-p>"] = { "select_prev", "fallback" },
					["<C-y>"] = { "accept", "fallback" },
					["<C-e>"] = { "hide", "fallback" },
				},
			},
			snippets = { preset = "luasnip" },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},
}
