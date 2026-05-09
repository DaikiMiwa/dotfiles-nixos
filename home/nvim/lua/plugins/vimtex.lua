return {
	{
		"lervag/vimtex",
		ft = { "bib", "plaintex", "tex" },
		init = function()
			local platex_engine =
				"-pdfdvi -latex='platex -synctex=1 -interaction=nonstopmode -file-line-error %O %S' -bibtex='pbibtex %O %B' -dvipdf='dvipdfmx %O -o %D %S'"
			local uplatex_engine =
				"-pdfdvi -latex='uplatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S' -bibtex='upbibtex %O %B' -dvipdf='dvipdfmx %O -o %D %S'"
			local skim_displayline = "/Applications/Skim.app/Contents/SharedSupport/displayline"

			vim.g.tex_flavor = "latex"
			vim.g.vimtex_quickfix_mode = 0
			vim.g.vimtex_quickfix_open_on_warning = 0
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_compiler_latexmk = {
				build_dir = "build",
				callback = 1,
				continuous = 1,
				executable = "latexmk",
				options = {
					"-file-line-error",
					"-interaction=nonstopmode",
					"-synctex=1",
					"-verbose",
				},
			}
			vim.g.vimtex_compiler_latexmk_engines = {
				_ = "-pdf",
				pdflatex = "-pdf",
				lualatex = "-lualatex",
				platex = platex_engine,
				uplatex = uplatex_engine,
			}

			if vim.fn.executable(skim_displayline) == 1 then
				vim.g.vimtex_view_method = "skim"
			elseif vim.fn.executable("zathura") == 1 then
				vim.g.vimtex_view_method = "zathura"
			else
				vim.g.vimtex_view_method = "general"
				vim.g.vimtex_view_general_viewer = vim.fn.has("macunix") == 1 and "open" or "xdg-open"
			end
		end,
		keys = {
			{ "<leader>ll", "<cmd>VimtexCompile<cr>", desc = "LaTeX compile" },
			{ "<leader>lv", "<cmd>VimtexView<cr>", desc = "LaTeX view PDF" },
			{ "<leader>ls", "<cmd>VimtexStop<cr>", desc = "LaTeX stop compiler" },
			{ "<leader>le", "<cmd>VimtexErrors<cr>", desc = "LaTeX errors" },
			{ "<leader>lc", "<cmd>VimtexClean<cr>", desc = "LaTeX clean" },
			{ "<leader>li", "<cmd>VimtexInfo<cr>", desc = "LaTeX info" },
		},
	},
}
