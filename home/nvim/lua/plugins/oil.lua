return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
      default_file_explorer = true,
      columns = {
        "icon",
      },
      keymaps = {
        ["gF"] = {
          desc = "Reveal entry in Finder",
          callback = function()
            local oil = require("oil")
            local entry, dir = oil.get_cursor_entry(), oil.get_current_dir()
            if not entry or not dir then
              return
            end
            if vim.fn.has("mac") ~= 1 then
              vim.notify("Finder is only available on macOS; use gx to open externally", vim.log.levels.INFO)
              return
            end
            vim.system({ "open", "-R", dir .. entry.name }, {}, function(result)
              if result.code ~= 0 then
                vim.schedule(function()
                  vim.notify("Could not reveal entry in Finder: " .. (result.stderr or ""), vim.log.levels.ERROR)
                end)
              end
            end)
          end,
        },
      },
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },
    },
    keys = {
      {
        "<leader>e",
        function()
          require("oil").open()
        end,
        mode = { "n" },
      },
    },
  },
}
