return {
  "sudormrfbin/cheatsheet.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  cmd = { "Cheatsheet", "CheatsheetEdit" },
  keys = {
    { "<Leader>?", "<Cmd>Cheatsheet<CR>", desc = "Open cheatsheet" },
  },
  opts = {},
}
