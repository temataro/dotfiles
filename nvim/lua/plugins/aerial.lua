-- =============================================================================
-- aerial.lua — symbol outline sidebar
--
-- Everything not listed here uses aerial's upstream defaults (treesitter/lsp
-- backends, prefer_right layout, default keymaps and filter_kind).
--
-- Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
-- SPDX-License-Identifier: Apache-2.0
-- =============================================================================

return {
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen" },
  keys = {
    { "<Leader>s", "<Cmd>AerialToggle left<CR>", desc = "Toggle symbol sidebar" },
    { "<Leader>a", "<Cmd>AerialToggle!<CR>", desc = "Toggle symbol sidebar (stay)" },
  },
  opts = {
    show_guides = true,
  },
}
