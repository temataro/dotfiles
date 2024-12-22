vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Optional: Configure the undo directory
vim.opt.undodir = vim.fn.stdpath("config") .. "/undodir"
vim.opt.undofile = true
