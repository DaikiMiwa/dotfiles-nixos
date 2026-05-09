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
		config = function()
			local function tex_root()
				if vim.b.vimtex and vim.b.vimtex.root then
					return vim.b.vimtex.root
				end

				local current = vim.api.nvim_buf_get_name(0)
				if current ~= "" then
					return vim.fs.root(current, { ".latexmkrc", "latexmkrc", "main.tex", ".git" })
						or vim.fn.fnamemodify(current, ":p:h")
				end

				return vim.uv.cwd()
			end

			local function glob(root, pattern)
				return vim.fn.globpath(root, pattern, false, true)
			end

			local function first_field(lines, start_index, field)
				local pattern = "^%s*" .. field .. '%s*=%s*[{"].-'

				for index = start_index, math.min(start_index + 20, #lines) do
					local line = lines[index]
					if line and line:lower():match(pattern) then
						local value = line:gsub("^%s*" .. field .. "%s*=%s*", "")
						value = value:gsub('^[{"]', ""):gsub('[}",]%s*$', "")
						return value
					end
				end
			end

			local function bibliography_entries()
				local root = tex_root()
				local entries = {}

				for _, file in ipairs(glob(root, "**/*.bib")) do
					local ok, lines = pcall(vim.fn.readfile, file)
					if ok then
						for index, line in ipairs(lines) do
							local kind, key = line:match("^%s*@([%w%-]+)%s*{%s*([^,%s]+)")
							if kind and key then
								local title = first_field(lines, index + 1, "title")
								local relative = vim.fn.fnamemodify(file, ":~:.")
								local label = title and (key .. " [" .. kind .. "] " .. title)
									or (key .. " [" .. kind .. "]")

								table.insert(entries, {
									key = key,
									label = label .. " -- " .. relative,
								})
							end
						end
					end
				end

				table.sort(entries, function(left, right)
					return left.key < right.key
				end)

				return entries
			end

			local function labels()
				local root = tex_root()
				local entries = {}

				for _, file in ipairs(glob(root, "**/*.tex")) do
					local ok, lines = pcall(vim.fn.readfile, file)
					if ok then
						for line_number, line in ipairs(lines) do
							for label in line:gmatch("\\label%s*{%s*([^}]+)%s*}") do
								local relative = vim.fn.fnamemodify(file, ":~:.")
								table.insert(entries, {
									label = label,
									display = label .. " -- " .. relative .. ":" .. line_number,
								})
							end
						end
					end
				end

				table.sort(entries, function(left, right)
					return left.label < right.label
				end)

				return entries
			end

			local function insert_text(text)
				vim.api.nvim_put({ text }, "c", true, true)
			end

			local function pick_citation()
				local entries = bibliography_entries()
				if vim.tbl_isempty(entries) then
					vim.notify("No bibliography entries found", vim.log.levels.WARN)
					return
				end

				require("fzf-lua").fzf_exec(
					vim.tbl_map(function(entry)
						return entry.label
					end, entries),
					{
						prompt = "Cite> ",
						actions = {
							["default"] = function(selected)
								if not selected[1] then
									return
								end
								local key = selected[1]:match("^([^%s]+)")
								insert_text("\\cite{" .. key .. "}")
							end,
						},
					}
				)
			end

			local function pick_reference()
				local entries = labels()
				if vim.tbl_isempty(entries) then
					vim.notify("No labels found", vim.log.levels.WARN)
					return
				end

				require("fzf-lua").fzf_exec(
					vim.tbl_map(function(entry)
						return entry.display
					end, entries),
					{
						prompt = "Ref> ",
						actions = {
							["default"] = function(selected)
								if not selected[1] then
									return
								end
								local label = selected[1]:match("^([^%s]+)")
								insert_text("\\cref{" .. label .. "}")
							end,
						},
					}
				)
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("my.vimtex.paper", {}),
				pattern = { "bib", "plaintex", "tex" },
				callback = function(event)
					vim.keymap.set("n", "<leader>lb", pick_citation, {
						buffer = event.buf,
						desc = "LaTeX cite bibliography entry",
					})
					vim.keymap.set("i", "<C-g>b", pick_citation, {
						buffer = event.buf,
						desc = "LaTeX cite bibliography entry",
					})
					vim.keymap.set("n", "<leader>lr", pick_reference, {
						buffer = event.buf,
						desc = "LaTeX insert reference",
					})
					vim.keymap.set("i", "<C-g>r", pick_reference, {
						buffer = event.buf,
						desc = "LaTeX insert reference",
					})
					vim.keymap.set("n", "<leader>lt", "<cmd>VimtexTocToggle<cr>", {
						buffer = event.buf,
						desc = "LaTeX table of contents",
					})
				end,
			})
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
