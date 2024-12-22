print("[DBG_TEM] Settings Loaded from ./lua/settings/set.lua!")

-- all the vim things we wanna set in vim
vim.g.mapleader = " "

vim.opt.ruler = true
vim.opt.guicursor = ""

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.updatetime = 10

vim.opt.nu = true
vim.opt.wrap = false
vim.opt.colorcolumn = "80"
vim.opt.smartindent = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.softtabstop = 4


-- Always keeps 12 lines in view when scrolling up or down
vim.opt.scrolloff = 12

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
