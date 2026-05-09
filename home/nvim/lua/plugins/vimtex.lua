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

			local function is_ignored_path(path)
				return path:find("/build/", 1, true) ~= nil or path:find("/.git/", 1, true) ~= nil
			end

			local function project_files(pattern)
				local root = tex_root()
				local files = {}

				for _, file in ipairs(glob(root, pattern)) do
					if not is_ignored_path(file) then
						table.insert(files, file)
					end
				end

				table.sort(files)
				return files
			end

			local function relative_path(file)
				return vim.fn.fnamemodify(file, ":~:.")
			end

			local function edit_file_at(file, line)
				vim.cmd.edit(vim.fn.fnameescape(file))
				if line then
					vim.api.nvim_win_set_cursor(0, { line, 0 })
				end
			end

			local function main_tex()
				local root = tex_root()
				local candidates = {
					vim.fs.joinpath(root, "main.tex"),
					vim.api.nvim_buf_get_name(0),
				}

				for _, file in ipairs(candidates) do
					if file ~= "" and vim.fn.filereadable(file) == 1 and file:match("%.tex$") then
						return file
					end
				end
			end

			local function first_field(lines, start_index, field)
				local pattern = "^%s*" .. field .. '%s*=%s*[{"].-'

				for index = start_index, math.min(start_index + 20, #lines) do
					local line = lines[index]
					if line and line:lower():match(pattern) then
						local value = line:match('=%s*[{"]?(.-)[}"],?%s*$')
						return value
					end
				end
			end

			local function bibliography_entries()
				local root = tex_root()
				local entries = {}

				for _, file in ipairs(project_files("**/*.bib")) do
					local ok, lines = pcall(vim.fn.readfile, file)
					if ok then
						for index, line in ipairs(lines) do
							local kind, key = line:match("^%s*@([%w%-]+)%s*{%s*([^,%s]+)")
							if kind and key then
								local title = first_field(lines, index + 1, "title")
								local relative = relative_path(file)
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

			local function labels(prefix)
				local entries = {}

				for _, file in ipairs(project_files("**/*.tex")) do
					local ok, lines = pcall(vim.fn.readfile, file)
					if ok then
						for line_number, line in ipairs(lines) do
							for label in line:gmatch("\\label%s*{%s*([^}]+)%s*}") do
								if not prefix or label:match("^" .. vim.pesc(prefix)) then
									local relative = relative_path(file)
									table.insert(entries, {
										label = label,
										display = label .. " -- " .. relative .. ":" .. line_number,
									})
								end
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

			local function pick_citation(command)
				command = command or "cite"
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
						prompt = command .. "> ",
						fzf_opts = {
							["--multi"] = true,
						},
						actions = {
							["default"] = function(selected)
								if not selected[1] then
									return
								end
								local keys = vim.tbl_map(function(item)
									return item:match("^([^%s]+)")
								end, selected)
								insert_text("\\" .. command .. "{" .. table.concat(keys, ",") .. "}")
							end,
						},
					}
				)
			end

			local function pick_reference(prefix)
				local entries = labels(prefix)
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

			local function todo_entries()
				local entries = {}

				for _, pattern in ipairs({ "**/*.tex", "**/*.bib" }) do
					for _, file in ipairs(project_files(pattern)) do
						local ok, lines = pcall(vim.fn.readfile, file)
						if ok then
							for line_number, line in ipairs(lines) do
								if
									line:match("%%[%s]*TODO:")
									or line:match("%%[%s]*FIXME:")
									or line:match("%%[%s]*REVIEW:")
									or line:match("%%[%s]*NOTE:")
								then
									table.insert(entries, {
										file = file,
										line = line_number,
										display = relative_path(file) .. ":" .. line_number .. ": " .. line:gsub(
											"^%s*",
											""
										),
									})
								end
							end
						end
					end
				end

				table.sort(entries, function(left, right)
					return left.display < right.display
				end)

				return entries
			end

			local function pick_todo()
				local entries = todo_entries()
				if vim.tbl_isempty(entries) then
					vim.notify("No paper TODO comments found", vim.log.levels.INFO)
					return
				end

				local by_display = {}
				for _, entry in ipairs(entries) do
					by_display[entry.display] = entry
				end

				require("fzf-lua").fzf_exec(
					vim.tbl_map(function(entry)
						return entry.display
					end, entries),
					{
						prompt = "Paper TODO> ",
						actions = {
							["default"] = function(selected)
								if not selected[1] then
									return
								end
								local entry = by_display[selected[1]]
								if entry then
									edit_file_at(entry.file, entry.line)
								end
							end,
						},
					}
				)
			end

			local function paper_dashboard()
				local entries = {}
				local root = tex_root()
				local patterns = {
					"main.tex",
					"*.tex",
					"**/*.tex",
					"**/*.bib",
					"figures/*",
					"tables/*",
					"notes/*",
					"build/*.pdf",
				}

				local seen = {}
				for _, pattern in ipairs(patterns) do
					for _, file in ipairs(glob(root, pattern)) do
						if not seen[file] and (pattern == "build/*.pdf" or not is_ignored_path(file)) then
							seen[file] = true
							table.insert(entries, {
								file = file,
								display = relative_path(file),
							})
						end
					end
				end

				table.sort(entries, function(left, right)
					return left.display < right.display
				end)

				local by_display = {}
				for _, entry in ipairs(entries) do
					by_display[entry.display] = entry
				end

				require("fzf-lua").fzf_exec(
					vim.tbl_map(function(entry)
						return entry.display
					end, entries),
					{
						prompt = "Paper> ",
						actions = {
							["default"] = function(selected)
								local entry = by_display[selected[1]]
								if entry then
									vim.cmd.edit(vim.fn.fnameescape(entry.file))
								end
							end,
						},
					}
				)
			end

			local function word_count()
				local main = main_tex()
				if not main then
					vim.notify("No main TeX file found", vim.log.levels.WARN)
					return
				end

				local output = vim.fn.systemlist({ "texcount", "-inc", "-total", main })
				local pdf = vim.fs.joinpath(tex_root(), "build", vim.fn.fnamemodify(main, ":t:r") .. ".pdf")
				if vim.fn.filereadable(pdf) == 1 then
					vim.list_extend(output, { "", "PDF:" })
					vim.list_extend(output, vim.fn.systemlist({ "pdfinfo", pdf }))
				end

				vim.cmd("botright 16new")
				vim.bo.buftype = "nofile"
				vim.bo.bufhidden = "wipe"
				vim.bo.swapfile = false
				vim.api.nvim_buf_set_name(0, "paper-count")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
				vim.bo.modifiable = false
			end

			local function run_paper_check()
				local main = main_tex() or "main.tex"
				vim.cmd("botright split | terminal paper-check " .. vim.fn.fnameescape(main))
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("my.vimtex.paper", {}),
				pattern = { "bib", "plaintex", "tex" },
				callback = function(event)
					vim.keymap.set("n", "<leader>lb", function()
						pick_citation("cite")
					end, {
						buffer = event.buf,
						desc = "LaTeX cite bibliography entry",
					})
					vim.keymap.set("i", "<C-g>b", function()
						pick_citation("cite")
					end, {
						buffer = event.buf,
						desc = "LaTeX cite bibliography entry",
					})
					vim.keymap.set("n", "<leader>lp", function()
						pick_citation("parencite")
					end, {
						buffer = event.buf,
						desc = "LaTeX parencite bibliography entry",
					})
					vim.keymap.set("i", "<C-g>p", function()
						pick_citation("parencite")
					end, {
						buffer = event.buf,
						desc = "LaTeX parencite bibliography entry",
					})
					vim.keymap.set("n", "<leader>la", function()
						pick_citation("textcite")
					end, {
						buffer = event.buf,
						desc = "LaTeX textcite bibliography entry",
					})
					vim.keymap.set("i", "<C-g>a", function()
						pick_citation("textcite")
					end, {
						buffer = event.buf,
						desc = "LaTeX textcite bibliography entry",
					})
					vim.keymap.set("n", "<leader>lr", function()
						pick_reference()
					end, {
						buffer = event.buf,
						desc = "LaTeX insert reference",
					})
					vim.keymap.set("i", "<C-g>r", function()
						pick_reference()
					end, {
						buffer = event.buf,
						desc = "LaTeX insert reference",
					})
					vim.keymap.set("n", "<leader>lF", function()
						pick_reference("fig:")
					end, {
						buffer = event.buf,
						desc = "LaTeX insert figure reference",
					})
					vim.keymap.set("n", "<leader>lT", function()
						pick_reference("tab:")
					end, {
						buffer = event.buf,
						desc = "LaTeX insert table reference",
					})
					vim.keymap.set("n", "<leader>lE", function()
						pick_reference("eq:")
					end, {
						buffer = event.buf,
						desc = "LaTeX insert equation reference",
					})
					vim.keymap.set("n", "<leader>lt", "<cmd>VimtexTocToggle<cr>", {
						buffer = event.buf,
						desc = "LaTeX table of contents",
					})
					vim.keymap.set("n", "<leader>ld", paper_dashboard, {
						buffer = event.buf,
						desc = "LaTeX paper dashboard",
					})
					vim.keymap.set("n", "<leader>lo", pick_todo, {
						buffer = event.buf,
						desc = "LaTeX TODO picker",
					})
					vim.keymap.set("n", "<leader>lw", word_count, {
						buffer = event.buf,
						desc = "LaTeX word and page count",
					})
					vim.keymap.set("n", "<leader>lC", run_paper_check, {
						buffer = event.buf,
						desc = "LaTeX run paper-check",
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
