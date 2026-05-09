return {
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = {
				timeout_ms = 1000,
				lsp_format = "fallback",
			},
			formatters_by_ft = {
				astro = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				lua = { "stylua" },
				markdown = { "prettier", "textlint" },
				mdx = { "prettier" },
				-- Conform will run multiple formatters sequentially
				python = { "ruff_format" },
				plaintex = { "latexindent" },
				tex = { "latexindent" },
				-- You can customize some of the format options for the filetype (:help conform.format)
				rust = { "rustfmt", lsp_format = "fallback" },
				terraform = { "terraform_fmt" },
				["terraform-vars"] = { "terraform_fmt" },
				-- Conform will run the first available formatter
				javascript = { "biome", "prettier", stop_after_first = true },
				javascriptreact = { "biome", "prettier", stop_after_first = true },
				typescript = { "biome", "prettier", stop_after_first = true },
				typescriptreact = { "biome", "prettier", stop_after_first = true },
				json = { "biome", "prettier", stop_after_first = true },
				jsonc = { "biome", "prettier", stop_after_first = true },
			},
			formatters = {
				biome = {
					condition = function(_, ctx)
						return vim.fs.root(ctx.filename, { "biome.json", "biome.jsonc" }) ~= nil
					end,
				},
				prettier = {
					condition = function(_, ctx)
						return vim.fs.root(ctx.filename, {
							".prettierrc",
							".prettierrc.json",
							".prettierrc.json5",
							".prettierrc.yaml",
							".prettierrc.yml",
							".prettierrc.js",
							".prettierrc.cjs",
							"prettier.config.js",
							"prettier.config.cjs",
							"package.json",
						}) ~= nil
					end,
				},
				textlint = {
					condition = function(_, ctx)
						return vim.fs.root(ctx.filename, {
							".textlintrc",
							".textlintrc.json",
							".textlintrc.js",
							".textlintrc.cjs",
							"textlint.config.js",
							"textlint.config.cjs",
							"package.json",
						}) ~= nil
					end,
					command = "textlint",
					args = {
						"--fix",
						"--config",
						vim.fn.expand("~/.textlintrc.json"),
						"$FILENAME",
					},
					stdin = false,
				},
			},
		},
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" }, function(err, did_edit)
						-- コールバック関数: フォーマット完了後に呼ばれる
						if err then
							-- エラーがあった場合
							vim.notify(
								"フォーマット失敗: " .. tostring(err),
								vim.log.levels.ERROR,
								{ title = "Conform" }
							)
						elseif did_edit then
							-- 変更があった場合のみ通知
							vim.notify("フォーマット完了！", vim.log.levels.INFO, { title = "Conform" })
						else
							-- 変更がなかった場合（すでに綺麗だった場合）
							vim.notify("変更なし", vim.log.levels.INFO, { title = "Conform" })
						end
					end)
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
	},
}
