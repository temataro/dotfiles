local telescope = require("telescope")

-- Basic Telescope setup
telescope.setup({
    defaults = {
        prompt_prefix = "🔍 ",
        selection_caret = "➤ ",
        path_display = { "truncate" },
    },
    pickers = {
        find_files = { theme = "dropdown" }, -- Apply a dropdown theme
    },
    extensions = {
        -- Add Telescope extensions here
    },
})

-- Keymaps for Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })

