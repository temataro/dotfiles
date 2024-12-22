require("neo-tree").setup({
    close_if_last_window = true,
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
})

-- Keymap for Neo-tree
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })

