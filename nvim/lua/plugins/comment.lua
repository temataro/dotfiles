-- =============================================================================
-- comment.lua — comment toggling on <Leader>/
--
-- mini.comment provides the toggle. We can't lean on the builtin gcc operator
-- because normal-mode gc is taken by the strip-trailing-whitespace map in
-- config/vimrc.lua, which shadows the gcc prefix.
--
-- Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
-- SPDX-License-Identifier: Apache-2.0
-- =============================================================================

return {
  "echasnovski/mini.comment",
  keys = {
    { "<Leader>/", mode = { "n", "v" }, desc = "Toggle comment" },
  },
  opts = {
    mappings = {
      comment = "",
      comment_line = "<Leader>/",
      comment_visual = "<Leader>/",
      textobject = "",
    },
  },
}
