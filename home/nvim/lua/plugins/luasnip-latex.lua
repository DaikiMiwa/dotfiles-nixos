return {
  {
    "iurimateus/luasnip-latex-snippets.nvim",
    ft = { "bib", "markdown", "plaintex", "tex" },
    dependencies = {
      "L3MON4D3/LuaSnip",
      "lervag/vimtex",
    },
    config = function()
      require("luasnip-latex-snippets").setup({
        allow_on_markdown = false,
        use_treesitter = false,
      })
      -- Only register math snippets for Markdown; upstream also adds prose triggers.
      local ls = require("luasnip")
      local is_math = function()
        local parser = vim.treesitter.get_parser(0, "markdown", { error = false })
        if not parser then
          return false
        end
        parser:parse(true)
        local node = vim.treesitter.get_node({ ignore_injections = true })
        while node do
          if node:type() == "fenced_code_block" or node:type() == "indented_code_block" then
            return false
          end
          node = node:parent()
        end
        return require("luasnip-latex-snippets.util.ts_utils").in_mathzone()
      end
      ls.add_snippets("markdown", require("luasnip-latex-snippets.math_i").retrieve(is_math))
      local autosnippets = {}
      for _, module in ipairs({
        "math_wRA_no_backslash",
        "math_rA_no_backslash",
        "math_wA_no_backslash",
        "math_iA_no_backslash",
        "math_iA",
        "math_wrA",
        "bwA",
      }) do
        vim.list_extend(autosnippets, require("luasnip-latex-snippets." .. module).retrieve(is_math))
      end
      ls.add_snippets("markdown", autosnippets, { type = "autosnippets", default_priority = 0 })
    end,
  },
}
