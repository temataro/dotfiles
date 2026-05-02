local groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "SignColumn",
  "FoldColumn",
  "LineNr",
  "CursorLineNr",
  "EndOfBuffer",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "Pmenu",
  "NvimTreeNormal",
  "NvimTreeNormalNC",
  "NvimTreeEndOfBuffer",
  "NvimTreeWinSeparator",
}

local function clear_background(group)
  local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok then return end

  highlight.bg = nil
  highlight.ctermbg = nil
  vim.api.nvim_set_hl(0, group, highlight)
end

local function apply_transparency()
  for _, group in ipairs(groups) do
    clear_background(group)
  end
end

apply_transparency()

local group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  desc = "Keep theme backgrounds transparent",
  callback = apply_transparency,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "NvimTree",
  desc = "Keep nvim-tree background transparent",
  callback = apply_transparency,
})
