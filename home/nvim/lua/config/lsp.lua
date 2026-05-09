local servers = {
	"astro",
	"tailwindcss",
	"emmet_language_server",
	"html",
	"cssls",
	"jsonls",
	"pyrefly",
	"ruff",
	"ts_ls",
	"biome",
	"basedpyright",
	"lua_ls",
	"sqls",
	"terraformls",
	"texlab",
	"ltex_plus",
}

local function get_typescript_tsdk(root_dir)
	if root_dir then
		local local_tsdk = vim.fs.joinpath(root_dir, "node_modules", "typescript", "lib")
		if vim.fn.isdirectory(local_tsdk) == 1 then
			return local_tsdk
		end
	end

	local global_root = vim.fn.trim(vim.fn.system({ "npm", "root", "-g" }))
	if vim.v.shell_error == 0 and global_root ~= "" then
		local global_tsdk = vim.fs.joinpath(global_root, "typescript", "lib")
		if vim.fn.isdirectory(global_tsdk) == 1 then
			return global_tsdk
		end
	end
end

vim.lsp.config("pyrefly", {
	root_markers = { "pyrefly.toml" },
})

vim.lsp.config.astro = vim.tbl_deep_extend("force", vim.lsp.config.astro or {}, {
	cmd = { "astro-ls", "--stdio" },
	init_options = {
		typescript = {},
	},
	before_init = function(_, config)
		config.init_options = config.init_options or {}
		config.init_options.typescript = config.init_options.typescript or {}
		config.init_options.typescript.tsdk = get_typescript_tsdk(config.root_dir)
	end,
})

vim.lsp.config("tailwindcss", {
	filetypes = {
		"astro",
		"css",
		"html",
		"javascript",
		"javascriptreact",
		"markdown",
		"scss",
		"typescript",
		"typescriptreact",
	},
	settings = {
		tailwindCSS = {
			includeLanguages = {
				astro = "html",
				javascript = "javascript",
				javascriptreact = "javascript",
				typescript = "typescript",
				typescriptreact = "typescript",
			},
			classAttributes = { "class", "className", "class:list" },
			experimental = {
				classRegex = {
					{ "class:list=\\{([^}]*)\\}", "[\"'`]([^\"'`]*)[\"'`]" },
					{ "clsx\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
					{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*)[\"'`]" },
				},
			},
		},
	},
})

vim.lsp.config("emmet_language_server", {
	filetypes = {
		"astro",
		"css",
		"html",
		"javascriptreact",
		"typescriptreact",
	},
})

vim.lsp.config("html", {
	filetypes = { "html" },
})

vim.lsp.config("cssls", {
	filetypes = { "css", "scss" },
})

vim.lsp.config("jsonls", {
	filetypes = { "json", "jsonc" },
})

vim.lsp.config("terraformls", {
	filetypes = { "terraform" },
})

local function tex_forward_search()
	local skim_displayline = "/Applications/Skim.app/Contents/SharedSupport/displayline"

	if vim.fn.executable(skim_displayline) == 1 then
		return {
			executable = skim_displayline,
			args = {
				"-r",
				"%l",
				"%p",
				"%f",
			},
		}
	end

	if vim.fn.executable("zathura") == 1 then
		return {
			executable = "zathura",
			args = {
				"--synctex-forward",
				"%l:1:%f",
				"%p",
			},
		}
	end
end

local texlab_forward_search = tex_forward_search()

local texlab_settings = {
	build = {
		args = {
			"-file-line-error",
			"-interaction=nonstopmode",
			"-synctex=1",
			"%f",
		},
		auxDirectory = "build",
		executable = "latexmk",
		forwardSearchAfter = texlab_forward_search ~= nil,
		onSave = false,
	},
	chktex = {
		onEdit = false,
		onOpenAndSave = true,
	},
	latexFormatter = "latexindent",
}

if texlab_forward_search then
	texlab_settings.forwardSearch = texlab_forward_search
end

vim.lsp.config("texlab", {
	settings = {
		texlab = texlab_settings,
	},
})

vim.lsp.config("ltex_plus", {
	filetypes = {
		"bib",
		"gitcommit",
		"markdown",
		"plaintex",
		"tex",
	},
	settings = {
		ltex = {
			language = "auto",
			additionalRules = {
				enablePickyRules = true,
			},
			disabledRules = {
				["en-US"] = {
					"WHITESPACE_RULE",
				},
			},
		},
	},
})

if vim.fn.executable("sourcekit-lsp") == 1 then
	vim.list_extend(servers, { "sourcekit" })
end

vim.lsp.enable(servers)

-- 言語サーバーがアタッチされた時に呼ばれる
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		local buf = args.buf

		-- デフォルトで設定されている言語サーバー用キーバインドに設定を追加する
		-- See https://neovim.io/doc/user/lsp.html#lsp-defaults
		-- 言語サーバーのクライアントがLSPで定められた機能を実装していたら設定を追加するという流れ
		if client:supports_method("textDocument/definition") then
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
		end

		if client:supports_method("textDocument/declaration") then
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = buf, desc = "Go to declaration" })
		end

		if client:supports_method("textDocument/implementation") then
			vim.keymap.set("n", "gI", vim.lsp.buf.implementation, { buffer = buf, desc = "Go to implementation" })
		end

		if client:supports_method("textDocument/typeDefinition") then
			vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { buffer = buf, desc = "Go to type definition" })
		end

		if client:supports_method("textDocument/rename") then
			vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { buffer = buf, desc = "Rename symbol" })
		end

		if client:supports_method("textDocument/hover") then
			vim.keymap.set("n", "<leader>k", function()
				vim.lsp.buf.hover({ border = "single" })
			end, { buffer = buf, desc = "Show hover documentation" })
		end

		if client:supports_method("textDocument/inlineCompletion") and vim.lsp.inline_completion then
			vim.lsp.inline_completion.enable(true, { bufnr = buf })
			vim.keymap.set("i", "<Tab>", function()
				if not vim.lsp.inline_completion.get() then
					return "<Tab>"
				end
				-- close the completion popup if it's open
				if vim.fn.pumvisible() == 1 then
					return "<C-e>"
				end
			end, {
				expr = true,
				buffer = buf,
				desc = "Accept the current inline completion",
			})
		end
	end,
})
