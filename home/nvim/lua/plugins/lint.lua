return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local lint = require("lint")

			local function has_root_file(names)
				local path = vim.api.nvim_buf_get_name(0)
				return path ~= "" and vim.fs.root(path, names) ~= nil
			end

			local function linters_for_current_buffer()
				local ft = vim.bo.filetype

				if ft == "python" then
					return { "ruff" }
				end

				if ft == "terraform" and has_root_file({ ".tflint.hcl" }) then
					return { "tflint" }
				end

				if
					vim.tbl_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact" }, ft)
					and has_root_file({
						"eslint.config.js",
						"eslint.config.mjs",
						"eslint.config.cjs",
						".eslintrc",
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.json",
						".eslintrc.yaml",
						".eslintrc.yml",
					})
				then
					return { "eslint" }
				end

				return {}
			end

			lint.linters_by_ft = {}

			vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("my.lint", {}),
				callback = function()
					lint.try_lint(linters_for_current_buffer())
				end,
			})

			vim.keymap.set("n", "<leader>cl", function()
				lint.try_lint(linters_for_current_buffer())
			end, { desc = "Lint buffer" })
		end,
	},
}
