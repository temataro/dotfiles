local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com:443/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if not ok then
  vim.api.nvim_echo({
    { ("Unable to load lazy.nvim from: %s\n"):format(lazypath), "ErrorMsg" },
    { "Press any key to exit...", "MoreMsg" },
  }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

lazy.setup({
  { import = "plugins" },
} --[[@as LazySpec]], {
  install = { colorscheme = { "rose-pine-main", "gruvbox", "github_dark" } },
  git = { url_format = "https://github.com:443/%s.git" },
  ui = { backdrop = 100 },
  rocks = { hererocks = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
} --[[@as LazyConfig]])
