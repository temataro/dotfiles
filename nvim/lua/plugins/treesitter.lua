return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master", -- pin: the `main` rewrite has a different API
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "lua", "vim", "vimdoc", "python", "c", "cpp",
      "bash", "markdown", "markdown_inline", "json", "toml", "yaml",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    -- incremental_selection left off: it binds <C-Space>, which cmp uses.
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
