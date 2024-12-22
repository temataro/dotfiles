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

