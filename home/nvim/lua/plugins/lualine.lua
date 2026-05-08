return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "SmiteshP/nvim-navic" },
		lazy = false,
		config = function()
			require("lualine").setup({
				options = {
					globalstatus = true,
				},
				winbar = {
					lualine_c = {
						{
							"navic",
							color_correction = "static",
							navic_opts = nil,
						},
					},
				},
				inactive_winbar = {
					lualine_c = { "filename" },
				},
			})
		end,
	},
}
