return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    current_line_blame = false,
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- Navigate between chunks
      map("n", "]c", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(gs.next_hunk)
        return "<Ignore>"
      end, "Next git chunk")

      map("n", "[c", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(gs.prev_hunk)
        return "<Ignore>"
      end, "Prev git chunk")

      -- Stage / reset / preview
      map("n", "<Leader>gs", gs.stage_hunk, "Stage hunk")
      map("n", "<Leader>gr", gs.reset_hunk, "Reset hunk")
      map("v", "<Leader>gs", function() gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" } end, "Stage hunk")
      map("v", "<Leader>gr", function() gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" } end, "Reset hunk")
      map("n", "<Leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<Leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
      map("n", "<Leader>gd", gs.diffthis, "Diff this file")
    end,
  },
}
