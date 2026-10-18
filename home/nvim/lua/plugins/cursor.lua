return {
  {
    "h4kbas/cursor.nvim",
    cmd = {
      "CursorChat",
      "CursorClose",
      "CursorStop",
      "CursorSessionManage",
      "CursorSessionNew",
      "CursorSessionSwitch",
      "CursorSessionDelete",
      "CursorSessionRename",
      "CursorCheckpointRevert",
    },
    keys = {
      { "<leader>ac", "<cmd>CursorChat<cr>", desc = "Cursor chat" },
      { "<leader>aS", "<cmd>CursorStop<cr>", desc = "Stop Cursor" },
      { "<leader>as", "<cmd>CursorSessionManage<cr>", desc = "Cursor sessions" },
    },
    opts = {},
  },
}
