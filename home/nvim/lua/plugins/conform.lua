-- Stop at the project boundary so the personal config in $HOME is opt-in.
local function textlint_root(ctx)
  local dir = vim.fs.dirname(vim.fs.normalize(ctx.filename))
  local home = vim.fs.normalize(vim.fn.expand("~"))
  while dir and dir ~= home do
    for _, name in ipairs({
      ".textlintrc",
      ".textlintrc.json",
      ".textlintrc.yaml",
      ".textlintrc.yml",
      ".textlintrc.js",
      ".textlintrc.cjs",
      "textlint.config.js",
      "textlint.config.cjs",
    }) do
      if vim.uv.fs_stat(dir .. "/" .. name) then
        return dir
      end
    end
    if vim.uv.fs_stat(dir .. "/.git") then
      return nil
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

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
            return textlint_root(ctx) ~= nil
          end,
          cwd = function(_, ctx)
            return textlint_root(ctx)
          end,
          command = "textlint",
          args = {
            "--fix",
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
              vim.notify("フォーマット失敗: " .. tostring(err), vim.log.levels.ERROR, { title = "Conform" })
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
