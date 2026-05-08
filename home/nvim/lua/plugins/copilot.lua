return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = {
				auto_trigger = true,
				hide_during_completion = false,
				keymap = {
					accept = "<C-l>",
					accept_word = false,
					accept_line = false,
					dismiss = "<C-e>",
				},
			},
			filetypes = {
				markdown = true,
				gitcommit = true,
			},
		},
	},
}
