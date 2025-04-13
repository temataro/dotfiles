-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      "c",
      "python",
      "rust"
      -- add more arguments for adding more treesitter parsers
    },
  },
}
