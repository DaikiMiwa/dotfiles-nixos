return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
            return
          end
          vim.schedule(gitsigns.next_hunk)
        end, "Next git hunk")

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
            return
          end
          vim.schedule(gitsigns.prev_hunk)
        end, "Previous git hunk")

        map("n", "<leader>gh", gitsigns.stage_hunk, "Stage hunk")
        map("v", "<leader>gh", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage hunk")

        map("n", "<leader>gr", gitsigns.reset_hunk, "Reset hunk")
        map("v", "<leader>gr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset hunk")

        map("n", "<leader>gH", gitsigns.stage_buffer, "Stage buffer")
        map("n", "<leader>gR", gitsigns.reset_buffer, "Reset buffer")
        map("n", "<leader>gp", gitsigns.preview_hunk, "Preview hunk")
        map("n", "<leader>gB", gitsigns.blame_line, "Blame line")
        map("n", "<leader>gd", gitsigns.diffthis, "Diff against index")
        map("n", "<leader>gD", function()
          gitsigns.diffthis("~")
        end, "Diff against previous commit")
      end,
    },
  },
}
