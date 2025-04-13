-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
-- *** === *** Load vim's vimrcs here *** === ***
local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd.source(vimrc)
-- *** === ***        ^ __ ^          *** === ***

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
-- vim.opt.colorcolumn = "80"
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


-- Basic Key Remaps
vim.g.mapleader = " " -- Set leader key

-- Move selected lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Better cursor handling when joining lines
vim.keymap.set("n", "J", "mzJ`z")

-- Center search results
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
