return {
  {
    "stevearc/oil.nvim",
    lazy=false,
    opts={
      default_file_explorer = true,
      columns = {
        "icon"
      },
      view_options = {
        -- Show files and directories that start with "."
        show_hidden = true,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      }
    },
    keys = {
      {
        "<leader>e",
        function()
          require("oil").open()
        end,
        mode = {"n"},
      }
    }
  }
}
