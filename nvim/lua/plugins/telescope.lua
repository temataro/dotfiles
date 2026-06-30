return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    { "<Leader>ff", "<Cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<Leader>fg", "<Cmd>Telescope live_grep<CR>", desc = "Live grep" },
    { "<Leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<Leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Help tags" },
    { "<Leader>fr", "<Cmd>Telescope oldfiles<CR>", desc = "Recent files" },
    { "<Leader>fw", "<Cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
    { "<Leader>/", "<Cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },
  },
  opts = {
    defaults = {
      prompt_prefix = "   ",
      selection_caret = "  ",
      sorting_strategy = "ascending",
      layout_config = { prompt_position = "top" },
    },
  },
  config = function(_, opts)
    local telescope = require "telescope"
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf") -- falls back to lua sorter if build failed
  end,
}
