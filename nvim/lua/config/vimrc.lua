-- Ported from ~/.vimrc. This file is loaded before lazy.nvim and polish.lua,
-- matching the old source order where polish.lua could override Vim defaults.

local opt = vim.opt

opt.autoindent = true
opt.expandtab = true
opt.softtabstop = 4
opt.shiftwidth = 4
opt.tabstop = 4
opt.backspace = { "indent", "eol", "start" }
opt.background = "dark"
opt.hlsearch = true
opt.incsearch = true
opt.ruler = true
opt.visualbell = true
opt.errorbells = false
opt.joinspaces = false
opt.textwidth = 79
opt.number = true
opt.spelllang = "en_us"
opt.wrap = false
opt.showbreak = ""
opt.fileformats = { "unix", "dos", "mac" }
opt.encoding = "utf-8"
opt.list = true
opt.listchars = { tab = "»·" }

opt.formatoptions:remove "t"

pcall(vim.cmd, "language en_US.UTF-8")
vim.cmd.syntax "on"

local function apply_highlights()
  vim.cmd.highlight "default link TooLong Error"
  vim.cmd.highlight "default link TrailinWhites MatchParen"
end

local function highlight_too_long_lines(highlight_trailing_whitespace)
  if vim.bo.textwidth ~= 0 then
    vim.cmd("match TooLong /\\%>" .. vim.bo.textwidth .. "v.\\+/")
  else
    vim.cmd "match none"
  end

  if highlight_trailing_whitespace then
    vim.cmd [[2match TrailinWhites /\s\+$/]]
  else
    vim.cmd "2match none"
  end
end

local function strip_trailing_whitespace()
  local view = vim.fn.winsaveview()
  vim.cmd [[%s/\s\+$//e]]
  vim.fn.winrestview(view)
end

apply_highlights()

local highlight_group = vim.api.nvim_create_augroup("VimrcHighlight", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = highlight_group,
  desc = "Restore vimrc highlight links after colorscheme changes",
  callback = apply_highlights,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufNewFile", "BufRead" }, {
  group = highlight_group,
  desc = "Highlight long lines and trailing whitespace",
  callback = function() highlight_too_long_lines(true) end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = highlight_group,
  desc = "Hide trailing whitespace highlight while inserting",
  callback = function() highlight_too_long_lines(false) end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = highlight_group,
  desc = "Restore trailing whitespace highlight after inserting",
  callback = function() highlight_too_long_lines(true) end,
})

local filetype_group = vim.api.nvim_create_augroup("VimrcFiletypes", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufFilePre", "BufRead" }, {
  group = filetype_group,
  pattern = { "*.markdown", "*.mdown", "*.mkd", "*.mkdn", "*.mdwn", "*.md" },
  desc = "Detect markdown files",
  callback = function() vim.bo.filetype = "markdown" end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufFilePre", "BufRead" }, {
  group = filetype_group,
  pattern = "*.function",
  desc = "Detect Mbed TLS function files as C",
  callback = function() vim.bo.filetype = "c" end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = filetype_group,
  pattern = { "*.vert", "*.tesc", "*.tese", "*.geom", "*.frag", "*.comp" },
  desc = "Detect GLSL shader files",
  callback = function() vim.bo.filetype = "glsl" end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = filetype_group,
  pattern = { "*.glsl", "*.glvs", "*.glfs", "*.vs", "*.fs" },
  desc = "Detect GLSL shader files",
  callback = function() vim.bo.filetype = "glsl" end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = filetype_group,
  pattern = { "*.rgen", "*.rmiss", "*.rchit", "*.rahit", "*.rint", "*.rcall" },
  desc = "Detect GLSL ray tracing shader files",
  callback = function() vim.bo.filetype = "glsl" end,
})

local ft_group = vim.api.nvim_create_augroup("VimrcFiletypeSettings", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = { "make", "automake" },
  desc = "Use hard tabs in Makefiles",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.softtabstop = 0
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = "go",
  desc = "Use hard tabs in Go files",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.softtabstop = 0
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = { "gitcommit", "patch" },
  desc = "Wrap and spell-check commit messages and patches",
  callback = function()
    vim.opt_local.textwidth = 72
    vim.opt_local.spell = true
    vim.opt_local.formatoptions:append "t"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = "markdown",
  desc = "Spell-check markdown",
  callback = function() vim.opt_local.spell = true end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = ft_group,
  pattern = "asm",
  desc = "Use hard tabs in assembly files",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.softtabstop = 8
    vim.opt_local.tabstop = 8
    vim.opt_local.shiftwidth = 8
  end,
})

vim.keymap.set("n", "gc", strip_trailing_whitespace, { desc = "Strip trailing whitespace" })

local clang_format
if vim.fn.has "macunix" == 1 then
  clang_format = ":pyf /opt/homebrew/Cellar/clang-format/12.0.1/share/clang/clang-format.py<CR>"
else
  clang_format = ":py3f /usr/local/llvm90/share/clang/clang-format.py<CR>"
end

vim.keymap.set({ "n", "v" }, "<C-K>", clang_format, { desc = "Run clang-format" })
vim.keymap.set("i", "<C-K>", "<C-o>" .. clang_format, { desc = "Run clang-format" })
