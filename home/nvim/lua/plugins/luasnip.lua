return {
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		version = "v2.*",
		build = "make install_jsregexp",
		config = function()
			local luasnip = require("luasnip")

			luasnip.config.set_config({
				enable_autosnippets = true,
				history = true,
				updateevents = "TextChanged,TextChangedI",
			})

			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_lua").lazy_load({
				paths = vim.fn.stdpath("config") .. "/lua/snippets",
			})
		end,
		keys = {
			{
				"<C-l>",
				function()
					local luasnip = require("luasnip")
					if luasnip.expand_or_locally_jumpable() then
						luasnip.expand_or_jump()
					end
				end,
				mode = { "i", "s" },
				desc = "Expand or jump snippet",
			},
			{
				"<C-h>",
				function()
					local luasnip = require("luasnip")
					if luasnip.locally_jumpable(-1) then
						luasnip.jump(-1)
					end
				end,
				mode = { "i", "s" },
				desc = "Jump to previous snippet field",
			},
			{
				"<M-e>",
				function()
					local luasnip = require("luasnip")
					if luasnip.choice_active() then
						luasnip.change_choice(1)
					end
				end,
				mode = { "i", "s" },
				desc = "Change snippet choice",
			},
		},
	},
}
