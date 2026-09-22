return {
  "nvim-tree/nvim-tree.lua",
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
  keys = {
    { "<Leader>e", "<Cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
  },
  opts = {
    view = {
      side = "left",
      width = 32,
    },
    git = {
      enable = true,
    },
    renderer = {
      group_empty = true,
      icons = {
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
        },
      },
    },
    update_focused_file = {
      enable = true,
    },
  },
}
