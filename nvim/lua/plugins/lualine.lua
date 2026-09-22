-- =============================================================================
-- lualine.lua — statusline and buffer tabline
--
-- Single global statusline plus a buffer list in the tabline so
-- <C-l>/<C-j> and <Leader>H/<Leader>L cycling is no longer blind.
-- config/transparency.lua strips the tabline backgrounds on ColorScheme.
--
-- Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
-- SPDX-License-Identifier: Apache-2.0
-- =============================================================================

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      theme = "rose-pine",
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "lsp_status", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    tabline = {
      lualine_a = {
        {
          "buffers",
          show_filename_only = true,
          mode = 0, -- name only
          symbols = { modified = " ●", alternate_file = "" },
        },
      },
    },
    extensions = { "nvim-tree", "aerial", "lazy" },
  },
}
