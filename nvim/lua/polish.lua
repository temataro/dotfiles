-- This will run last in the setup process and override anything set by plugins.

vim.opt.ruler = true
vim.opt.guicursor = ""

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true
vim.opt.updatetime = 10

vim.opt.nu = true
vim.opt.wrap = false
-- vim.opt.colorcolumn = "80"
vim.opt.smartindent = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.softtabstop = 4

-- Always keep 12 lines in view when scrolling
vim.opt.scrolloff = 12

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv "HOME" .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.signcolumn = "yes"

vim.g.mapleader = " "

-- Move selected lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Better cursor handling when joining lines
vim.keymap.set("n", "J", "mzJ`z")

-- Center search results
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Run Black on current file
vim.keymap.set("n", "<C-b>", ":!uv tool run black %<cr>")

vim.cmd [[ set showtabline=0 ]]
