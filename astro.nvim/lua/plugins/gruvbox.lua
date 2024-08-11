return {
  "ellisonleao/gruvbox.nvim",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "gruvbox",
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = false,
      emphasis = true,
      comments = false,
      operators = false,
      folds = false,
    },
    strikethrough = true,
    invert_selection = true,
    invert_signs = true,
    invert_tabline = true,
    invert_intend_guides = true,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "", -- can be "hard", "soft" or empty string
    palette_overrides = {bg = "#000000"},
    overrides = {},
    dim_inactive = true,
    transparent_mode = false,
  }
}
