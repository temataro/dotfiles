return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<Leader>f", group = "find (telescope)" },
      { "<Leader>g", group = "git (hunks)" },
    },
  },
}
